@echo off
setlocal
cd /d "%~dp0manufacturing_app"
call build_apk.bat
if %ERRORLEVEL% EQU 0 (
    copy /y "build\app\outputs\flutter-apk\app-release.apk" "%~dp0manufacturing_app_release.apk" >nul
    copy /y "build\app\outputs\flutter-apk\app-release.apk" "%~dp0manufacturing.apk" >nul
    echo.
    echo ========================================================
    echo  APK Build Successful! 
    echo  Output: %~dp0manufacturing_app_release.apk
    echo ========================================================
) else (
    echo.
    echo [ERROR] Build failed with code %ERRORLEVEL%
)
