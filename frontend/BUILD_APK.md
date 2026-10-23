# Build APK

## Cloud (recommended) — needs Expo account

```bash
npx eas-cli@latest login
npx eas-cli@latest init
npm run build:apk
```

Download the APK from the link Expo prints (expo.dev → Builds).

## Local debug APK (no Expo login)

Requires Android SDK (`android/local.properties`) and **JDK 17** (`android/gradle.properties` sets `org.gradle.java.home`).

**Easiest on Windows** — run in a normal PowerShell window (not only inside Cursor):

```powershell
# 1. Build the APK:
.\scripts\build-debug-apk.ps1

# 2. Install on connected phone via USB:
.\scripts\install-debug-apk.ps1
```

**APK path after success:**

Each build creates an auto-incremented file in the project root:
- `manufacturing_1.apk`, `manufacturing_2.apk`, etc.
- `manufacturing.apk` (always points to the latest build)
- Full debug output: `android\app\build\outputs\apk\debug\app-debug.apk`

If the build fails with *Filename longer than 260 characters*, enable [Windows long paths](https://learn.microsoft.com/en-us/windows/win32/fileio/maximum-file-path-limitation) or move the project to a short folder (e.g. `C:\Manufacturing`) and build again.

### `expo-log-box:compileDebugKotlin` — unresolved `expo.modules.core.interfaces`

This means `@expo/log-box` compiled without `expo-modules-core` on the classpath (Kotlin then treats `Package` as `java.lang.Package`). The repo includes a config plugin (`plugins/withExpoAndroidBuildFix.js`) that adds an explicit `implementation` dependency. After `npx expo prebuild --clean`, run the build script again.

### Gradle daemon disappeared / OOM

Close other heavy apps, use `.\scripts\build-debug-apk.ps1` (uses `--no-daemon` and limits workers). `android/gradle.properties` uses a 2GB heap so native (CMake) builds have room on 16GB RAM machines.

### `clean` build fails: clang signal / paging file too small

NDK compile ran out of RAM. Use `.\scripts\build-debug-apk.ps1` **without** `-Clean` if you only changed JS; for `-Clean`, close other apps (script uses 1 worker). Increase Windows **virtual memory** (paging file) if errors mention `0x5AF` or “paging file is too small”.

### `expo-log-box:compileDebugKotlin` — unresolved `expo.modules.core.interfaces`

This means `@expo/log-box` compiled without `expo-modules-core` on the classpath (Kotlin then treats `Package` as `java.lang.Package`). The repo includes a config plugin (`plugins/withExpoAndroidBuildFix.js`) that adds an explicit `implementation` dependency. After `npx expo prebuild --clean`, run the build script again.

### Gradle daemon disappeared / OOM

Close other heavy apps, use `.\scripts\build-debug-apk.ps1` (uses `--no-daemon` and limits workers). `android/gradle.properties` uses a 2GB heap so native (CMake) builds have room on 16GB RAM machines.

Install on a device: copy the file and open it, or `adb install app-debug.apk`.

## Device support (Android phones, incl. Redmi / Mi 8A)

- **Minimum Android:** 7.0 (API 24). **Redmi 8A / Mi 8A** ships with Android 9+ and is supported.
- **CPU:** APK includes **armeabi-v7a** and **arm64-v8a** (typical Qualcomm/MediaTek phones in India).
- After changing `app.json` / architectures, run `npx expo prebuild --platform android` (or rebuild with the script) and reinstall the APK.

**On Xiaomi / MIUI:** allow “Install unknown apps” for your file manager, then open the APK. If the app closes in background, disable battery restrictions for *Manufacturing* (Settings → Apps → Manufacturing → Battery → No restrictions).

### App not installing?

| Symptom | Fix |
|--------|-----|
| “App not installed” (no detail) | **Uninstall** any old *Manufacturing* / `com.manufacturing.ops` app, then install again. |
| Same app, different signature | Uninstall first (debug vs release / old build). |
| WhatsApp / Telegram APK | **Do not** send APK in chat — use USB, Google Drive, or Mi Share. |
| Wrong CPU (rare) | Re-run `.\scripts\build-debug-apk.ps1` — script prints `CPU ABIs in APK` (need **armeabi-v7a** and **arm64-v8a**). |
| USB install | `.\scripts\install-debug-apk.ps1` (USB debugging on). |

After changing architectures, the build script runs **`clean`** so native libraries are rebuilt.

### Red screen: “Unable to load script”

A **debug** APK built without an embedded bundle only works with **Metro** running (`npx expo start`) and the phone on the same network (or `adb reverse tcp:8081 tcp:8081` over USB).

The project sets `debuggableVariants = []` so the local build script **embeds** the JavaScript bundle in the APK. Re-run `.\scripts\build-debug-apk.ps1`, reinstall the new APK, then open the app again.
