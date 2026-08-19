# Generates a multi-resolution Windows icon (.ico) from the project's custom icon.
# Uses classic BMP/DIB-encoded entries for maximum compatibility (Explorer, GDI+, WiX).
# Input : assets\icon\app_icon.png
# Output: windows\runner\resources\app_icon.ico
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$srcPath = Join-Path $root "assets\icon\app_icon.png"
$outPath = Join-Path $root "windows\runner\resources\app_icon.ico"

if (-not (Test-Path $srcPath)) {
    Write-Error "Source image not found: $srcPath"
    exit 1
}

$sizes = @(16, 24, 32, 48, 64, 128, 256)

$src = [System.Drawing.Image]::FromFile($srcPath)

# Build one ICO image entry (BITMAPINFOHEADER + bottom-up BGRA pixels + AND mask).
function New-IcoEntry([int]$s) {
    $bmp = New-Object System.Drawing.Bitmap($s, $s, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.DrawImage($src, 0, 0, $s, $s)
    $g.Dispose()

    $rect = New-Object System.Drawing.Rectangle(0, 0, $s, $s)
    $bd = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $stride = $bd.Stride
    $pixels = New-Object byte[] ($s * $stride)
    [System.Runtime.InteropServices.Marshal]::Copy($bd.Scan0, $pixels, 0, $pixels.Length)
    $bmp.UnlockBits($bd)
    $bmp.Dispose()

    # DIB stores rows bottom-up; the bitmap buffer is top-down (stride = s*4 for 32bpp).
    $xor = New-Object byte[] ($s * $s * 4)
    for ($row = 0; $row -lt $s; $row++) {
        $srcRow = $row * $stride
        $dstRow = ($s - 1 - $row) * ($s * 4)
        [Array]::Copy($pixels, $srcRow, $xor, $dstRow, $s * 4)
    }

    # AND mask: 1bpp, each row padded to a 32-bit boundary, all zero (alpha governs).
    $andStride = [int]([math]::Ceiling($s / 32.0) * 4)
    $and = New-Object byte[] ($s * $andStride)

    $ms = New-Object System.IO.MemoryStream
    $bw = New-Object System.IO.BinaryWriter($ms)
    $bw.Write([int]40)                                   # biSize
    $bw.Write([int]$s)                                   # biWidth
    $bw.Write([int]($s * 2))                             # biHeight (XOR + AND)
    $bw.Write([uint16]1)                                 # biPlanes
    $bw.Write([uint16]32)                                # biBitCount
    $bw.Write([int]0)                                    # biCompression (BI_RGB)
    $bw.Write([int]($xor.Length + $and.Length))          # biSizeImage
    $bw.Write([int]0)                                    # biXPelsPerMeter
    $bw.Write([int]0)                                    # biYPelsPerMeter
    $bw.Write([int]0)                                    # biClrUsed
    $bw.Write([int]0)                                    # biClrImportant
    $bw.Write($xor)
    $bw.Write($and)
    $bw.Flush()
    $data = $ms.ToArray()
    $bw.Close()
    $ms.Dispose()
    return ,$data
}

$entries = New-Object System.Collections.ArrayList
foreach ($s in $sizes) {
    [void]$entries.Add((New-IcoEntry $s))
}
$src.Dispose()

$count = $entries.Count
$outDir = Split-Path -Parent $outPath
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

$fs = [System.IO.File]::Open($outPath, [System.IO.FileMode]::Create)
$bw = New-Object System.IO.BinaryWriter($fs)
$bw.Write([uint16]0)   # reserved
$bw.Write([uint16]1)   # type: icon
$bw.Write([uint16]$count)

$offset = 6 + 16 * $count
for ($i = 0; $i -lt $count; $i++) {
    $s = $sizes[$i]
    $dim = if ($s -ge 256) { 0 } else { $s }
    $data = $entries[$i]
    $bw.Write([byte]$dim)        # width (0 means 256)
    $bw.Write([byte]$dim)        # height (0 means 256)
    $bw.Write([byte]0)           # color count
    $bw.Write([byte]0)           # reserved
    $bw.Write([uint16]1)         # color planes
    $bw.Write([uint16]32)        # bits per pixel
    $bw.Write([uint32]$data.Length)
    $bw.Write([uint32]$offset)
    $offset += $data.Length
}

foreach ($data in $entries) {
    $bw.Write($data)
}

$bw.Flush()
$bw.Close()
$fs.Close()

Write-Output ("Generated icon: " + $outPath + " (" + $count + " sizes)")
