import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../widgets/shimmers/index.dart';

class StaffScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;
  const StaffScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends ConsumerState<StaffScreen> {
  int _selectedTab = 0; // 0: Staff Roster, 1: Daily Attendance & Shifts
  int _attendanceViewMode = 0; // 0: Daily Sheet, 1: Past 7 Days, 2: Past 30 Days

  bool _loading = false;
  String? _error;

  List<Map<String, dynamic>> _staffList = [];
  List<Map<String, dynamic>> _attendanceList = [];
  List<Map<String, dynamic>> _allAttendance = [];

  // Search & Filter state for Staff Roster
  String _searchQuery = '';
  String _selectedRole = 'ALL';
  String _selectedShift = 'ALL';
  final TextEditingController _searchController = TextEditingController();

  // Date selection for Daily Sheet
  late String _selectedDate;
  late String _todayDateStr;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex.clamp(0, 1);
    final now = DateTime.now();
    _todayDateStr = now.toIso8601String().split('T').first;
    _selectedDate = _todayDateStr;
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);

      final results = await Future.wait([
        apiService.getCollection('staff', queryParams: {'limit': 200}).then((r) => r.data).catchError((_) => <Map<String, dynamic>>[]),
        apiService.getCollection('staff_attendance', queryParams: {'limit': 500}).then((r) => r.data).catchError((_) => <Map<String, dynamic>>[]),
      ]);

      final rawStaff = results[0];
      final rawAttendance = results[1];

      // Enrich staff records
      final enrichedStaff = rawStaff.map((s) {
        return {
          ...s,
          'id': s['id'] ?? s['_id'] ?? '',
          'employee_id': s['employee_id'] ?? 'EMP-000',
          'name': s['name'] ?? 'Staff Member',
          'role': (s['role'] ?? 'OPERATOR').toString().toUpperCase(),
          'shift': (s['shift'] ?? 'MORNING').toString().toUpperCase(),
          'status': (s['status'] ?? 'ACTIVE').toString().toUpperCase(),
          'phone': s['phone'] ?? '',
          'skills': s['skills'] ?? '',
          'department': s['department'] ?? '',
          'login_pin': s['login_pin'] ?? '1234',
        };
      }).toList();

      // Sort staff by employee_id
      enrichedStaff.sort((a, b) {
        final idA = a['employee_id']?.toString() ?? '';
        final idB = b['employee_id']?.toString() ?? '';
        return idA.compareTo(idB);
      });

      // Filter attendance for currently selected date
      final forDate = rawAttendance.where((a) => a['date'] == _selectedDate).toList();

      if (mounted) {
        setState(() {
          _staffList = enrichedStaff;
          _allAttendance = rawAttendance;
          _attendanceList = forDate;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  // Filtered staff based on search, role, shift
  List<Map<String, dynamic>> get _filteredStaff {
    return _staffList.where((s) {
      // Role filter
      if (_selectedRole != 'ALL' && s['role'] != _selectedRole) return false;

      // Shift filter
      if (_selectedShift != 'ALL' && s['shift'] != _selectedShift) return false;

      // Search query
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final name = (s['name'] ?? '').toString().toLowerCase();
        final empId = (s['employee_id'] ?? '').toString().toLowerCase();
        final phone = (s['phone'] ?? '').toString().toLowerCase();
        final skills = (s['skills'] ?? '').toString().toLowerCase();
        final dept = (s['department'] ?? '').toString().toLowerCase();
        return name.contains(q) || empId.contains(q) || phone.contains(q) || skills.contains(q) || dept.contains(q);
      }

      return true;
    }).toList();
  }

  // Attendance for the selected date mapped to staff
  List<Map<String, dynamic>> get _dailyAttendanceRows {
    final attMap = <String, Map<String, dynamic>>{};
    for (final a in _attendanceList) {
      final sId = a['staff_id']?.toString() ?? '';
      if (sId.isNotEmpty) attMap[sId] = a;
    }

    return _staffList.map((s) {
      final sId = s['id']?.toString() ?? '';
      final att = attMap[sId];
      return {
        'staff_id': sId,
        'attendance_id': att?['id'] ?? att?['_id'],
        'name': s['name'],
        'employee_id': s['employee_id'],
        'role': s['role'],
        'shift': att?['shift'] ?? s['shift'],
        'status': (att?['status'] ?? 'ABSENT').toString().toUpperCase(),
        'overtime_hours': (att?['overtime_hours'] as num?)?.toDouble() ?? 0.0,
        'notes': att?['notes'],
        'created_at': att?['created_at'],
      };
    }).toList();
  }

  // Quick stats
  int get _presentCount => _dailyAttendanceRows.where((a) => a['status'] == 'PRESENT').length;
  int get _halfDayCount => _dailyAttendanceRows.where((a) => a['status'] == 'HALF_DAY').length;
  int get _leaveCount => _dailyAttendanceRows.where((a) => a['status'] == 'LEAVE').length;
  int get _absentCount => _dailyAttendanceRows.where((a) => a['status'] == 'ABSENT').length;

  void _onBackPress() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/management');
    }
  }

  void _changeDate(int offsetDays) {
    try {
      final current = DateTime.parse(_selectedDate);
      final newDate = current.add(Duration(days: offsetDays));
      final newDateStr = newDate.toIso8601String().split('T').first;
      setState(() {
        _selectedDate = newDateStr;
        _attendanceList = _allAttendance.where((a) => a['date'] == newDateStr).toList();
      });
    } catch (_) {}
  }

  // Cycle Attendance Status: PRESENT -> HALF_DAY -> ABSENT -> LEAVE -> PRESENT
  Future<void> _toggleAttendance(String staffId, String currentStatus, String staffShift) async {
    const cycle = {
      'PRESENT': 'HALF_DAY',
      'HALF_DAY': 'ABSENT',
      'ABSENT': 'LEAVE',
      'LEAVE': 'PRESENT',
    };
    final nextStatus = cycle[currentStatus] ?? 'PRESENT';
    await _recordAttendance(staffId, nextStatus, staffShift);
  }

  // Set explicit status for a staff member
  Future<void> _recordAttendance(String staffId, String status, String staffShift, {double? overtime, String? notes}) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final now = DateTime.now().millisecondsSinceEpoch;

      // Check if attendance already exists for this staff on this date
      final existing = _attendanceList.where((a) => a['staff_id'] == staffId).toList();

      if (existing.isNotEmpty) {
        final attId = existing.first['id']?.toString() ?? existing.first['_id']?.toString() ?? '';
        await apiService.updateCollectionItem('staff_attendance', attId, {
          'status': status,
          'shift': staffShift,
          'date': _selectedDate,
          if (overtime != null) 'overtime_hours': overtime,
          if (notes != null) 'notes': notes,
          'updated_at': now,
        });
      } else {
        final newId = 'att_${staffId}_$_selectedDate';
        await apiService.createCollectionItem('staff_attendance', {
          '_id': newId,
          'id': newId,
          'staff_id': staffId,
          'date': _selectedDate,
          'shift': staffShift,
          'status': status,
          'overtime_hours': overtime ?? 0.0,
          if (notes != null) 'notes': notes,
          'created_at': now,
          'updated_at': now,
        });
      }

      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update attendance: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Mark all staff present for today
  Future<void> _markAllPresent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark All Present'),
        content: Text('Do you want to mark all ${_staffList.length} staff members as PRESENT for $_selectedDate?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Mark All Present'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      for (final s in _staffList) {
        final sId = s['id']?.toString() ?? '';
        final shift = s['shift']?.toString() ?? 'MORNING';
        await _recordAttendance(sId, 'PRESENT', shift);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All staff marked as PRESENT!'), backgroundColor: Color(0xFF16A34A)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Add / Edit Staff Modal
  void _openStaffFormModal({Map<String, dynamic>? editStaff}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => _StaffFormSheet(
        staffToEdit: editStaff,
        existingCount: _staffList.length,
        onSaved: _loadData,
      ),
    );
  }

  // Delete staff confirmation
  Future<void> _deleteStaff(String staffId, String staffName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24),
            SizedBox(width: 8),
            Text('Delete Staff Member'),
          ],
        ),
        content: Text('Are you sure you want to delete $staffName? This will remove their profile and all attendance records.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.deleteCollectionItem('staff', staffId);

      // Log deletion activity
      try {
        await apiService.createCollectionItem('activity_history', {
          'event_type': 'STAFF_DELETED',
          'title': 'Staff deleted: $staffName',
          'description': staffId,
          'reference_type': 'STAFF',
          'reference_id': staffId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        });
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Staff member $staffName deleted.')),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete staff: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // =========================================================================
  // VIEW AS STAFF / IMPERSONATE
  // =========================================================================
  void _impersonateStaff(Map<String, dynamic> staff) {
    final staffName = staff['name']?.toString() ?? 'Staff';
    final role = (staff['role']?.toString() ?? 'OPERATOR').toUpperCase();
    final authState = ref.read(authStateProvider);

    ref.read(impersonationProvider.notifier).startImpersonation(
      staff,
      adminName: authState.userName ?? 'Admin',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.switch_account_rounded, color: Color(0xFFD97706), size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Viewing as Staff Member',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are now experiencing the app as $staffName ($role).',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Role permissions are now active.', style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
                  SizedBox(height: 4),
                  Text('• Restricted modules are locked.', style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
                  SizedBox(height: 4),
                  Text('• Use "Exit View" in the top banner anytime to return.', style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Stay on Roster'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/dashboard');
            },
            icon: const Icon(Icons.dashboard_outlined, size: 16),
            label: const Text('Go to Dashboard'),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0A1E38)),
          ),
        ],
      ),
    );
  }

  void _showQuickImpersonateDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final list = _staffList.where((s) {
              final n = (s['name'] ?? '').toString().toLowerCase();
              final r = (s['role'] ?? '').toString().toLowerCase();
              final e = (s['employee_id'] ?? '').toString().toLowerCase();
              final q = query.toLowerCase();
              return q.isEmpty || n.contains(q) || r.contains(q) || e.contains(q);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.switch_account_rounded, color: Color(0xFFD97706), size: 22),
                          SizedBox(width: 8),
                          Text('Select Staff to Impersonate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Preview the application with the exact role and permissions of the selected worker.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (val) => setModalState(() => query = val),
                    decoration: InputDecoration(
                      hintText: 'Search staff by name, role or ID...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: list.isEmpty
                        ? const Center(child: Text('No staff members found'))
                        : ListView.separated(
                            itemCount: list.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, index) {
                              final item = list[index];
                              final name = item['name']?.toString() ?? 'Staff';
                              final role = (item['role']?.toString() ?? 'OPERATOR').toUpperCase();
                              final empId = item['employee_id']?.toString() ?? 'EMP-000';
                              final shift = item['shift']?.toString() ?? 'MORNING';

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFFEF3C7),
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                    style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFD97706)),
                                  ),
                                ),
                                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                subtitle: Text('$empId • $shift Shift', style: const TextStyle(fontSize: 12)),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    role.replaceAll('_', ' '),
                                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _impersonateStaff(item);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Export summary report as CSV to clipboard
  void _exportAttendanceSummary() {
    final buffer = StringBuffer();
    buffer.writeln('Employee ID,Name,Role,Shift,Present Days,Half Days,Leaves,Absent,Overtime Hours,Attendance Rate');

    final summary = _calculateRangeSummary(_attendanceViewMode == 1 ? 7 : 30);
    for (final s in summary) {
      buffer.writeln('${s['employee_id']},"${s['name']}",${s['role']},${s['shift']},${s['present']},${s['half_day']},${s['leave']},${s['absent']},${s['overtime']}h,${s['rate']}%');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Attendance summary copied to clipboard in CSV format!'),
        backgroundColor: Color(0xFF0284C7),
      ),
    );
  }

  // Calculate Attendance Range Summary (7 days or 30 days)
  List<Map<String, dynamic>> _calculateRangeSummary(int days) {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days - 1)).toIso8601String().split('T').first;
    final endDate = now.toIso8601String().split('T').first;

    final rangeAttendance = _allAttendance.where((a) {
      final d = a['date']?.toString() ?? '';
      return d.compareTo(startDate) >= 0 && d.compareTo(endDate) <= 0;
    }).toList();

    final attByStaff = <String, List<Map<String, dynamic>>>{};
    for (final a in rangeAttendance) {
      final sId = a['staff_id']?.toString() ?? '';
      attByStaff.putIfAbsent(sId, () => []).add(a);
    }

    return _staffList.map((s) {
      final sId = s['id']?.toString() ?? '';
      final records = attByStaff[sId] ?? [];

      int present = 0;
      int half = 0;
      int leave = 0;
      int absent = 0;
      double overtime = 0.0;

      for (final r in records) {
        final st = (r['status'] ?? '').toString().toUpperCase();
        if (st == 'PRESENT') {
          present++;
        } else if (st == 'HALF_DAY') {
          half++;
        } else if (st == 'LEAVE') {
          leave++;
        } else if (st == 'ABSENT') {
          absent++;
        }
        overtime += (r['overtime_hours'] as num?)?.toDouble() ?? 0.0;
      }

      final logged = records.length;
      final rate = logged > 0 ? (((present + 0.5 * half) / logged) * 100).round() : 0;

      return {
        'staff_id': sId,
        'employee_id': s['employee_id'],
        'name': s['name'],
        'role': s['role'],
        'shift': s['shift'],
        'logged': logged,
        'present': present,
        'half_day': half,
        'leave': leave,
        'absent': absent,
        'overtime': overtime,
        'rate': rate,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1E38),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
          tooltip: 'Back to Management',
          onPressed: _onBackPress,
        ),
        title: const Text(
          'Staff & Shifts Roster',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.switch_account_outlined, color: Colors.white, size: 22),
            tooltip: 'View as Staff / Impersonate',
            onPressed: _showQuickImpersonateDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 22),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => _openStaffFormModal(),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18, color: Colors.white),
              label: const Text(
                'Add Staff',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Summary Banner
              _buildHeaderBanner(),
              const SizedBox(height: 14),

              // Segment Switcher (Staff Roster vs Daily Attendance)
              _buildSegmentSwitcher(),
              const SizedBox(height: 14),

              // Error banner if any
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12)),
                      ),
                      TextButton(onPressed: _loadData, child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w700))),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Content based on selected tab
              if (_loading && _staffList.isEmpty)
                AppShimmer(
                  child: Column(
                    children: List.generate(5, (_) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      child: const Row(
                        children: [
                          ShimmerBox(width: 44, height: 44, borderRadius: 22),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ShimmerBox(width: 120, height: 16, borderRadius: 4),
                                    SizedBox(width: 8),
                                    ShimmerBox(width: 60, height: 16, borderRadius: 10),
                                  ],
                                ),
                                SizedBox(height: 6),
                                ShimmerBox(width: 160, height: 12, borderRadius: 4),
                                SizedBox(height: 4),
                                ShimmerBox(width: 90, height: 11, borderRadius: 4),
                              ],
                            ),
                          ),
                          ShimmerBox(width: 65, height: 26, borderRadius: 8),
                        ],
                      ),
                    )),
                  ),
                )
              else if (_selectedTab == 0)
                _buildStaffRosterTab()
              else
                _buildAttendanceTab(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // Top KPI Header Banner
  Widget _buildHeaderBanner() {
    final activeStaff = _staffList.where((s) => s['status'] == 'ACTIVE').length;
    final operators = _staffList.where((s) => s['role'] == 'OPERATOR').length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDDD6FE)),
            ),
            child: const Icon(Icons.groups_rounded, color: Color(0xFF7C3AED), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Staff & Shift Operations',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_staffList.length} enrolled • $activeStaff active • $operators operators',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildMiniBadge('$_presentCount Present', const Color(0xFFDCFCE7), const Color(0xFF15803D)),
              const SizedBox(width: 6),
              _buildMiniBadge('$_absentCount Absent', const Color(0xFFFEE2E2), const Color(0xFFDC2626)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textCol)),
    );
  }

  // Tab Switcher (Staff Roster vs Attendance)
  Widget _buildSegmentSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _buildSegmentButton(0, 'Staff Roster (${_staffList.length})', Icons.badge_outlined),
          _buildSegmentButton(1, 'Daily Attendance & Shifts', Icons.calendar_today_outlined),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(int index, String label, IconData icon) {
    final isActive = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isActive ? const Color(0xFF0A1E38) : const Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive ? const Color(0xFF0A1E38) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 1: STAFF ROSTER
  // =========================================================================
  Widget _buildStaffRosterTab() {
    final filtered = _filteredStaff;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search Field
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search staff by name, employee ID, skills or phone...',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: Color(0xFF64748B)),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Role Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['ALL', 'OPERATOR', 'SUPERVISOR', 'TECHNICIAN', 'QUALITY_INSPECTOR', 'MANAGER'].map((r) {
              final isSelected = _selectedRole == r;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  selected: isSelected,
                  label: Text(
                    r == 'ALL' ? 'All Roles' : r.replaceAll('_', ' '),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                  selectedColor: const Color(0xFF0A1E38),
                  backgroundColor: Colors.white,
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: isSelected ? const Color(0xFF0A1E38) : const Color(0xFFE2E8F0)),
                  ),
                  onSelected: (_) => setState(() => _selectedRole = r),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),

        // Shift Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['ALL', 'MORNING', 'EVENING', 'NIGHT', 'GENERAL'].map((sh) {
              final isSelected = _selectedShift == sh;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  selected: isSelected,
                  label: Text(
                    sh == 'ALL' ? 'All Shifts' : '$sh Shift',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                  selectedColor: const Color(0xFF7C3AED),
                  backgroundColor: Colors.white,
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0)),
                  ),
                  onSelected: (_) => setState(() => _selectedShift = sh),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const Icon(Icons.person_search_outlined, size: 40, color: Color(0xFF94A3B8)),
                const SizedBox(height: 12),
                const Text(
                  'No Staff Members Found',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                const Text(
                  'No staff match your search or filter. Tap "+ Add Staff" to enroll a new worker.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _openStaffFormModal(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Enroll New Staff'),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = filtered[index];
              return _buildStaffCard(item);
            },
          ),
      ],
    );
  }

  // Single Staff Card (Matching frontend StaffScreen.tsx)
  Widget _buildStaffCard(Map<String, dynamic> item) {
    final staffId = item['id']?.toString() ?? '';
    final name = item['name']?.toString() ?? 'Staff';
    final empId = item['employee_id']?.toString() ?? 'EMP-000';
    final role = item['role']?.toString() ?? 'OPERATOR';
    final shift = item['shift']?.toString() ?? 'MORNING';
    final isActive = item['status'] == 'ACTIVE';
    final phone = item['phone']?.toString() ?? '';
    final skills = item['skills']?.toString() ?? '';
    final dept = item['department']?.toString() ?? '';
    final pin = item['login_pin']?.toString() ?? '1234';

    Color roleBg = const Color(0xFFEFF6FF);
    Color roleText = const Color(0xFF0284C7);
    if (role == 'SUPERVISOR') {
      roleBg = const Color(0xFFF5F3FF);
      roleText = const Color(0xFF7C3AED);
    } else if (role == 'MANAGER') {
      roleBg = const Color(0xFFF0FDF4);
      roleText = const Color(0xFF16A34A);
    } else if (role == 'TECHNICIAN') {
      roleBg = const Color(0xFFFFFBEB);
      roleText = const Color(0xFFD97706);
    } else if (role == 'QUALITY_INSPECTOR') {
      roleBg = const Color(0xFFFDF2F8);
      roleText = const Color(0xFFDB2777);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Name & ID + Role Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(width: 6),
                        if (!isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('INACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: $empId • Shift: $shift • PIN: $pin',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: roleBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  role.replaceAll('_', ' '),
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: roleText),
                ),
              ),
            ],
          ),

          if (dept.isNotEmpty || skills.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.construction_outlined, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    dept.isNotEmpty ? '$dept • Skills: $skills' : 'Skills: $skills',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          if (phone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(phone, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ],

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),

          // Actions Row: View as Staff (Impersonate), Edit, Delete
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _impersonateStaff(item),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  visualDensity: VisualDensity.compact,
                  side: const BorderSide(color: Color(0xFFD97706)),
                  backgroundColor: const Color(0xFFFFFBEB),
                ),
                icon: const Icon(Icons.switch_account_outlined, size: 14, color: Color(0xFFB45309)),
                label: const Text(
                  'View as Staff',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _openStaffFormModal(editStaff: item),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  visualDensity: VisualDensity.compact,
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                icon: const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF0A1E38)),
                label: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0A1E38))),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => _deleteStaff(staffId, name),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                  side: const BorderSide(color: Color(0xFFFECACA)),
                  backgroundColor: const Color(0xFFFEF2F2),
                ),
                child: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFDC2626)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 2: DAILY ATTENDANCE & SHIFTS
  // =========================================================================
  Widget _buildAttendanceTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Attendance View Mode Selector (Daily Sheet, Past 7 Days, Past 30 Days)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              _buildAttendanceModeBtn(0, 'Daily Sheet', Icons.today_outlined),
              _buildAttendanceModeBtn(1, 'Past 7 Days', Icons.calendar_view_week_outlined),
              _buildAttendanceModeBtn(2, 'Past 30 Days', Icons.analytics_outlined),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (_attendanceViewMode == 0) ...[
          // Date Navigator Card
          _buildDateNavCard(),
          const SizedBox(height: 12),

          // Daily Attendance KPI Stats
          _buildDailyStatsBar(),
          const SizedBox(height: 12),

          // Action Row: "Mark All Present" & Hint
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tap status badge to cycle: P ➔ HD ➔ A ➔ L',
                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF64748B)),
              ),
              FilledButton.tonalIcon(
                onPressed: _markAllPresent,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFDCFCE7),
                  foregroundColor: const Color(0xFF15803D),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.done_all, size: 14),
                label: const Text('Mark All Present', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Worker Daily Attendance Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _dailyAttendanceRows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = _dailyAttendanceRows[index];
              return _buildDailyAttendanceCard(item);
            },
          ),
        ] else ...[
          // Summary Range Banner & Export
          _buildRangeSummaryBanner(_attendanceViewMode == 1 ? 7 : 30),
          const SizedBox(height: 12),

          // Range Summary Table Cards
          ..._calculateRangeSummary(_attendanceViewMode == 1 ? 7 : 30).map((s) => _buildRangeSummaryCard(s)),
        ],
      ],
    );
  }

  Widget _buildAttendanceModeBtn(int mode, String label, IconData icon) {
    final isActive = _attendanceViewMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _attendanceViewMode = mode),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF0A1E38) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isActive ? Colors.white : const Color(0xFF64748B)),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Date Navigator Card
  Widget _buildDateNavCard() {
    final isToday = _selectedDate == _todayDateStr;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            onPressed: () => _changeDate(-1),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.chevron_left, size: 16),
            label: const Text('Prev', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          Column(
            children: [
              Text(
                isToday ? 'Today ($_selectedDate)' : _selectedDate,
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              if (!isToday)
                InkWell(
                  onTap: () {
                    setState(() {
                      _selectedDate = _todayDateStr;
                      _attendanceList = _allAttendance.where((a) => a['date'] == _todayDateStr).toList();
                    });
                  },
                  child: const Text(
                    'Jump to Today',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0284C7)),
                  ),
                ),
            ],
          ),
          OutlinedButton.icon(
            onPressed: () => _changeDate(1),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              visualDensity: VisualDensity.compact,
            ),
            label: const Text('Next', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            icon: const Icon(Icons.chevron_right, size: 16),
          ),
        ],
      ),
    );
  }

  // Daily Stats Summary Bar
  Widget _buildDailyStatsBar() {
    return Row(
      children: [
        _buildStatChip('$_presentCount Present', const Color(0xFFDCFCE7), const Color(0xFF15803D)),
        const SizedBox(width: 8),
        _buildStatChip('$_halfDayCount Half Day', const Color(0xFFEFF6FF), const Color(0xFF0284C7)),
        const SizedBox(width: 8),
        _buildStatChip('$_leaveCount Leave', const Color(0xFFFEF3C7), const Color(0xFFB45309)),
        const SizedBox(width: 8),
        _buildStatChip('$_absentCount Absent', const Color(0xFFFEE2E2), const Color(0xFFDC2626)),
      ],
    );
  }

  Widget _buildStatChip(String text, Color bg, Color textCol) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: textCol)),
      ),
    );
  }

  // Single Worker Daily Attendance Card
  Widget _buildDailyAttendanceCard(Map<String, dynamic> item) {
    final staffId = item['staff_id']?.toString() ?? '';
    final name = item['name']?.toString() ?? 'Staff';
    final empId = item['employee_id']?.toString() ?? 'EMP';
    final role = item['role']?.toString() ?? 'OPERATOR';
    final shift = item['shift']?.toString() ?? 'MORNING';
    final status = item['status']?.toString() ?? 'ABSENT';
    final overtime = (item['overtime_hours'] as num?)?.toDouble() ?? 0.0;

    Color badgeBg = const Color(0xFFFEE2E2);
    Color badgeText = const Color(0xFFDC2626);
    if (status == 'PRESENT') {
      badgeBg = const Color(0xFFDCFCE7);
      badgeText = const Color(0xFF15803D);
    } else if (status == 'HALF_DAY') {
      badgeBg = const Color(0xFFEFF6FF);
      badgeText = const Color(0xFF0284C7);
    } else if (status == 'LEAVE') {
      badgeBg = const Color(0xFFFEF3C7);
      badgeText = const Color(0xFFB45309);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _toggleAttendance(staffId, status, shift),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(4)),
                        child: Text(status, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: badgeText)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$empId • ${role.replaceAll("_", " ")} • $shift Shift',
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
                if (overtime > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Overtime: +${overtime}h',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0284C7)),
                  ),
                ],
              ],
            ),
          ),
          // 4 Direct One-Tap Status Buttons
          Row(
            children: [
              _buildQuickStatusBtn(staffId, status, 'P', 'PRESENT', shift, const Color(0xFF16A34A), const Color(0xFFDCFCE7)),
              const SizedBox(width: 4),
              _buildQuickStatusBtn(staffId, status, 'HD', 'HALF_DAY', shift, const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
              const SizedBox(width: 4),
              _buildQuickStatusBtn(staffId, status, 'L', 'LEAVE', shift, const Color(0xFFD97706), const Color(0xFFFEF3C7)),
              const SizedBox(width: 4),
              _buildQuickStatusBtn(staffId, status, 'A', 'ABSENT', shift, const Color(0xFFDC2626), const Color(0xFFFEE2E2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatusBtn(
    String staffId,
    String currentStatus,
    String shortLabel,
    String targetStatus,
    String shift,
    Color activeColor,
    Color activeBg,
  ) {
    final isSelected = currentStatus == targetStatus;
    return InkWell(
      onTap: () => _recordAttendance(staffId, targetStatus, shift),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? activeColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? activeColor : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          shortLabel,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  // Range Summary Banner (7 days or 30 days)
  Widget _buildRangeSummaryBanner(int days) {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days - 1)).toIso8601String().split('T').first;
    final endDate = now.toIso8601String().split('T').first;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Past $days Days Attendance Summary',
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 2),
              Text('$startDate  ➔  $endDate', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            ],
          ),
          OutlinedButton.icon(
            onPressed: _exportAttendanceSummary,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.download_rounded, size: 14, color: Color(0xFF0284C7)),
            label: const Text('Export CSV', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0284C7))),
          ),
        ],
      ),
    );
  }

  // Range Summary Card for each staff
  Widget _buildRangeSummaryCard(Map<String, dynamic> item) {
    final name = item['name']?.toString() ?? 'Staff';
    final empId = item['employee_id']?.toString() ?? 'EMP';
    final role = item['role']?.toString() ?? 'OPERATOR';
    final shift = item['shift']?.toString() ?? 'MORNING';
    final present = item['present'] as int;
    final half = item['half_day'] as int;
    final leave = item['leave'] as int;
    final absent = item['absent'] as int;
    final rate = item['rate'] as int;
    final overtime = item['overtime'] as double;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: rate >= 80 ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$rate% Attendance',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: rate >= 80 ? const Color(0xFF15803D) : const Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '$empId • ${role.replaceAll("_", " ")} • $shift',
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildMiniStat('Present: $present', const Color(0xFF16A34A)),
              const SizedBox(width: 8),
              _buildMiniStat('Half: $half', const Color(0xFF2563EB)),
              const SizedBox(width: 8),
              _buildMiniStat('Leave: $leave', const Color(0xFFD97706)),
              const SizedBox(width: 8),
              _buildMiniStat('Absent: $absent', const Color(0xFFDC2626)),
              if (overtime > 0) ...[
                const Spacer(),
                Text('OT: ${overtime}h', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0284C7))),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String text, Color col) {
    return Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: col));
  }
}

// =========================================================================
// Add / Edit Staff Modal Sheet Sub-Widget
// =========================================================================
class _StaffFormSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic>? staffToEdit;
  final int existingCount;
  final VoidCallback onSaved;

  const _StaffFormSheet({
    this.staffToEdit,
    required this.existingCount,
    required this.onSaved,
  });

  @override
  ConsumerState<_StaffFormSheet> createState() => _StaffFormSheetState();
}

class _StaffFormSheetState extends ConsumerState<_StaffFormSheet> {
  final _empIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _deptController = TextEditingController();
  final _skillsController = TextEditingController();
  final _pinController = TextEditingController(text: '1234');

  String _role = 'OPERATOR';
  String _shift = 'MORNING';
  bool _isActive = true;
  bool _submitting = false;

  final _roles = ['OPERATOR', 'SUPERVISOR', 'TECHNICIAN', 'QUALITY_INSPECTOR', 'MANAGER'];
  final _shifts = ['MORNING', 'EVENING', 'NIGHT', 'GENERAL'];

  @override
  void initState() {
    super.initState();
    final s = widget.staffToEdit;
    if (s != null) {
      _empIdController.text = s['employee_id']?.toString() ?? '';
      _nameController.text = s['name']?.toString() ?? '';
      _phoneController.text = s['phone']?.toString() ?? '';
      _deptController.text = s['department']?.toString() ?? '';
      _skillsController.text = s['skills']?.toString() ?? '';
      _pinController.text = s['login_pin']?.toString() ?? '1234';
      _role = s['role']?.toString().toUpperCase() ?? 'OPERATOR';
      _shift = s['shift']?.toString().toUpperCase() ?? 'MORNING';
      _isActive = (s['status']?.toString().toUpperCase() ?? 'ACTIVE') == 'ACTIVE';
    } else {
      final nextNum = (widget.existingCount + 1).toString().padLeft(3, '0');
      _empIdController.text = 'EMP-$nextNum';
    }
  }

  @override
  void dispose() {
    _empIdController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _deptController.dispose();
    _skillsController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final empId = _empIdController.text.trim().toUpperCase();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter staff member full name.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final apiService = ref.read(apiServiceProvider);
      final now = DateTime.now().millisecondsSinceEpoch;

      final currentCompanyId = apiService.companyId ?? 
                               ref.read(authStateProvider).companyId ?? 
                               ref.read(authStateProvider).userId ?? '';
      final currentCompanyCode = ref.read(authStateProvider).companyId ?? '';

      final doc = {
        'company_id': currentCompanyId,
        'company_code': currentCompanyCode,
        'employee_id': empId,
        'name': name,
        'role': _role,
        'shift': _shift,
        'status': _isActive ? 'ACTIVE' : 'INACTIVE',
        'phone': _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : '+91 98765 00000',
        'department': _deptController.text.trim().isNotEmpty ? _deptController.text.trim() : 'Operations',
        'skills': _skillsController.text.trim().isNotEmpty ? _skillsController.text.trim() : null,
        'login_pin': _pinController.text.trim().isNotEmpty ? _pinController.text.trim() : '1234',
        'updated_at': now,
      };

      if (widget.staffToEdit != null) {
        final id = widget.staffToEdit!['id']?.toString() ?? widget.staffToEdit!['_id']?.toString() ?? '';
        await apiService.updateCollectionItem('staff', id, doc);
      } else {
        final id = 'st_${now}_${empId.replaceAll("-", "_")}';
        doc['_id'] = id;
        doc['id'] = id;
        doc['created_at'] = now;
        await apiService.createCollectionItem('staff', doc);

        // Activity Log
        try {
          await apiService.createCollectionItem('activity_history', {
            'event_type': 'STAFF_ADDED',
            'title': 'Staff enrolled: $name ($empId)',
            'description': 'Role: $_role, Shift: $_shift, PIN: ${_pinController.text.trim()}',
            'reference_type': 'STAFF',
            'reference_id': id,
            'timestamp': now,
            'created_at': now,
          });
        } catch (_) {}
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.staffToEdit != null ? 'Staff member updated!' : 'Staff member $name enrolled successfully!'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save staff member: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.staffToEdit != null;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sheet Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? 'Edit Staff Profile' : 'Enroll New Staff Member',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                IconButton(icon: const Icon(Icons.close, color: Color(0xFF64748B)), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 12),

            // Employee ID & Full Name
            Row(
              children: [
                SizedBox(
                  width: 110,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Employee ID *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _empIdController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Full Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Ramesh Kumar',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Role Selector Chips
            const Text('Role / Designation *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            Builder(
              builder: (context) {
                final dynamicRoles = ref.watch(companyRolesProvider);
                final allRoleOptions = <String>{
                  ..._roles,
                  ...dynamicRoles.map((r) => (r['name'] ?? '').toString().toUpperCase()).where((n) => n.isNotEmpty),
                }.toList();

                return Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: allRoleOptions.map((r) {
                    final isSelected = _role == r;
                    return InkWell(
                      onTap: () => setState(() => _role = r),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF0A1E38) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: isSelected ? const Color(0xFF0A1E38) : const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          r.replaceAll('_', ' '),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 14),

            // Shift Selector Chips
            const Text('Shift Assignment *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            Row(
              children: _shifts.map((sh) {
                final isSelected = _shift == sh;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _shift = sh),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        sh,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Phone & PIN
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Phone Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: '+91 98765 00000',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 110,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Login PIN *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _pinController,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        decoration: InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Department & Skills
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Department', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _deptController,
                        decoration: InputDecoration(
                          hintText: 'e.g. CNC Shop, Assembly',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Skills / Specialty', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _skillsController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Milling, Lathe, 5S',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Active Switch
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Active Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                Switch(
                  value: _isActive,
                  activeThumbColor: const Color(0xFF16A34A),
                  onChanged: (val) => setState(() => _isActive = val),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Save Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _submitting ? null : () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _submitting ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _submitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(isEdit ? 'Update Profile' : 'Enroll Staff', style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}