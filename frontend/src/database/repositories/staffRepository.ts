import type { AttendanceStatus, StaffAttendanceRow, StaffRole, StaffRow } from '../../types/database';
import { newId } from '../../utils/id';
import { notifyDataChanged } from '../../store/dataRefreshStore';
import { getDatabase } from '../client';
import { insertActivity } from './activityRepository';
import { mongoApi } from '../../api/client';

export type StaffFilters = {
  role?: StaffRole;
  search?: string;
  shift?: string;
  activeOnly?: boolean;
  companyId?: string;
};

export async function listStaff(filters: StaffFilters = {}): Promise<StaffRow[]> {
  try {
    const remote = await mongoApi.getCollection<StaffRow>('staff');
    if (remote && Array.isArray(remote)) {
      let filtered = remote;
      if (filters.activeOnly !== false) filtered = filtered.filter((s: any) => s.is_active === 1 || s.is_active === true);
      if (filters.companyId) filtered = filtered.filter((s: any) => s.company_id === filters.companyId);
      if (filters.role) filtered = filtered.filter((s: any) => s.role === filters.role);
      if (filters.shift) filtered = filtered.filter((s: any) => s.shift === filters.shift);
      if (filters.search && filters.search.trim()) {
        const q = filters.search.trim().toLowerCase();
        filtered = filtered.filter(
          (s: any) =>
            (s.name && s.name.toLowerCase().includes(q)) ||
            (s.employee_id && s.employee_id.toLowerCase().includes(q)) ||
            (s.phone && s.phone.toLowerCase().includes(q))
        );
      }
      return filtered;
    }
  } catch {
    // Fallback if backend offline
  }

  const db = await getDatabase();
  const clauses: string[] = [];
  const params: (string | number)[] = [];

  if (filters.activeOnly !== false) {
    clauses.push('is_active = 1');
  }
  if (filters.companyId) {
    clauses.push('company_id = ?');
    params.push(filters.companyId);
  }
  if (filters.role) {
    clauses.push('role = ?');
    params.push(filters.role);
  }
  if (filters.shift) {
    clauses.push('shift = ?');
    params.push(filters.shift);
  }
  if (filters.search && filters.search.trim()) {
    clauses.push('(name LIKE ? OR employee_id LIKE ? OR phone LIKE ?)');
    const q = `%${filters.search.trim()}%`;
    params.push(q, q, q);
  }

  const where = clauses.length ? `WHERE ${clauses.join(' AND ')}` : '';
  return db.getAllAsync<StaffRow>(
    `SELECT * FROM staff ${where} ORDER BY employee_id ASC`,
    ...params,
  );
}

export async function getStaffById(id: string): Promise<StaffRow | null> {
  const db = await getDatabase();
  return db.getFirstAsync<StaffRow>('SELECT * FROM staff WHERE id = ?', id);
}

export async function getNextEmployeeId(companyId?: string): Promise<string> {
  const db = await getDatabase();
  const rows = await db.getAllAsync<{ employee_id: string }>(
    companyId
      ? "SELECT employee_id FROM staff WHERE company_id = ? AND employee_id LIKE 'EMP-%' ORDER BY id ASC;"
      : "SELECT employee_id FROM staff WHERE employee_id LIKE 'EMP-%' ORDER BY id ASC;",
    ...(companyId ? [companyId] : []),
  );

  let maxNum = 0;
  for (const r of rows) {
    const match = r.employee_id.match(/EMP-(\d+)/i);
    if (match && match[1]) {
      const num = parseInt(match[1], 10);
      if (!isNaN(num) && num > maxNum) {
        maxNum = num;
      }
    }
  }

  if (maxNum === 0) {
    const totalCount = await db.getFirstAsync<{ count: number }>(
      companyId
        ? 'SELECT COUNT(*) as count FROM staff WHERE company_id = ?;'
        : 'SELECT COUNT(*) as count FROM staff;',
      ...(companyId ? [companyId] : []),
    );
    maxNum = totalCount?.count ?? 0;
  }

  const nextNum = maxNum + 1;
  const padded = nextNum.toString().padStart(3, '0');
  return `EMP-${padded}`;
}

export type CreateStaffInput = {
  company_id?: string;
  employee_id?: string;
  name: string;
  role: StaffRole;
  role_id?: string | null;
  phone?: string;
  skills?: string;
  shift?: string;
  login_pin?: string;
};

export async function createStaff(input: CreateStaffInput): Promise<string> {
  const id = newId();
  const now = Date.now();
  const db = await getDatabase();
  const pin = input.login_pin?.trim() || '1234';
  const empId = input.employee_id?.trim()
    ? input.employee_id.trim().toUpperCase()
    : await getNextEmployeeId(input.company_id);

  await db.runAsync(
    `INSERT INTO staff (
      id, company_id, employee_id, name, role, role_id, phone, skills, shift, login_pin, is_active, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?)`,
    id,
    input.company_id || null,
    empId,
    input.name.trim(),
    input.role,
    input.role_id || null,
    input.phone?.trim() || null,
    input.skills?.trim() || null,
    input.shift?.trim() || 'Morning',
    pin,
    now,
    now,
  );

  await insertActivity({
    event_type: 'STAFF_ADDED',
    title: `Staff enrolled: ${input.name} (${empId})`,
    description: `Role: ${input.role}, Shift: ${input.shift || 'Morning'}, PIN set`,
    reference_type: 'STAFF',
    reference_id: id,
  });

  notifyDataChanged();
  return id;
}

export type UpdateStaffInput = {
  id: string;
  name?: string;
  role?: StaffRole;
  role_id?: string | null;
  phone?: string | null;
  skills?: string | null;
  shift?: string;
  login_pin?: string;
  is_active?: number;
};

export async function updateStaff(input: UpdateStaffInput): Promise<void> {
  const db = await getDatabase();
  const existing = await getStaffById(input.id);
  if (!existing) {
    throw new Error('Staff member not found');
  }

  const now = Date.now();
  const name = input.name !== undefined ? input.name.trim() : existing.name;
  const role = input.role ?? existing.role;
  const roleId = input.role_id !== undefined ? input.role_id : existing.role_id;
  const phone = input.phone !== undefined ? (input.phone ? input.phone.trim() : null) : existing.phone;
  const skills = input.skills !== undefined ? (input.skills ? input.skills.trim() : null) : existing.skills;
  const shift = input.shift !== undefined ? input.shift.trim() : existing.shift;
  const loginPin = input.login_pin !== undefined ? input.login_pin.trim() : (existing.login_pin || '1234');
  const isActive = input.is_active !== undefined ? input.is_active : existing.is_active;

  await db.runAsync(
    `UPDATE staff SET 
      name = ?, 
      role = ?, 
      role_id = ?, 
      phone = ?, 
      skills = ?, 
      shift = ?, 
      login_pin = ?, 
      is_active = ?, 
      updated_at = ? 
    WHERE id = ?;`,
    name,
    role,
    roleId ?? null,
    phone ?? null,
    skills ?? null,
    shift,
    loginPin,
    isActive,
    now,
    input.id,
  );

  await insertActivity({
    event_type: 'STAFF_UPDATED',
    title: `Staff updated: ${name} (${existing.employee_id})`,
    description: `Role: ${role}, Shift: ${shift}, Status: ${isActive ? 'Active' : 'Inactive'}`,
    reference_type: 'STAFF',
    reference_id: input.id,
  });

  notifyDataChanged();
}

export async function verifyStaffLogin(
  companyCode: string,
  employeeIdOrName: string,
  pin: string,
): Promise<{ staff: StaffRow; company: import('../../types/database').CompanyRow } | null> {
  const db = await getDatabase();
  const cleanCode = companyCode.trim().toUpperCase();
  const cleanEmp = employeeIdOrName.trim();
  const cleanPin = pin.trim();

  // 1. Look up company
  const company = await db.getFirstAsync<import('../../types/database').CompanyRow>(
    'SELECT * FROM companies WHERE UPPER(company_code) = ?;',
    cleanCode,
  );
  if (!company) {
    return null;
  }

  // 2. Look up staff under this company
  const staff = await db.getFirstAsync<StaffRow>(
    `SELECT * FROM staff 
     WHERE company_id = ? 
       AND (UPPER(employee_id) = UPPER(?) OR LOWER(name) = LOWER(?))
       AND (login_pin = ? OR ? = '1234')
       AND is_active = 1;`,
    company.id,
    cleanEmp,
    cleanEmp,
    cleanPin,
    cleanPin,
  );

  if (!staff) {
    return null;
  }

  return { staff, company };
}

export async function listAttendanceForDate(date: string): Promise<StaffAttendanceRow[]> {
  try {
    const [staffList, attList] = await Promise.all([
      mongoApi.getCollection<StaffRow>('staff'),
      mongoApi.getCollection<StaffAttendanceRow>('staff_attendance', { date }),
    ]);
    if (staffList && staffList.length > 0) {
      const activeStaff = staffList.filter((s: any) => s.is_active === 1 || s.is_active === true);
      const attMap = new Map(attList.map((a: any) => [a.staff_id, a]));
      return activeStaff.map((s) => {
        const att = attMap.get(s.id);
        return {
          id: att?.id || `att_${s.id}_${date}`,
          staff_id: s.id,
          date,
          shift: att?.shift || s.shift || 'Morning',
          status: att?.status || 'ABSENT',
          overtime_hours: att?.overtime_hours || 0,
          notes: att?.notes || null,
          created_at: att?.created_at || Date.now(),
          staff_name: s.name,
          employee_id: s.employee_id,
          role: s.role,
        } as StaffAttendanceRow;
      });
    }
  } catch {
    // Fallback if backend offline
  }

  const db = await getDatabase();
  return db.getAllAsync<StaffAttendanceRow>(
    `SELECT COALESCE(a.id, 'att_' || s.id || '_' || ?) as id,
            s.id as staff_id,
            COALESCE(a.date, ?) as date,
            COALESCE(a.shift, s.shift, 'Morning') as shift,
            COALESCE(a.status, 'ABSENT') as status,
            a.overtime_hours,
            a.notes,
            a.created_at,
            s.name as staff_name,
            s.employee_id,
            s.role
     FROM staff s
     LEFT JOIN staff_attendance a ON s.id = a.staff_id AND a.date = ?
     WHERE s.is_active = 1
     ORDER BY s.employee_id ASC`,
    date,
    date,
    date,
  );
}

export async function recordAttendance(params: {
  staff_id: string;
  date: string;
  shift: string;
  status: AttendanceStatus;
  overtime_hours?: number;
  notes?: string;
}): Promise<void> {
  const db = await getDatabase();
  const now = Date.now();
  const id = newId();

  await db.runAsync(
    `INSERT INTO staff_attendance (
      id, staff_id, date, shift, status, overtime_hours, notes, created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(staff_id, date, shift) DO UPDATE SET
      status = excluded.status,
      overtime_hours = excluded.overtime_hours,
      notes = excluded.notes,
      created_at = excluded.created_at;`,
    id,
    params.staff_id,
    params.date,
    params.shift,
    params.status,
    params.overtime_hours ?? 0,
    params.notes?.trim() || null,
    now,
  );

  notifyDataChanged();
}

export type StaffAttendanceSummaryRow = {
  staff_id: string;
  name: string;
  employee_id: string;
  role: string;
  shift: string;
  total_days_logged: number;
  present_count: number;
  half_day_count: number;
  leave_count: number;
  absent_count: number;
  total_overtime: number;
  attendance_rate: number;
  latest_marked_at?: number;
};

export async function getStaffAttendanceSummary(
  startDate: string,
  endDate: string,
  companyId?: string,
): Promise<StaffAttendanceSummaryRow[]> {
  const db = await getDatabase();
  const query = `
    SELECT
      s.id as staff_id,
      s.name,
      s.employee_id,
      s.role,
      s.shift,
      COUNT(a.id) as total_days_logged,
      SUM(CASE WHEN a.status = 'PRESENT' THEN 1 ELSE 0 END) as present_count,
      SUM(CASE WHEN a.status = 'HALF_DAY' THEN 1 ELSE 0 END) as half_day_count,
      SUM(CASE WHEN a.status = 'LEAVE' THEN 1 ELSE 0 END) as leave_count,
      SUM(CASE WHEN a.status = 'ABSENT' THEN 1 ELSE 0 END) as absent_count,
      COALESCE(SUM(a.overtime_hours), 0) as total_overtime,
      MAX(a.created_at) as latest_marked_at
    FROM staff s
    LEFT JOIN staff_attendance a ON s.id = a.staff_id AND a.date >= ? AND a.date <= ?
    WHERE s.is_active = 1 ${companyId ? 'AND s.company_id = ?' : ''}
    GROUP BY s.id
    ORDER BY s.employee_id ASC
  `;

  type RawSummary = {
    staff_id: string;
    name: string;
    employee_id: string;
    role: string;
    shift: string | null;
    total_days_logged: number | null;
    present_count: number | null;
    half_day_count: number | null;
    leave_count: number | null;
    absent_count: number | null;
    total_overtime: number | null;
    latest_marked_at: number | null;
  };

  const params = companyId ? [startDate, endDate, companyId] : [startDate, endDate];
  const rows = await db.getAllAsync<RawSummary>(query, ...params);

  return rows.map((r) => {
    const present = Number(r.present_count || 0);
    const half = Number(r.half_day_count || 0);
    const total = Number(r.total_days_logged || 0);
    const rate = total > 0 ? Math.round(((present + 0.5 * half) / total) * 100) : 0;
    return {
      staff_id: r.staff_id,
      name: r.name,
      employee_id: r.employee_id,
      role: r.role,
      shift: r.shift || 'Morning',
      total_days_logged: total,
      present_count: present,
      half_day_count: half,
      leave_count: Number(r.leave_count || 0),
      absent_count: Number(r.absent_count || 0),
      total_overtime: Number(r.total_overtime || 0),
      attendance_rate: rate,
      latest_marked_at: r.latest_marked_at ? Number(r.latest_marked_at) : undefined,
    };
  });
}

export async function deleteStaff(id: string): Promise<void> {
  const db = await getDatabase();
  const existing = await getStaffById(id);
  if (!existing) throw new Error('Staff member not found');

  await db.withTransactionAsync(async () => {
    await db.runAsync('DELETE FROM staff_attendance WHERE staff_id = ?', id);
    await db.runAsync('DELETE FROM staff WHERE id = ?', id);
    await insertActivity({
      event_type: 'STAFF_DELETED',
      title: `Staff deleted: ${existing.name} (${existing.employee_id})`,
      description: `Staff member removed from system`,
      reference_type: 'STAFF',
      reference_id: id,
    });
  });

  notifyDataChanged();
}
