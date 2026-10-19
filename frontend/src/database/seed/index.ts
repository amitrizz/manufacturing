import type { SQLiteDatabase } from 'expo-sqlite';
import { SEED_HISTORY_DAYS, SEED_VERSION } from '../../constants/seedConfig';
import { setMetaValue } from '../repositories/appMetaRepository';
import { seedBom } from './seedBom';
import { seedFactories } from './seedFactories';
import { seedFinishedGoodsAndDispatch, seedQuality } from './seedQuality';
import type { SeedContext } from './seedContext';
import { seedHistoricalProduction } from './seedHistoricalProduction';
import { seedMachines } from './seedMachines';
import { seedMaintenance } from './seedMaintenance';
import { seedMaterials } from './seedMaterials';
import { seedNotifications } from './seedNotifications';
import { seedProducts } from './seedProducts';
import { seedV2 } from './seedV2';

function createContext(db: SQLiteDatabase): SeedContext {
  const now = Date.now();
  return {
    db,
    now,
    historyDays: SEED_HISTORY_DAYS,
    factoryId: '',
    lineIds: { A: '', B: '', C: '', D: '' },
    productIds: [],
    materialIds: [],
    machineIds: [],
    delayedOrderId: null,
    lowStockMaterialIds: [],
    maintenanceDueMachineId: null,
    failedInspectionId: null,
  };
}

export async function runSeed(db: SQLiteDatabase): Promise<void> {
  await db.withTransactionAsync(async () => {
    const ctx = createContext(db);
    await seedFactories(ctx);
    await seedProducts(ctx);
    await seedMaterials(ctx);
    await seedBom(ctx);
    await seedMachines(ctx);
    const orders = await seedHistoricalProduction(ctx);
    const fgMap = await seedQuality(ctx, orders);
    await seedMaintenance(ctx);
    await seedFinishedGoodsAndDispatch(ctx, fgMap);
    await seedNotifications(ctx);
    await seedV2(ctx);
    await setMetaValue('seed_version', SEED_VERSION, db);
    await setMetaValue('first_launch_done', 'true', db);
  });
}
