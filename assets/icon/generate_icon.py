#!/usr/bin/env python3
"""生成 FreeBuff 网关管理应用图标。
设计: 蓝→紫渐变 + 白色极简"路由器"符号(圆环+中心点+顶部三天线)。
- app_icon.png: 1024 完整图标 (iOS 圆角矩形)
- app_icon_foreground.png: 自适应前景 (透明背景, 66% 安全区)
"""
from PIL import Image, ImageDraw

SIZE = 1024

TOP = (0x0A, 0x84, 0xFF)   # 系统蓝
BOT = (0x58, 0x56, 0xD6)   # 靛蓝紫


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def vertical_gradient(size, top, bot):
    img = Image.new('RGB', (size, size))
    px = img.load()
    for y in range(size):
        c = lerp(top, bot, y / (size - 1))
        for x in range(size):
            px[x, y] = c
    return img


def draw_symbol(d, cx, cy, s, color=(255, 255, 255)):
    def v(x):
        return int(x * s)

    # 天线 (三条短线, 从圆环顶向上) + 顶端圆点
    a_w, a_h = v(26), v(150)
    top_y = cy - v(250) - a_h
    for dx in (-v(96), 0, v(96)):
        d.rounded_rectangle(
            [cx + dx - a_w // 2, top_y, cx + dx + a_w // 2, top_y + a_h],
            radius=a_w // 2, fill=color,
        )
        r = v(22)
        d.ellipse([cx + dx - r, top_y - r, cx + dx + r, top_y + r], fill=color)

    # 圆环
    ring_r = v(250)
    ring_w = v(34)
    d.ellipse([cx - ring_r, cy - ring_r, cx + ring_r, cy + ring_r],
              outline=color, width=ring_w)

    # 中心实心圆
    dot_r = v(78)
    d.ellipse([cx - dot_r, cy - dot_r, cx + dot_r, cy + dot_r], fill=color)

    # 高光弧
    hl_r = v(190)
    hl_w = v(14)
    d.arc([cx - hl_r, cy - hl_r, cx + hl_r, cy + hl_r],
          start=200, end=340, fill=(255, 255, 255, 90), width=hl_w)


def rounded(img, radius):
    mask = Image.new('L', img.size, 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle([0, 0, img.size[0] - 1, img.size[1] - 1],
                        radius=radius, fill=255)
    out = Image.new('RGBA', img.size)
    out.paste(img, (0, 0), mask)
    return out


base = '/var/minis/workspace/freebuff-gateway-admin/assets/icon/'

bg = vertical_gradient(SIZE, TOP, BOT).convert('RGBA')
d = ImageDraw.Draw(bg, 'RGBA')
draw_symbol(d, SIZE / 2, SIZE / 2 + 6, SIZE / 1024)
rounded(bg, int(SIZE * 0.225)).save(base + 'app_icon.png')

fg = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
d2 = ImageDraw.Draw(fg, 'RGBA')
draw_symbol(d2, SIZE / 2, SIZE / 2, SIZE / 1024 * 0.80)
fg.save(base + 'app_icon_foreground.png')

print('icon done')
