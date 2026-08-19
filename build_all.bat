@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem ============================================================
rem  FreeBuff Gateway Admin - one-click build (Android + Windows)
rem  Outputs are copied to the "artifact" folder next to this file.
rem ============================================================

set "PROJECT_DIR=%~dp0"
cd /d "%PROJECT_DIR%"

rem ---------- Toolchain paths (edit if your machine differs) ----------
set "FLUTTER_BIN=D:\software\flutter\bin"
set "ANDROID_SDK=D:\software\AndroidSDK"
set "ANDROID_NDK=%ANDROID_SDK%\ndk\30.0.15729638"
set "JAVA_HOME=D:\software\Android Studio\jbr"
set "WIX_BIN=D:\software\wix"

rem ---------- App metadata (keep in sync with pubspec.yaml) ----------
set "APP_VERSION=1.0.0"

rem ---------- Derived paths ----------
set "ARTIFACT_DIR=%PROJECT_DIR%artifact"
set "ANDROID_APK_SRC=%PROJECT_DIR%build\app\outputs\flutter-apk\app-release.apk"
set "WIN_REL_DIR=%PROJECT_DIR%build\windows\x64\runner\Release"
set "WIX_SRC_DIR=%PROJECT_DIR%windows\installer"
set "WIX_OUT_DIR=%PROJECT_DIR%build\wix"

rem ---------- Environment ----------
set "ANDROID_HOME=%ANDROID_SDK%"
set "ANDROID_SDK_ROOT=%ANDROID_SDK%"
set "PATH=%FLUTTER_BIN%;%WIX_BIN%;%JAVA_HOME%\bin;%PATH%"

echo.
echo ============================================================
echo   FreeBuff Gateway Admin - Build (Android + Windows)
echo   Version: %APP_VERSION%
echo ============================================================
echo.

rem ============================================================
echo [1/8] Checking toolchain...
rem ============================================================
if not exist "%FLUTTER_BIN%\flutter.bat" ( echo [ERROR] Flutter not found at %FLUTTER_BIN% & exit /b 1 )
if not exist "%ANDROID_SDK%"            ( echo [ERROR] Android SDK not found at %ANDROID_SDK% & exit /b 1 )
if not exist "%ANDROID_NDK%"            ( echo [ERROR] Android NDK not found at %ANDROID_NDK% & exit /b 1 )
if not exist "%JAVA_HOME%\bin\java.exe" ( echo [ERROR] JDK not found at %JAVA_HOME% & exit /b 1 )
if not exist "%WIX_BIN%\candle.exe"    ( echo [ERROR] WiX candle.exe not found at %WIX_BIN% & exit /b 1 )
if not exist "%WIX_BIN%\light.exe"     ( echo [ERROR] WiX light.exe not found at %WIX_BIN% & exit /b 1 )
if not exist "%WIX_BIN%\heat.exe"      ( echo [ERROR] WiX heat.exe not found at %WIX_BIN% & exit /b 1 )
echo       Toolchain OK.

rem Point Flutter at this machine's Android SDK and JDK.
call "%FLUTTER_BIN%\flutter.bat" config --android-sdk "%ANDROID_SDK%" --jdk-dir "%JAVA_HOME%" 1>nul 2>nul

rem ============================================================
echo [2/8] Generating application icons...
rem ============================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%PROJECT_DIR%tools\make_icon.ps1"
if errorlevel 1 ( echo [ERROR] Icon generation failed. & exit /b 1 )
echo       Windows icon generated.

rem ============================================================
echo [3/8] Resolving dependencies (flutter pub get)...
rem ============================================================
call "%FLUTTER_BIN%\flutter.bat" pub get
if errorlevel 1 ( echo [ERROR] flutter pub get failed. & exit /b 1 )

rem ============================================================
echo [4/8] Regenerating Android launcher icons (flutter_launcher_icons)...
rem ============================================================
call "%FLUTTER_BIN%\dart.bat" run flutter_launcher_icons
if errorlevel 1 ( echo [WARN] flutter_launcher_icons failed; continuing with existing icons. )

rem ============================================================
echo [5/8] Building Android APK (release)...
rem ============================================================
call "%FLUTTER_BIN%\flutter.bat" build apk --release
if errorlevel 1 ( echo [ERROR] Android build failed. & exit /b 1 )
echo       Android APK built.

rem ============================================================
echo [6/8] Building Windows executable (release)...
rem ============================================================
call "%FLUTTER_BIN%\flutter.bat" build windows --release
if errorlevel 1 ( echo [ERROR] Windows build failed. & exit /b 1 )
echo       Windows executable built.

rem ============================================================
echo [7/8] Packaging Windows installer (WiX MSI)...
rem ============================================================
if not exist "%WIX_OUT_DIR%" mkdir "%WIX_OUT_DIR%"
if not exist "%WIN_REL_DIR%\gateway_admin.exe" ( echo [ERROR] Windows exe missing: %WIN_REL_DIR% & exit /b 1 )

"%WIX_BIN%\heat.exe" dir "%WIN_REL_DIR%" -gg -g1 -sfrag -srd -dr INSTALLFOLDER -cg ProductComponents -var var.SourceDir -out "%WIX_OUT_DIR%\harvested.wxs"
if errorlevel 1 ( echo [ERROR] heat.exe failed. & exit /b 1 )

"%WIX_BIN%\candle.exe" -arch x64 -dSourceDir=%WIN_REL_DIR% -dAppIcon=%PROJECT_DIR%windows\runner\resources\app_icon.ico -dVersion=%APP_VERSION% -out %WIX_OUT_DIR%\ "%WIX_SRC_DIR%\Product.wxs" "%WIX_OUT_DIR%\harvested.wxs"
if errorlevel 1 ( echo [ERROR] candle.exe failed. & exit /b 1 )

"%WIX_BIN%\light.exe" -ext WixUIExtension -out "%WIX_OUT_DIR%\FreeBuffGatewayAdmin-%APP_VERSION%-x64.msi" "%WIX_OUT_DIR%\Product.wixobj" "%WIX_OUT_DIR%\harvested.wixobj"
if errorlevel 1 ( echo [ERROR] light.exe failed. & exit /b 1 )
echo       MSI built.

rem ============================================================
echo [8/8] Collecting artifacts...
rem ============================================================
if not exist "%ARTIFACT_DIR%" mkdir "%ARTIFACT_DIR%"

rem --- Android APK ---
copy /y "%ANDROID_APK_SRC%" "%ARTIFACT_DIR%\FreeBuffGatewayAdmin-%APP_VERSION%.apk" >nul
if errorlevel 1 ( echo [ERROR] Failed to copy APK. & exit /b 1 )

rem --- Windows installer (MSI) ---
copy /y "%WIX_OUT_DIR%\FreeBuffGatewayAdmin-%APP_VERSION%-x64.msi" "%ARTIFACT_DIR%\FreeBuffGatewayAdmin-%APP_VERSION%-x64.msi" >nul
if errorlevel 1 ( echo [ERROR] Failed to copy MSI. & exit /b 1 )

rem --- Windows portable bundle (exe + dependencies) ---
if exist "%ARTIFACT_DIR%\gateway_admin-windows-x64" rmdir /s /q "%ARTIFACT_DIR%\gateway_admin-windows-x64"
robocopy "%WIN_REL_DIR%" "%ARTIFACT_DIR%\gateway_admin-windows-x64" /E /NFL /NDL /NJH /NJS /NP >nul
if errorlevel 8 ( echo [ERROR] Failed to copy Windows bundle. & exit /b 1 )

rem --- Windows portable zip ---
if exist "%ARTIFACT_DIR%\gateway_admin-windows-x64.zip" del /q "%ARTIFACT_DIR%\gateway_admin-windows-x64.zip"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Compress-Archive -Path '%ARTIFACT_DIR%\gateway_admin-windows-x64' -DestinationPath '%ARTIFACT_DIR%\gateway_admin-windows-x64.zip' -Force"
if errorlevel 1 ( echo [WARN] Failed to create zip; the portable folder is still available. )

echo.
echo ============================================================
echo   BUILD SUCCESSFUL
echo ============================================================
echo   Artifacts:
echo     - %ARTIFACT_DIR%\FreeBuffGatewayAdmin-%APP_VERSION%.apk
echo     - %ARTIFACT_DIR%\gateway_admin-windows-x64\gateway_admin.exe
echo     - %ARTIFACT_DIR%\gateway_admin-windows-x64.zip
echo     - %ARTIFACT_DIR%\FreeBuffGatewayAdmin-%APP_VERSION%-x64.msi
echo ============================================================
echo.
exit /b 0
