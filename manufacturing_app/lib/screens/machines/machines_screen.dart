import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../models/machine.dart';
import '../../utils/formatters.dart';
import '../../widgets/shimmers/index.dart';

enum DatePreset { today, week, month }
enum ViewMode { machines, operators }

class MachinesScreen extends ConsumerStatefulWidget {
  final bool isViewOnly;
  const MachinesScreen({super.key, this.isViewOnly = false});

  @override
  ConsumerState<MachinesScreen> createState() => _MachinesScreenState();
}

class _MachinesScreenState extends ConsumerState<MachinesScreen> {
  DatePreset _period = DatePreset.today;
  ViewMode _viewMode = ViewMode.machines;
  String _statusFilter = 'ALL';
  String _searchQuery = '';
  bool _isLoading = false;

  // Enriched data
  List<MachineSummary> _machineSummaries = [];
  List<OperatorSummary> _operatorSummaries = [];
  List<Map<String, dynamic>> _staffList = [];
  List<Map<String, dynamic>> _lines = [];
  Map<String, dynamic> _activeAssignments = {};

  // Assign Modal
  bool _assignModalVisible = false;
  String _selectedMachineId = '';
  String _selectedMachineCode = '';
  String _selectedOperator = '';
  String _selectedShift = 'Morning';
  String _assignNotes = '';

  // Create Machine Modal
  bool _createMachineModalVisible = false;
  final _machineCodeController = TextEditingController();
  final _machineNameController = TextEditingController();
  final _machineTypeController = TextEditingController();
  String _selectedLineId = '';

  // Create Line Modal
  bool _createLineModalVisible = false;
  final _lineCodeController = TextEditingController();
  final _lineNameController = TextEditingController();

  final List<String> _statusFilters = [
    'ALL',
    'RUNNING',
    'IDLE',
    'BREAKDOWN',
    'MAINTENANCE',
  ];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _machineCodeController.dispose();
    _machineNameController.dispose();
    _machineTypeController.dispose();
    _lineCodeController.dispose();
    _lineNameController.dispose();
    super.dispose();
  }

  (int start, int end) _getRange(DatePreset preset) {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999).millisecondsSinceEpoch;
    final int start;
    switch (preset) {
      case DatePreset.today:
        start = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
        break;
      case DatePreset.week:
        final sixDaysAgo = now.subtract(const Duration(days: 6));
        start = DateTime(sixDaysAgo.year, sixDaysAgo.month, sixDaysAgo.day).millisecondsSinceEpoch;
        break;
      case DatePreset.month:
        final twentyNineDaysAgo = now.subtract(const Duration(days: 29));
        start = DateTime(twentyNineDaysAgo.year, twentyNineDaysAgo.month, twentyNineDaysAgo.day).millisecondsSinceEpoch;
        break;
    }
    return (start, end);
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final range = _getRange(_period);

      List<Machine> machinesList = [];
      try {
        final resp = await api.listMachines(limit: 100);
        machinesList = resp.data;
      } catch (_) {}

      List<Map<String, dynamic>> lines = [];
      try {
        final resp = await api.getCollection('production_lines', queryParams: {'limit': 100});
        lines = resp.data;
      } catch (_) {}

      List<Map<String, dynamic>> allEntries = [];
      try {
        final resp = await api.getCollection('production_entries', queryParams: {'limit': 100});
        allEntries = resp.data;
      } catch (_) {}

      List<Map<String, dynamic>> staff = [];
      try {
        final resp = await api.getCollection('staff', queryParams: {'limit': 100});
        staff = resp.data;
      } catch (_) {}

      // Filter entries by range
      final filteredEntries = allEntries.where((e) {
        final ts = (e['entry_timestamp'] ?? e['created_at'] ?? 0) as num;
        return ts >= range.$1 && ts <= range.$2;
      }).toList();

      // Index entries by machine_id
      final entriesByMachine = <String, List<Map<String, dynamic>>>{};
      for (final e in filteredEntries) {
        final mId = (e['machine_id'] ?? '').toString();
        entriesByMachine.putIfAbsent(mId, () => []).add(e);
      }

      // Build MachineSummaries
      final mSummaries = machinesList.map((m) {
        final mEntries = entriesByMachine[m.id] ?? entriesByMachine[m.code] ?? [];
        mEntries.sort((a, b) {
          final aTs = (a['entry_timestamp'] ?? a['created_at'] ?? 0) as num;
          final bTs = (b['entry_timestamp'] ?? b['created_at'] ?? 0) as num;
          return bTs.compareTo(aTs);
        });

        int totalProduced = 0;
        int totalRejected = 0;

        final shiftMap = {
          'Morning': ShiftInfo(shift: 'Morning', operator: null, totalProduced: 0),
          'Evening': ShiftInfo(shift: 'Evening', operator: null, totalProduced: 0),
          'Night': ShiftInfo(shift: 'Night', operator: null, totalProduced: 0),
        };

        for (final e in mEntries) {
          final good = ((e['good_quantity'] ?? e['quantity_produced'] ?? 0) as num).toInt();
          final rej = ((e['rejected_quantity'] ?? e['scrap_quantity'] ?? 0) as num).toInt();
          totalProduced += good;
          totalRejected += rej;

          final rawShift = (e['shift'] ?? '').toString().trim();
          final sKey = (rawShift == 'Evening' || rawShift == 'B')
              ? 'Evening'
              : (rawShift == 'Night' || rawShift == 'C')
                  ? 'Night'
                  : 'Morning';

          final sInfo = shiftMap[sKey]!;
          sInfo.totalProduced += good;
          if (sInfo.operator == null && (e['operator'] ?? '').toString().isNotEmpty) {
            sInfo.operator = e['operator'].toString();
            sInfo.lastActiveAt = (e['entry_timestamp'] ?? e['created_at']) as int?;
          }
        }

        // If Morning has no entry operator, fallback to machine currentOperator
        if (shiftMap['Morning']!.operator == null && m.currentOperator != null && m.currentOperator!.isNotEmpty) {
          shiftMap['Morning']!.operator = m.currentOperator;
        }

        final latestEntry = mEntries.isNotEmpty ? mEntries.first : null;

        return MachineSummary(
          machineId: m.id,
          machineCode: m.code,
          machineName: m.name,
          machineStatus: m.status,
          machineType: m.machineType,
          lineId: m.lineId,
          lineCode: m.lineCode ?? 'Line A',
          lineName: m.lineName ?? '',
          currentOperator: latestEntry?['operator'] ?? m.currentOperator,
          currentShift: latestEntry?['shift'],
          currentProduct: latestEntry?['product_code'] ?? m.productCode ?? 'General',
          totalProduced: totalProduced,
          totalRejected: totalRejected,
          shiftAssignments: [
            shiftMap['Morning']!,
            shiftMap['Evening']!,
            shiftMap['Night']!,
          ],
        );
      }).toList();

      // Build OperatorSummaries (By Person mode)
      final opMap = <String, OperatorSummaryBuilder>{};
      final machLookup = {for (var m in machinesList) m.id: m, for (var m in machinesList) m.code: m};

      for (final e in filteredEntries) {
        final op = (e['operator'] ?? '').toString().trim();
        if (op.isEmpty) continue;

        final ts = (e['entry_timestamp'] ?? e['created_at'] ?? 0) as int;
        final mId = (e['machine_id'] ?? '').toString();
        final mach = machLookup[mId];
        final mCode = mach?.code ?? mId;
        final shift = (e['shift'] ?? 'Morning').toString();
        final good = ((e['good_quantity'] ?? e['quantity_produced'] ?? 0) as num).toInt();
        final rej = ((e['rejected_quantity'] ?? e['scrap_quantity'] ?? 0) as num).toInt();

        final b = opMap.putIfAbsent(op, () => OperatorSummaryBuilder(operatorName: op));
        b.machines.add(mCode);
        b.shifts.add(shift);
        b.totalProduced += good;
        b.totalRejected += rej;
        if (ts > b.lastActiveAt) {
          b.lastActiveAt = ts;
          b.latestMachine = mCode;
        }
      }

      final oSummaries = opMap.values.map((b) => b.build()).toList();
      oSummaries.sort((a, b) => b.lastActiveAt.compareTo(a.lastActiveAt));

      // Build Active Assignments across fleet (last 18 hours or today)
      final sinceTs = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).millisecondsSinceEpoch;
      final recentEntries = allEntries.where((e) {
        final ts = (e['entry_timestamp'] ?? e['created_at'] ?? 0) as num;
        final op = (e['operator'] ?? '').toString().trim();
        return ts >= sinceTs && op.isNotEmpty;
      }).toList();

      final lineLookup = {for (var l in lines) (l['id'] ?? l['_id'])?.toString(): l};
      final activeAssignments = <String, Map<String, dynamic>>{};

      for (final e in recentEntries) {
        final op = (e['operator'] ?? '').toString().trim();
        if (op.isEmpty) continue;
        final mId = (e['machine_id'] ?? '').toString();
        final mObj = machLookup[mId];
        final lObj = mObj != null ? lineLookup[mObj.lineId] : null;

        activeAssignments.putIfAbsent(op, () => {
          'operatorName': op,
          'machines': <Map<String, dynamic>>[],
        });

        final mList = activeAssignments[op]!['machines'] as List<Map<String, dynamic>>;
        if (!mList.any((item) => item['machineId'] == mId)) {
          mList.add({
            'machineId': mId,
            'machineCode': mObj?.code ?? mId,
            'machineName': mObj?.name ?? 'Machine',
            'lineCode': lObj?['code'] ?? mObj?.lineCode ?? '',
            'shift': e['shift'] ?? 'Morning',
          });
        }
      }

      setState(() {
        _machineSummaries = mSummaries;
        _operatorSummaries = oSummaries;
        _staffList = staff;
        _lines = lines;
        _activeAssignments = activeAssignments;
        if (lines.isNotEmpty && _selectedLineId.isEmpty) {
          _selectedLineId = (lines.first['id'] ?? lines.first['_id'])?.toString() ?? '';
        }
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _openAssignModal(String machineId, String machineCode, {String shift = 'Morning', String? currentOp}) {
    final availableStaff = _staffList.firstWhere(
      (s) => !_activeAssignments.containsKey(s['name'] ?? ''),
      orElse: () => _staffList.isNotEmpty ? _staffList.first : <String, dynamic>{},
    );

    setState(() {
      _selectedMachineId = machineId;
      _selectedMachineCode = machineCode;
      _selectedOperator = currentOp ?? availableStaff['name'] ?? (_staffList.isNotEmpty ? _staffList.first['name'] : 'Arun Kumar');
      _selectedShift = shift;
      _assignNotes = '';
      _assignModalVisible = true;
    });
  }

  Future<void> _confirmAssign() async {
    if (_selectedMachineId.isEmpty || _selectedOperator.trim().isEmpty) return;

    try {
      final api = ref.read(apiServiceProvider);
      final now = DateTime.now().millisecondsSinceEpoch;
      final entryId = 'entry-$now';

      await api.createCollectionItem('production_entries', {
        'id': entryId,
        'machine_id': _selectedMachineId,
        'shift': _selectedShift,
        'good_quantity': 0,
        'rejected_quantity': 0,
        'operator': _selectedOperator.trim(),
        'notes': _assignNotes.trim().isEmpty ? 'Operator assigned to machine' : _assignNotes.trim(),
        'entry_timestamp': now,
        'created_at': now,
        'updated_at': now,
      });

      await api.updateCollectionItem('machines', _selectedMachineId, {
        'current_operator': _selectedOperator.trim(),
        'status': 'RUNNING',
        'updated_at': now,
      });

      try {
        await api.createCollectionItem('activity_history', {
          'event_type': 'WORKER_ASSIGNED',
          'title': 'Operator assigned: ${_selectedOperator.trim()}',
          'description': 'Assigned to $_selectedMachineCode on $_selectedShift shift',
          'reference_type': 'machine',
          'reference_id': _selectedMachineId,
          'timestamp': now,
          'created_at': now,
        });
      } catch (_) {}

      setState(() => _assignModalVisible = false);
      ref.invalidate(machinesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Assigned $_selectedOperator to $_selectedMachineCode on $_selectedShift shift.')),
        );
      }
      await _loadAllData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not assign operator: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleCreateMachine() async {
    if (_machineCodeController.text.trim().isEmpty || _machineNameController.text.trim().isEmpty || _selectedLineId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter machine code, name, and select a production line.'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      final api = ref.read(apiServiceProvider);
      final now = DateTime.now().millisecondsSinceEpoch;
      final mId = 'mach-$now';

      await api.createCollectionItem('machines', {
        'id': mId,
        'code': _machineCodeController.text.trim().toUpperCase(),
        'name': _machineNameController.text.trim(),
        'machine_type': _machineTypeController.text.trim().isEmpty ? 'General' : _machineTypeController.text.trim(),
        'line_id': _selectedLineId,
        'status': 'IDLE',
        'efficiency': 0,
        'runtime_seconds': 0,
        'downtime_seconds': 0,
        'created_at': now,
        'updated_at': now,
      });

      _machineCodeController.clear();
      _machineNameController.clear();
      _machineTypeController.clear();
      setState(() => _createMachineModalVisible = false);
      ref.invalidate(machinesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Machine created successfully!')),
        );
      }
      await _loadAllData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating machine: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleCreateLine() async {
    if (_lineCodeController.text.trim().isEmpty || _lineNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter line code and name.'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      final api = ref.read(apiServiceProvider);
      final now = DateTime.now().millisecondsSinceEpoch;
      final lId = 'line-$now';

      await api.createCollectionItem('production_lines', {
        'id': lId,
        'code': _lineCodeController.text.trim().toUpperCase(),
        'name': _lineNameController.text.trim(),
        'created_at': now,
        'updated_at': now,
      });

      _lineCodeController.clear();
      _lineNameController.clear();
      _selectedLineId = lId;
      setState(() => _createLineModalVisible = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Production Line created successfully!')),
        );
      }
      await _loadAllData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating line: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter machines by status & search
    final q = _searchQuery.trim().toLowerCase();
    final filteredMachines = _machineSummaries.where((m) {
      final matchesStatus = _statusFilter == 'ALL' || m.machineStatus == _statusFilter;
      final matchesQuery = q.isEmpty ||
          m.machineCode.toLowerCase().contains(q) ||
          m.machineName.toLowerCase().contains(q) ||
          m.lineCode.toLowerCase().contains(q);
      return matchesStatus && matchesQuery;
    }).toList();

    // Filter operators by search
    final filteredOperators = _operatorSummaries.where((o) {
      return q.isEmpty ||
          o.operatorName.toLowerCase().contains(q) ||
          o.machines.any((m) => m.toLowerCase().contains(q));
    }).toList();

    // KPI Metrics Bar calculations
    final totalMachines = _machineSummaries.length;
    final activeMachines = _machineSummaries.where((m) =>
        m.shiftAssignments.any((s) => s.operator != null && s.operator!.isNotEmpty) ||
        (m.currentOperator != null && m.currentOperator!.isNotEmpty)).length;
    final totalProduced = _machineSummaries.fold<int>(0, (sum, m) => sum + m.totalProduced);
    final totalOperatorsCount = _operatorSummaries.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Machines Fleet', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: const Color(0xFF0A1E38),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/management');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Navy Bar with Period Chips and View Mode Switcher
            _buildTopBar(),

            // 2. KPI Metrics Bar
            _buildKpiBar(activeMachines, totalMachines, totalOperatorsCount, totalProduced),

            // 3. Search and Action Buttons
            _buildSearchBar(),

            // 3b. Machine Status Filter Chips (only in By Machine mode)
            if (_viewMode == ViewMode.machines) _buildStatusFilterChips(),

            // 4. Main List (Machines vs Operators)
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadAllData,
                child: _isLoading && _machineSummaries.isEmpty
                    ? AppShimmer(
                        child: GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: 6,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.15,
                          ),
                          itemBuilder: (context, index) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      ShimmerBox(width: 32, height: 32, borderRadius: 8),
                                      ShimmerBox(width: 55, height: 16, borderRadius: 10),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ShimmerBox(width: 80, height: 13, borderRadius: 4),
                                      SizedBox(height: 4),
                                      ShimmerBox(width: 110, height: 15, borderRadius: 4),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      ShimmerBox(width: 50, height: 11, borderRadius: 4),
                                      ShimmerBox(width: 35, height: 11, borderRadius: 4),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      )
                    : (_viewMode == ViewMode.machines
                        ? _buildMachinesList(filteredMachines)
                        : _buildOperatorsList(filteredOperators)),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _assignModalVisible
          ? _buildAssignModalSheet()
          : (_createMachineModalVisible
              ? _buildCreateMachineModalSheet()
              : (_createLineModalVisible ? _buildCreateLineModalSheet() : null)),
    );
  }

  // 1. Top Navy Bar
  Widget _buildTopBar() {
    return Container(
      color: const Color(0xFF0A1E38),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              // Period Tabs (1 Day, 1 Week, 1 Month)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF162E4E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      _buildPeriodChip('1 Day', DatePreset.today),
                      _buildPeriodChip('1 Week', DatePreset.week),
                      _buildPeriodChip('1 Month', DatePreset.month),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // View Mode Toggle (By Machine vs By Person)
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFF162E4E),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _buildViewModeBtn('By Machine', ViewMode.machines, Icons.settings_outlined),
                    _buildViewModeBtn('By Person', ViewMode.operators, Icons.people_outline),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, DatePreset preset) {
    final active = _period == preset;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _period = preset);
          _loadAllData();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              color: active ? const Color(0xFF0A1E38) : const Color(0xFF94A3B8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewModeBtn(String label, ViewMode mode, IconData icon) {
    final active = _viewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0284C7) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: active ? Colors.white : const Color(0xFF94A3B8)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                color: active ? Colors.white : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. KPI Metrics Bar
  Widget _buildKpiBar(int active, int total, int operators, int output) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _buildKpiCard('Assigned', '$active', '/ $total machines'),
          const SizedBox(width: 10),
          _buildKpiCard('Operators', '$operators', 'active'),
          const SizedBox(width: 10),
          _buildKpiCard('Output', Formatters.formatNumber(output), 'pcs produced'),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, String sub) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha:0.03), blurRadius: 4, offset: const Offset(0, 1)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(sub, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 3. Search and Actions Bar
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                  hintText: _viewMode == ViewMode.machines ? 'Search machine or line…' : 'Search person or machine…',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          if (!widget.isViewOnly) ...[
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => setState(() => _createLineModalVisible = true),
              icon: const Icon(Icons.alt_route, size: 14, color: Color(0xFF0284C7)),
              label: const Text('+ Line', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0284C7))),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFBAE6FD)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 6),
            ElevatedButton.icon(
              onPressed: () => setState(() => _createMachineModalVisible = true),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('+ Machine', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 3b. Machine Status Filter Chips
  Widget _buildStatusFilterChips() {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(top: 6, bottom: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _statusFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, idx) {
          final s = _statusFilters[idx];
          final active = _statusFilter == s;
          final count = s == 'ALL'
              ? _machineSummaries.length
              : _machineSummaries.where((m) => m.machineStatus == s).length;

          return GestureDetector(
            onTap: () => setState(() => _statusFilter = s),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: active ? const Color(0xFF0A1E38) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: active ? const Color(0xFF0A1E38) : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Text(
                    s,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFF1E3A5F) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: active ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 4. Main Machines List
  Widget _buildMachinesList(List<MachineSummary> machines) {
    if (machines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.precision_manufacturing_outlined, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              _statusFilter == 'ALL' ? 'No machines found' : 'No $_statusFilter machines',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            const Text('Try adjusting your search or period filter.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: machines.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, index) {
        final m = machines[index];
        return _buildMachineCard(m);
      },
    );
  }

  // Single Machine Card
  Widget _buildMachineCard(MachineSummary m) {
    final assignedCount = m.shiftAssignments.where((s) => s.operator != null && s.operator!.isNotEmpty).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha:0.03), blurRadius: 4, offset: const Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Code + Line Badge + Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(m.machineCode, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(m.lineCode, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                  ),
                ],
              ),
              _buildStatusBadge(m.machineStatus),
            ],
          ),
          const SizedBox(height: 4),
          Text(m.machineName, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
          const SizedBox(height: 8),

          // Product & Items Created Badges
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 13, color: Color(0xFF0369A1)),
                    const SizedBox(width: 4),
                    Text(
                      'Product: ${m.currentProduct}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0369A1)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.layers_outlined, size: 13, color: Color(0xFF15803D)),
                    const SizedBox(width: 4),
                    Text(
                      'Created: ${Formatters.formatNumber(m.totalProduced)} pcs',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3-Shift Staff Allocation Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Color(0xFF0A1E38)),
                        SizedBox(width: 6),
                        Text('3-Shift Staff Allocation', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0A1E38))),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$assignedCount / 3 Assigned',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0284C7)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...m.shiftAssignments.map((sa) => _buildShiftRow(m, sa)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Card Actions Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/machines/${m.machineId}'),
                  icon: const Icon(Icons.history, size: 16, color: Color(0xFF0284C7)),
                  label: const Text('History & Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0284C7))),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: const BorderSide(color: Color(0xFF0284C7)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              if (!widget.isViewOnly) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openAssignModal(m.machineId, m.machineCode, shift: 'Morning'),
                    icon: const Icon(Icons.person_add_outlined, size: 15),
                    label: const Text('Assign Staff', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShiftRow(MachineSummary m, ShiftInfo sa) {
    final isMorning = sa.shift == 'Morning';
    final isEvening = sa.shift == 'Evening';

    final shiftIcon = isMorning
        ? Icons.wb_sunny_outlined
        : (isEvening ? Icons.wb_twilight_outlined : Icons.nightlight_outlined);
    final shiftColor = isMorning
        ? const Color(0xFFEA580C)
        : (isEvening ? const Color(0xFFD97706) : const Color(0xFF6366F1));
    final shiftBg = isMorning
        ? const Color(0xFFFFF7ED)
        : (isEvening ? const Color(0xFFFEF3C7) : const Color(0xFFEEF2FF));
    final shiftTime = isMorning
        ? '06:00 - 14:00'
        : (isEvening ? '14:00 - 22:00' : '22:00 - 06:00');

    final isAssigned = sa.operator != null && sa.operator!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isAssigned ? Colors.white : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isAssigned ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(color: shiftBg, borderRadius: BorderRadius.circular(6)),
            child: Icon(shiftIcon, size: 14, color: shiftColor),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${sa.shift} Shift', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: shiftColor)),
              Text(shiftTime, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
            ],
          ),
          const Spacer(),
          if (isAssigned) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, size: 11, color: Color(0xFF0284C7)),
                    const SizedBox(width: 4),
                    Text(sa.operator!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0A1E38))),
                  ],
                ),
                if (sa.totalProduced > 0)
                  Text('${Formatters.formatNumber(sa.totalProduced)} pcs', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
              ],
            ),
            const SizedBox(width: 8),
            if (!widget.isViewOnly)
              InkWell(
                onTap: () => _openAssignModal(m.machineId, m.machineCode, shift: sa.shift, currentOp: sa.operator),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: const Icon(Icons.edit_outlined, size: 12, color: Color(0xFF0284C7)),
                ),
              ),
          ] else ...[
            if (!widget.isViewOnly)
              InkWell(
                onTap: () => _openAssignModal(m.machineId, m.machineCode, shift: sa.shift),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.person_add_outlined, size: 12, color: Color(0xFF0284C7)),
                      SizedBox(width: 4),
                      Text('Assign', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0284C7))),
                    ],
                  ),
                ),
              )
            else
              const Text('Unassigned', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          ],
        ],
      ),
    );
  }

  // Operators List (By Person View Mode)
  Widget _buildOperatorsList(List<OperatorSummary> operators) {
    if (operators.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 48, color: Color(0xFF94A3B8)),
            SizedBox(height: 12),
            Text('No workers active', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            SizedBox(height: 4),
            Text('No operator production logged in this period.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: operators.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, index) {
        final o = operators[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha:0.03), blurRadius: 4, offset: const Offset(0, 1)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(21),
                    ),
                    child: const Icon(Icons.person, size: 22, color: Color(0xFF0284C7)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o.operatorName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                        const SizedBox(height: 2),
                        Text(
                          '${o.shifts.join(', ')} Shift${o.shifts.length > 1 ? 's' : ''}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(Formatters.formatNumber(o.totalProduced), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0284C7))),
                      const Text('pcs produced', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Machines Operated Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Machines Operated:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: o.machines.map((mCode) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.precision_manufacturing_outlined, size: 12, color: Color(0xFF0A1E38)),
                              const SizedBox(width: 4),
                              Text(mCode, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0A1E38))),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Footer: Latest on + timestamp
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Latest on: ${o.latestMachine}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                  Text(
                    o.lastActiveAt > 0
                        ? Formatters.formatDateTime(DateTime.fromMillisecondsSinceEpoch(o.lastActiveAt))
                        : '',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'RUNNING':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF16A34A);
        break;
      case 'IDLE':
      case 'STOPPED':
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        break;
      case 'BREAKDOWN':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        break;
      case 'MAINTENANCE':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }

  // Assign Operator Modal Bottom Sheet
  Widget _buildAssignModalSheet() {
    final curAssign = _activeAssignments[_selectedOperator];
    final otherMachines = (curAssign?['machines'] as List<Map<String, dynamic>>?)
            ?.where((m) => m['machineId'] != _selectedMachineId && m['machineId'] != _selectedMachineCode)
            .toList() ??
        [];
    final isOnThisMachine = (curAssign?['machines'] as List<Map<String, dynamic>>?)
            ?.any((m) => m['machineId'] == _selectedMachineId || m['machineId'] == _selectedMachineCode) ??
        false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha:0.15), blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Assign Person to Machine', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _assignModalVisible = false),
                ),
              ],
            ),
            Text('Machine: $_selectedMachineCode', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0284C7))),
            const SizedBox(height: 12),

            const Text('Select Staff / Worker (Each machine has 1 person)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            const SizedBox(height: 6),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _staffList.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, idx) {
                  final st = _staffList[idx];
                  final stName = st['name'] ?? '';
                  final active = _selectedOperator == stName;
                  final assign = _activeAssignments[stName];
                  final isStaffOnThis = (assign?['machines'] as List<Map<String, dynamic>>?)
                          ?.any((m) => m['machineId'] == _selectedMachineId || m['machineId'] == _selectedMachineCode) ??
                      false;
                  final staffOtherMachines = (assign?['machines'] as List<Map<String, dynamic>>?)
                          ?.where((m) => m['machineId'] != _selectedMachineId && m['machineId'] != _selectedMachineCode)
                          .toList() ??
                      [];

                  return GestureDetector(
                    onTap: () => setState(() => _selectedOperator = stName),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: active ? const Color(0xFF0284C7) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: active
                              ? const Color(0xFF0284C7)
                              : (staffOtherMachines.isNotEmpty ? const Color(0xFFBAE6FD) : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isStaffOnThis
                                    ? Icons.check_circle
                                    : (staffOtherMachines.isNotEmpty ? Icons.account_tree_outlined : Icons.person_outline),
                                size: 13,
                                color: active ? Colors.white : (staffOtherMachines.isNotEmpty ? const Color(0xFF0284C7) : const Color(0xFF64748B)),
                              ),
                              const SizedBox(width: 4),
                              Text(stName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? Colors.white : const Color(0xFF0F172A))),
                            ],
                          ),
                          Text(
                            isStaffOnThis
                                ? 'On this'
                                : (staffOtherMachines.isNotEmpty ? 'Operates ${staffOtherMachines.length} mach' : 'Available'),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: active
                                  ? Colors.white.withValues(alpha:0.9)
                                  : (isStaffOnThis ? const Color(0xFF0369A1) : (staffOtherMachines.isNotEmpty ? const Color(0xFF0284C7) : const Color(0xFF16A34A))),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // Live status banner
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isOnThisMachine ? const Color(0xFFF0FDF4) : (otherMachines.isNotEmpty ? const Color(0xFFF0F9FF) : const Color(0xFFF0FDF4)),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isOnThisMachine ? const Color(0xFFBBF7D0) : (otherMachines.isNotEmpty ? const Color(0xFFBAE6FD) : const Color(0xFFBBF7D0))),
              ),
              child: Row(
                children: [
                  Icon(
                    isOnThisMachine ? Icons.check_circle : (otherMachines.isNotEmpty ? Icons.account_tree_outlined : Icons.check_circle),
                    size: 16,
                    color: isOnThisMachine ? const Color(0xFF16A34A) : (otherMachines.isNotEmpty ? const Color(0xFF0284C7) : const Color(0xFF16A34A)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isOnThisMachine
                          ? '$_selectedOperator is already operating $_selectedMachineCode. You can adjust shift or work order notes.'
                          : (otherMachines.isNotEmpty
                              ? 'Multi-Machine Operator (${otherMachines.length + 1} total). They also operate ${otherMachines.map((m) => m['machineCode']).join(', ')}.'
                              : '$_selectedOperator is available (no other machines assigned today).'),
                      style: TextStyle(
                        fontSize: 11,
                        color: isOnThisMachine ? const Color(0xFF15803D) : (otherMachines.isNotEmpty ? const Color(0xFF0369A1) : const Color(0xFF15803D)),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            const Text('Shift', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            const SizedBox(height: 6),
            Row(
              children: ['Morning', 'Evening', 'Night'].map((sh) {
                final active = _selectedShift == sh;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedShift = sh),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? const Color(0xFF0A1E38) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: active ? const Color(0xFF0A1E38) : const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        sh,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: active ? Colors.white : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),

            const Text('Notes / Work Order (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            const SizedBox(height: 6),
            TextField(
              onChanged: (val) => _assignNotes = val,
              decoration: InputDecoration(
                hintText: 'e.g. Morning batch run',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _assignModalVisible = false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _confirmAssign,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      otherMachines.isNotEmpty ? 'Assign (Multi-Machine)' : 'Assign to $_selectedMachineCode',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Create Machine Modal Bottom Sheet
  Widget _buildCreateMachineModalSheet() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha:0.15), blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Add New Machine', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _createMachineModalVisible = false),
                ),
              ],
            ),
            const SizedBox(height: 12),

            const Text('Machine Code *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            const SizedBox(height: 4),
            TextField(
              controller: _machineCodeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'e.g. M-07 or CNC-02',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              ),
            ),
            const SizedBox(height: 10),

            const Text('Machine Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            const SizedBox(height: 4),
            TextField(
              controller: _machineNameController,
              decoration: InputDecoration(
                hintText: 'e.g. 5-Axis Milling Unit',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              ),
            ),
            const SizedBox(height: 10),

            const Text('Machine Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            const SizedBox(height: 4),
            TextField(
              controller: _machineTypeController,
              decoration: InputDecoration(
                hintText: 'e.g. CNC, Press, Lathe, Assembly',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              ),
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Production Line *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _createMachineModalVisible = false;
                      _createLineModalVisible = true;
                    });
                  },
                  child: const Text('+ New Line', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0284C7))),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _lines.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, idx) {
                  final line = _lines[idx];
                  final lId = (line['id'] ?? line['_id'])?.toString() ?? '';
                  final active = _selectedLineId == lId;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedLineId = lId),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: active ? const Color(0xFF0284C7) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: active ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0)),
                      ),
                      child: Center(
                        child: Text(
                          'Line ${line['code'] ?? 'A'} (${line['name'] ?? ''})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: active ? Colors.white : const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _createMachineModalVisible = false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleCreateMachine,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Create Machine', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Create Line Modal Bottom Sheet
  Widget _buildCreateLineModalSheet() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha:0.15), blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Add Production Line', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _createLineModalVisible = false),
                ),
              ],
            ),
            const SizedBox(height: 12),

            const Text('Line Code *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            const SizedBox(height: 4),
            TextField(
              controller: _lineCodeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'e.g. LINE-E or PACK-01',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              ),
            ),
            const SizedBox(height: 10),

            const Text('Line Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            const SizedBox(height: 4),
            TextField(
              controller: _lineNameController,
              decoration: InputDecoration(
                hintText: 'e.g. Assembly Line E',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _createLineModalVisible = false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleCreateLine,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Create Line', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Data models for the screen
class ShiftInfo {
  final String shift;
  String? operator;
  int totalProduced;
  int? lastActiveAt;

  ShiftInfo({
    required this.shift,
    this.operator,
    required this.totalProduced,
    this.lastActiveAt,
  });
}

class MachineSummary {
  final String machineId;
  final String machineCode;
  final String machineName;
  final String machineStatus;
  final String machineType;
  final String lineId;
  final String lineCode;
  final String lineName;
  final String? currentOperator;
  final String? currentShift;
  final String currentProduct;
  final int totalProduced;
  final int totalRejected;
  final List<ShiftInfo> shiftAssignments;

  MachineSummary({
    required this.machineId,
    required this.machineCode,
    required this.machineName,
    required this.machineStatus,
    required this.machineType,
    required this.lineId,
    required this.lineCode,
    required this.lineName,
    this.currentOperator,
    this.currentShift,
    required this.currentProduct,
    required this.totalProduced,
    required this.totalRejected,
    required this.shiftAssignments,
  });
}

class OperatorSummaryBuilder {
  final String operatorName;
  final Set<String> machines = {};
  final Set<String> shifts = {};
  int totalProduced = 0;
  int totalRejected = 0;
  int lastActiveAt = 0;
  String latestMachine = '';

  OperatorSummaryBuilder({required this.operatorName});

  OperatorSummary build() {
    return OperatorSummary(
      operatorName: operatorName,
      machines: machines.toList(),
      shifts: shifts.toList(),
      totalProduced: totalProduced,
      totalRejected: totalRejected,
      lastActiveAt: lastActiveAt,
      latestMachine: latestMachine,
    );
  }
}

class OperatorSummary {
  final String operatorName;
  final List<String> machines;
  final List<String> shifts;
  final int totalProduced;
  final int totalRejected;
  final int lastActiveAt;
  final String latestMachine;

  OperatorSummary({
    required this.operatorName,
    required this.machines,
    required this.shifts,
    required this.totalProduced,
    required this.totalRejected,
    required this.lastActiveAt,
    required this.latestMachine,
  });
}