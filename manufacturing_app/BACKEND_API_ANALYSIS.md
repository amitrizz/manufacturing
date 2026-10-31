# Backend API Analysis for Manufacturing ERP

This document provides a complete analysis of the backend API endpoints, data models, and frontend structure for building the Flutter/Dart mobile application.

## API Base URL

- **Development**: `http://10.0.2.2:5000/api/v1` (Android Emulator) / `http://localhost:5000/api/v1` (iOS Simulator)
- **Production**: Configured via environment variable `EXPO_PUBLIC_API_URL`

## Authentication

- **Company-based multi-tenancy**: All requests require `x-company-id` header
- **Admin verification**: POST `/companies/verify-admin` with email/code + password
- **Session storage**: Company ID stored in AsyncStorage after login

---

## API Endpoints

### 1. Health Check
```
GET /health
Response: { status, database, collectionsCount, version, timestamp }
```

### 2. Company Management
```
POST /companies                    # Create company
GET /companies                     # List all companies
GET /companies/:id                 # Get company by ID
POST /companies/verify-admin       # Verify admin credentials
```

### 3. Dashboard & KPIs
```
GET /dashboard/stats?start=&end=   # Comprehensive dashboard data
Response: {
  kpis: { target, produced, achievement, qualityRate, machineAvailability, downtimeHours, machineStatusCounts, lineProgress[] },
  machines: { running, breakdown, maintenance, idle, total },
  attendance: { total, present, halfDay, leave, absent, rate },
  pendingTasksCount,
  recentActivities[],
  monthlyData[{ month, year, target, produced, pct }]
}
```

### 4. Machines
```
GET /machines?status=&lineId=&search=&limit=&skip=&sort=&order=
POST /machines/:id/status { status, reason? }
```

### 5. Production Orders
```
GET /production-orders?status=&limit=&skip=&sort=&order=
POST /production-orders/:id/start
```

### 6. Purchase & GRN
```
GET /purchase/grn-receipts
POST /purchase/receive-grn { po_id?, supplier_id?, invoice_number?, notes?, received_items[{ material_id, received_qty }] }
DELETE /purchase/delete-grn/:id
```

### 7. Generic Collections CRUD
```
GET /collections/:name?filter&limit&skip&sort&order
GET /collections/:name/:id
POST /collections/:name
PUT /collections/:name/:id
DELETE /collections/:name/:id
```

### 8. Units
```
GET /units
POST /units { code, name, symbol?, category?, precision? }
POST /units/seed
```

### 9. Database Operations
```
GET /database/all
POST /database/clear { confirm: true }
POST /database/seed { confirm: true }
POST /database/reset { confirm: true }
```

---

## Data Models (MongoDB Collections)

### Core Collections (Global)
- **companies** - Company registration, admin credentials
- **units** - Measurement units (PCS, KG, MTR, etc.)

### Multi-Tenant Collections (Scoped by company_id)
- **staff** - Employees with roles, shifts, rates
- **staff_attendance** - Daily attendance records
- **production_lines** - Production line definitions
- **machines** - Machine fleet with status, line assignment
- **machine_downtime** - Breakdown/maintenance records
- **production_plans** - High-level production plans
- **production_orders** - Shop floor production orders
- **production_entries** - Daily production output records
- **materials** - Raw materials with stock levels
- **products** - Finished product catalog
- **product_categories** - Product categorization
- **bom** - Bill of Materials headers
- **bom_items** - BOM line items
- **stock_transactions** - Inventory movements
- **suppliers** - Supplier master data
- **customers** - Customer master data
- **purchase_requests** - Internal purchase requests
- **purchase_orders** - Purchase orders to suppliers
- **purchase_order_items** - PO line items
- **grn_receipts** - Goods Receipt Notes
- **quality_inspections** - Quality inspection records
- **quality_results** - Inspection parameter results
- **rework_orders** - Rework tracking
- **maintenance_orders** - Maintenance work orders
- **maintenance_history** - Completed maintenance records
- **finished_goods** - Finished goods inventory
- **dispatch_orders** - Customer dispatch/delivery orders
- **activity_history** - Audit trail
- **notifications** - User notifications

---

## Frontend Structure (React Native/Expo Reference)

### Navigation Structure
```
RootNavigator
├── Onboarding (FirstLaunch)
├── Login
└── Main (Authenticated)
    ├── RootTabs (Bottom Navigation)
    │   ├── Home → DashboardScreen
    │   ├── MyTasks → ActivityHistoryScreen
    │   ├── Management → ManagementScreen
    │   └── Profile → SettingsScreen
    └── Stack Screens (Modal/Detail)
        ├── ProductionOrders, ProductionOrderCreate, ProductionOrderDetail
        ├── ProductionFloor, RecordProduction, ProductionHub
        ├── ProductionPlans, ProductionPlanCreate, ProductionPlanDetail
        ├── StockHome, Materials, MaterialDetail
        ├── Products, ProductBom, ProductCreate, ProductEdit
        ├── PurchaseHome
        ├── MachineList, MachineDetail, ReportBreakdown
        ├── Maintenance, MaintenanceDetail
        ├── FinishedGoods
        ├── Staff
        ├── QualityDashboard, InspectionCreate, ReworkList
        ├── Dispatch, DispatchCreate
        ├── Reports, Oee
        ├── Contacts
        ├── GlobalSearch
        ├── Management, RolesList
        ├── ActivityHistory, Notifications
        ├── Settings, PlatformWorkflow
```

### Key Screens & Components

#### DashboardScreen
- Greeting header with date
- 4 KPI cards: Output, Quality, Active Machines, Alerts
- Circular production progress
- Machine status row (Running/Breakdown/Maintenance/Total)
- Recent activity feed
- Monthly production bar chart
- Attendance & Pending Tasks bottom cards

#### Production Screens
- **ProductionHubScreen**: Main production dashboard
- **ProductionFloorScreen**: Real-time machine status grid
- **ProductionOrdersScreen**: Order list with filters
- **ProductionOrderDetailScreen**: Order details, BOM, entries
- **RecordProductionScreen**: Daily output entry per machine
- **ProductionPlansScreen**: Plan list with progress

#### Inventory Screens
- **MaterialsScreen**: Raw materials with stock levels
- **MaterialDetailScreen**: Stock history, transactions
- **ProductsScreen**: Finished product catalog
- **ProductBomScreen**: BOM management
- **StockHomeScreen**: Inventory overview

#### Machine Screens
- **MachineListScreen**: Filterable machine grid
- **MachineDetailScreen**: Status, production history, downtime

#### Quality Screens
- **QualityDashboardScreen**: Inspection overview
- **InspectionCreateScreen**: New inspection entry

#### Purchase Screens
- **PurchaseHomeScreen**: GRN receipts, PO management
- **GRN Create**: Receive goods against PO or direct

#### Maintenance Screens
- **MaintenanceScreen**: Work orders list
- **MaintenanceDetailScreen**: Order details, completion

#### Staff Screens
- **StaffScreen**: Employee directory
- **AttendanceScreen**: Daily attendance marking

---

## Flutter App Implementation Guide

### Required Dependencies
```yaml
dependencies:
  flutter_riverpod: ^2.5.0      # State management
  go_router: ^14.0.0            # Navigation
  dio: ^5.4.0                   # HTTP client
  freezed_annotation: ^2.4.0    # Immutable models
  json_annotation: ^4.9.0       # JSON serialization
  shared_preferences: ^2.2.0    # Local storage
  flutter_secure_storage: ^9.0.0 # Secure token storage
  fl_chart: ^0.68.0             # Charts
  intl: ^0.19.0                 # Date/number formatting
```

### Code Generation
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Key Implementation Patterns

1. **API Service** - Singleton Dio instance with interceptors for auth headers
2. **Riverpod Providers** - FutureProvider for API calls, StateNotifier for auth/theme
3. **Freezed Models** - Immutable data classes with JSON serialization
4. **GoRouter** - Declarative routing with auth redirects
5. **Repository Pattern** - Separate API calls from UI logic

### Theme Configuration
- Material 3 with custom colors matching React Native theme
- Light/Dark mode support with system default
- Primary: #2563EB, Success: #16A34A, Warning: #D97706, Danger: #DC2626

### Responsive Design
- Works on phone and tablet
- Proper safe area handling
- Landscape support for charts

---

## API Integration Notes

### Pagination
All list endpoints support:
- `limit` (default 20, max 100)
- `skip` (offset)
- `sort` field
- `order` (asc/desc)

### Filtering
Generic collections support query parameter filtering:
```
GET /collections/materials?category=RAW&current_stock_lte=100
```

### Date Handling
- Backend uses Unix timestamps (milliseconds)
- Date ranges: `start` and `end` query params
- Attendance dates: YYYY-MM-DD strings

### Error Handling
Standard error response:
```json
{ "error": "Error message", "details": {...} }
```

### Status Codes
- 200: Success
- 201: Created
- 400: Validation error
- 401: Unauthorized (token expired)
- 404: Not found
- 409: Conflict (duplicate)
- 500: Server error

---

## Development Workflow

1. **Start Backend**: `cd backend && npm run dev` (port 5000)
2. **Generate Models**: `flutter pub run build_runner build`
3. **Run App**: `flutter run` (choose device)
4. **Test API**: Use Settings screen to test connection

## Build Commands

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release
```

---

## Key Differences from React Native Version

| Feature | React Native | Flutter |
|---------|-------------|---------|
| State | Zustand | Riverpod |
| Navigation | React Navigation | GoRouter |
| HTTP | fetch/axios | Dio |
| Models | TypeScript interfaces | Freezed classes |
| Charts | react-native-svg | fl_chart |
| Storage | AsyncStorage | SharedPreferences + SecureStorage |
| Code Gen | Manual | build_runner |

---

## Future Enhancements

- Offline support with local database (Drift/SQLite)
- Push notifications (Firebase)
- Biometric authentication
- Barcode/QR scanning for materials
- Photo capture for quality inspections
- Real-time updates via WebSocket
- Multi-language support (i18n)