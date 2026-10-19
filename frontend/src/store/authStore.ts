import AsyncStorage from '@react-native-async-storage/async-storage';
import { create } from 'zustand';
import {
  createCompany,
  getCompanyById,
  verifyCompanyAdmin,
  type CreateCompanyInput,
} from '../database/repositories/companyRepository';
import {
  ensureCompanyRolesSeeded,
  getRoleById,
  getRoleByName,
} from '../database/repositories/roleRepository';
import { verifyStaffLogin } from '../database/repositories/staffRepository';
import type { CompanyRow, StaffRole } from '../types/database';

const AUTH_STORAGE_KEY = 'mfg_auth_session';

export type AuthUser = {
  id: string;
  name: string;
  role: 'ADMIN' | StaffRole;
  role_id?: string | null;
  type: 'COMPANY_ADMIN' | 'STAFF';
  employee_id?: string;
  email?: string;
  shift?: string;
  permissions: string[];
};

type StoredAuthSession = {
  companyId: string;
  user: AuthUser;
};

export type PreviewRoleInfo = {
  id: string;
  name: string;
  permissions: string[];
};

export type PreviewStaffInfo = {
  id: string;
  employee_id: string;
  name: string;
  role: string;
  shift?: string;
  permissions: string[];
};

type AuthState = {
  user: AuthUser | null;
  company: CompanyRow | null;
  isAuthenticated: boolean;
  isHydrated: boolean;
  previewRole: PreviewRoleInfo | null;
  previewStaff: PreviewStaffInfo | null;
  hasPermission: (permissionKey: string) => boolean;
  startRolePreview: (role: PreviewRoleInfo) => void;
  startStaffPreview: (staff: PreviewStaffInfo) => void;
  exitRolePreview: () => void;
  exitStaffPreview: () => void;
  exitPreview: () => void;
  hydrateAuth: () => Promise<void>;
  loginCompanyAdmin: (emailOrCode: string, password: string) => Promise<void>;
  loginStaff: (companyCode: string, employeeIdOrName: string, pin: string) => Promise<void>;
  registerCompany: (input: CreateCompanyInput) => Promise<void>;
  logout: () => Promise<void>;
};

export const useAuthStore = create<AuthState>((set, get) => ({
  user: null,
  company: null,
  isAuthenticated: false,
  isHydrated: false,
  previewRole: null,
  previewStaff: null,

  hasPermission: (permissionKey: string) => {
    const previewStaff = get().previewStaff;
    if (previewStaff) {
      if (previewStaff.permissions?.includes('*')) return true;
      return previewStaff.permissions?.includes(permissionKey) ?? false;
    }
    const preview = get().previewRole;
    if (preview) {
      if (preview.permissions?.includes('*')) return true;
      return preview.permissions?.includes(permissionKey) ?? false;
    }
    const user = get().user;
    if (!user) return false;
    if (user.type === 'COMPANY_ADMIN' || user.permissions?.includes('*')) return true;
    return user.permissions?.includes(permissionKey) ?? false;
  },

  startRolePreview: (role: PreviewRoleInfo) => {
    set({ previewRole: role, previewStaff: null });
  },

  startStaffPreview: (staff: PreviewStaffInfo) => {
    set({ previewStaff: staff, previewRole: null });
  },

  exitRolePreview: () => {
    set({ previewRole: null, previewStaff: null });
  },

  exitStaffPreview: () => {
    set({ previewStaff: null, previewRole: null });
  },

  exitPreview: () => {
    set({ previewRole: null, previewStaff: null });
  },

  hydrateAuth: async () => {
    try {
      const raw = await AsyncStorage.getItem(AUTH_STORAGE_KEY);
      if (raw) {
        const parsed: StoredAuthSession = JSON.parse(raw);
        if (parsed?.companyId && parsed?.user) {
          const company = await getCompanyById(parsed.companyId);
          if (company) {
            set({
              user: parsed.user,
              company,
              isAuthenticated: true,
              isHydrated: true,
            });
            return;
          }
        }
      }
    } catch {
      // Ignore corrupted session and fallback to logged out
    }
    set({ user: null, company: null, isAuthenticated: false, isHydrated: true });
  },

  loginCompanyAdmin: async (emailOrCode: string, password: string) => {
    const comp = await verifyCompanyAdmin(emailOrCode, password);
    if (!comp) {
      throw new Error('Invalid Company Code / Email or Admin Password.');
    }

    await ensureCompanyRolesSeeded(comp.id);

    const adminUser: AuthUser = {
      id: `admin-${comp.id}`,
      name: `${comp.name} Admin`,
      role: 'ADMIN',
      type: 'COMPANY_ADMIN',
      email: comp.admin_email,
      permissions: ['*'],
    };

    const session: StoredAuthSession = {
      companyId: comp.id,
      user: adminUser,
    };
    await AsyncStorage.setItem(AUTH_STORAGE_KEY, JSON.stringify(session));

    set({
      user: adminUser,
      company: comp,
      isAuthenticated: true,
    });
  },

  loginStaff: async (companyCode: string, employeeIdOrName: string, pin: string) => {
    const res = await verifyStaffLogin(companyCode, employeeIdOrName, pin);
    if (!res) {
      throw new Error(
        `Staff login failed. Check company code "${companyCode.toUpperCase()}", Employee ID/Name, and 4-digit PIN.`,
      );
    }

    await ensureCompanyRolesSeeded(res.company.id);

    let permissions: string[] = [];
    if (res.staff.role_id) {
      const r = await getRoleById(res.staff.role_id);
      if (r) permissions = r.permissions;
    }
    if (permissions.length === 0) {
      const r = await getRoleByName(res.company.id, res.staff.role);
      if (r) permissions = r.permissions;
    }
    if (permissions.length === 0) {
      permissions = ['home_production', 'home_machines', 'tasks_production'];
    }

    const staffUser: AuthUser = {
      id: res.staff.id,
      name: res.staff.name,
      role: res.staff.role,
      role_id: res.staff.role_id,
      type: 'STAFF',
      employee_id: res.staff.employee_id,
      shift: res.staff.shift,
      permissions,
    };

    const session: StoredAuthSession = {
      companyId: res.company.id,
      user: staffUser,
    };
    await AsyncStorage.setItem(AUTH_STORAGE_KEY, JSON.stringify(session));

    set({
      user: staffUser,
      company: res.company,
      isAuthenticated: true,
    });
  },

  registerCompany: async (input: CreateCompanyInput) => {
    const created = await createCompany(input);
    await ensureCompanyRolesSeeded(created.id);

    const adminUser: AuthUser = {
      id: `admin-${created.id}`,
      name: `${created.name} Admin`,
      role: 'ADMIN',
      type: 'COMPANY_ADMIN',
      email: created.admin_email,
      permissions: ['*'],
    };

    const session: StoredAuthSession = {
      companyId: created.id,
      user: adminUser,
    };
    await AsyncStorage.setItem(AUTH_STORAGE_KEY, JSON.stringify(session));

    set({
      user: adminUser,
      company: created,
      isAuthenticated: true,
    });
  },

  logout: async () => {
    await AsyncStorage.removeItem(AUTH_STORAGE_KEY);
    set({
      user: null,
      company: null,
      previewRole: null,
      previewStaff: null,
      isAuthenticated: false,
    });
  },
}));
