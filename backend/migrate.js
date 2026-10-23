import { MongoClient } from 'mongodb';
import dotenv from 'dotenv';
import { DEFAULT_UNITS } from './seed/units.seed.js';

dotenv.config();

const MONGODB_URI =
  process.env.DATABASE_URL ||
  'mongodb+srv://amit:amit@cluster0.tysk0hr.mongodb.net/manufacturing?retryWrites=true&w=majority&appName=Cluster0';

const DB_NAME = process.env.MONGODB_DB_NAME || 'manufacturing';

console.log('--------------------------------------------------');
console.log('🚀 Manufacturing Multi-Tenant Schema & Index Setup');
console.log(`📦 Target Database: ${DB_NAME}`);
console.log(`🌐 Target Cluster: cluster0.tysk0hr.mongodb.net`);
console.log('--------------------------------------------------');

async function safeDropIndex(col, indexName) {
  try {
    await col.dropIndex(indexName);
    console.log(`  Dropped legacy index: ${indexName} on ${col.collectionName}`);
  } catch {
    // index may not exist, ignore
  }
}

export async function runMigration(existingDb = null) {
  let client = null;

  try {
    let db = existingDb;
    if (!db) {
      client = new MongoClient(MONGODB_URI);
      console.log('Connecting to MongoDB cluster...');
      await client.connect();
      console.log('✅ Connected successfully!');
      db = client.db(DB_NAME);
    }

    // 1. Seed or update standard units collection
    const unitsCol = db.collection('units');
    const now = Date.now();
    for (let idx = 0; idx < DEFAULT_UNITS.length; idx++) {
      const u = DEFAULT_UNITS[idx];
      const unitId = `unit-${u.code.toLowerCase()}`;
      await unitsCol.updateOne(
        { $or: [{ id: unitId }, { _id: unitId }, { code: u.code }] },
        {
          $set: {
            _id: unitId,
            id: unitId,
            ...u,
            is_active: true,
            updated_at: now + idx,
          },
          $setOnInsert: {
            created_at: now + idx,
          },
        },
        { upsert: true }
      );
    }
    console.log(`✅ Collection 'units': Seeded ${DEFAULT_UNITS.length} standard industrial units.`);

    // 2. Multi-tenant backfill: assign any existing unassigned records to default company
    const firstCompany = await db.collection('companies').findOne({});
    const defaultCompanyId = firstCompany?.id || firstCompany?._id || '11bfc9aa-755b-42af-9ee8-cdabb6172079';
    console.log(`\n🏢 Default Company for backfill: ${defaultCompanyId} (${firstCompany?.name || 'Logix technova'})`);

    const tenantCollections = [
      'staff',
      'staff_attendance',
      'production_lines',
      'machines',
      'machine_downtime',
      'materials',
      'products',
      'finished_goods',
      'bom',
      'bom_items',
      'production_plans',
      'production_orders',
      'production_entries',
      'quality_inspections',
      'suppliers',
      'customers',
      'purchase_orders',
      'purchase_order_items',
      'purchase_requests',
      'grn_receipts',
      'stock_transactions',
      'maintenance_orders',
      'dispatch_orders',
      'activity_history',
    ];

    for (const colName of tenantCollections) {
      const col = db.collection(colName);
      const res = await col.updateMany(
        { $or: [{ company_id: { $exists: false } }, { company_id: null }] },
        { $set: { company_id: defaultCompanyId } }
      );
      if (res.modifiedCount > 0) {
        console.log(`  Backfilled ${res.modifiedCount} docs in '${colName}' with company_id=${defaultCompanyId}`);
      }
    }

    // 3. Drop legacy global unique indexes that block multi-tenancy
    console.log('\n--- Dropping Legacy Global Indexes ---');
    await safeDropIndex(db.collection('products'), 'code_1');
    await safeDropIndex(db.collection('materials'), 'code_1');
    await safeDropIndex(db.collection('machines'), 'code_1');
    await safeDropIndex(db.collection('production_orders'), 'order_number_1');
    await safeDropIndex(db.collection('purchase_orders'), 'po_number_1');
    await safeDropIndex(db.collection('grn_receipts'), 'grn_number_1');
    await safeDropIndex(db.collection('purchase_requests'), 'request_number_1');
    await safeDropIndex(db.collection('production_plans'), 'plan_number_1');
    await safeDropIndex(db.collection('production_lines'), 'code_1');

    // 4. Set up compound multi-tenant unique indexes
    console.log('\n--- Creating Multi-Tenant Compound Indexes ---');
    try {
      await db.collection('companies').createIndex({ company_code: 1 }, { unique: true, sparse: true });
      await db.collection('staff').createIndex({ company_id: 1, employee_id: 1 }, { unique: true, sparse: true });
      await db.collection('staff_attendance').createIndex({ company_id: 1, staff_id: 1, date: 1, shift: 1 });
      await db.collection('products').createIndex({ company_id: 1, code: 1 }, { unique: true, sparse: true });
      await db.collection('materials').createIndex({ company_id: 1, code: 1 }, { unique: true, sparse: true });
      await db.collection('machines').createIndex({ company_id: 1, code: 1 }, { unique: true, sparse: true });
      await db.collection('production_lines').createIndex({ company_id: 1, code: 1 }, { unique: true, sparse: true });
      await db.collection('production_orders').createIndex({ company_id: 1, order_number: 1 }, { unique: true, sparse: true });
      await db.collection('production_plans').createIndex({ company_id: 1, plan_number: 1 }, { unique: true, sparse: true });
      await db.collection('purchase_orders').createIndex({ company_id: 1, po_number: 1 }, { unique: true, sparse: true });
      await db.collection('grn_receipts').createIndex({ company_id: 1, grn_number: 1 }, { unique: true, sparse: true });
      await db.collection('purchase_requests').createIndex({ company_id: 1, request_number: 1 }, { unique: true, sparse: true });
      await db.collection('units').createIndex({ code: 1 }, { unique: true, sparse: true });
      await db.collection('stock_transactions').createIndex({ company_id: 1, reference_type: 1, reference_id: 1 });
      await db.collection('activity_history').createIndex({ company_id: 1, timestamp: -1 });
      console.log('✅ Multi-tenant compound unique & query indexes created.');
    } catch (idxErr) {
      console.warn('Index creation notice:', idxErr.message);
    }

    const summary = await db.listCollections().toArray();
    console.log('\n--------------------------------------------------');
    console.log('🎉 Setup Completed! Database is clean & multi-tenant ready.');
    console.log(`Database: ${DB_NAME}`);
    console.log(`Total Collections: ${summary.length}`);
    return { success: true, count: summary.length };
  } catch (err) {
    console.error('❌ Migration failed:', err);
    throw err;
  } finally {
    if (client) {
      await client.close();
      console.log('Connection closed.');
    }
  }
}

// Run directly if invoked from CLI
if (process.argv[1] && process.argv[1].endsWith('migrate.js')) {
  runMigration().catch((err) => {
    console.error(err);
    process.exit(1);
  });
}
