import AsyncStorage from '@react-native-async-storage/async-storage';
import { Platform } from 'react-native';

const STORAGE_KEY_API_URL = '@mfg_api_url';
const STORAGE_KEY_API_KEY = '@mfg_api_key';

// Remote endpoint for production APK builds and cloud fallback
const REMOTE_URL = (process.env.EXPO_PUBLIC_API_URL || '').trim().replace(/\/+$/, '');

// Local candidate endpoints for development (no hardcoded IPs)
const getLocalUrls = (): string[] => {
  const urls: string[] = [
    Platform.select({
      android: 'http://10.0.2.2:5000',
      default: 'http://localhost:5000',
    }),
    'http://localhost:5000',
  ].filter((url): url is string => Boolean(url && url.trim()));
  
  // In development, allow adding LAN IP via env var
  if (__DEV__ && process.env.EXPO_PUBLIC_LAN_API_URL) {
    urls.unshift(process.env.EXPO_PUBLIC_LAN_API_URL.trim().replace(/\/+$/, ''));
  }
  
  return urls;
};

const LOCAL_URLS = getLocalUrls();

// In dev mode (running Expo), prioritize local backend first; in APK build, use remote server first
const CANDIDATE_URLS: string[] = __DEV__
  ? [...LOCAL_URLS, REMOTE_URL].filter(Boolean)
  : [REMOTE_URL, ...LOCAL_URLS].filter(Boolean);

let cachedBaseUrl: string | null = null;
let isResolving: Promise<string> | null = null;
let activeCompanyId: string | null = null;
let apiKey: string | null = null;

// Simple logger for frontend (can be replaced with proper logging lib)
const log = {
  debug: (...args: unknown[]) => { if (__DEV__) console.debug('[DEBUG]', ...args); },
  info: (...args: unknown[]) => { if (__DEV__) console.info('[INFO]', ...args); },
  warn: (...args: unknown[]) => console.warn('[WARN]', ...args),
  error: (...args: unknown[]) => console.error('[ERROR]', ...args),
};

export function setActiveCompanyId(id: string | null): void {
  activeCompanyId = id;
}

export function getActiveCompanyId(): string | null {
  return activeCompanyId;
}

export async function setApiKey(key: string): Promise<void> {
  apiKey = key;
  await AsyncStorage.setItem(STORAGE_KEY_API_KEY, key);
}

export async function getApiKey(): Promise<string | null> {
  if (apiKey) return apiKey;
  try {
    const saved = await AsyncStorage.getItem(STORAGE_KEY_API_KEY);
    if (saved) {
      apiKey = saved;
      return saved;
    }
  } catch {
    // ignore
  }
  return null;
}

export async function resolveActiveCompanyId(): Promise<string | null> {
  if (activeCompanyId) return activeCompanyId;
  try {
    const raw = await AsyncStorage.getItem('mfg_auth_session');
    if (raw) {
      const parsed = JSON.parse(raw);
      if (parsed?.companyId) {
        activeCompanyId = parsed.companyId;
        console.log('[DEBUG] resolveActiveCompanyId from storage:', parsed.companyId);
        return parsed.companyId;
      }
    }
  } catch {
    // ignore
  }
  console.log('[DEBUG] resolveActiveCompanyId: null (no session)');
  return null;
}

// Debug helper to clear saved API URL
export async function clearSavedApiUrl(): Promise<void> {
  await AsyncStorage.removeItem(STORAGE_KEY_API_URL);
  cachedBaseUrl = null;
  console.log('[DEBUG] Cleared saved API URL');
}

async function pingUrl(url: string, timeoutMs = 2500): Promise<boolean> {
  const clean = url.trim().replace(/\/+$/, '');
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const res = await fetch(`${clean}/api/v1/health`, {
      method: 'GET',
      headers: {
        Accept: 'application/json',
        'Bypass-Tunnel-Reminder': 'true',
        'bypass-tunnel-reminder': 'true',
      },
      signal: controller.signal,
    });
    clearTimeout(timer);
    return res.ok;
  } catch {
    clearTimeout(timer);
    return false;
  }
}

export async function getApiBaseUrl(): Promise<string> {
  if (cachedBaseUrl) return cachedBaseUrl;
  if (isResolving) return isResolving;

  isResolving = (async () => {
    // 1. Check user-configured URL from Settings
    try {
      const saved = await AsyncStorage.getItem(STORAGE_KEY_API_URL);
      if (saved && saved.trim()) {
        const clean = saved.trim().replace(/\/+$/, '');
        const ok = await pingUrl(clean, 2000);
        if (ok) {
          cachedBaseUrl = clean;
          log.info('Using saved API URL:', clean);
          return clean;
        }
      }
    } catch {
      // ignore
    }

    // 2. Test candidate endpoints in order
    for (const candidate of CANDIDATE_URLS) {
      const clean = candidate.trim().replace(/\/+$/, '');
      const ok = await pingUrl(clean, 2000);
      if (ok) {
        cachedBaseUrl = clean;
        await AsyncStorage.setItem(STORAGE_KEY_API_URL, clean).catch(() => {});
        log.info('Resolved working Backend API URL:', clean);
        return clean;
      }
    }

    // 3. Fallback to first candidate if all fail ping
    const fallback = CANDIDATE_URLS[0] || 'http://localhost:5000';
    cachedBaseUrl = fallback;
    log.warn('All backend URLs failed ping, using fallback:', fallback);
    return fallback;
  })();

  try {
    return await isResolving;
  } finally {
    isResolving = null;
  }
}

export async function setApiBaseUrl(url: string): Promise<void> {
  const clean = url.trim().replace(/\/+$/, '');
  cachedBaseUrl = clean;
  await AsyncStorage.setItem(STORAGE_KEY_API_URL, clean);
}

export async function apiFetch<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
  let baseUrl = await getApiBaseUrl();
  const cleanEndpoint = endpoint.startsWith('/') ? endpoint : `/${endpoint}`;
  const method = (options.method || 'GET').toUpperCase();
  const companyId = await resolveActiveCompanyId();
  const key = await getApiKey();

  console.log('[DEBUG] apiFetch:', { endpoint, companyId, method });

  const makeRequest = async (urlHost: string) => {
    const url = `${urlHost}${cleanEndpoint}`;
    log.debug(`[API ${method}] -> ${url}`);
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      'Bypass-Tunnel-Reminder': 'true',
      'bypass-tunnel-reminder': 'true',
      ...(companyId ? { 'x-company-id': companyId } : {}),
      ...(key ? { 'x-api-key': key } : {}),
      ...((options.headers as Record<string, string>) || {}),
    };

    return fetch(url, {
      ...options,
      headers,
    });
  };

  let res: Response;
  try {
    res = await makeRequest(baseUrl);
    log.debug(`[API ${res.status} ${res.statusText || 'OK'}] <- ${baseUrl}${cleanEndpoint}`);
  } catch (netErr) {
    // If the network request failed, invalidate cached URL, re-resolve, and retry once
    log.warn(`Fetch failed on ${baseUrl}, attempting re-discovery:`, netErr);
    cachedBaseUrl = null;
    baseUrl = await getApiBaseUrl();
    res = await makeRequest(baseUrl);
    log.debug(`[API ${res.status} ${res.statusText || 'OK'}] <- ${baseUrl}${cleanEndpoint}`);
  }

  if (!res.ok) {
    let errMsg = `API error ${res.status}: ${res.statusText}`;
    let errJson: any = null;
    try {
      errJson = await res.json();
      if (errJson && errJson.error) {
        errMsg = errJson.error;
      }
      // Handle validation errors with details
      if (errJson && errJson.details) {
        errMsg = `${errMsg} - ${JSON.stringify(errJson.details)}`;
      }
    } catch {
      // ignore
    }
    log.error(`[API Error] ${errMsg}`);
    const error = new Error(errMsg) as Error & { status?: number; details?: any };
    error.status = res.status;
    error.details = errJson?.details;
    throw error;
  }

  return res.json();
}

export const mongoApi = {
  async getHealth() {
    return apiFetch<{ status: string; database: string; collectionsCount: number; version: string; timestamp: number }>(
      '/api/v1/health'
    );
  },

  async getCollection<T>(name: string, queryParams: Record<string, unknown> = {}): Promise<T[]> {
    const companyId = (queryParams.company_id as string) || (await resolveActiveCompanyId());
    const query = new URLSearchParams();
    if (companyId && name !== 'companies' && name !== 'units' && !queryParams.company_id) {
      query.append('company_id', String(companyId));
    }
    for (const [key, val] of Object.entries(queryParams)) {
      if (val !== undefined && val !== null) {
        query.append(key, String(val));
      }
    }
    const qStr = query.toString();
    const response = await apiFetch<{ data: T[]; pagination?: any } | T[]>(`/api/v1/collections/${name}${qStr ? `?${qStr}` : ''}`);
    // Handle both paginated response { data: [...], pagination: {...} } and direct array [...]
    if (Array.isArray(response)) {
      return response;
    }
    return response?.data || [];
  },

  async getById<T>(name: string, id: string): Promise<T> {
    return apiFetch<T>(`/api/v1/collections/${name}/${id}`);
  },

  async insert<T>(name: string, doc: Partial<T>): Promise<T> {
    const companyId = (doc as any)?.company_id || (await resolveActiveCompanyId());
    const payload = { ...doc };
    if (companyId && name !== 'companies' && name !== 'units' && !(payload as any).company_id) {
      (payload as any).company_id = companyId;
    }
    return apiFetch<T>(`/api/v1/collections/${name}`, {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },

  async update<T>(name: string, id: string, doc: Partial<T>): Promise<T> {
    return apiFetch<T>(`/api/v1/collections/${name}/${id}`, {
      method: 'PUT',
      body: JSON.stringify(doc),
    });
  },

  async delete(name: string, id: string): Promise<{ success: boolean }> {
    return apiFetch<{ success: boolean }>(`/api/v1/collections/${name}/${id}`, {
      method: 'DELETE',
    });
  },

  // Dashboard & KPIs
  async getDashboardStats() {
    return apiFetch<{
      kpis: {
        target: number;
        produced: number;
        achievement: number;
        qualityRate: number;
        machineAvailability: number;
        downtimeHours: number;
        machineStatusCounts: Record<string, number>;
        lineProgress: { lineCode: string; lineName?: string; produced: number; pct: number }[];
      };
      machines: { running: number; breakdown: number; maintenance: number; idle: number; total: number };
      attendance: { total: number; present: number; halfDay: number; leave: number; absent: number; rate: number };
      pendingTasksCount: number;
      recentActivities: any[];
      monthlyData: { month: string; year: number; target: number; produced: number; pct: number }[];
    }>('/api/v1/dashboard/stats');
  },

  // Machines
  async listMachines(filters: { status?: string; lineId?: string; search?: string } = {}) {
    const params = new URLSearchParams();
    if (filters.status) params.append('status', filters.status);
    if (filters.lineId) params.append('lineId', filters.lineId);
    if (filters.search) params.append('search', filters.search);
    const qStr = params.toString();
    const response = await apiFetch<{ data: any[]; pagination?: any } | any[]>(`/api/v1/machines${qStr ? `?${qStr}` : ''}`);
    if (Array.isArray(response)) return response;
    return response?.data || [];
  },

  async updateMachineStatus(id: string, status: string, reason?: string) {
    return apiFetch<{ success: boolean; machineId: string; status: string }>(`/api/v1/machines/${id}/status`, {
      method: 'POST',
      body: JSON.stringify({ status, reason }),
    });
  },

  // Production Orders
  async listProductionOrders(status?: string) {
    const q = status ? `?status=${encodeURIComponent(status)}` : '';
    const response = await apiFetch<{ data: any[]; pagination?: any } | any[]>(`/api/v1/production-orders${q}`);
    if (Array.isArray(response)) return response;
    return response?.data || [];
  },

  async startProductionOrder(id: string) {
    return apiFetch<{ success: boolean; orderId: string; status: string }>(`/api/v1/production-orders/${id}/start`, {
      method: 'POST',
    });
  },

  // Purchase & GRN
  async listGrnReceipts<T>(): Promise<T[]> {
    return apiFetch<T[]>('/api/v1/purchase/grn-receipts');
  },

  async receiveGrn(payload: {
    po_id?: string | null;
    supplier_id?: string | null;
    invoice_number?: string | null;
    notes?: string | null;
    received_items: { material_id: string; received_qty: number }[];
  }) {
    return apiFetch<{ success: boolean; grnId: string; grnNumber: string }>(
      '/api/v1/purchase/receive-grn',
      {
        method: 'POST',
        body: JSON.stringify(payload),
      }
    );
  },

  async deleteGrn(id: string) {
    return apiFetch<{ success: boolean }>(`/api/v1/purchase/delete-grn/${id}`, {
      method: 'DELETE',
    });
  },

  async getAllData(): Promise<{ success: boolean; data: Record<string, any[]> }> {
    return apiFetch<{ success: boolean; data: Record<string, any[]> }>('/api/v1/database/all');
  },

  // Database actions - require confirmation
  async clearAllData() {
    return apiFetch<{ success: boolean; message: string }>('/api/v1/database/clear', {
      method: 'POST',
      body: JSON.stringify({ confirm: true }),
    });
  },

  async resetDemoData() {
    return apiFetch<{ success: boolean; message: string }>('/api/v1/database/reset', {
      method: 'POST',
      body: JSON.stringify({ confirm: true }),
    });
  },

  async seedDemoData() {
    return apiFetch<{ success: boolean; message: string }>('/api/v1/database/seed', {
      method: 'POST',
      body: JSON.stringify({ confirm: true }),
    });
  },
};
