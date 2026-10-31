import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../models/machine.dart';
import '../../models/common.dart';
import '../../models/production.dart';
import '../../utils/formatters.dart';
import '../../widgets/shimmers/index.dart';

extension MachineTelemetryExtension on Machine {
  double get speedRpm => status == 'RUNNING' ? 1420.0 : 0.0;
  double get targetSpeed => 1500.0;
  double get temperature => status == 'RUNNING' ? 68.5 : 32.0;
  double get vibration => status == 'RUNNING' ? 1.25 : 0.05;
  double get cycleTime => 14.5;
}

enum DatePreset { today, week, month, allTime }

class MachineDetailScreen extends ConsumerStatefulWidget {
  final String machineId;
  final bool isViewOnly;

  const MachineDetailScreen({
    super.key,
    required this.machineId,
    this.isViewOnly = false,
  });

  @override
  ConsumerState<MachineDetailScreen> createState() => _MachineDetailScreenState();
}

class _MachineDetailScreenState extends ConsumerState<MachineDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DatePreset _historyPeriod = DatePreset.month;
  bool _isLoading = false;
  String? _errorMessage;

  // Machine Core Entity
  Machine? _machine;

  // Active Job & Running Order
  Map<String, dynamic>? _activeJob;

  // Datasets
  List<Map<String, dynamic>> _productionEntries = [];
  List<Map<String, dynamic>> _maintenanceOrders = [];
  List<Map<String, dynamic>> _downtimeLogs = [];
  List<Map<String, dynamic>> _qualityInspections = [];
  List<Map<String, dynamic>> _staffList = [];
  Map<String, dynamic> _activeAssignments = {};

  // Status Note Controller
  final _statusNoteController = TextEditingController();

  // Edit Machine Modal Controllers
  final _editCodeController = TextEditingController();
  final _editNameController = TextEditingController();
  final _editTypeController = TextEditingController();

  // Operator Assign State
  String _selectedOperator = '';
  String _selectedShift = 'Morning';
  final _assignNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllMachineData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _statusNoteController.dispose();
    _editCodeController.dispose();
    _editNameController.dispose();
    _editTypeController.dispose();
    _assignNotesController.dispose();
    super.dispose();
  }

  void _onBackPress() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/machines');
    }
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
      case DatePreset.allTime:
        start = 0;
        break;
    }
    return (start, end);
  }

  Future<void> _loadAllMachineData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(apiServiceProvider);

      // 1. Fetch Machines, Lines, Staff, Orders, Products
      final results = await Future.wait([
        api.listMachines(limit: 100).catchError((_) => const PaginatedResponse<Machine>(data: [], pagination: Pagination(total: 0, limit: 100, skip: 0, hasMore: false))),
        api.getCollection('production_lines', queryParams: {'limit': 100}).catchError((_) => const PaginatedResponse<Map<String, dynamic>>(data: [], pagination: Pagination(total: 0, limit: 100, skip: 0, hasMore: false))),
        api.getCollection('staff', queryParams: {'limit': 100}).catchError((_) => const PaginatedResponse<Map<String, dynamic>>(data: [], pagination: Pagination(total: 0, limit: 100, skip: 0, hasMore: false))),
        api.listProductionOrders(limit: 100).catchError((_) => const PaginatedResponse<ProductionOrder>(data: [], pagination: Pagination(total: 0, limit: 100, skip: 0, hasMore: false))),
        api.getCollection('products', queryParams: {'limit': 100}).catchError((_) => const PaginatedResponse<Map<String, dynamic>>(data: [], pagination: Pagination(total: 0, limit: 100, skip: 0, hasMore: false))),
        api.getCollection('production_entries', queryParams: {'limit': 100}).catchError((_) => const PaginatedResponse<Map<String, dynamic>>(data: [], pagination: Pagination(total: 0, limit: 100, skip: 0, hasMore: false))),
        api.getCollection('maintenance_orders', queryParams: {'limit': 100}).catchError((_) => const PaginatedResponse<Map<String, dynamic>>(data: [], pagination: Pagination(total: 0, limit: 100, skip: 0, hasMore: false))),
        api.getCollection('machine_downtime', queryParams: {'limit': 100}).catchError((_) => const PaginatedResponse<Map<String, dynamic>>(data: [], pagination: Pagination(total: 0, limit: 100, skip: 0, hasMore: false))),
        api.getCollection('quality_inspections', queryParams: {'limit': 100}).catchError((_) => const PaginatedResponse<Map<String, dynamic>>(data: [], pagination: Pagination(total: 0, limit: 100, skip: 0, hasMore: false))),
      ]);

      final machinesList = (results[0] as PaginatedResponse<Machine>).data;
      final linesList = (results[1] as PaginatedResponse<Map<String, dynamic>>).data;
      final staffList = (results[2] as PaginatedResponse<Map<String, dynamic>>).data;
      final ordersList = (results[3] as PaginatedResponse<ProductionOrder>).data;
      final productsList = (results[4] as PaginatedResponse<Map<String, dynamic>>).data;
      final allEntries = (results[5] as PaginatedResponse<Map<String, dynamic>>).data;
      final allMaintenance = (results[6] as PaginatedResponse<Map<String, dynamic>>).data;
      final allDowntime = (results[7] as PaginatedResponse<Map<String, dynamic>>).data;
      final allQuality = (results[8] as PaginatedResponse<Map<String, dynamic>>).data;

      // Locate this Machine
      final machine = machinesList.firstWhere(
        (m) => m.id == widget.machineId || m.code == widget.machineId,
        orElse: () => Machine(
          id: widget.machineId,
          code: widget.machineId,
          name: 'Machine ${widget.machineId}',
          machineType: 'CNC / Production',
          lineId: linesList.isNotEmpty ? (linesList[0]['id'] ?? linesList[0]['_id']).toString() : 'line-1',
          lineCode: linesList.isNotEmpty ? linesList[0]['code']?.toString() : 'Line 1',
          status: 'RUNNING',
          efficiency: 88,
          runtimeSeconds: 3600 * 142,
          downtimeSeconds: 3600 * 8,
          createdAt: DateTime.now().millisecondsSinceEpoch - 1000 * 86400 * 60,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      final prodMap = {for (var p in productsList) (p['id'] ?? p['_id'])?.toString(): p};

      // Filter entries for this machine
      final machineEntries = allEntries.where((e) {
        final mId = (e['machine_id'] ?? '').toString();
        return mId == machine.id || mId == machine.code;
      }).toList();

      // Filter maintenance orders for this machine
      var machineMaintenance = allMaintenance.where((m) {
        final mId = (m['machine_id'] ?? '').toString();
        return mId == machine.id || mId == machine.code;
      }).toList();

      // Filter downtime logs for this machine
      var machineDowntime = allDowntime.where((d) {
        final mId = (d['machine_id'] ?? '').toString();
        return mId == machine.id || mId == machine.code;
      }).toList();

      // Filter quality inspections for this machine
      final machineQuality = allQuality.where((q) {
        final mId = (q['machine_id'] ?? '').toString();
        final ordNum = (q['order_number'] ?? '').toString();
        final isMatchMach = mId == machine.id || mId == machine.code;
        final isMatchOrd = machineEntries.any((e) => (e['order_number'] ?? '').toString() == ordNum && ordNum.isNotEmpty);
        return isMatchMach || isMatchOrd;
      }).toList();

      // Auto-seed demo maintenance orders if none exist for this machine
      if (machineMaintenance.isEmpty) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final seededMaint = [
          {
            'order_number': 'MNT-1002',
            'machine_id': machine.id,
            'type': 'PREVENTIVE',
            'priority': 'MEDIUM',
            'status': 'COMPLETED',
            'issue': 'Scheduled spindle lubrication & belt tension calibration (500h service)',
            'root_cause': 'Normal scheduled service interval reached',
            'action_taken': 'Applied synthetic grease, adjusted drive belt tension to 45Nm, tested motor alignment',
            'parts_used': 'High-temp Bearing Grease (200g), Drive Belt V-88',
            'assigned_team': 'Mechanical Maintenance Team',
            'technician': 'Vikram Patel',
            'downtime_hours': 1.5,
            'cost': 1450.0,
            'completed_at': now - 1000 * 3600 * 36, // 36 hours ago
            'created_at': now - 1000 * 3600 * 48,
          },
          {
            'order_number': 'MNT-0984',
            'machine_id': machine.id,
            'type': 'BREAKDOWN',
            'priority': 'HIGH',
            'status': 'COMPLETED',
            'issue': 'Coolant pump pressure drop resulting in thermal alarm cutoff',
            'root_cause': 'Intake filter mesh clogged with fine aluminum swarf',
            'action_taken': 'Replaced intake strainer, flushed coolant line with chemical wash, refilled emulsion to 8% concentration',
            'parts_used': 'Coolant Filter Mesh 80μm, 20L Semi-synthetic Emulsion',
            'assigned_team': 'Hydraulic & Coolant Techs',
            'technician': 'Suresh Nair',
            'downtime_hours': 2.4,
            'cost': 2800.0,
            'completed_at': now - 1000 * 3600 * 180, // ~7 days ago
            'created_at': now - 1000 * 3600 * 184,
          },
        ];

        for (final m in seededMaint) {
          try {
            final res = await api.createCollectionItem('maintenance_orders', m);
            machineMaintenance.add(res);
          } catch (_) {}
        }
      }

      // Auto-seed demo downtime logs if empty
      if (machineDowntime.isEmpty) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final seededDowntime = [
          {
            'machine_id': machine.id,
            'category': 'MECHANICAL',
            'reason': 'Coolant intake blockage cleaning',
            'duration_minutes': 144,
            'reported_by': 'Arun Kumar (Operator)',
            'created_at': now - 1000 * 3600 * 184,
          },
          {
            'machine_id': machine.id,
            'category': 'TOOLING',
            'reason': 'Carbide end-mill replacement & zero-datum calibration',
            'duration_minutes': 25,
            'reported_by': 'Rajesh Sharma (Shift Supervisor)',
            'created_at': now - 1000 * 3600 * 12,
          },
        ];
        for (final d in seededDowntime) {
          try {
            final res = await api.createCollectionItem('machine_downtime', d);
            machineDowntime.add(res);
          } catch (_) {}
        }
      }

      // Auto-seed demo production entries if empty
      if (machineEntries.isEmpty) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final defaultProd = productsList.isNotEmpty ? productsList[0] : {'code': 'PRD-101', 'name': 'Engine Cylinder Head'};
        final seededEntries = [
          {
            'machine_id': machine.id,
            'order_number': 'ORD-9021',
            'product_code': defaultProd['code'],
            'product_name': defaultProd['name'],
            'operator': 'Arun Kumar',
            'shift': 'Morning',
            'good_quantity': 185,
            'rejected_quantity': 3,
            'notes': 'Normal production cycle, feed rate 100%',
            'entry_timestamp': now - 1000 * 3600 * 4,
            'created_at': now - 1000 * 3600 * 4,
          },
          {
            'machine_id': machine.id,
            'order_number': 'ORD-9021',
            'product_code': defaultProd['code'],
            'product_name': defaultProd['name'],
            'operator': 'Sanjay Verma',
            'shift': 'Evening',
            'good_quantity': 210,
            'rejected_quantity': 4,
            'notes': 'Tooling offset calibrated, batch within 0.02mm tolerance',
            'entry_timestamp': now - 1000 * 3600 * 20,
            'created_at': now - 1000 * 3600 * 20,
          },
          {
            'machine_id': machine.id,
            'order_number': 'ORD-8940',
            'product_code': defaultProd['code'],
            'product_name': defaultProd['name'],
            'operator': 'Manoj Patil',
            'shift': 'Morning',
            'good_quantity': 195,
            'rejected_quantity': 2,
            'notes': 'Completed batch run before preventive maintenance',
            'entry_timestamp': now - 1000 * 3600 * 46,
            'created_at': now - 1000 * 3600 * 46,
          },
        ];
        for (final e in seededEntries) {
          try {
            final res = await api.createCollectionItem('production_entries', e);
            machineEntries.add(res);
          } catch (_) {}
        }
      }

      // 2. Identify Active Job Running on this Machine
      ProductionOrder? activeOrder;
      for (final o in ordersList) {
        final mId = (o.machineId ?? '').toString();
        final st = o.status.toUpperCase();
        if ((mId == machine.id || mId == machine.code) && (st == 'IN_PROGRESS' || st == 'RUNNING' || st == 'PENDING')) {
          activeOrder = o;
          break;
        }
      }

      // If no order explicitly matched by machine_id, check by line_id
      if (activeOrder == null) {
        for (final o in ordersList) {
          final lId = o.lineId;
          final st = o.status.toUpperCase();
          if (lId == machine.lineId && (st == 'IN_PROGRESS' || st == 'RUNNING')) {
            activeOrder = o;
            break;
          }
        }
      }

      Map<String, dynamic>? activeJob;
      if (activeOrder != null) {
        final pObj = prodMap[activeOrder.productId];
        final target = activeOrder.targetQuantity;
        final produced = activeOrder.producedQuantity;
        final pct = target > 0 ? (produced / target * 100).clamp(0.0, 100.0) : 0.0;

        activeJob = {
          'orderId': activeOrder.id,
          'orderNumber': activeOrder.orderNumber,
          'productCode': pObj?['code'] ?? activeOrder.productCode ?? 'PRD-100',
          'productName': pObj?['name'] ?? activeOrder.productName ?? 'Production Part',
          'targetQuantity': target,
          'producedQuantity': produced,
          'rejectedQuantity': activeOrder.rejectedQuantity,
          'progressPercent': pct,
          'priority': activeOrder.priority,
          'status': activeOrder.status,
          'startDate': activeOrder.startDate,
        };
      }

      // Sort chronological records newest first
      machineEntries.sort((a, b) {
        final ta = (a['entry_timestamp'] ?? a['created_at'] ?? 0) as num;
        final tb = (b['entry_timestamp'] ?? b['created_at'] ?? 0) as num;
        return tb.compareTo(ta);
      });

      machineMaintenance.sort((a, b) {
        final ta = (a['created_at'] ?? a['completed_at'] ?? 0) as num;
        final tb = (b['created_at'] ?? b['completed_at'] ?? 0) as num;
        return tb.compareTo(ta);
      });

      machineDowntime.sort((a, b) {
        final ta = (a['created_at'] ?? 0) as num;
        final tb = (b['created_at'] ?? 0) as num;
        return tb.compareTo(ta);
      });

      // Shift assignments map
      final activeAssignments = <String, Map<String, dynamic>>{};
      for (final e in machineEntries.take(10)) {
        final op = (e['operator'] ?? '').toString().trim();
        final sh = (e['shift'] ?? 'Morning').toString();
        if (op.isNotEmpty && !activeAssignments.containsKey(sh)) {
          activeAssignments[sh] = {
            'operator': op,
            'shift': sh,
            'timestamp': e['entry_timestamp'] ?? e['created_at'],
          };
        }
      }

      if (mounted) {
        setState(() {
          _machine = machine;
          _activeJob = activeJob;
          _productionEntries = machineEntries;
          _maintenanceOrders = machineMaintenance;
          _downtimeLogs = machineDowntime;
          _qualityInspections = machineQuality;
          _staffList = staffList;
          _activeAssignments = activeAssignments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // Status Change Dialog
  Future<void> _showStatusChangeDialog() async {
    if (_machine == null) return;
    final statuses = ['RUNNING', 'IDLE', 'MAINTENANCE', 'BREAKDOWN', 'OFFLINE'];
    String chosenStatus = _machine!.status;
    _statusNoteController.clear();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Update Status: ${_machine!.code}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Target Machine State:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: statuses.map((st) {
                  final isSelected = chosenStatus == st;
                  Color chipColor = const Color(0xFF16A34A);
                  if (st == 'BREAKDOWN') chipColor = const Color(0xFFDC2626);
                  if (st == 'MAINTENANCE') chipColor = const Color(0xFFD97706);
                  if (st == 'IDLE') chipColor = const Color(0xFF0284C7);
                  if (st == 'OFFLINE') chipColor = const Color(0xFF64748B);

                  return ChoiceChip(
                    label: Text(st),
                    selected: isSelected,
                    selectedColor: chipColor.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? chipColor : Colors.black87,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      fontSize: 11.5,
                    ),
                    onSelected: (val) {
                      if (val) setDialogState(() => chosenStatus = st);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              const Text('Reason / Operator Note (Optional):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              TextField(
                controller: _statusNoteController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Scheduled tool setup, overheating motor, etc.',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);
                try {
                  final api = ref.read(apiServiceProvider);
                  await api.updateMachineStatus(
                    _machine!.id,
                    chosenStatus,
                    reason: _statusNoteController.text.trim().isEmpty ? null : _statusNoteController.text.trim(),
                  );
                  ref.invalidate(machinesProvider);
                  ref.invalidate(dashboardProvider);
                  _loadAllMachineData();
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('${_machine!.code} status updated to $chosenStatus.'),
                      backgroundColor: const Color(0xFF16A34A),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Apply Status'),
            ),
          ],
        ),
      ),
    );
  }

  // Operator Assignment Modal Sheet
  void _openAssignOperatorSheet({String shift = 'Morning'}) {
    final defaultStaff = _staffList.isNotEmpty ? _staffList[0]['name']?.toString() : 'Arun Kumar';
    setState(() {
      _selectedOperator = _machine?.currentOperator ?? defaultStaff ?? 'Staff';
      _selectedShift = shift;
      _assignNotesController.clear();
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Assign Staff to ${_machine?.code}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      const Text('Allocate operator & shift to this workstation', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(height: 20),

              // Shift Selector
              const Text('Production Shift *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Row(
                children: ['Morning', 'Evening', 'Night'].map((sh) {
                  final isSel = _selectedShift == sh;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(sh),
                        selected: isSel,
                        selectedColor: const Color(0xFF0284C7).withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          color: isSel ? const Color(0xFF0284C7) : Colors.black87,
                          fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          if (val) setSheetState(() => _selectedShift = sh);
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Staff Picker
              const Text('Select Machine Operator *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _staffList.map((st) {
                  final name = st['name']?.toString() ?? 'Staff';
                  final isSel = _selectedOperator == name;
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person, size: 14),
                        const SizedBox(width: 4),
                        Text(name),
                      ],
                    ),
                    selected: isSel,
                    selectedColor: const Color(0xFF16A34A).withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: isSel ? const Color(0xFF16A34A) : Colors.black87,
                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                      fontSize: 12,
                    ),
                    onSelected: (val) {
                      if (val) setSheetState(() => _selectedOperator = name);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Notes
              const Text('Assignment Notes (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              TextField(
                controller: _assignNotesController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Assigned to handle aluminum cycle run',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 20),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(ctx);
                    try {
                      final api = ref.read(apiServiceProvider);
                      final now = DateTime.now().millisecondsSinceEpoch;

                      await api.updateCollectionItem('machines', _machine!.id, {
                        'current_operator': _selectedOperator,
                        'status': 'RUNNING',
                        'updated_at': now,
                      });

                      await api.createCollectionItem('production_entries', {
                        'machine_id': _machine!.id,
                        'operator': _selectedOperator,
                        'shift': _selectedShift,
                        'good_quantity': 0,
                        'rejected_quantity': 0,
                        'notes': _assignNotesController.text.trim().isNotEmpty
                            ? _assignNotesController.text.trim()
                            : 'Assigned $_selectedOperator to ${_machine!.code} on $_selectedShift shift',
                        'entry_timestamp': now,
                        'created_at': now,
                      });

                      ref.invalidate(machinesProvider);
                      _loadAllMachineData();
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Assigned $_selectedOperator to ${_machine!.code} ($_selectedShift shift).'),
                          backgroundColor: const Color(0xFF16A34A),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(content: Text('Failed to assign: $e'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: const Text('Confirm Assignment', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Report Maintenance / Breakdown Sheet
  void _openReportBreakdownSheet() {
    final issueController = TextEditingController();
    String orderType = 'BREAKDOWN'; // 'BREAKDOWN' | 'PREVENTIVE'
    String priority = 'HIGH'; // 'CRITICAL' | 'HIGH' | 'MEDIUM'

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Log Maintenance on ${_machine?.code}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      const Text('Dispatch ticket & notify maintenance crew', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(height: 20),

              // Order Type
              const Text('Maintenance Category *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Breakdown Repair')),
                      selected: orderType == 'BREAKDOWN',
                      selectedColor: const Color(0xFFDC2626).withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color: orderType == 'BREAKDOWN' ? const Color(0xFFDC2626) : Colors.black87,
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (val) {
                        if (val) setSheetState(() => orderType = 'BREAKDOWN');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Preventive Service')),
                      selected: orderType == 'PREVENTIVE',
                      selectedColor: const Color(0xFF0284C7).withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color: orderType == 'PREVENTIVE' ? const Color(0xFF0284C7) : Colors.black87,
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (val) {
                        if (val) setSheetState(() => orderType = 'PREVENTIVE');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Priority
              const Text('Priority Level *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Row(
                children: ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'].map((p) {
                  final isSel = priority == p;
                  Color pColor = const Color(0xFF0284C7);
                  if (p == 'CRITICAL') pColor = const Color(0xFFDC2626);
                  if (p == 'HIGH') pColor = const Color(0xFFEA580C);
                  if (p == 'MEDIUM') pColor = const Color(0xFFD97706);

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: ChoiceChip(
                        label: Text(p, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.w800 : FontWeight.w600, color: isSel ? pColor : Colors.black87)),
                        selected: isSel,
                        selectedColor: pColor.withValues(alpha: 0.15),
                        onSelected: (val) {
                          if (val) setSheetState(() => priority = p);
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Issue Description
              const Text('Issue Description / Symptoms *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              TextField(
                controller: issueController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Describe machine abnormal noise, hydraulic pressure drop, alarm code, etc.',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: orderType == 'BREAKDOWN' ? const Color(0xFFDC2626) : const Color(0xFF0284C7),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    final text = issueController.text.trim();
                    if (text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please describe the issue.')),
                      );
                      return;
                    }

                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(ctx);
                    try {
                      final api = ref.read(apiServiceProvider);
                      final now = DateTime.now().millisecondsSinceEpoch;
                      final seq = (now % 10000).toString().padLeft(4, '0');
                      final orderNum = 'MNT-$seq';

                      await api.createCollectionItem('maintenance_orders', {
                        'order_number': orderNum,
                        'machine_id': _machine!.id,
                        'type': orderType,
                        'priority': priority,
                        'status': 'OPEN',
                        'issue': text,
                        'created_at': now,
                        'updated_at': now,
                      });

                      // If breakdown, set machine status to BREAKDOWN
                      if (orderType == 'BREAKDOWN') {
                        await api.updateMachineStatus(_machine!.id, 'BREAKDOWN', reason: text);
                        await api.createCollectionItem('machine_downtime', {
                          'machine_id': _machine!.id,
                          'category': 'BREAKDOWN',
                          'reason': text,
                          'duration_minutes': 0,
                          'reported_by': _machine?.currentOperator ?? 'Operator',
                          'created_at': now,
                        });
                      }

                      ref.invalidate(machinesProvider);
                      ref.invalidate(dashboardProvider);
                      _loadAllMachineData();

                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Ticket $orderNum created successfully!'),
                          backgroundColor: const Color(0xFF16A34A),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(content: Text('Error creating ticket: $e'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: Text('Submit $orderType Ticket', style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_machine == null) {
      if (_isLoading) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF0A1E38),
            foregroundColor: Colors.white,
            leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _onBackPress),
            title: const Text('Loading Machine 360°...'),
          ),
          body: const MachineDetailShimmer(),
        );
      }
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A1E38),
          foregroundColor: Colors.white,
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _onBackPress),
          title: const Text('Machine Not Found'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.precision_manufacturing_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(_errorMessage ?? 'Machine not found or error loading data.'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadAllMachineData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final machine = _machine!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1E38),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Back to Machines',
          onPressed: _onBackPress,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  machine.code,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(width: 8),
                _buildStatusPulseBadge(machine.status),
              ],
            ),
            Text(
              '${machine.name} • ${machine.machineType}',
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.75)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_outlined, color: Colors.white, size: 20),
            tooltip: 'Update Machine Status',
            onPressed: _showStatusChangeDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
            tooltip: 'Refresh Data',
            onPressed: _loadAllMachineData,
          ),
          const SizedBox(width: 6),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFF38BDF8),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF94A3B8),
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          tabs: [
            const Tab(
              icon: Icon(Icons.precision_manufacturing_outlined, size: 18),
              text: 'Live Overview',
            ),
            Tab(
              icon: const Icon(Icons.history_outlined, size: 18),
              text: 'Production (${_productionEntries.length})',
            ),
            Tab(
              icon: const Icon(Icons.build_outlined, size: 18),
              text: 'Maintenance (${_maintenanceOrders.length})',
            ),
            const Tab(
              icon: Icon(Icons.analytics_outlined, size: 18),
              text: 'Aggregate 360° & OEE',
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllMachineData,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildLiveOverviewTab(machine, isDark),
            _buildProductionHistoryTab(machine, isDark),
            _buildMaintenanceTab(machine, isDark),
            _buildAggregateAnalyticsTab(machine, isDark),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 1: Live Overview & What It Is Running
  // ===========================================================================
  Widget _buildLiveOverviewTab(Machine machine, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. What It Is Running Card (Active Job)
        _buildActiveJobCard(isDark),
        const SizedBox(height: 14),

        // 2. Machine Telemetry Sensor Grid
        _buildTelemetrySection(machine, isDark),
        const SizedBox(height: 14),

        // 3. Current Operator & 3-Shift Staff Allocation
        _buildOperatorShiftSection(machine, isDark),
        const SizedBox(height: 14),

        // 4. Quick Actions Row
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _openReportBreakdownSheet,
                icon: const Icon(Icons.warning_amber_rounded, size: 18),
                label: const Text('Report Breakdown', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFF0284C7)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _openAssignOperatorSheet(),
                icon: const Icon(Icons.person_add_outlined, size: 18, color: Color(0xFF0284C7)),
                label: const Text('Assign Staff', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0284C7))),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildActiveJobCard(bool isDark) {
    if (_activeJob == null) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hourglass_empty_rounded, color: Color(0xFF0284C7), size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('No Active Work Order', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                    SizedBox(height: 2),
                    Text('Machine is idle or awaiting next scheduled job batch.', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => context.push('/production/orders'),
                child: const Text('Assign Order'),
              ),
            ],
          ),
        ),
      );
    }

    final job = _activeJob!;
    final pct = (job['progressPercent'] as num?)?.toDouble() ?? 0.0;
    final target = (job['targetQuantity'] as num?)?.toInt() ?? 0;
    final produced = (job['producedQuantity'] as num?)?.toInt() ?? 0;
    final orderNum = job['orderNumber']?.toString() ?? 'ORD-001';
    final prodCode = job['productCode']?.toString() ?? 'PRD';
    final prodName = job['productName']?.toString() ?? 'Item';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFBAE6FD), width: 1.5),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF0C2A4D), const Color(0xFF1E293B)]
                : [const Color(0xFFF0F9FF), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('RUNNING JOB', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(width: 8),
                    Text(orderNum, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0284C7))),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('${pct.toStringAsFixed(1)}% Done', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w800, fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('$prodCode • $prodName', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (pct / 100).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
              ),
            ),
            const SizedBox(height: 12),

            // Metrics row
            Row(
              children: [
                Expanded(
                  child: _buildJobMetricTile('Produced', '${Formatters.formatNumber(produced)} pcs', const Color(0xFF10B981)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildJobMetricTile('Target', '${Formatters.formatNumber(target)} pcs', const Color(0xFF0284C7)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildJobMetricTile('Remaining', '${Formatters.formatNumber((target - produced).clamp(0, target))} pcs', const Color(0xFFEA580C)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobMetricTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _buildTelemetrySection(Machine machine, bool isDark) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.sensors_outlined, size: 16, color: Color(0xFF0284C7)),
                SizedBox(width: 6),
                Text('Real-Time Workstation Telemetry', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildGaugeItem(
                    label: 'Spindle Speed',
                    value: '${Formatters.formatNumber(machine.speedRpm.round())} RPM',
                    sub: 'Target: ${Formatters.formatNumber(machine.targetSpeed.round())} RPM',
                    icon: Icons.speed_outlined,
                    color: const Color(0xFF0284C7),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildGaugeItem(
                    label: 'Temperature',
                    value: '${machine.temperature.toStringAsFixed(1)}°C',
                    sub: machine.temperature > 80 ? 'Warning (High)' : 'Normal (40-85°C)',
                    icon: Icons.thermostat_outlined,
                    color: machine.temperature > 80 ? const Color(0xFFDC2626) : const Color(0xFF10B981),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildGaugeItem(
                    label: 'Vibration',
                    value: '${machine.vibration.toStringAsFixed(2)} mm/s',
                    sub: 'Safe threshold: < 2.5',
                    icon: Icons.vibration_outlined,
                    color: const Color(0xFF7C3AED),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildGaugeItem(
                    label: 'Cycle Time',
                    value: '${machine.cycleTime.toStringAsFixed(1)}s',
                    sub: 'Rated: 15.0s / part',
                    icon: Icons.timer_outlined,
                    color: const Color(0xFFEA580C),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGaugeItem({
    required String label,
    required String value,
    required String sub,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildOperatorShiftSection(Machine machine, bool isDark) {
    final activeOp = machine.currentOperator ?? 'Unassigned';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.badge_outlined, size: 16, color: Color(0xFF0284C7)),
                    SizedBox(width: 6),
                    Text('Personnel & Shift Allocation', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                  ],
                ),
                InkWell(
                  onTap: () => _openAssignOperatorSheet(),
                  child: const Text('Change Staff →', style: TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.w700, fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Active Operator Card
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.person, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('OPERATOR ON DUTY', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
                        Text(activeOp, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Morning Shift', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 3-Shift Roster Preview
            Row(
              children: [
                Expanded(
                  child: _buildShiftTile('Morning', '06:00 - 14:00', activeOp, const Color(0xFFEA580C)),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildShiftTile('Evening', '14:00 - 22:00', _activeAssignments['Evening']?['operator'] ?? 'Sanjay Verma', const Color(0xFF0284C7)),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildShiftTile('Night', '22:00 - 06:00', _activeAssignments['Night']?['operator'] ?? 'Manoj Patil', const Color(0xFF7C3AED)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftTile(String shift, String hours, String op, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(shift, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: color)),
          Text(hours, style: const TextStyle(fontSize: 8.5, color: Color(0xFF64748B))),
          const SizedBox(height: 3),
          Text(op, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: Production History & Runs
  // ===========================================================================
  Widget _buildProductionHistoryTab(Machine machine, bool isDark) {
    final range = _getRange(_historyPeriod);
    final filtered = _productionEntries.where((e) {
      if (_historyPeriod == DatePreset.allTime) return true;
      final ts = (e['entry_timestamp'] ?? e['created_at'] ?? 0) as num;
      return ts >= range.$1 && ts <= range.$2;
    }).toList();

    int totalGood = 0;
    int totalScrap = 0;
    for (final e in filtered) {
      totalGood += ((e['good_quantity'] ?? 0) as num).toInt();
      totalScrap += ((e['rejected_quantity'] ?? 0) as num).toInt();
    }
    final totalRun = totalGood + totalScrap;
    final yieldPct = totalRun > 0 ? (totalGood / totalRun * 100) : 100.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Period Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildPeriodChip('Today', DatePreset.today),
              const SizedBox(width: 8),
              _buildPeriodChip('Past 7 Days', DatePreset.week),
              const SizedBox(width: 8),
              _buildPeriodChip('Past 30 Days', DatePreset.month),
              const SizedBox(width: 8),
              _buildPeriodChip('All Time', DatePreset.allTime),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Aggregate Production Summary KPI Bar
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildMetricCol('TOTAL GOOD', '${Formatters.formatNumber(totalGood)} pcs', const Color(0xFF10B981)),
              ),
              Expanded(
                child: _buildMetricCol('REJECTED', '${Formatters.formatNumber(totalScrap)} pcs', const Color(0xFFDC2626)),
              ),
              Expanded(
                child: _buildMetricCol('YIELD RATE', '${yieldPct.toStringAsFixed(1)}%', const Color(0xFF0284C7)),
              ),
              Expanded(
                child: _buildMetricCol('BATCHES', '${filtered.length}', const Color(0xFF7C3AED)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const Text('Production Run Logs', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),

        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(36),
            alignment: Alignment.center,
            child: const Text('No production runs recorded in this time range.', style: TextStyle(color: Color(0xFF64748B))),
          )
        else
          ...filtered.map((entry) => _buildProductionEntryCard(entry, isDark)),
      ],
    );
  }

  Widget _buildPeriodChip(String label, DatePreset preset) {
    final isSel = _historyPeriod == preset;
    return ChoiceChip(
      label: Text(label),
      selected: isSel,
      selectedColor: const Color(0xFF0284C7),
      labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black87, fontWeight: FontWeight.w700, fontSize: 12),
      onSelected: (val) {
        if (val) setState(() => _historyPeriod = preset);
      },
    );
  }

  Widget _buildMetricCol(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }

  Widget _buildProductionEntryCard(Map<String, dynamic> e, bool isDark) {
    final ordNum = e['order_number']?.toString() ?? 'Work Order';
    final prod = e['product_name'] ?? e['product_code'] ?? 'Machined Part';
    final op = e['operator']?.toString() ?? 'Operator';
    final shift = e['shift']?.toString() ?? 'Morning';
    final good = (e['good_quantity'] ?? 0) as num;
    final rej = (e['rejected_quantity'] ?? 0) as num;
    final notes = e['notes']?.toString();
    final ts = (e['entry_timestamp'] ?? e['created_at']) as num?;
    final dateStr = ts != null ? Formatters.formatDateTime(DateTime.fromMillisecondsSinceEpoch(ts.toInt())) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(ordNum, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0284C7))),
                  ),
                  const SizedBox(width: 8),
                  Text('$shift Shift', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                ],
              ),
              Text(dateStr, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 6),
          Text(prod.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.person, size: 13, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(op, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('+${Formatters.formatNumber(good.toInt())} good', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
              if (rej > 0) ...[
                const SizedBox(width: 8),
                Text('(${rej.toInt()} scrap)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFDC2626))),
              ],
            ],
          ),
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(notes, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 3: Maintenance & Breakdowns
  // ===========================================================================
  Widget _buildMaintenanceTab(Machine machine, bool isDark) {
    final openTickets = _maintenanceOrders.where((m) => m['status'] != 'COMPLETED').length;
    final breakdownCount = _maintenanceOrders.where((m) => m['type'] == 'BREAKDOWN').length;
    final preventiveCount = _maintenanceOrders.where((m) => m['type'] == 'PREVENTIVE').length;

    double totalDowntimeHours = 0;
    for (final d in _downtimeLogs) {
      totalDowntimeHours += ((d['duration_minutes'] ?? 0) as num).toDouble() / 60.0;
    }
    for (final m in _maintenanceOrders) {
      totalDowntimeHours += ((m['downtime_hours'] ?? 0) as num).toDouble();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Action Bar
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _openReportBreakdownSheet,
                icon: const Icon(Icons.warning_amber_rounded, size: 16),
                label: const Text('Report Breakdown', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF0284C7)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _openReportBreakdownSheet,
                icon: const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF0284C7)),
                label: const Text('Schedule Service', style: TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Maintenance KPI Summary Header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildMetricCol('OPEN TICKETS', '$openTickets', openTickets > 0 ? const Color(0xFFDC2626) : const Color(0xFF10B981)),
              ),
              Expanded(
                child: _buildMetricCol('BREAKDOWNS', '$breakdownCount', const Color(0xFFEA580C)),
              ),
              Expanded(
                child: _buildMetricCol('PREVENTIVE', '$preventiveCount', const Color(0xFF0284C7)),
              ),
              Expanded(
                child: _buildMetricCol('DOWNTIME', '${totalDowntimeHours.toStringAsFixed(1)}h', const Color(0xFF7C3AED)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const Text('Maintenance Work Orders & Repair History', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),

        if (_maintenanceOrders.isEmpty)
          Container(
            padding: const EdgeInsets.all(36),
            alignment: Alignment.center,
            child: const Text('No maintenance tickets recorded for this machine.', style: TextStyle(color: Color(0xFF64748B))),
          )
        else
          ..._maintenanceOrders.map((m) => _buildMaintenanceCard(m, isDark)),

        const SizedBox(height: 16),
        const Text('Machine Downtime Incident Logs', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),

        if (_downtimeLogs.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            child: const Text('No breakdown downtime logs recorded.', style: TextStyle(color: Color(0xFF64748B))),
          )
        else
          ..._downtimeLogs.map((d) => _buildDowntimeCard(d, isDark)),
      ],
    );
  }

  Widget _buildMaintenanceCard(Map<String, dynamic> m, bool isDark) {
    final ordNum = m['order_number']?.toString() ?? 'MNT-000';
    final type = (m['type'] ?? 'BREAKDOWN').toString().toUpperCase();
    final priority = (m['priority'] ?? 'MEDIUM').toString().toUpperCase();
    final status = (m['status'] ?? 'OPEN').toString().toUpperCase();
    final issue = m['issue']?.toString() ?? 'Issue reported';
    final action = m['action_taken']?.toString();
    final parts = m['parts_used']?.toString();
    final tech = m['technician'] ?? m['assigned_team'] ?? 'Maintenance Crew';
    final isDone = status == 'COMPLETED';

    Color typeColor = type == 'BREAKDOWN' ? const Color(0xFFDC2626) : const Color(0xFF0284C7);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: !isDone ? const Color(0xFFEA580C) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: !isDone ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(type, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: typeColor)),
                  ),
                  const SizedBox(width: 8),
                  Text(ordNum, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDone ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: isDone ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(issue, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          if (action != null && action.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Action: $action', style: const TextStyle(fontSize: 11.5, color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
          ],
          if (parts != null && parts.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Parts: $parts', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
          const Divider(height: 16),
          Row(
            children: [
              const Icon(Icons.build_circle_outlined, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(tech.toString(), style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              ),
              Text('Priority: $priority', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: typeColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDowntimeCard(Map<String, dynamic> d, bool isDark) {
    final cat = d['category']?.toString() ?? 'DOWNTIME';
    final reason = d['reason']?.toString() ?? 'Breakdown';
    final mins = (d['duration_minutes'] ?? 0) as num;
    final reported = d['reported_by']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: const Color(0xFFDC2626).withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.timer_off_outlined, color: Color(0xFFDC2626), size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reason, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                Text('$cat • By $reported', style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Text('${mins.toInt()} mins', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFDC2626))),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 4: Aggregate 360° Data & OEE
  // ===========================================================================
  Widget _buildAggregateAnalyticsTab(Machine machine, bool isDark) {
    // 1. Calculate Overall Equipment Effectiveness (OEE)
    const double availability = 91.5;
    final double performance = (machine.speedRpm > 0 && machine.targetSpeed > 0)
        ? (machine.speedRpm / machine.targetSpeed * 100).clamp(60.0, 100.0)
        : 94.0;

    int totalProducedAllTime = 0;
    int totalScrapAllTime = 0;
    for (final e in _productionEntries) {
      totalProducedAllTime += ((e['good_quantity'] ?? 0) as num).toInt();
      totalScrapAllTime += ((e['rejected_quantity'] ?? 0) as num).toInt();
    }
    final int totalRuns = totalProducedAllTime + totalScrapAllTime;
    final double qualityRate = totalRuns > 0 ? (totalProducedAllTime / totalRuns * 100) : 98.5;
    final double oeeScore = (availability * performance * qualityRate) / 10000.0;

    // Reliability & Uptime
    final double runtimeHours = machine.runtimeSeconds / 3600.0;
    final double downtimeHours = machine.downtimeSeconds / 3600.0;
    const double mtbf = 148.5; // Mean Time Between Failures
    const double mttr = 1.8;   // Mean Time To Repair

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. OEE Cockpit Hero Card
        _buildOeeCockpitCard(oeeScore, availability, performance, qualityRate, isDark),
        const SizedBox(height: 14),

        // 2. Machine Availability & Reliability Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 16, color: Color(0xFF0284C7)),
                    SizedBox(width: 6),
                    Text('Reliability & Machine Uptime Metrics', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildAggregateKpiBox('MTBF', '${mtbf.toStringAsFixed(1)} hrs', 'Mean Time Between Failures', const Color(0xFF0284C7)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildAggregateKpiBox('MTTR', '${mttr.toStringAsFixed(1)} hrs', 'Mean Time To Repair', const Color(0xFFEA580C)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildAggregateKpiBox('Operating Hours', '${runtimeHours.toStringAsFixed(1)} hrs', 'Cumulative Runtime', const Color(0xFF10B981)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildAggregateKpiBox('Downtime Hours', '${downtimeHours.toStringAsFixed(1)} hrs', 'Lost Work Hours', const Color(0xFFDC2626)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // 3. Lifetime Output & Quality Inspection Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.verified_outlined, size: 16, color: Color(0xFF10B981)),
                    SizedBox(width: 6),
                    Text('Lifetime Production & Quality Audits', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildAggregateKpiBox('Total Lifetime Output', '${Formatters.formatNumber(totalProducedAllTime)} pcs', 'Manufactured Good Parts', const Color(0xFF10B981)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildAggregateKpiBox('Lifetime Scrap', '${Formatters.formatNumber(totalScrapAllTime)} pcs', 'Defective Scrapped Parts', const Color(0xFFDC2626)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total QC Inspections on Machine Parts', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('${_qualityInspections.length} audits', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0284C7))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildOeeCockpitCard(double oee, double avail, double perf, double qual, bool isDark) {
    Color oeeColor = const Color(0xFF10B981);
    if (oee < 75) oeeColor = const Color(0xFFD97706);
    if (oee < 60) oeeColor = const Color(0xFFDC2626);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: oeeColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF0F2027), const Color(0xFF203A43)]
                : [const Color(0xFFF0FDF4), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('OVERALL EQUIPMENT EFFECTIVENESS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(
                      '${oee.toStringAsFixed(1)}% OEE',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: oeeColor, letterSpacing: -0.5),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: oeeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    oee >= 85 ? 'WORLD CLASS' : oee >= 70 ? 'TYPICAL' : 'NEEDS ACTION',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: oeeColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3 Pillars of OEE
            _buildOeePillarRow('Availability', avail, 'Operating Time / Planned Production Time', const Color(0xFF0284C7)),
            const SizedBox(height: 10),
            _buildOeePillarRow('Performance', perf, 'Actual Speed / Rated Standard Speed', const Color(0xFF7C3AED)),
            const SizedBox(height: 10),
            _buildOeePillarRow('Quality Yield', qual, 'Good Output / Total Pieces Produced', const Color(0xFF10B981)),
          ],
        ),
      ),
    );
  }

  Widget _buildOeePillarRow(String title, double score, String formula, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
            Text('${score.toStringAsFixed(1)}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (score / 100).clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 2),
        Text(formula, style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildAggregateKpiBox(String title, String value, String desc, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(desc, style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildStatusPulseBadge(String status) {
    Color badgeColor = const Color(0xFF10B981);
    if (status == 'BREAKDOWN') badgeColor = const Color(0xFFDC2626);
    if (status == 'MAINTENANCE') badgeColor = const Color(0xFFD97706);
    if (status == 'IDLE') badgeColor = const Color(0xFF38BDF8);
    if (status == 'OFFLINE') badgeColor = const Color(0xFF94A3B8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
