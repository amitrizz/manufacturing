# Manufacturing Frontend (Android & Expo Mobile App)

Decoupled mobile application for the Manufacturing operations platform built with Expo & React Native.
All data queries, mutations, calculations, and workflows are processed by calling the standalone **Backend Service** (`backend/`) connected to **MongoDB Atlas**.

---

## 🏗️ Architecture

- **Framework**: React Native 0.86 with Expo SDK 57
- **API Client**: `src/api/client.ts` (`mongoApi`) connecting over HTTP to the Backend Service
- **Single Source of Truth**: MongoDB Atlas via backend REST APIs (`/api/dashboard/stats`, `/api/machines`, `/api/production-orders`, `/api/purchase/grn-receipts`, etc.)
- **Platform Support**: Android (standalone APK & Expo Go), iOS

---

## 🚀 Quick Start

### 1. Ensure Backend is Running
Before starting the frontend, ensure the backend server in `../backend` is running on port 5000:
```bash
cd ../backend
npm start
```

### 2. Run with Expo Go
```bash
cd frontend
npm start
```
- Scan the printed QR code with **Expo Go** on Android or iOS.
- Or open directly in Expo Go using URL: `exp://<YOUR_LOCAL_IP>:8081` (e.g. `exp://192.168.1.53:8081`).

---

## 📦 Building the Android APK

Build a local debug APK directly from `frontend/`:
```bash
npm run build:apk:local
```
Output APK location:
`frontend/android/app/build/outputs/apk/debug/app-debug.apk`
(Also copied to root as `manufacturing_frontend.apk`).

---

## ⚙️ Backend URL Configuration in App
- In the app, navigate to **Settings** -> **Data Management** -> **Test MongoDB Backend**.
- For Android Emulator, the default URL is `http://10.0.2.2:5000`.
- For physical Android devices on Wi-Fi, the app connects to `http://<YOUR_PC_IP>:5000` (e.g. `http://192.168.1.53:5000`).
