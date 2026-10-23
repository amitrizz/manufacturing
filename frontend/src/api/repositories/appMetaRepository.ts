import AsyncStorage from '@react-native-async-storage/async-storage';
import { mongoApi } from '../client';

const META_PREFIX = '@app_meta_';

export async function getMetaValue(key: string): Promise<string | null> {
  try {
    const val = await AsyncStorage.getItem(`${META_PREFIX}${key}`);
    if (val !== null) return val;
  } catch {
    // fallback
  }

  try {
    const metas = await mongoApi.getCollection<any>('app_meta', { key });
    if (metas && metas.length > 0) {
      return metas[0].value ?? null;
    }
  } catch {
    // ignore
  }

  return null;
}

export async function setMetaValue(key: string, value: string): Promise<void> {
  try {
    await AsyncStorage.setItem(`${META_PREFIX}${key}`, value);
  } catch {
    // ignore
  }

  try {
    const metas = await mongoApi.getCollection<any>('app_meta', { key }).catch(() => []);
    if (metas && metas.length > 0) {
      const existingId = metas[0].id || metas[0]._id;
      await mongoApi.update('app_meta', existingId, { value, updated_at: Date.now() });
    } else {
      await mongoApi.insert('app_meta', { key, value, created_at: Date.now(), updated_at: Date.now() });
    }
  } catch {
    // ignore
  }
}
