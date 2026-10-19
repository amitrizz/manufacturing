import { getDatabase } from './client';
import { runMigrations } from './migrations';
import { getMetaValue } from './repositories/appMetaRepository';
import { runSeed } from './seed';
import { mongoApi } from '../api/client';

export type DatabaseInitResult = {
  seeded: boolean;
};

export async function initializeDatabase(): Promise<DatabaseInitResult> {
  // Check live MongoDB Backend API connection
  try {
    const health = await mongoApi.getHealth();
    if (health && health.status === 'ok') {
      console.log('✅ Connected to live MongoDB backend:', health.database);
    }
  } catch (err) {
    console.warn('Backend API not reachable during initialization, will use local fallback:', err);
  }

  try {
    const db = await getDatabase();
    await runMigrations(db);

    const firstLaunch = await getMetaValue('first_launch_done', db);
    if (firstLaunch !== 'true') {
      await runSeed(db);
      return { seeded: true };
    }
  } catch (e) {
    console.warn('Local SQLite initialization skipped/failed:', e);
  }

  return { seeded: false };
}
