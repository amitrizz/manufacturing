import AsyncStorage from '@react-native-async-storage/async-storage';
import { Platform } from 'react-native';

const STORAGE_KEY_API_URL = '@mfg_api_url';

// Multi-endpoint candidate list for seamless connectivity across Cloud, Wi-Fi, 4G/5G, and emulators
const CANDIDATE_URLS: string[] = [
  'https://manufacturing-i0lp.onrender.com',
  process.env.EXPO_PUBLIC_API_URL || '',
  'http://192.168.1.53:5000',
  Platform.select({
    android: 'http://10.0.2.2:5000',
    default: 'http://localhost:5000',
  }),
  'http://localhost:5000',
].filter((url): url is string => Boolean(url && url.trim()));

let cachedBaseUrl: string | null = null;
let isResolving: Promise<string> | null = null;

async function pingUrl(url: string, timeoutMs = 2500): Promise<boolean> {
  const clean = url.trim().replace(/\/+$/, '');
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const res = await fetch(`${clean}/api/health`, {
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
          return clean;
        }
      }
    } catch {
      // ignore
    }

    // 2. Test candidate endpoints in order (Tunnel -> LAN -> Emulator -> Localhost)
    for (const candidate of CANDIDATE_URLS) {
      const clean = candidate.trim().replace(/\/+$/, '');
      const ok = await pingUrl(clean, 2000);
      if (ok) {
        cachedBaseUrl = clean;
        await AsyncStorage.setItem(STORAGE_KEY_API_URL, clean).catch(() => {});
        console.log('✅ Resolved working Backend API URL:', clean);
        return clean;
      }
    }

    // 3. Fallback to first candidate if all fail ping
    const fallback = CANDIDATE_URLS[0] || 'http://localhost:5000';
    cachedBaseUrl = fallback;
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

  const makeRequest = async (urlHost: string) => {
    const url = `${urlHost}${cleanEndpoint}`;
    console.log(`🌐 [API ${method}] -> ${url}`);
    return fetch(url, {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
        'Bypass-Tunnel-Reminder': 'true',
        'bypass-tunnel-reminder': 'true',
        ...(options.headers || {}),
      },
    });
  };

  let res: Response;
  try {
    res = await makeRequest(baseUrl);
    console.log(`📡 [API ${res.status} ${res.statusText || 'OK'}] <- ${baseUrl}${cleanEndpoint}`);
  } catch (netErr) {
    // If the network request failed, invalidate cached URL, re-resolve, and retry once
    console.warn(`Fetch failed on ${baseUrl}, attempting re-discovery:`, netErr);
    cachedBaseUrl = null;
    baseUrl = await getApiBaseUrl();
    res = await makeRequest(baseUrl);
    console.log(`📡 [API ${res.status} ${res.statusText || 'OK'}] <- ${baseUrl}${cleanEndpoint}`);
  }

  if (!res.ok) {
    let errMsg = `API error ${res.status}: ${res.statusText}`;
    try {
      const errJson = await res.json();
      if (errJson && errJson.error) {
        errMsg = errJson.error;
      }
    } catch {
      // ignore
    }
    console.error(`❌ [API Error] ${errMsg}`);
    throw new Error(errMsg);
  }

  return res.json();
}

export const mongoApi = {
  async getHealth() {
    return apiFetch<{ status: string; database: string; collectionsCount: number; cluster: string }>(
      '/api/health'
    );
  },

  async getCollection<T>(name: string, queryParams: Record<string, unknown> = {}): Promise<T[]> {
    const query = new URLSearchParams();
    for (const [key, val] of Object.entries(queryParams)) {
      if (val !== undefined && val !== null) {
        query.append(key, String(val));
      }
    }
    const qStr = query.toString();
    return apiFetch<T[]>(`/api/collections/${name}${qStr ? `?${qStr}` : ''}`);
  },

  async getById<T>(name: string, id: string): Promise<T> {
    return apiFetch<T>(`/api/collections/${name}/${id}`);
  },

  async insert<T>(name: string, doc: Partial<T>): Promise<T> {
    return apiFetch<T>(`/api/collections/${name}`, {
      method: 'POST',
      body: JSON.stringify(doc),
    });
  },

  async update<T>(name: string, id: string, doc: Partial<T>): Promise<T> {
    return apiFetch<T>(`/api/collections/${name}/${id}`, {
      method: 'PUT',
      body: JSON.stringify(doc),
    });
  },

  async delete(name: string, id: string): Promise<{ success: boolean }> {
    return apiFetch<{ success: boolean }>(`/api/collections/${name}/${id}`, {
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
    }>('/api/dashboard/stats');
  },

  // Machines
  async listMachines(filters: { status?: string; lineId?: string; search?: string } = {}) {
    const params = new URLSearchParams();
    if (filters.status) params.append('status', filters.status);
    if (filters.lineId) params.append('lineId', filters.lineId);
    if (filters.search) params.append('search', filters.search);
    const qStr = params.toString();
    return apiFetch<any[]>(`/api/machines${qStr ? `?${qStr}` : ''}`);
  },

  async updateMachineStatus(id: string, status: string, reason?: string) {
    return apiFetch<{ success: boolean; machineId: string; status: string }>(`/api/machines/${id}/status`, {
      method: 'POST',
      body: JSON.stringify({ status, reason }),
    });
  },

  // Production Orders
  async listProductionOrders(status?: string) {
    const q = status ? `?status=${encodeURIComponent(status)}` : '';
    return apiFetch<any[]>(`/api/production-orders${q}`);
  },

  async startProductionOrder(id: string) {
    return apiFetch<{ success: boolean; orderId: string; status: string }>(`/api/production-orders/${id}/start`, {
      method: 'POST',
    });
  },

  // Purchase & GRN
  async listGrnReceipts<T>(): Promise<T[]> {
    return apiFetch<T[]>('/api/purchase/grn-receipts');
  },

  async receiveGrn(payload: {
    po_id?: string | null;
    supplier_id?: string | null;
    invoice_number?: string | null;
    notes?: string | null;
    received_items: { material_id: string; received_qty: number }[];
  }) {
    return apiFetch<{ success: boolean; grnId: string; grnNumber: string }>(
      '/api/purchase/receive-grn',
      {
        method: 'POST',
        body: JSON.stringify(payload),
      }
    );
  },

  async deleteGrn(id: string) {
    return apiFetch<{ success: boolean }>(`/api/purchase/delete-grn/${id}`, {
      method: 'DELETE',
    });
  },

  // Database actions
  async clearAllData() {
    return apiFetch<{ success: boolean; message: string }>('/api/database/clear', {
      method: 'POST',
    });
  },

  async resetDemoData() {
    return apiFetch<{ success: boolean; message: string }>('/api/database/reset', {
      method: 'POST',
    });
  },

  async seedDemoData() {
    return apiFetch<{ success: boolean; message: string }>('/api/database/seed', {
      method: 'POST',
    });
  },
};
