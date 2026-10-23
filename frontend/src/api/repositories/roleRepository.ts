import { mongoApi } from '../client';
import type { CompanyRoleRow } from '../../types/permissions';
import { newId } from '../../utils/id';
import { notifyDataChanged } from '../../store/dataRefreshStore';

export const STANDARD_COMPANY_ROLES = [
  {
    name: 'OPERATOR',
    description: 'Machine operations, live production output logging & breakdown view',
    permissions: [
      'home_production',
      'home_machines',
      'home_orders',
      'tasks_production',
      'tasks_machines',
      'mgmt_alerts',
    ],
    is_system: 1,
  },
  {
    name: 'SUPERVISOR',
    description: 'Floor supervision, attendance, orders, task dispatch & inspections',
    permissions: [
      'home_orders',
      'home_production',
      'home_stock',
      'home_machines',
      'home_quality',
      'home_maintenance',
      'home_products',
      'tasks_production',
      'tasks_machines',
      'tasks_materials',
      'tasks_maintenance',
      'tasks_quality',
      'tasks_dispatch',
      'tasks_quick_actions',
      'mgmt_staff',
      'mgmt_reports',
      'mgmt_dispatch',
      'mgmt_alerts',
    ],
    is_system: 1,
  },
  {
    name: 'TECHNICIAN',
    description: 'Machine repairs, routine maintenance servicing & breakdown response',
    permissions: [
      'home_machines',
      'home_maintenance',
      'home_production',
      'tasks_machines',
      'tasks_maintenance',
      'mgmt_alerts',
    ],
    is_system: 1,
  },
  {
    name: 'QUALITY_INSPECTOR',
    description: 'Part inspections, defect recording & rework order verification',
    permissions: [
      'home_quality',
      'home_production',
      'home_products',
      'tasks_quality',
      'tasks_quick_actions',
      'mgmt_alerts',
    ],
    is_system: 1,
  },
  {
    name: 'MANAGER',
    description: 'Full plant operations, purchase, dispatch, roles & configuration',
    permissions: [
      'home_orders',
      'home_production',
      'home_stock',
      'home_machines',
      'home_quality',
      'home_maintenance',
      'home_products',
      'tasks_production',
      'tasks_machines',
      'tasks_materials',
      'tasks_maintenance',
      'tasks_quality',
      'tasks_dispatch',
      'tasks_quick_actions',
      'mgmt_purchase',
      'mgmt_staff',
      'mgmt_reports',
      'mgmt_dispatch',
      'mgmt_contacts',
      'mgmt_alerts',
      'mgmt_settings',
      'mgmt_roles',
    ],
    is_system: 1,
  },
];

export async function listRolesByCompany(companyId: string): Promise<CompanyRoleRow[]> {
  try {
    const remote = await mongoApi.getCollection<any>('company_roles');
    if (remote && Array.isArray(remote) && remote.length > 0) {
      const filtered = remote.filter((r) => r.company_id === companyId || !r.company_id);
      if (filtered.length > 0) {
        return filtered.map((r) => ({
          id: r.id || String(r._id),
          company_id: r.company_id || companyId,
          name: r.name,
          description: r.description || null,
          permissions: Array.isArray(r.permissions) ? r.permissions : [],
          is_system: r.is_system ? 1 : 0,
          created_at: r.created_at || Date.now(),
          updated_at: r.updated_at || Date.now(),
        }));
      }
    }
  } catch (err) {
    console.warn('MongoDB listRolesByCompany error:', err);
  }

  // Return standard roles if none found
  return STANDARD_COMPANY_ROLES.map((r, i) => ({
    id: `role-${r.name.toLowerCase()}`,
    company_id: companyId,
    name: r.name,
    description: r.description,
    permissions: r.permissions,
    is_system: 1,
    created_at: Date.now(),
    updated_at: Date.now(),
  }));
}

export async function getRoleById(id: string): Promise<CompanyRoleRow | null> {
  try {
    const role = await mongoApi.getById<any>('company_roles', id);
    if (role) {
      return {
        id: role.id || String(role._id),
        company_id: role.company_id,
        name: role.name,
        description: role.description || null,
        permissions: Array.isArray(role.permissions) ? role.permissions : [],
        is_system: role.is_system ? 1 : 0,
        created_at: role.created_at || Date.now(),
        updated_at: role.updated_at || Date.now(),
      };
    }
  } catch {
    // fallback
  }

  const all = await mongoApi.getCollection<any>('company_roles').catch(() => []);
  const found = all.find((r: any) => r.id === id || String(r._id) === id);
  if (found) {
    return {
      id: found.id || String(found._id),
      company_id: found.company_id,
      name: found.name,
      description: found.description || null,
      permissions: Array.isArray(found.permissions) ? found.permissions : [],
      is_system: found.is_system ? 1 : 0,
      created_at: found.created_at || Date.now(),
      updated_at: found.updated_at || Date.now(),
    };
  }

  return null;
}

export async function getRoleByName(
  companyId: string,
  name: string,
): Promise<CompanyRoleRow | null> {
  const all = await listRolesByCompany(companyId);
  return all.find((r) => r.name.toUpperCase() === name.trim().toUpperCase()) || null;
}

export type CreateRoleInput = {
  company_id: string;
  name: string;
  description?: string;
  permissions: string[];
};

export async function createRole(input: CreateRoleInput): Promise<CompanyRoleRow> {
  const id = newId();
  const now = Date.now();
  const cleanName = input.name.trim();

  const doc = {
    _id: id,
    id,
    company_id: input.company_id,
    name: cleanName,
    description: input.description?.trim() || null,
    permissions: input.permissions,
    is_system: 0,
    created_at: now,
    updated_at: now,
  };

  await mongoApi.insert('company_roles', doc);
  notifyDataChanged();

  return {
    ...doc,
    is_system: 0,
  };
}

export type UpdateRoleInput = {
  id: string;
  name?: string;
  description?: string;
  permissions?: string[];
};

export async function updateRole(input: UpdateRoleInput): Promise<void> {
  const now = Date.now();
  const updates: Record<string, unknown> = { updated_at: now };
  if (input.name !== undefined) updates.name = input.name.trim();
  if (input.description !== undefined) updates.description = input.description.trim();
  if (input.permissions !== undefined) updates.permissions = input.permissions;

  await mongoApi.update('company_roles', input.id, updates);
  notifyDataChanged();
}

export async function deleteRole(id: string): Promise<void> {
  await mongoApi.delete('company_roles', id);
  notifyDataChanged();
}

export async function ensureCompanyRolesSeeded(companyId: string): Promise<void> {
  try {
    const existing = await mongoApi.getCollection<any>('company_roles', { company_id: companyId });
    if (existing && existing.length > 0) return;

    const now = Date.now();
    for (const r of STANDARD_COMPANY_ROLES) {
      const id = newId();
      await mongoApi.insert('company_roles', {
        _id: id,
        id,
        company_id: companyId,
        name: r.name,
        description: r.description,
        permissions: r.permissions,
        is_system: r.is_system,
        created_at: now,
        updated_at: now,
      }).catch(() => {});
    }
  } catch (err) {
    console.warn('ensureCompanyRolesSeeded error:', err);
  }
}
