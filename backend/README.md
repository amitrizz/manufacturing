# Manufacturing Backend Service (MongoDB Atlas)

Independent backend service for the Manufacturing application connecting to MongoDB Atlas.

## Architecture

- **Runtime**: Node.js (ES Modules)
- **Framework**: Express.js with CORS enabled
- **Database**: MongoDB Atlas (`cluster0.tysk0hr.mongodb.net`)
- **Database Name**: `manufacturing`
- **Total Collections**: 32 manufacturing tables (including `grn_receipts`, `stock_transactions`, `purchase_orders`, `quality_inspections`, `machines`, `materials`, `products`, `staff`, etc.)

## Quick Start

```bash
# 1. Enter backend directory
cd backend

# 2. Install dependencies
npm install

# 3. Seed / Migrate database collections
npm run migrate

# 4. Start backend server
npm start
```

The server listens on `http://0.0.0.0:5000`.

## API Endpoints

- `GET /api/health` - MongoDB connection check
- `GET /api/collections/:name` - Query any collection with filters & sorting
- `GET /api/collections/:name/:id` - Fetch single document
- `POST /api/collections/:name` - Insert new document
- `PUT /api/collections/:name/:id` - Update document
- `DELETE /api/collections/:name/:id` - Delete document
- `GET /api/purchase/grn-receipts` - Full Goods Receipts list with joined items, supplier, & quantities
- `POST /api/purchase/receive-grn` - Atomic Goods Receipt (GRN) creation, inventory increment & PO status update
- `DELETE /api/purchase/delete-grn/:id` - Revert GRN and restore material inventory
- `POST /api/database/clear` - Clear all business collections
