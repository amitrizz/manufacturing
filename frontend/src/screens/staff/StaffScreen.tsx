import { Ionicons } from '@expo/vector-icons';
import { useNavigation, useRoute } from '@react-navigation/native';
import { useCallback, useMemo, useState } from 'react';
import {
  Alert,
  FlatList,
  Modal,
  Pressable,
  RefreshControl,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { Button } from '../../components/common/Button';
import { Card } from '../../components/common/Card';
import { Screen } from '../../components/common/Screen';
import { SearchField } from '../../components/common/SearchField';
import {
  createStaff,
  deleteStaff,
  getNextEmployeeId,
  getStaffAttendanceSummary,
  listAttendanceForDate,
  listStaff,
  recordAttendance,
  updateStaff,
  type StaffAttendanceSummaryRow,
} from '../../database/repositories/staffRepository';
import { listRolesByCompany } from '../../database/repositories/roleRepository';
import { exportReport } from '../../services/exportService';
import { useLiveQuery } from '../../hooks/useLiveQuery';
import { colors, spacing, typography } from '../../theme';
import { formatDateTime, formatTime } from '../../utils/format';
import type { AttendanceStatus, StaffAttendanceRow, StaffRole, StaffRow } from '../../types/database';
import type { CompanyRoleRow } from '../../types/permissions';

import { ViewModeBanner } from '../../components/common/ViewModeBanner';
import { useAuthStore } from '../../store/authStore';

type Tab = 'staff' | 'attendance';

const ROLES: StaffRole[] = ['OPERATOR', 'SUPERVISOR', 'TECHNICIAN', 'QUALITY_INSPECTOR', 'MANAGER'];

export function StaffScreen() {
  const navigation = useNavigation<any>();
  const route = useRoute<any>();
  const isViewOnly = Boolean(route.params?.viewOnly);
  const company = useAuthStore((s) => s.company);
  const startStaffPreview = useAuthStore((s) => s.startStaffPreview);
  const previewStaff = useAuthStore((s) => s.previewStaff);
  const exitPreview = useAuthStore((s) => s.exitPreview);
  const [tab, setTab] = useState<Tab>('staff');
  const [search, setSearch] = useState('');
  const [staffList, setStaffList] = useState<StaffRow[]>([]);
  const [attendanceList, setAttendanceList] = useState<StaffAttendanceRow[]>([]);
  const [attendanceSummary, setAttendanceSummary] = useState<StaffAttendanceSummaryRow[]>([]);
  const [attendanceViewMode, setAttendanceViewMode] = useState<'day' | 'week' | 'month'>('day');
  const [companyRoles, setCompanyRoles] = useState<CompanyRoleRow[]>([]);
  const [loading, setLoading] = useState(false);

  // Add / Edit Staff Modal
  const [showAddStaff, setShowAddStaff] = useState(false);
  const [modalMode, setModalMode] = useState<'create' | 'edit'>('create');
  const [editingStaffId, setEditingStaffId] = useState<string | null>(null);
  const [empId, setEmpId] = useState('');
  const [name, setName] = useState('');
  const [role, setRole] = useState<StaffRole>('OPERATOR');
  const [roleId, setRoleId] = useState<string | null>(null);
  const [phone, setPhone] = useState('');
  const [skills, setSkills] = useState('');
  const [shift, setShift] = useState('Morning');
  const [loginPin, setLoginPin] = useState('1234');
  const [isActiveStaff, setIsActiveStaff] = useState<number>(1);

  // Today's date string YYYY-MM-DD
  const todayDateStr = useMemo(() => new Date().toISOString().slice(0, 10), []);
  const [selectedDate, setSelectedDate] = useState(todayDateStr);

  const weekRange = useMemo(() => {
    const end = new Date();
    const start = new Date();
    start.setDate(end.getDate() - 6);
    return {
      start: start.toISOString().slice(0, 10),
      end: end.toISOString().slice(0, 10),
      startTimestamp: start.getTime(),
      endTimestamp: end.getTime(),
    };
  }, []);

  const monthRange = useMemo(() => {
    const end = new Date();
    const start = new Date();
    start.setDate(end.getDate() - 29);
    return {
      start: start.toISOString().slice(0, 10),
      end: end.toISOString().slice(0, 10),
      startTimestamp: start.getTime(),
      endTimestamp: end.getTime(),
    };
  }, []);

  const handlePrevDay = () => {
    const d = new Date(selectedDate);
    d.setDate(d.getDate() - 1);
    setSelectedDate(d.toISOString().slice(0, 10));
  };

  const handleNextDay = () => {
    const d = new Date(selectedDate);
    d.setDate(d.getDate() + 1);
    setSelectedDate(d.toISOString().slice(0, 10));
  };

  const handleExportAttendance = async () => {
    try {
      if (attendanceViewMode === 'month') {
        await exportReport('attendance', monthRange.startTimestamp, monthRange.endTimestamp, 'csv');
      } else if (attendanceViewMode === 'week') {
        await exportReport('attendance', weekRange.startTimestamp, weekRange.endTimestamp, 'csv');
      } else {
        const dayTime = new Date(selectedDate).getTime();
        await exportReport('attendance', dayTime, dayTime + 86400000 - 1, 'csv');
      }
    } catch (e: unknown) {
      Alert.alert('Export Error', e instanceof Error ? e.message : 'Could not export attendance');
    }
  };

  const loadData = useCallback(async () => {
    setLoading(true);
    try {
      if (company?.id) {
        const roles = await listRolesByCompany(company.id);
        setCompanyRoles(roles);
      }
      if (tab === 'staff') {
        const list = await listStaff({ search, companyId: company?.id });
        setStaffList(list);
      } else if (attendanceViewMode === 'day') {
        const att = await listAttendanceForDate(selectedDate);
        setAttendanceList(att);
      } else if (attendanceViewMode === 'week') {
        const summary = await getStaffAttendanceSummary(weekRange.start, weekRange.end, company?.id);
        setAttendanceSummary(summary);
      } else if (attendanceViewMode === 'month') {
        const summary = await getStaffAttendanceSummary(monthRange.start, monthRange.end, company?.id);
        setAttendanceSummary(summary);
      }
    } finally {
      setLoading(false);
    }
  }, [tab, search, selectedDate, attendanceViewMode, company?.id, weekRange, monthRange]);

  useLiveQuery(loadData);

  const handleOpenAddStaff = async () => {
    setModalMode('create');
    setEditingStaffId(null);
    try {
      const nextId = await getNextEmployeeId(company?.id);
      setEmpId(nextId);
    } catch {
      setEmpId('EMP-001');
    }
    setName('');
    const defaultRole = companyRoles[0];
    setRole(defaultRole?.name || 'OPERATOR');
    setRoleId(defaultRole?.id || null);
    setShift('Morning');
    setPhone('');
    setSkills('');
    setLoginPin('1234');
    setIsActiveStaff(1);
    setShowAddStaff(true);
  };

  const handleOpenEditStaff = (st: StaffRow) => {
    setModalMode('edit');
    setEditingStaffId(st.id);
    setEmpId(st.employee_id);
    setName(st.name);
    setRole(st.role);
    const matched = companyRoles.find(
      (r) => r.id === st.role_id || r.name.toUpperCase() === st.role.toUpperCase(),
    );
    setRoleId(matched?.id || st.role_id || null);
    setShift(st.shift || 'Morning');
    setPhone(st.phone || '');
    setSkills(st.skills || '');
    setLoginPin(st.login_pin || '1234');
    setIsActiveStaff(st.is_active);
    setShowAddStaff(true);
  };

  const handleDeleteStaff = (staffId: string) => {
    const st = staffList.find((s) => s.id === staffId);
    Alert.alert(
      'Delete Staff Member',
      `Are you sure you want to delete ${st?.name || 'this staff member'} (${st?.employee_id || ''})?\n\nThis will remove their profile and all attendance records.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: async () => {
            try {
              await deleteStaff(staffId);
              setShowAddStaff(false);
              Alert.alert('Deleted', 'Staff member deleted successfully.');
              await loadData();
            } catch (e: unknown) {
              Alert.alert('Error', e instanceof Error ? e.message : 'Could not delete staff');
            }
          },
        },
      ],
    );
  };

  const handleViewAsStaff = (st: StaffRow) => {
    const matchedRole = companyRoles.find(
      (r) => r.id === st.role_id || r.name.toUpperCase() === st.role.toUpperCase(),
    );
    const permissions = matchedRole?.permissions || [
      'home_production',
      'home_machines',
      'tasks_production',
    ];

    startStaffPreview({
      id: st.id,
      employee_id: st.employee_id,
      name: st.name,
      role: st.role,
      shift: st.shift || 'Morning',
      permissions,
    });
    setShowAddStaff(false);
    Alert.alert(
      `Viewing as "${st.name}"`,
      `You are now viewing the mobile app interface as "${st.name}" (${st.role} • ${st.employee_id}).\n\n• Home tab: Modules permitted for ${st.role}\n• My Tasks tab: Activities assigned for ${st.role}\n• Record Production: Auto-stamped as ${st.name} (${st.role})\n\nTap "Exit" in the top header at any time to return to Owner view.`,
      [
        {
          text: 'Open Home Screen',
          onPress: () => {
            try {
              navigation.navigate('Main', {
                screen: 'Home',
                params: { screen: 'Dashboard' },
              });
            } catch {
              navigation.navigate('Home');
            }
          },
        },
        {
          text: 'Stay on Staff',
          style: 'cancel',
        },
      ],
    );
  };

  const handleSaveStaff = async () => {
    if (!name.trim()) {
      Alert.alert('Required Fields', 'Please enter staff name.');
      return;
    }
    if (!loginPin.trim()) {
      Alert.alert('Required Fields', 'Please enter a 4-digit PIN for staff login.');
      return;
    }

    if (modalMode === 'edit' && editingStaffId) {
      try {
        await updateStaff({
          id: editingStaffId,
          name: name.trim(),
          role,
          role_id: roleId,
          phone: phone.trim() || null,
          skills: skills.trim() || null,
          shift: shift.trim() || 'Morning',
          login_pin: loginPin.trim(),
          is_active: isActiveStaff,
        });
        setShowAddStaff(false);
        Alert.alert('Success', `Staff member ${name} updated successfully.`);
        await loadData();
      } catch (e: unknown) {
        Alert.alert('Error', e instanceof Error ? e.message : 'Could not update staff member');
      }
      return;
    }

    try {
      await createStaff({
        company_id: company?.id,
        employee_id: empId.trim().toUpperCase(),
        name: name.trim(),
        role,
        role_id: roleId,
        phone: phone.trim() || undefined,
        skills: skills.trim() || undefined,
        shift: shift.trim() || 'Morning',
        login_pin: loginPin.trim(),
      });
      setShowAddStaff(false);
      setEmpId('');
      setName('');
      setPhone('');
      setSkills('');
      setLoginPin('1234');
      Alert.alert(
        'Staff Enrolled Successfully!',
        `${name} (${empId.toUpperCase()}) is registered under ${company?.name || 'Company'}.\n\nStaff Login Credentials:\n• Company Code: ${company?.company_code || 'APEX01'}\n• Employee ID: ${empId.toUpperCase()}\n• PIN: ${loginPin.trim()}`,
      );
      await loadData();
    } catch (e: unknown) {
      Alert.alert('Error', e instanceof Error ? e.message : 'Could not add staff member');
    }
  };

  const handleToggleAttendance = async (staffId: string, currentStatus: AttendanceStatus | undefined, staffShift: string) => {
    const cycle: Record<AttendanceStatus, AttendanceStatus> = {
      PRESENT: 'HALF_DAY',
      HALF_DAY: 'ABSENT',
      ABSENT: 'LEAVE',
      LEAVE: 'PRESENT',
    };
    const nextStatus = currentStatus ? cycle[currentStatus] : 'PRESENT';
    try {
      await recordAttendance({
        staff_id: staffId,
        date: selectedDate,
        shift: staffShift || 'Morning',
        status: nextStatus,
      });
      await loadData();
    } catch (e: unknown) {
      Alert.alert('Error', e instanceof Error ? e.message : 'Failed to update attendance');
    }
  };

  return (
    <Screen scroll={false}>
      {isViewOnly && (
        <ViewModeBanner
          message="Staff roster & attendance monitoring mode. Staff enrollment, edits, and attendance marking are disabled. Use the Management tab to make changes."
        />
      )}

      {/* Active Staff Preview Banner */}
      {previewStaff && (
        <View style={styles.activePreviewBanner}>
          <View style={{ flex: 1, flexDirection: 'row', alignItems: 'center', gap: 6 }}>
            <Ionicons name="eye" size={16} color="#D97706" />
            <Text style={styles.activePreviewText} numberOfLines={1}>
              Previewing: <Text style={styles.activePreviewBold}>{previewStaff.name}</Text> ({previewStaff.role} • {previewStaff.employee_id})
            </Text>
          </View>
          <Pressable style={styles.activeExitBtn} onPress={exitPreview}>
            <Ionicons name="close-circle" size={13} color="#FFFFFF" />
            <Text style={styles.activeExitText}>Exit</Text>
          </Pressable>
        </View>
      )}

      {/* Company Scope Banner */}
      {company && (
        <View style={styles.companyScopeBanner}>
          <Ionicons name="business" size={16} color="#0369A1" />
          <Text style={styles.companyScopeText}>
            Company: <Text style={styles.bold}>{company.name}</Text> (Code: {company.company_code})
          </Text>
        </View>
      )}

      {/* Segmented Switcher */}
      <View style={styles.segmentContainer}>
        <Pressable
          style={[styles.segmentBtn, tab === 'staff' && styles.segmentBtnActive]}
          onPress={() => setTab('staff')}
        >
          <Text style={[styles.segmentText, tab === 'staff' && styles.segmentTextActive]}>
            Staff Roster ({staffList.length})
          </Text>
        </Pressable>
        <Pressable
          style={[styles.segmentBtn, tab === 'attendance' && styles.segmentBtnActive]}
          onPress={() => setTab('attendance')}
        >
          <Text style={[styles.segmentText, tab === 'attendance' && styles.segmentTextActive]}>
            Daily Attendance
          </Text>
        </Pressable>
      </View>

      {tab === 'staff' ? (
        <>
          <View style={styles.actionRow}>
            <View style={{ flex: 1 }}>
              <SearchField
                value={search}
                onChangeText={setSearch}
                placeholder="Search staff by name or ID..."
              />
            </View>
            {!isViewOnly && <Button label="+ Add Staff" onPress={handleOpenAddStaff} />}
          </View>

          <FlatList
            data={staffList}
            keyExtractor={(item) => item.id}
            refreshControl={<RefreshControl refreshing={loading} onRefresh={loadData} />}
            contentContainerStyle={{ paddingBottom: 24 }}
            ListEmptyComponent={
              <View style={styles.empty}>
                <Text style={styles.emptyText}>No staff members found</Text>
              </View>
            }
            renderItem={({ item }) => (
              <Card style={styles.cardItem}>
                <View style={styles.cardHeader}>
                  <View style={{ flex: 1, marginRight: 8 }}>
                    <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
                      <Text style={styles.cardTitle}>{item.name}</Text>
                      {item.is_active === 0 && (
                        <View style={styles.inactiveBadge}>
                          <Text style={styles.inactiveBadgeText}>INACTIVE</Text>
                        </View>
                      )}
                    </View>
                    <Text style={styles.cardSubtitle}>
                      ID: {item.employee_id} • Shift: {item.shift} • PIN: {item.login_pin || '1234'}
                    </Text>
                  </View>
                  <View style={{ alignItems: 'flex-end', gap: 6 }}>
                    <View style={[styles.roleBadge, { backgroundColor: colors.infoBg }]}>
                      <Text style={[styles.roleBadgeText, { color: colors.info }]}>{item.role}</Text>
                    </View>
                    {!isViewOnly && (
                      <View style={{ flexDirection: 'row', gap: 6 }}>
                        <Pressable
                          style={styles.editBtn}
                          onPress={() => handleOpenEditStaff(item)}
                          hitSlop={8}
                        >
                          <Ionicons name="create-outline" size={13} color="#0A1E38" />
                          <Text style={styles.editBtnText}>Edit</Text>
                        </Pressable>
                        <Pressable
                          style={[styles.editBtn, { borderColor: '#FECACA', backgroundColor: '#FEF2F2' }]}
                          onPress={() => handleDeleteStaff(item.id)}
                          hitSlop={8}
                        >
                          <Ionicons name="trash-outline" size={13} color={colors.danger} />
                        </Pressable>
                      </View>
                    )}
                  </View>
                </View>
                {item.skills ? (
                  <View style={styles.infoRow}>
                    <Ionicons name="construct-outline" size={14} color={colors.textSecondary} />
                    <Text style={styles.infoText}>Skills: {item.skills}</Text>
                  </View>
                ) : null}
                {item.phone ? (
                  <View style={styles.infoRow}>
                    <Ionicons name="call-outline" size={14} color={colors.textSecondary} />
                    <Text style={styles.infoText}>{item.phone}</Text>
                  </View>
                ) : null}

                {/* View As Staff Action Button */}
                <View style={styles.cardFooterRow}>
                  <Pressable
                    style={styles.viewAsStaffBtn}
                    onPress={() => handleViewAsStaff(item)}
                  >
                    <Ionicons name="eye-outline" size={14} color="#0284C7" />
                    <Text style={styles.viewAsStaffBtnText}>View as this staff</Text>
                  </Pressable>
                </View>
              </Card>
            )}
          />
        </>
      ) : (
        <>
          {/* Attendance Timeframe Scope Bar */}
          <View style={styles.attendanceScopeRow}>
            <Pressable
              style={[
                styles.attendanceScopeBtn,
                attendanceViewMode === 'day' && styles.attendanceScopeBtnActive,
              ]}
              onPress={() => setAttendanceViewMode('day')}
            >
              <Ionicons
                name="today-outline"
                size={13}
                color={attendanceViewMode === 'day' ? '#0A1E38' : colors.textSecondary}
              />
              <Text
                style={[
                  styles.attendanceScopeText,
                  attendanceViewMode === 'day' && styles.attendanceScopeTextActive,
                ]}
              >
                Daily Sheet
              </Text>
            </Pressable>

            <Pressable
              style={[
                styles.attendanceScopeBtn,
                attendanceViewMode === 'week' && styles.attendanceScopeBtnActive,
              ]}
              onPress={() => setAttendanceViewMode('week')}
            >
              <Ionicons
                name="calendar-outline"
                size={13}
                color={attendanceViewMode === 'week' ? '#0A1E38' : colors.textSecondary}
              />
              <Text
                style={[
                  styles.attendanceScopeText,
                  attendanceViewMode === 'week' && styles.attendanceScopeTextActive,
                ]}
              >
                Last 7 Days
              </Text>
            </Pressable>

            <Pressable
              style={[
                styles.attendanceScopeBtn,
                attendanceViewMode === 'month' && styles.attendanceScopeBtnActive,
              ]}
              onPress={() => setAttendanceViewMode('month')}
            >
              <Ionicons
                name="stats-chart-outline"
                size={13}
                color={attendanceViewMode === 'month' ? '#0A1E38' : colors.textSecondary}
              />
              <Text
                style={[
                  styles.attendanceScopeText,
                  attendanceViewMode === 'month' && styles.attendanceScopeTextActive,
                ]}
              >
                Last 30 Days
              </Text>
            </Pressable>
          </View>

          {/* Sub Header for View Mode */}
          {attendanceViewMode === 'day' ? (
            <View style={styles.dateNavCard}>
              <Pressable style={styles.dateNavArrow} onPress={handlePrevDay} hitSlop={8}>
                <Ionicons name="chevron-back" size={16} color="#0A1E38" />
                <Text style={styles.dateNavArrowText}>Prev</Text>
              </Pressable>

              <View style={styles.dateNavCenter}>
                <Text style={styles.dateNavDateText}>
                  {selectedDate === todayDateStr ? `Today (${selectedDate})` : selectedDate}
                </Text>
                {selectedDate !== todayDateStr ? (
                  <Pressable onPress={() => setSelectedDate(todayDateStr)} hitSlop={6}>
                    <Text style={styles.jumpToTodayText}>Jump to Today</Text>
                  </Pressable>
                ) : (
                  <Text style={styles.attendanceHint}>Tap badge: Present ➔ Half ➔ Absent ➔ Leave</Text>
                )}
              </View>

              <Pressable style={styles.dateNavArrow} onPress={handleNextDay} hitSlop={8}>
                <Text style={styles.dateNavArrowText}>Next</Text>
                <Ionicons name="chevron-forward" size={16} color="#0A1E38" />
              </Pressable>
            </View>
          ) : (
            <View style={styles.rangeBannerCard}>
              <View style={{ flex: 1 }}>
                <Text style={styles.rangeBannerTitle}>
                  {attendanceViewMode === 'week' ? 'Past 7 Days Attendance' : 'Past 30 Days Attendance'}
                </Text>
                <Text style={styles.rangeBannerSubtitle}>
                  {attendanceViewMode === 'week'
                    ? `${weekRange.start}  ➔  ${weekRange.end}`
                    : `${monthRange.start}  ➔  ${monthRange.end}`}
                </Text>
              </View>
              <Pressable style={styles.exportCsvBtn} onPress={handleExportAttendance} hitSlop={8}>
                <Ionicons name="download-outline" size={13} color="#0284C7" />
                <Text style={styles.exportCsvBtnText}>Export CSV</Text>
              </Pressable>
            </View>
          )}

          {attendanceViewMode === 'day' ? (
            <FlatList
              data={attendanceList}
              keyExtractor={(item, index) => item.staff_id || item.employee_id || String(index)}
              refreshControl={<RefreshControl refreshing={loading} onRefresh={loadData} />}
              contentContainerStyle={{ paddingBottom: 24 }}
              ListEmptyComponent={
                <View style={styles.empty}>
                  <Text style={styles.emptyText}>No staff records found for {selectedDate}</Text>
                </View>
              }
              renderItem={({ item }) => {
                const status = item.status ?? 'ABSENT';
                const statusColor =
                  status === 'PRESENT'
                    ? colors.success
                    : status === 'HALF_DAY'
                    ? colors.warning
                    : status === 'LEAVE'
                    ? colors.info
                    : colors.danger;
                const statusBg =
                  status === 'PRESENT'
                    ? colors.successBg
                    : status === 'HALF_DAY'
                    ? colors.warningBg
                    : status === 'LEAVE'
                    ? colors.infoBg
                    : colors.dangerBg;

                const timeDisplay =
                  item.created_at && status !== 'ABSENT'
                    ? `Marked at ${formatTime(item.created_at)}`
                    : 'Not clocked in yet';

                return (
                  <Card style={styles.cardItem}>
                    <View style={styles.cardHeader}>
                      <View style={{ flex: 1, marginRight: 8 }}>
                        <Text style={styles.cardTitle}>{item.staff_name || 'Staff'}</Text>
                        <Text style={styles.cardSubtitle}>
                          {item.employee_id} • {item.role}
                        </Text>
                      </View>
                      {isViewOnly ? (
                        <View style={[styles.attendanceBadge, { backgroundColor: statusBg }]}>
                          <Text style={[styles.attendanceBadgeText, { color: statusColor }]}>
                            {status}
                          </Text>
                        </View>
                      ) : (
                        <Pressable
                          style={[styles.attendanceBadge, { backgroundColor: statusBg }]}
                          onPress={() => handleToggleAttendance(item.staff_id, item.status, item.shift || 'Morning')}
                        >
                          <Text style={[styles.attendanceBadgeText, { color: statusColor }]}>
                            {status}
                          </Text>
                        </Pressable>
                      )}
                    </View>
                    <View style={styles.attendanceMetaRow}>
                      <View style={styles.attendanceMetaItem}>
                        <Ionicons
                          name="time-outline"
                          size={13}
                          color={Boolean(item.created_at) && status !== 'ABSENT' ? '#0A1E38' : colors.textSecondary}
                        />
                        <Text
                          style={[
                            styles.attendanceMetaText,
                            Boolean(item.created_at) && status !== 'ABSENT' ? styles.attendanceMetaTextActive : null,
                          ]}
                        >
                          {timeDisplay}
                        </Text>
                      </View>
                      <View style={styles.attendanceMetaItem}>
                        <Ionicons name="sunny-outline" size={13} color={colors.textSecondary} />
                        <Text style={styles.attendanceMetaText}>Shift: {item.shift || 'Morning'}</Text>
                      </View>
                    </View>
                  </Card>
                );
              }}
            />
          ) : (
            <FlatList
              data={attendanceSummary}
              keyExtractor={(item) => item.staff_id}
              refreshControl={<RefreshControl refreshing={loading} onRefresh={loadData} />}
              contentContainerStyle={{ paddingBottom: 24 }}
              ListEmptyComponent={
                <View style={styles.empty}>
                  <Text style={styles.emptyText}>No attendance history found in this period</Text>
                </View>
              }
              renderItem={({ item }) => {
                const rateColor =
                  item.attendance_rate >= 90
                    ? '#15803D'
                    : item.attendance_rate >= 75
                    ? '#D97706'
                    : '#DC2626';
                const rateBg =
                  item.attendance_rate >= 90
                    ? '#DCFCE7'
                    : item.attendance_rate >= 75
                    ? '#FEF3C7'
                    : '#FEE2E2';

                return (
                  <Card style={styles.cardItem}>
                    <View style={styles.cardHeader}>
                      <View style={{ flex: 1, marginRight: 8 }}>
                        <Text style={styles.cardTitle}>{item.name}</Text>
                        <Text style={styles.cardSubtitle}>
                          {item.employee_id} • {item.role} • {item.shift}
                        </Text>
                      </View>
                      <View style={[styles.rateBadge, { backgroundColor: rateBg }]}>
                        <Ionicons name="ribbon-outline" size={13} color={rateColor} />
                        <Text style={[styles.rateBadgeText, { color: rateColor }]}>
                          {item.attendance_rate}% Rate
                        </Text>
                      </View>
                    </View>

                    {/* Stats Breakdown Grid */}
                    <View style={styles.summaryStatsGrid}>
                      <View style={styles.summaryStatPill}>
                        <Text style={[styles.statPillLabel, { color: '#15803D' }]}>Present</Text>
                        <Text style={[styles.statPillValue, { color: '#15803D' }]}>
                          {item.present_count}
                        </Text>
                      </View>
                      <View style={styles.summaryStatPill}>
                        <Text style={[styles.statPillLabel, { color: '#D97706' }]}>Half-Day</Text>
                        <Text style={[styles.statPillValue, { color: '#D97706' }]}>
                          {item.half_day_count}
                        </Text>
                      </View>
                      <View style={styles.summaryStatPill}>
                        <Text style={[styles.statPillLabel, { color: '#2563EB' }]}>Leave</Text>
                        <Text style={[styles.statPillValue, { color: '#2563EB' }]}>
                          {item.leave_count}
                        </Text>
                      </View>
                      <View style={styles.summaryStatPill}>
                        <Text style={[styles.statPillLabel, { color: '#DC2626' }]}>Absent</Text>
                        <Text style={[styles.statPillValue, { color: '#DC2626' }]}>
                          {item.absent_count}
                        </Text>
                      </View>
                      {item.total_overtime > 0 && (
                        <View style={styles.summaryStatPill}>
                          <Text style={[styles.statPillLabel, { color: '#7C3AED' }]}>OT Hours</Text>
                          <Text style={[styles.statPillValue, { color: '#7C3AED' }]}>
                            {item.total_overtime}h
                          </Text>
                        </View>
                      )}
                    </View>

                    {Boolean(item.latest_marked_at) && (
                      <View style={styles.attendanceMetaRow}>
                        <View style={styles.attendanceMetaItem}>
                          <Ionicons name="time-outline" size={13} color={colors.textSecondary} />
                          <Text style={styles.attendanceMetaText}>
                            Latest Clock-In: {formatDateTime(item.latest_marked_at!)}
                          </Text>
                        </View>
                      </View>
                    )}
                  </Card>
                );
              }}
            />
          )}
        </>
      )}

      {/* Add Staff Modal */}
      <Modal visible={showAddStaff} animationType="slide" transparent>
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={typography.h2}>
                {modalMode === 'create' ? 'Enroll New Staff Member' : 'Edit Staff Member'}
              </Text>
              <Pressable onPress={() => setShowAddStaff(false)}>
                <Ionicons name="close" size={24} color={colors.text} />
              </Pressable>
            </View>

            {company && (
              <View style={styles.companyEnrollingBanner}>
                <Ionicons name="business-outline" size={15} color="#0A1E38" />
                <Text style={styles.companyEnrollingText}>
                  {modalMode === 'create' ? 'Enrolling under:' : 'Company:'}{' '}
                  <Text style={{ fontWeight: '800' }}>{company.name}</Text> ({company.company_code})
                </Text>
              </View>
            )}
            <ScrollView style={{ maxHeight: 420 }}>
              <Text style={styles.inputLabel}>
                Employee ID {modalMode === 'create' ? '(Auto-Generated)' : '(Fixed ID)'}
              </Text>
              <View style={styles.autoIdRow}>
                <TextInput
                  style={[styles.input, styles.inputDisabled, { flex: 1 }]}
                  placeholder="Auto-generating..."
                  autoCapitalize="characters"
                  value={empId}
                  editable={false}
                />
                <View style={styles.autoBadge}>
                  <Ionicons
                    name={modalMode === 'create' ? 'sparkles' : 'lock-closed'}
                    size={13}
                    color="#0284C7"
                  />
                  <Text style={styles.autoBadgeText}>
                    {modalMode === 'create' ? 'AUTO' : 'LOCKED'}
                  </Text>
                </View>
              </View>
              <Text style={styles.inputLabel}>Full Name *</Text>
              <TextInput
                style={styles.input}
                placeholder="e.g. Vikram Sharma"
                value={name}
                onChangeText={setName}
              />
              <Text style={styles.inputLabel}>Role & Permissions *</Text>
              <View style={styles.rolePickerRow}>
                {companyRoles.length > 0 ? (
                  companyRoles.map((r, idx) => {
                    const isSelected = roleId
                      ? roleId === r.id
                      : role.toUpperCase() === r.name.toUpperCase();
                    return (
                      <Pressable
                        key={r.id || `${r.name}-${idx}`}
                        style={[styles.roleChip, isSelected && styles.roleChipActive]}
                        onPress={() => {
                          setRole(r.name);
                          setRoleId(r.id);
                        }}
                      >
                        <Text
                          style={[
                            styles.roleChipText,
                            isSelected && styles.roleChipTextActive,
                          ]}
                        >
                          {r.name}
                        </Text>
                      </Pressable>
                    );
                  })
                ) : (
                  ROLES.map((r) => (
                    <Pressable
                      key={r}
                      style={[styles.roleChip, role === r && styles.roleChipActive]}
                      onPress={() => {
                        setRole(r);
                        setRoleId(null);
                      }}
                    >
                      <Text
                        style={[
                          styles.roleChipText,
                          role === r && styles.roleChipTextActive,
                        ]}
                      >
                        {r}
                      </Text>
                    </Pressable>
                  ))
                )}
              </View>
              <Text style={styles.inputLabel}>Assigned Shift</Text>
              <TextInput
                style={styles.input}
                placeholder="e.g. Morning / Evening / Night"
                value={shift}
                onChangeText={setShift}
              />
              <Text style={styles.inputLabel}>Phone Number</Text>
              <TextInput
                style={styles.input}
                placeholder="+91 ..."
                keyboardType="phone-pad"
                value={phone}
                onChangeText={setPhone}
              />
              <Text style={styles.inputLabel}>Skills & Certifications</Text>
              <TextInput
                style={styles.input}
                placeholder="e.g. CNC Lathe, Milling, Safety Inspection"
                value={skills}
                onChangeText={setSkills}
              />
              <Text style={styles.inputLabel}>Login PIN (for staff mobile login) *</Text>
              <TextInput
                style={styles.input}
                placeholder="4-digit PIN (e.g. 1234)"
                keyboardType="numeric"
                value={loginPin}
                onChangeText={setLoginPin}
              />
              <Text style={styles.helperText}>
                Staff will use this PIN + Employee ID under {company?.company_code || 'APEX01'} to sign in.
              </Text>

              {modalMode === 'edit' && (
                <View style={{ marginTop: 12 }}>
                  <Text style={styles.inputLabel}>Employment Status</Text>
                  <View style={{ flexDirection: 'row', gap: 8, marginTop: 4 }}>
                    <Pressable
                      style={[styles.statusToggleBtn, isActiveStaff === 1 && styles.statusToggleBtnActive]}
                      onPress={() => setIsActiveStaff(1)}
                    >
                      <Text style={[styles.statusToggleText, isActiveStaff === 1 && styles.statusToggleTextActive]}>
                        Active
                      </Text>
                    </Pressable>
                    <Pressable
                      style={[styles.statusToggleBtn, isActiveStaff === 0 && styles.statusToggleBtnInactive]}
                      onPress={() => setIsActiveStaff(0)}
                    >
                      <Text
                        style={[styles.statusToggleText, isActiveStaff === 0 && styles.statusToggleTextInactive]}
                      >
                        Inactive
                      </Text>
                    </Pressable>
                  </View>
                </View>
              )}
            </ScrollView>
            {modalMode === 'edit' && editingStaffId && (
              <>
                <Pressable
                  style={styles.modalViewAsStaffBtn}
                  onPress={() => {
                    const st = staffList.find((s) => s.id === editingStaffId);
                    if (st) {
                      handleViewAsStaff(st);
                    }
                  }}
                >
                  <Ionicons name="eye-outline" size={16} color="#0284C7" />
                  <Text style={styles.modalViewAsStaffBtnText}>View as this staff member</Text>
                </Pressable>
                <Pressable
                  style={[
                    styles.modalViewAsStaffBtn,
                    { borderColor: '#FECACA', backgroundColor: '#FEF2F2', marginTop: 6 },
                  ]}
                  onPress={() => handleDeleteStaff(editingStaffId)}
                >
                  <Ionicons name="trash-outline" size={16} color={colors.danger} />
                  <Text style={[styles.modalViewAsStaffBtnText, { color: colors.danger }]}>
                    Delete Staff Member
                  </Text>
                </Pressable>
              </>
            )}
            <View style={styles.modalActions}>
              <Button label="Cancel" variant="secondary" onPress={() => setShowAddStaff(false)} />
              <Button
                label={modalMode === 'create' ? 'Save Staff' : 'Update Staff'}
                onPress={handleSaveStaff}
              />
            </View>
          </View>
        </View>
      </Modal>
    </Screen>
  );
}

const styles = StyleSheet.create({
  segmentContainer: {
    flexDirection: 'row',
    backgroundColor: colors.border,
    borderRadius: 8,
    padding: 3,
    marginBottom: spacing.md,
  },
  segmentBtn: {
    flex: 1,
    paddingVertical: 8,
    alignItems: 'center',
    borderRadius: 6,
  },
  segmentBtnActive: {
    backgroundColor: colors.surface,
  },
  segmentText: {
    fontSize: 14,
    fontWeight: '600',
    color: colors.textSecondary,
  },
  segmentTextActive: {
    color: colors.primary,
  },
  actionRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    marginBottom: spacing.md,
  },
  cardItem: {
    marginBottom: spacing.sm,
    padding: spacing.md,
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  cardTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.text,
  },
  cardSubtitle: {
    fontSize: 13,
    color: colors.textSecondary,
    marginTop: 2,
  },
  roleBadge: {
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 4,
  },
  roleBadgeText: {
    fontSize: 11,
    fontWeight: '700',
  },
  attendanceBadge: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: 'transparent',
  },
  attendanceBadgeText: {
    fontSize: 12,
    fontWeight: '800',
  },
  attendanceMetaRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginTop: 8,
    paddingTop: 8,
    borderTopWidth: 1,
    borderTopColor: '#F1F5F9',
  },
  attendanceMetaItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  attendanceMetaText: {
    fontSize: 11,
    color: colors.textSecondary,
  },
  attendanceMetaTextActive: {
    color: '#0A1E38',
    fontWeight: '700',
  },
  infoRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginTop: 6,
  },
  infoText: {
    fontSize: 13,
    color: colors.textSecondary,
  },
  attendanceHeader: {
    marginBottom: spacing.md,
  },
  attendanceHint: {
    fontSize: 12,
    color: colors.textMuted,
    marginTop: 2,
  },
  empty: {
    alignItems: 'center',
    padding: 32,
  },
  emptyText: {
    color: colors.textMuted,
    fontSize: 15,
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'flex-end',
  },
  modalContent: {
    backgroundColor: colors.surface,
    borderTopLeftRadius: 16,
    borderTopRightRadius: 16,
    padding: spacing.lg,
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing.md,
  },
  inputLabel: {
    fontSize: 12,
    fontWeight: '700',
    color: colors.textSecondary,
    marginTop: 10,
    marginBottom: 4,
  },
  input: {
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 8,
    fontSize: 14,
    color: colors.text,
    backgroundColor: colors.background,
  },
  rolePickerRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 6,
    marginTop: 4,
  },
  roleChip: {
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.background,
  },
  roleChipActive: {
    backgroundColor: colors.primary,
    borderColor: colors.primary,
  },
  roleChipText: {
    fontSize: 11,
    fontWeight: '600',
    color: colors.textSecondary,
  },
  roleChipTextActive: {
    color: colors.surface,
  },
  modalActions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: spacing.sm,
    marginTop: spacing.lg,
  },
  companyScopeBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    backgroundColor: '#F0F9FF',
    borderWidth: 1,
    borderColor: '#BAE6FD',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 8,
    marginBottom: spacing.sm,
  },
  companyScopeText: {
    fontSize: 12,
    color: '#0369A1',
    flex: 1,
  },
  companyEnrollingBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    backgroundColor: '#F1F5F9',
    borderRadius: 8,
    paddingHorizontal: 10,
    paddingVertical: 6,
    marginBottom: 10,
  },
  companyEnrollingText: {
    fontSize: 12,
    color: '#0A1E38',
  },
  helperText: {
    fontSize: 11,
    color: colors.textSecondary,
    marginTop: 3,
  },
  bold: {
    fontWeight: '700',
  },
  autoIdRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  autoBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: '#E0F2FE',
    borderWidth: 1,
    borderColor: '#BAE6FD',
    borderRadius: 8,
    paddingHorizontal: 10,
    paddingVertical: 9,
  },
  autoBadgeText: {
    fontSize: 11,
    fontWeight: '800',
    color: '#0284C7',
  },
  editBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 6,
    backgroundColor: '#F1F5F9',
    borderWidth: 1,
    borderColor: '#CBD5E1',
  },
  editBtnText: {
    fontSize: 11,
    fontWeight: '700',
    color: '#0A1E38',
  },
  inactiveBadge: {
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
    backgroundColor: '#FEE2E2',
  },
  inactiveBadgeText: {
    fontSize: 9,
    fontWeight: '800',
    color: '#DC2626',
  },
  inputDisabled: {
    backgroundColor: '#E2E8F0',
    color: colors.textSecondary,
  },
  statusToggleBtn: {
    flex: 1,
    paddingVertical: 9,
    alignItems: 'center',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#CBD5E1',
    backgroundColor: '#F8FAFC',
  },
  statusToggleBtnActive: {
    backgroundColor: '#DCFCE7',
    borderColor: '#86EFAC',
  },
  statusToggleBtnInactive: {
    backgroundColor: '#FEE2E2',
    borderColor: '#FCA5A5',
  },
  statusToggleText: {
    fontSize: 12,
    fontWeight: '600',
    color: colors.textSecondary,
  },
  statusToggleTextActive: {
    color: '#15803D',
    fontWeight: '800',
  },
  statusToggleTextInactive: {
    color: '#DC2626',
    fontWeight: '800',
  },
  activePreviewBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: '#FEF3C7',
    borderWidth: 1,
    borderColor: '#FCD34D',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 8,
    marginBottom: spacing.sm,
  },
  activePreviewText: {
    fontSize: 12,
    color: '#92400E',
    flex: 1,
  },
  activePreviewBold: {
    fontWeight: '800',
    color: '#78350F',
  },
  activeExitBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: '#DC2626',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 6,
    marginLeft: 6,
  },
  activeExitText: {
    fontSize: 11,
    fontWeight: '800',
    color: '#FFFFFF',
  },
  cardFooterRow: {
    marginTop: 10,
    paddingTop: 8,
    borderTopWidth: 1,
    borderTopColor: '#F1F5F9',
    flexDirection: 'row',
    justifyContent: 'flex-end',
  },
  viewAsStaffBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    backgroundColor: '#F0F9FF',
    borderWidth: 1,
    borderColor: '#BAE6FD',
    borderRadius: 6,
    paddingHorizontal: 10,
    paddingVertical: 5,
  },
  viewAsStaffBtnText: {
    fontSize: 12,
    fontWeight: '700',
    color: '#0284C7',
  },
  modalViewAsStaffBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
    backgroundColor: '#F0F9FF',
    borderWidth: 1,
    borderColor: '#BAE6FD',
    borderRadius: 8,
    paddingVertical: 10,
    marginTop: 12,
  },
  modalViewAsStaffBtnText: {
    fontSize: 13,
    fontWeight: '700',
    color: '#0284C7',
  },
  attendanceScopeRow: {
    flexDirection: 'row',
    gap: 6,
    marginBottom: spacing.sm,
  },
  attendanceScopeBtn: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 4,
    paddingVertical: 7,
    borderRadius: 8,
    backgroundColor: '#F1F5F9',
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  attendanceScopeBtnActive: {
    backgroundColor: '#FFFFFF',
    borderColor: '#0A1E38',
    elevation: 1,
    shadowColor: '#000',
    shadowOpacity: 0.05,
    shadowRadius: 2,
  },
  attendanceScopeText: {
    fontSize: 11,
    fontWeight: '600',
    color: colors.textSecondary,
  },
  attendanceScopeTextActive: {
    color: '#0A1E38',
    fontWeight: '800',
  },
  dateNavCard: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#E2E8F0',
    borderRadius: 8,
    paddingHorizontal: 10,
    paddingVertical: 8,
    marginBottom: spacing.sm,
  },
  dateNavArrow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 3,
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 6,
    backgroundColor: '#F8FAFC',
  },
  dateNavArrowText: {
    fontSize: 12,
    fontWeight: '700',
    color: '#0A1E38',
  },
  dateNavCenter: {
    alignItems: 'center',
  },
  dateNavDateText: {
    fontSize: 13,
    fontWeight: '800',
    color: '#0A1E38',
  },
  jumpToTodayText: {
    fontSize: 11,
    color: '#0284C7',
    fontWeight: '700',
    marginTop: 2,
  },
  rangeBannerCard: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: '#F0F9FF',
    borderWidth: 1,
    borderColor: '#BAE6FD',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 9,
    marginBottom: spacing.sm,
  },
  rangeBannerTitle: {
    fontSize: 13,
    fontWeight: '800',
    color: '#0369A1',
  },
  rangeBannerSubtitle: {
    fontSize: 11,
    color: '#0284C7',
    marginTop: 2,
    fontWeight: '600',
  },
  exportCsvBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#BAE6FD',
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 6,
  },
  exportCsvBtnText: {
    fontSize: 11,
    fontWeight: '700',
    color: '#0284C7',
  },
  rateBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 6,
  },
  rateBadgeText: {
    fontSize: 12,
    fontWeight: '800',
  },
  summaryStatsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 6,
    marginTop: 10,
    paddingTop: 8,
    borderTopWidth: 1,
    borderTopColor: '#F1F5F9',
  },
  summaryStatPill: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: '#F8FAFC',
    borderWidth: 1,
    borderColor: '#E2E8F0',
    borderRadius: 6,
    paddingHorizontal: 7,
    paddingVertical: 3,
  },
  statPillLabel: {
    fontSize: 11,
    fontWeight: '600',
  },
  statPillValue: {
    fontSize: 11,
    fontWeight: '800',
  },
});
