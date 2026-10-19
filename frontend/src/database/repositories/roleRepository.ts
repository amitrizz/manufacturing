import { getDatabase } from '../client';
import type { CompanyRoleRow } from '../../types/permissions';
import { newId } from '../../utils/id';
import { notifyDataChanged } from '../../store/dataRefreshStore';

type RoleDbRow = {
  id: string;
  company_id: string;
  name: string;
  description: string | null;
  permissions: string;
  is_system: number;
  created_at: number;
  updated_at: number;
};

function mapRoleRow(row: RoleDbRow): CompanyRoleRow {
  let perms: string[] = [];
  try {
    perms = JSON.parse(row.permissions);
  } catch {
    perms = [];
  }
  return {
    ...row,
    permissions: perms,
  };
}

export async function listRolesByCompany(companyId: string): Promise<CompanyRoleRow[]> {
  const db = await getDatabase();
  const rows = await db.getAllAsync<RoleDbRow>(
    'SELECT * FROM company_roles WHERE company_id = ? ORDER BY is_system DESC, name ASC;',
    companyId,
  );
  return rows.map(mapRoleRow);
}

export async function getRoleById(id: string): Promise<CompanyRoleRow | null> {
  const db = await getDatabase();
  const row = await db.getFirstAsync<RoleDbRow>(
    'SELECT * FROM company_roles WHERE id = ?;',
    id,
  );
  return row ? mapRoleRow(row) : null;
}

export async function getRoleByName(
  companyId: string,
  name: string,
): Promise<CompanyRoleRow | null> {
  const db = await getDatabase();
  const row = await db.getFirstAsync<RoleDbRow>(
    'SELECT * FROM company_roles WHERE company_id = ? AND UPPER(name) = UPPER(?);',
    companyId,
    name.trim(),
  );
  return row ? mapRoleRow(row) : null;
}

export type CreateRoleInput = {
  company_id: string;
  name: string;
  description?: string;
  permissions: string[];
};

export async function createRole(input: CreateRoleInput): Promise<CompanyRoleRow> {
  const db = await getDatabase();
  const id = newId();
  const now = Date.now();
  const cleanName = input.name.trim();

  // Check duplicate
  const existing = await getRoleByName(input.company_id, cleanName);
  if (existing) {
    throw new Error(`A role named "${cleanName}" already exists for this company.`);
  }

  await db.runAsync(
    `INSERT INTO company_roles (
      id, company_id, name, description, permissions, is_system, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, 0, ?, ?);`,
    id,
    input.company_id,
    cleanName,
    input.description?.trim() || null,
    JSON.stringify(input.permissions),
    now,
    now,
  );

  notifyDataChanged();
  const created = await getRoleById(id);
  if (!created) throw new Error('Failed to create role');
  return created;
}

export type UpdateRoleInput = {
  id: string;
  name?: string;
  description?: string;
  permissions?: string[];
};

export async function updateRole(input: UpdateRoleInput): Promise<void> {
  const db = await getDatabase();
  const existing = await getRoleById(input.id);
  if (!existing) {
    throw new Error('Role not found');
  }

  const now = Date.now();
  const name = input.name !== undefined ? input.name.trim() : existing.name;
  const description = (input.description !== undefined ? input.description.trim() : existing.description) ?? null;
  const permissions = input.permissions !== undefined ? JSON.stringify(input.permissions) : JSON.stringify(existing.permissions);

  await db.runAsync(
    `UPDATE company_roles SET 
      name = ?, 
      description = ?, 
      permissions = ?, 
      updated_at = ? 
    WHERE id = ?;`,
    name,
    description,
    permissions,
    now,
    input.id,
  );

  notifyDataChanged();
}

export async function deleteRole(id: string): Promise<void> {
  const db = await getDatabase();
  const existing = await getRoleById(id);
  if (!existing) return;
  if (existing.is_system === 1) {
    throw new Error('Default system roles cannot be deleted. You can modify their permissions.');
  }

  // Check if any staff is using this role
  const staffWithRole = await db.getFirstAsync<{ count: number }>(
    'SELECT COUNT(*) as count FROM staff WHERE role_id = ?;',
    id,
  );
  if (staffWithRole && staffWithRole.count > 0) {
    throw new Error(`Cannot delete role: ${staffWithRole.count} staff members are currently assigned to this role.`);
  }

  await db.runAsync('DELETE FROM company_roles WHERE id = ?;', id);
  notifyDataChanged();
}

export async function ensureCompanyRolesSeeded(companyId: string): Promise<void> {
  const db = await getDatabase();
  const count = await db.getFirstAsync<{ count: number }>(
    'SELECT COUNT(*) as count FROM company_roles WHERE company_id = ?;',
    companyId,
  );
  if (count && count.count > 0) return;

  const now = Date.now();
  const standardRoles = [
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
      isSystem: 1,
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
      isSystem: 1,
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
      isSystem: 1,
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
      isSystem: 1,
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
      isSystem: 1,
    },
  ];

  for (const r of standardRoles) {
    const id = newId();
    await db.runAsync(
      `INSERT OR IGNORE INTO company_roles (
        id, company_id, name, description, permissions, is_system, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?);`,
      id,
      companyId,
      r.name,
      r.description,
      JSON.stringify(r.permissions),
      r.isSystem,
      now,
      now,
    );
  }
}
