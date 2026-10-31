# Manufacturing ERP - Flutter App

A cross-platform mobile application for Manufacturing ERP built with Flutter for Android and iOS.

## Features

- **Dashboard** - Real-time KPIs, production progress, machine status, attendance, and activity feed
- **Production Management** - Orders, plans, and shop floor tracking
- **Inventory Management** - Materials, products, stock transactions, finished goods
- **Machine Monitoring** - Real-time status, efficiency, runtime tracking
- **Maintenance** - Preventive/breakdown orders, scheduling, history
- **Quality Control** - Inspections, rework tracking, results
- **Purchase & GRN** - Purchase orders, supplier management, goods receipt
- **Dispatch** - Delivery orders, customer management
- **Reports** - Production trends, OEE, quality analytics
- **Staff Management** - Employee directory, attendance tracking
- **Settings** - API configuration, theme, data management

## Architecture

- **State Management**: Riverpod
- **Navigation**: GoRouter
- **Networking**: Dio with interceptors
- **Local Storage**: SharedPreferences + Flutter Secure Storage
- **Serialization**: Freezed + JSON Serializable
- **Charts**: FL Chart

## Project Structure

```
lib/
├── constants/          # App constants and theme
├── models/             # Freezed data models
├── providers/          # Riverpod providers
├── routes/             # GoRouter configuration
├── screens/            # Feature screens
│   ├── auth/
│   ├── dashboard/
│   ├── production/
│   ├── inventory/
│   ├── machines/
│   ├── maintenance/
│   ├── quality/
│   ├── purchase/
│   ├── dispatch/
│   ├── reports/
│   ├── staff/
│   ├── settings/
│   └── onboarding/
├── services/           # API service
├── utils/              # Formatters, validators, logger
└── main.dart
```

## Getting Started

### Prerequisites

- Flutter SDK 3.16+
- Dart 3.2+
- Android Studio / Xcode
- Backend API running (Node.js Manufacturing API)

### Installation

```bash
cd manufacturing_app
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

### Code Generation

After modifying models, run:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Or for continuous generation:

```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

## API Configuration

The app automatically discovers the backend API:
- **Development**: Tries localhost (10.0.2.2 for Android emulator, localhost for iOS)
- **Production**: Uses configured remote URL
- **Manual**: Set custom URL in Settings > API Configuration

## Backend API

This app connects to the Manufacturing Node.js API with endpoints:
- `/api/v1/health` - Health check
- `/api/v1/companies` - Company management
- `/api/v1/dashboard/stats` - Dashboard KPIs
- `/api/v1/machines` - Machine fleet
- `/api/v1/production-orders` - Production orders
- `/api/v1/collections/{name}` - Generic CRUD for all collections
- `/api/v1/purchase/grn-receipts` - GRN receipts
- `/api/v1/purchase/receive-grn` - Receive GRN

## Build for Production

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle (Play Store)
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## Model Reference

All models are generated from Freezed annotations and match the backend MongoDB schemas:

- **Company** - Company, CompanyRole
- **Staff** - Staff, StaffAttendance
- **Machine** - Machine, MachineDowntime, ProductionLine
- **Production** - ProductionPlan, ProductionOrder, ProductionEntry
- **Inventory** - Material, Product, ProductCategory, Bom, BomItem, StockTransaction
- **Quality** - QualityInspection, QualityResult, ReworkOrder
- **Maintenance** - MaintenanceOrder, MaintenanceHistory
- **Dispatch** - FinishedGoods, DispatchOrder
- **Purchase** - Supplier, Customer, PurchaseRequest, PurchaseOrder, PurchaseOrderItem, GrnReceipt, GrnItem

## Theme

Supports both Light and Dark modes with Material 3 design system. Theme preference is persisted and follows system setting by default.

## License

Proprietary - Manufacturing ERP System