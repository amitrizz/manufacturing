# Manufacturing Operations Management Platform

Complete separation into two independent modules: **Backend** (Node.js + Express + MongoDB Atlas) and **Frontend** (Expo / React Native Android mobile app).

```
Manufacturing/
├── backend/                  # Independent Node.js Backend connected to MongoDB Atlas
│   ├── .env                  # MongoDB Atlas connection string & configuration
│   ├── package.json          # Express, Cors, Dotenv, MongoDB dependencies
│   ├── server.js             # Comprehensive REST API (Dashboard, Production, Machines, GRN, Seed/Clear)
│   ├── migrate.js            # Standalone MongoDB migration and seeding script
│   └── README.md             # Backend setup & API reference
│
├── frontend/                 # Android Mobile App calling Backend for all data operations
│   ├── .env                  # Mobile configuration
│   ├── app.json              # Expo configuration
│   ├── package.json          # Mobile dependencies & npm scripts
│   ├── tsconfig.json         # TypeScript configuration
│   ├── android/              # Native Android project with Gradle wrapper
│   ├── assets/               # Icons & splash screens
│   ├── src/                  # App components, screens, hooks, navigation, and API client
│   └── README.md             # Frontend setup & APK build instructions
│
├── manufacturing_frontend.apk # Standalone release-ready Android debug APK
└── README.md                 # Project root overview
```

---

## 🚀 Running the Project

### 1. Backend Service
```bash
cd backend
npm install
npm start
```
- Listens on `http://0.0.0.0:5000`
- Directly connected to MongoDB Atlas (`cluster0.tysk0hr.mongodb.net/manufacturing`)

### 2. Frontend Mobile App (Expo Go)
```bash
cd frontend
npm start
```
- Metro bundler runs on `http://0.0.0.0:8081`
- Open in **Expo Go** with `exp://<LOCAL_IP>:8081`

### 3. Frontend Android APK
- Standalone debug APK: `manufacturing_frontend.apk`
- To recompile:
  ```bash
  cd frontend
  npm run build:apk:local
  ```
