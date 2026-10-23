# Run this in PowerShell to avoid path-length / sandbox issues.
# Optional: .\scripts\build-debug-apk.ps1 -Clean  (after CPU ABI changes; needs more RAM/time)
param([switch]$Clean)
$ErrorActionPreference = "Stop"
$scriptDir = $PSScriptRoot
$workspaceRoot = Split-Path -Parent $scriptDir
if (-not (Test-Path "$workspaceRoot\frontend")) {
  $workspaceRoot = Split-Path -Parent $workspaceRoot
}
if (Test-Path "$workspaceRoot\frontend\android\gradlew.bat") {
  $root = "$workspaceRoot\frontend"
} elseif (Test-Path "$workspaceRoot\android\gradlew.bat") {
  $root = $workspaceRoot
} else {
  $root = (Get-Location).Path
}

$env:JAVA_HOME = "C:\Program Files\Java\jdk-17"
$env:NODE_ENV = "production"
$env:GRADLE_USER_HOME = "C:\gradle-home"

Set-Location "$root\android"
$gradleTask = if ($Clean) { "clean assembleDebug" } else { "assembleDebug" }
# Clean rebuilds compile all native ABIs from scratch — use 1 worker to avoid clang OOM / small paging file
$workers = if ($Clean) { 1 } else { 2 }
.\gradlew.bat $gradleTask --no-daemon --max-workers=$workers

$apk = "$root\android\app\build\outputs\apk\debug\app-debug.apk"
if (-not (Test-Path $apk)) {
  Write-Host "Build finished but APK not found at expected path." -ForegroundColor Yellow
  exit 1
}

Write-Host ""
Write-Host "APK ready:" -ForegroundColor Green
Write-Host $apk
Write-Host ("Size: {0:N1} MB" -f ((Get-Item $apk).Length / 1MB))

# Auto-detect next build number for manufacturing_<N>.apk
$existingNums = Get-ChildItem -Path $workspaceRoot -Filter "manufacturing_*.apk" -ErrorAction SilentlyContinue |
  ForEach-Object {
    if ($_.Name -match '^manufacturing_(\d+)\.apk$') {
      [int]$Matches[1]
    }
  }

$nextBuildNum = 1
if ($existingNums) {
  $nextBuildNum = ($existingNums | Measure-Object -Maximum).Maximum + 1
}

$buildApkName = "manufacturing_$nextBuildNum.apk"
$buildApkPath = "$workspaceRoot\$buildApkName"
$latestApk = "$workspaceRoot\manufacturing.apk"

Copy-Item -Path $apk -Destination $buildApkPath -Force
Copy-Item -Path $apk -Destination $latestApk -Force
if ($root -ne $workspaceRoot) {
  Copy-Item -Path $apk -Destination "$root\$buildApkName" -Force
  Copy-Item -Path $apk -Destination "$root\manufacturing.apk" -Force
}

Write-Host "Copied to project root as:" -ForegroundColor Green
Write-Host "  - $buildApkName (Build #$nextBuildNum)" -ForegroundColor Green
Write-Host "  - manufacturing.apk" -ForegroundColor Cyan

Add-Type -AssemblyName System.IO.Compression.FileSystem
$z = [System.IO.Compression.ZipFile]::OpenRead($apk)
$abis = $z.Entries |
  Where-Object { $_.FullName -like 'lib/*/*.so' } |
  ForEach-Object { ($_.FullName -split '/')[1] } |
  Sort-Object -Unique
$z.Dispose()
Write-Host ("CPU ABIs in APK: {0}" -f ($abis -join ', ')) -ForegroundColor Cyan
if ($abis -notcontains 'armeabi-v7a' -or $abis -notcontains 'arm64-v8a') {
  Write-Host "Warning: expected both armeabi-v7a and arm64-v8a. If install fails on a phone, rebuild after checking android/gradle.properties reactNativeArchitectures." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Install tips (Mi / Redmi):" -ForegroundColor Yellow
Write-Host "  1. Uninstall old 'Manufacturing' app first (Settings -> Apps)."
Write-Host "  2. Copy APK with USB or Files app; do not send via WhatsApp."
Write-Host "  3. Allow install from this source (File Manager / Mi Browser)."
Write-Host "  4. Or USB: run scripts\install-debug-apk.ps1"
