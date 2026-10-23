import AsyncStorage from '@react-native-async-storage/async-storage';
import { mongoApi, getApiBaseUrl } from '../api/client';

const STORAGE_KEY_SERVER_URL = '@mfg_mongo_server_url';
export const DEFAULT_SERVER_URL = 'http://192.168.1.53:5000';

export async function getServerUrl(): Promise<string> {
  const saved = await AsyncStorage.getItem(STORAGE_KEY_SERVER_URL);
  if (saved?.trim()) return saved.trim();
  return getApiBaseUrl();
}

export async function setServerUrl(url: string): Promise<void> {
  await AsyncStorage.setItem(STORAGE_KEY_SERVER_URL, url.trim());
}

export async function checkServerHealth(customUrl?: string): Promise<{
  ok: boolean;
  message: string;
  database?: string;
}> {
  try {
    const health = await mongoApi.getHealth();
    if (health && health.status === 'ok') {
      return { ok: true, message: 'Server Connected', database: health.database };
    }
    return { ok: false, message: 'Backend healthy check did not return ok' };
  } catch (err) {
    return {
      ok: false,
      message: err instanceof Error ? err.message : 'Cannot reach sync server',
    };
  }
}

export async function syncLocalDataToMongoDB(): Promise<{
  success: boolean;
  syncedCounts: Record<string, number>;
  totalRows: number;
  message: string;
}> {
  // All data is live in MongoDB Atlas directly
  try {
    const all = await mongoApi.getAllData();
    const syncedCounts: Record<string, number> = {};
    let totalRows = 0;
    if (all && all.data) {
      for (const [k, v] of Object.entries(all.data)) {
        syncedCounts[k] = Array.isArray(v) ? v.length : 0;
        totalRows += syncedCounts[k];
      }
    }
    return {
      success: true,
      syncedCounts,
      totalRows,
      message: `MongoDB Atlas is live and synchronized with ${totalRows} documents.`,
    };
  } catch (err) {
    return {
      success: false,
      syncedCounts: {},
      totalRows: 0,
      message: err instanceof Error ? err.message : 'MongoDB sync failed',
    };
  }
}

export async function fetchAndFillFrontendDbFromBackend(): Promise<{
  success: boolean;
  message: string;
  count: number;
}> {
  // In pure MongoDB architecture, frontend reads directly from MongoDB Atlas API
  return {
    success: true,
    message: 'Pure MongoDB architecture: Frontend queries MongoDB Atlas directly via API.',
    count: 0,
  };
}
