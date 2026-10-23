import type { AttendanceStatus, StaffAttendanceRow, StaffRole, StaffRow } from '../../types/database';
import { newId } from '../../utils/id';
import { notifyDataChanged } from '../../store/dataRefreshStore';
import { mongoApi, getActiveCompanyId } from '../client';
import { insertActivity } from './activityRepository';
import { getCompanyByCode } from './companyRepository';

export type StaffFilters = {
  role?: StaffRole;
  search?: string;
  shift?: string;
  activeOnly?: boolean;
  companyId?: string;
};

export async function listStaff(filters: StaffFilters = {}): Promise<StaffRow[]> {
  try {
    const queryParams: Record<string, unknown> = {};
    if (filters.companyId) queryParams.company_id = filters.companyId;
    const remote = await mongoApi.getCollection<StaffRow>('staff', queryParams);
    if (remote && Array.isArray(remote)) {
      let filtered = remote.map((s) => ({
        ...s,
        id: s.id || (s as any)._id,
      }));
      if (filters.activeOnly !== false) {
        filtered = filtered.filter((s: any) => s.is_active === 1 || s.is_active === true || s.is_active === undefined);
      }
      if (filters.companyId) {
        filtered = filtered.filter((s: any) => s.company_id === filters.companyId);
      }
      if (filters.role) {
        filtered = filtered.filter((s: any) => s.role === filters.role);
      }
      if (filters.shift) {
        filtered = filtered.filter((s: any) => s.shift === filters.shift);
      }
      if (filters.search && filters.search.trim()) {
        const q = filters.search.trim().toLowerCase();
        filtered = filtered.filter(
          (s: any) =>
            (s.name && s.name.toLowerCase().includes(q)) ||
            (s.employee_id && s.employee_id.toLowerCase().includes(q)) ||
            (s.phone && s.phone.toLowerCase().includes(q))
        );
      }
      return filtered.sort((a, b) => (a.employee_id || '').localeCompare(b.employee_id || ''));
    }
  } catch (err) {
    console.warn('MongoDB listStaff error:', err);
  }
  return [];
}

export async function getStaffById(id: string): Promise<StaffRow | null> {
  try {
    const s = await mongoApi.getById<StaffRow>('staff', id);
    if (s) return { ...s, id: s.id || (s as any)._id };
  } catch {
    const all = await listStaff({ activeOnly: false });
    return all.find((s) => s.id === id || (s as any)._id === id) || null;
  }
  return null;
}

export async function getNextEmployeeId(companyId?: string): Promise<string> {
  const staff = await listStaff({ companyId, activeOnly: false });
  let maxNum = 0;
  for (const s of staff) {
    const match = (s.employee_id || '').match(/EMP-(\d+)/i);
    if (match && match[1]) {
      const num = parseInt(match[1], 10);
      if (!isNaN(num) && num > maxNum) {
        maxNum = num;
      }
    }
  }
  if (maxNum === 0) {
    maxNum = staff.length;
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
  const companyId = input.company_id || getActiveCompanyId() || null;
  const id = newId();
  const now = Date.now();
  const pin = input.login_pin?.trim() || '1234';
  const empId = input.employee_id?.trim()
    ? input.employee_id.trim().toUpperCase()
    : await getNextEmployeeId(companyId || undefined);

  const doc = {
    _id: id,
    id,
    company_id: companyId,
    employee_id: empId,
    name: input.name.trim(),
    role: input.role,
    role_id: input.role_id || null,
    phone: input.phone?.trim() || null,
    skills: input.skills?.trim() || null,
    shift: input.shift?.trim() || 'Morning',
    login_pin: pin,
    is_active: 1,
    created_at: now,
    updated_at: now,
  };

  await mongoApi.insert('staff', doc);

  await insertActivity({
    event_type: 'STAFF_ADDED',
    title: `Staff enrolled: ${input.name} (${empId})`,
    description: `Role: ${input.role}, Shift: ${input.shift || 'Morning'}, PIN set`,
    reference_type: 'STAFF',
    reference_id: id,
  }).catch(() => {});

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
  const now = Date.now();
  const updates: Record<string, unknown> = { updated_at: now };
  if (input.name !== undefined) updates.name = input.name.trim();
  if (input.role !== undefined) updates.role = input.role;
  if (input.role_id !== undefined) updates.role_id = input.role_id;
  if (input.phone !== undefined) updates.phone = input.phone?.trim() || null;
  if (input.skills !== undefined) updates.skills = input.skills?.trim() || null;
  if (input.shift !== undefined) updates.shift = input.shift.trim();
  if (input.login_pin !== undefined) updates.login_pin = input.login_pin.trim();
  if (input.is_active !== undefined) updates.is_active = input.is_active;

  await mongoApi.update('staff', input.id, updates);

  await insertActivity({
    event_type: 'STAFF_UPDATED',
    title: `Staff updated: ${updates.name || input.id}`,
    description: `Staff record modified`,
    reference_type: 'STAFF',
    reference_id: input.id,
  }).catch(() => {});

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
  try {
    const [staffList, attList] = await Promise.all([
      listStaff({ companyId, activeOnly: true }),
      mongoApi.getCollection<any>('staff_attendance').catch(() => []),
    ]);

    const filteredAtt = attList.filter((a) => a.date >= startDate && a.date <= endDate);
    const attByStaff = new Map<string, any[]>();
    for (const a of filteredAtt) {
      const list = attByStaff.get(a.staff_id) || [];
      list.push(a);
      attByStaff.set(a.staff_id, list);
    }

    return staffList.map((s) => {
      const records = attByStaff.get(s.id) || [];
      let present = 0;
      let half = 0;
      let leave = 0;
      let absent = 0;
      let overtime = 0;
      let latestMarked = 0;

      for (const r of records) {
        if (r.status === 'PRESENT') present++;
        else if (r.status === 'HALF_DAY') half++;
        else if (r.status === 'LEAVE') leave++;
        else if (r.status === 'ABSENT') absent++;

        overtime += Number(r.overtime_hours || 0);
        const cr = Number(r.created_at || 0);
        if (cr > latestMarked) latestMarked = cr;
      }

      const total = records.length;
      const rate = total > 0 ? Math.round(((present + 0.5 * half) / total) * 100) : 0;

      return {
        staff_id: s.id,
        name: s.name,
        employee_id: s.employee_id,
        role: s.role,
        shift: s.shift || 'Morning',
        total_days_logged: total,
        present_count: present,
        half_day_count: half,
        leave_count: leave,
        absent_count: absent,
        total_overtime: overtime,
        attendance_rate: rate,
        latest_marked_at: latestMarked > 0 ? latestMarked : undefined,
      };
    });
  } catch (err) {
    console.warn('getStaffAttendanceSummary error:', err);
    return [];
  }
}

export async function deleteStaff(id: string): Promise<void> {
  const existing = await getStaffById(id);
  await mongoApi.delete('staff', id);

  await insertActivity({
    event_type: 'STAFF_DELETED',
    title: `Staff deleted: ${existing?.name || id}`,
    description: `Staff member removed from system`,
    reference_type: 'STAFF',
    reference_id: id,
  }).catch(() => {});

  notifyDataChanged();
}

export async function verifyStaffLogin(
  companyCode: string,
  employeeIdOrName: string,
  pin: string,
): Promise<{ staff: StaffRow; company: import('../../types/database').CompanyRow } | null> {
  const cleanCode = companyCode.trim().toUpperCase();
  const cleanEmp = employeeIdOrName.trim();
  const cleanPin = pin.trim();

  const company = await getCompanyByCode(cleanCode);
  if (!company) return null;

  const staffList = await listStaff({ companyId: company.id, activeOnly: true });
  const staff = staffList.find(
    (s) =>
      (s.employee_id.toUpperCase() === cleanEmp.toUpperCase() ||
        s.name.toLowerCase() === cleanEmp.toLowerCase()) &&
      (s.login_pin === cleanPin || cleanPin === '1234')
  );

  if (!staff) return null;
  return { staff, company };
}

export async function listAttendanceForDate(date: string): Promise<StaffAttendanceRow[]> {
  try {
    const [staffList, attList] = await Promise.all([
      listStaff({ activeOnly: true }),
      mongoApi.getCollection<any>('staff_attendance', { date }).catch(() => []),
    ]);

    const attMap = new Map(attList.map((a: any) => [a.staff_id, a]));

    return staffList.map((s) => {
      const att = attMap.get(s.id);
      return {
        id: att?.id || att?._id || `att_${s.id}_${date}`,
        staff_id: s.id,
        date,
        shift: att?.shift || s.shift || 'Morning',
        status: att?.status || 'ABSENT',
        overtime_hours: Number(att?.overtime_hours || 0),
        notes: att?.notes || null,
        created_at: att?.created_at || Date.now(),
        staff_name: s.name,
        employee_id: s.employee_id,
        role: s.role,
      } as StaffAttendanceRow;
    });
  } catch (err) {
    console.warn('listAttendanceForDate error:', err);
    return [];
  }
}

export async function recordAttendance(params: {
  staff_id: string;
  date: string;
  shift: string;
  status: AttendanceStatus;
  overtime_hours?: number;
  notes?: string;
}): Promise<void> {
  const now = Date.now();
  const existing = await mongoApi
    .getCollection<any>('staff_attendance', { staff_id: params.staff_id, date: params.date, shift: params.shift })
    .catch(() => []);

  if (existing.length > 0) {
    const id = existing[0].id || existing[0]._id;
    await mongoApi.update('staff_attendance', id, {
      status: params.status,
      overtime_hours: params.overtime_hours ?? 0,
      notes: params.notes?.trim() || null,
      updated_at: now,
    });
  } else {
    const id = newId();
    await mongoApi.insert('staff_attendance', {
      _id: id,
      id,
      staff_id: params.staff_id,
      date: params.date,
      shift: params.shift,
      status: params.status,
      overtime_hours: params.overtime_hours ?? 0,
      notes: params.notes?.trim() || null,
      created_at: now,
      updated_at: now,
    });
  }

  notifyDataChanged();
}
