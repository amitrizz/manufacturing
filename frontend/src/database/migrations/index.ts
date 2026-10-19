import type { SQLiteDatabase } from 'expo-sqlite';
import { MIGRATION_VERSION as V1, up as up001 } from './001_initial_schema';
import { MIGRATION_VERSION as V2, up as up002 } from './002_v2_features';
import { MIGRATION_VERSION as V3, up as up003 } from './003_company_and_staff_auth';
import { MIGRATION_VERSION as V4, up as up004 } from './004_roles_and_permissions';
import { MIGRATION_VERSION as V5, up as up005 } from './005_pre_production_qc';

type Migration = {
  version: number;
  up: (db: SQLiteDatabase) => Promise<void>;
};

const migrations: Migration[] = [
  { version: V1, up: up001 },
  { version: V2, up: up002 },
  { version: V3, up: up003 },
  { version: V4, up: up004 },
  { version: V5, up: up005 },
];

async function getUserVersion(db: SQLiteDatabase): Promise<number> {
  const rows = await db.getAllAsync<{ user_version: number }>('PRAGMA user_version');
  return rows[0]?.user_version ?? 0;
}

export async function runMigrations(db: SQLiteDatabase): Promise<void> {
  const currentVersion = await getUserVersion(db);

  const pending = migrations
    .filter((m) => m.version > currentVersion)
    .sort((a, b) => a.version - b.version);

  for (const migration of pending) {
    await db.withTransactionAsync(async () => {
      await migration.up(db);
      await db.execAsync(`PRAGMA user_version = ${migration.version};`);
    });
  }
}
