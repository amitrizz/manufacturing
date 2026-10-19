# Install debug APK via adb (phone: USB debugging ON).
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$latestApkFile = Get-ChildItem -Path $root -Filter "manufacturing_*.apk" -ErrorAction SilentlyContinue |
  Sort-Object { [int]($_.BaseName -replace '\D','') } -Descending |
  Select-Object -First 1

$apk = if ($latestApkFile) { $latestApkFile.FullName } else { "$root\android\app\build\outputs\apk\debug\app-debug.apk" }
if (-not (Test-Path $apk)) {
  Write-Host "APK not found. Run .\scripts\build-debug-apk.ps1 first." -ForegroundColor Red
  exit 1
}

$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
if (-not (Test-Path $adb)) {
  Write-Host "adb not found at $adb - install Android SDK platform-tools or copy APK manually." -ForegroundColor Red
  exit 1
}

Write-Host "Checking for connected Android devices via adb..." -ForegroundColor Cyan
$devicesOutput = & $adb devices
Write-Host $devicesOutput

$deviceLines = ($devicesOutput -split "`r?`n") | Where-Object { $_ -match '\tdevice$' }
if (-not $deviceLines -or $deviceLines.Count -eq 0) {
  Write-Host ""
  Write-Host "No Android device/emulator currently detected via adb." -ForegroundColor Yellow
  Write-Host ""
  Write-Host "To install over USB:" -ForegroundColor Cyan
  Write-Host "  1. Connect your Android phone to PC with a USB cable."
  Write-Host "  2. On phone: Go to Settings -> Developer Options -> Enable USB Debugging."
  Write-Host "  3. Accept the 'Allow USB debugging?' prompt on your phone screen."
  Write-Host "  4. Re-run: .\scripts\install-debug-apk.ps1"
  Write-Host ""
  Write-Host "Alternative (Manual copy):" -ForegroundColor Green
  Write-Host "  Copy this APK file to your phone and tap to install:"
  Write-Host "  $apk"
  exit 0
}

Write-Host "Device detected: $($deviceLines[0])" -ForegroundColor Green
Write-Host "Uninstalling previous version..."
try {
  & $adb uninstall com.manufacturing.ops 2>&1 | Out-Null
} catch {
  # Ignore if not already installed
}

Write-Host "Installing fresh APK..." -ForegroundColor Cyan
& $adb install -r -d $apk
if ($LASTEXITCODE -eq 0) {
  Write-Host ""
  Write-Host "Installed successfully on device!" -ForegroundColor Green
} else {
  Write-Host ""
  Write-Host "Install failed. Try manually uninstalling 'Manufacturing' on the phone first." -ForegroundColor Red
  exit $LASTEXITCODE
}
