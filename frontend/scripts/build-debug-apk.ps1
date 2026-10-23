# Run this in PowerShell to avoid path-length / sandbox issues.
# Optional: .\scripts\build-debug-apk.ps1 -Clean  (after CPU ABI changes; needs more RAM/time)
param([switch]$Clean)
$ErrorActionPreference = "Stop"
$scriptDir = $PSScriptRoot
$workspaceRoot = Split-Path -Parent $scriptDir
if (-not (Test-Path "$workspaceRoot\frontend")) {
  $workspaceRoot = Split-Path -Parent $workspaceRoot
}

$origLocation = (Get-Location).Path
$origWorkspaceRoot = $workspaceRoot
$useSubst = $false
$driveLetter = "M"

# Clean any leftover virtual drive first
& subst "$driveLetter`:" /d 2>$null

# On Windows, Android NDK CMake / Ninja toolchains exceed MAX_PATH (260 chars) when project is in deep directories.
# Map frontend directory directly to virtual drive M:\ so root is M:\ and paths are extremely short (<190 chars).
$frontendDir = if (Test-Path "$workspaceRoot\frontend") { "$workspaceRoot\frontend" } else { $workspaceRoot }
try {
  subst "$driveLetter`:" "$frontendDir"
  if (Test-Path "$driveLetter`:\android\gradlew.bat") {
    $useSubst = $true
    $root = "$driveLetter`:\"
    Write-Host "Mapped frontend to $driveLetter`:\ for ultra-short path NDK compilation." -ForegroundColor Cyan
    # Clean stale cmake cache if present
    if (Test-Path "$root\android\app\.cxx") {
      Remove-Item -Path "$root\android\app\.cxx" -Recurse -Force -ErrorAction SilentlyContinue
    }
  } else {
    & subst "$driveLetter`:" /d 2>$null
    $root = $frontendDir
  }
} catch {
  Write-Host "Virtual drive fallback: $_" -ForegroundColor Yellow
  $root = $frontendDir
}

$env:JAVA_HOME = "C:\Program Files\Java\jdk-17"
$env:NODE_ENV = "production"
$env:GRADLE_USER_HOME = "C:\gradle-home"

try {
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
  $existingNums = Get-ChildItem -Path $origWorkspaceRoot -Filter "manufacturing_*.apk" -ErrorAction SilentlyContinue |
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
  $buildApkPath = "$origWorkspaceRoot\$buildApkName"
  $latestApk = "$origWorkspaceRoot\manufacturing.apk"

  Copy-Item -Path $apk -Destination $buildApkPath -Force
  Copy-Item -Path $apk -Destination $latestApk -Force

  # Also copy to frontend root
  if (Test-Path "$origWorkspaceRoot\frontend") {
    Copy-Item -Path $apk -Destination "$origWorkspaceRoot\frontend\$buildApkName" -Force
    Copy-Item -Path $apk -Destination "$origWorkspaceRoot\frontend\manufacturing.apk" -Force
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

  Write-Host ""
  Write-Host "Install tips (Mi / Redmi):" -ForegroundColor Yellow
  Write-Host "  1. Uninstall old 'Manufacturing' app first (Settings -> Apps)."
  Write-Host "  2. Copy APK with USB or Files app; do not send via WhatsApp."
  Write-Host "  3. Allow install from this source (File Manager / Mi Browser)."
  Write-Host "  4. Or USB: run scripts\install-debug-apk.ps1"
} finally {
  Set-Location $origLocation
  if ($useSubst) {
    & subst "$driveLetter`:" /d 2>$null
    Write-Host "Unmounted virtual drive $driveLetter`:" -ForegroundColor DarkGray
  }
}
