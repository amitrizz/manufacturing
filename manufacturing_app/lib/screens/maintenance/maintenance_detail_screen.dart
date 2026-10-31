import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../utils/formatters.dart';
import '../../widgets/shimmers/index.dart';

class MaintenanceDetailScreen extends ConsumerStatefulWidget {
  final String orderId;

  const MaintenanceDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<MaintenanceDetailScreen> createState() => _MaintenanceDetailScreenState();
}

class _MaintenanceDetailScreenState extends ConsumerState<MaintenanceDetailScreen> {
  final _rootCauseController = TextEditingController();
  final _actionController = TextEditingController();
  final _partsUsedController = TextEditingController();
  final _technicianNotesController = TextEditingController();

  bool _loading = false;
  bool _submitting = false;
  Map<String, dynamic>? _order;
  List<Map<String, dynamic>> _machines = [];

  @override
  void initState() {
    super.initState();
    _loadTicketDetails();
  }

  @override
  void dispose() {
    _rootCauseController.dispose();
    _actionController.dispose();
    _partsUsedController.dispose();
    _technicianNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadTicketDetails() async {
    setState(() => _loading = true);
    try {
      final apiService = ref.read(apiServiceProvider);

      // Load all machines to resolve machine code/name
      try {
        final mResp = await apiService.getCollection('machines', queryParams: {'limit': 100});
        _machines = mResp.data;
      } catch (_) {}

      // Fetch the specific order or search in collection
      Map<String, dynamic>? foundOrder;
      try {
        foundOrder = await apiService.getCollectionItem('maintenance_orders', widget.orderId);
      } catch (_) {
        // Fallback: list collection and find
        final ordersResp = await apiService.getCollection('maintenance_orders', queryParams: {'limit': 200});
        for (final o in ordersResp.data) {
          if ((o['id']?.toString() == widget.orderId) || (o['_id']?.toString() == widget.orderId)) {
            foundOrder = o;
            break;
          }
        }
      }

      if (foundOrder != null) {
        // Attach machine code if missing
        final mId = foundOrder['machine_id']?.toString() ?? '';
        final mMatch = _machines.firstWhere(
          (m) => (m['id']?.toString() == mId) || (m['_id']?.toString() == mId),
          orElse: () => <String, dynamic>{},
        );
        if (mMatch.isNotEmpty && (foundOrder['machine_code'] == null || foundOrder['machine_code'] == '')) {
          foundOrder = {
            ...foundOrder,
            'machine_code': mMatch['code'] ?? mMatch['name'] ?? mId,
            'machine_name': mMatch['name'] ?? '',
          };
        }

        if (mounted) {
          setState(() {
            _order = foundOrder;
            if (foundOrder!['root_cause'] != null) {
              _rootCauseController.text = foundOrder['root_cause'].toString();
            }
            if (foundOrder['action_taken'] != null) {
              _actionController.text = foundOrder['action_taken'].toString();
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load maintenance ticket: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _completeMaintenance() async {
    if (_actionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the action taken to resolve this ticket.'),
          backgroundColor: Color(0xFFD97706),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final apiService = ref.read(apiServiceProvider);
      final now = DateTime.now().millisecondsSinceEpoch;
      final rootCause = _rootCauseController.text.trim();
      final actionTaken = _actionController.text.trim();
      final partsUsed = _partsUsedController.text.trim();
      final techNotes = _technicianNotesController.text.trim();

      // 1. Update maintenance order status to COMPLETED
      await apiService.updateCollectionItem('maintenance_orders', widget.orderId, {
        'status': 'COMPLETED',
        'completed_at': now,
        'root_cause': rootCause,
        'action_taken': actionTaken,
        if (partsUsed.isNotEmpty) 'parts_used': partsUsed,
        if (techNotes.isNotEmpty) 'technician_notes': techNotes,
        'updated_at': now,
      });

      // 2. If order was associated with a machine, restore machine status to RUNNING
      final machineId = _order?['machine_id']?.toString();
      if (machineId != null && machineId.isNotEmpty) {
        try {
          await apiService.updateMachineStatus(machineId, 'RUNNING', reason: 'Maintenance completed');
        } catch (_) {}
      }

      // 3. Log maintenance history
      try {
        final historyId = 'mh_${now}_${widget.orderId.substring(0, widget.orderId.length.clamp(0, 6))}';
        await apiService.createCollectionItem('maintenance_history', {
          '_id': historyId,
          'id': historyId,
          'machine_id': machineId ?? '',
          'maintenance_order_id': widget.orderId,
          'performed_at': now,
          'summary': actionTaken,
          'created_at': now,
        });
      } catch (_) {}

      // 4. Log activity history
      try {
        await apiService.createCollectionItem('activity_history', {
          'event_type': 'MAINTENANCE_COMPLETED',
          'title': 'Maintenance completed',
          'description': actionTaken,
          'reference_type': 'maintenance_order',
          'reference_id': widget.orderId,
          'timestamp': now,
          'created_at': now,
        });
      } catch (_) {}

      ref.invalidate(maintenanceOrdersProvider);
      ref.invalidate(maintenanceHistoryProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maintenance ticket marked as completed!'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
        _loadTicketDetails();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing ticket: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _confirmDeleteTicket() {
    final orderNum = _order?['order_number']?.toString() ?? widget.orderId;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24),
            SizedBox(width: 8),
            Text('Delete Ticket'),
          ],
        ),
        content: Text('Are you sure you want to delete maintenance ticket $orderNum? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteTicket();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTicket() async {
    setState(() => _submitting = true);
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.deleteCollectionItem('maintenance_orders', widget.orderId);

      // Log deletion activity
      try {
        await apiService.createCollectionItem('activity_history', {
          'event_type': 'MAINTENANCE_DELETED',
          'title': 'Maintenance order deleted',
          'description': widget.orderId,
          'reference_type': 'maintenance_order',
          'reference_id': widget.orderId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        });
      } catch (_) {}

      ref.invalidate(maintenanceOrdersProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maintenance ticket deleted successfully.')),
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/maintenance');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete ticket: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _onBackPress() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/maintenance');
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final orderNumber = order?['order_number']?.toString() ?? 'Ticket: ${widget.orderId}';
    final machineCode = order?['machine_code']?.toString() ?? order?['machine_name']?.toString() ?? order?['machine_id']?.toString() ?? 'Machine';
    final type = (order?['type']?.toString() ?? order?['order_type']?.toString() ?? 'PREVENTIVE').toUpperCase();
    final status = (order?['status']?.toString() ?? 'OPEN').toUpperCase();
    final priority = (order?['priority']?.toString() ?? 'MEDIUM').toUpperCase();
    final issue = order?['issue']?.toString() ?? order?['description']?.toString() ?? '';
    final assignedTeam = order?['assigned_team']?.toString() ?? order?['assigned_to']?.toString();
    final actionTaken = order?['action_taken']?.toString();
    final rootCause = order?['root_cause']?.toString();

    final isCompleted = status == 'COMPLETED';
    final isBreakdown = type == 'BREAKDOWN';

    // Priority color
    Color priorityColor = const Color(0xFF2563EB);
    if (priority == 'CRITICAL' || priority == 'HIGH') priorityColor = const Color(0xFFDC2626);
    if (priority == 'LOW') priorityColor = const Color(0xFF16A34A);
    if (priority == 'MEDIUM') priorityColor = const Color(0xFF2563EB);

    final timestamp = (order?['created_at']) as num?;
    String dateStr = 'Recently logged';
    if (timestamp != null && timestamp > 0) {
      dateStr = Formatters.formatDateTime(DateTime.fromMillisecondsSinceEpoch(timestamp.toInt()));
    }

    final completedTimestamp = (order?['completed_at']) as num?;
    String completedDateStr = '';
    if (completedTimestamp != null && completedTimestamp > 0) {
      completedDateStr = Formatters.formatDateTime(DateTime.fromMillisecondsSinceEpoch(completedTimestamp.toInt()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1E38),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
          tooltip: 'Back to Maintenance',
          onPressed: _onBackPress,
        ),
        title: Text(
          orderNumber,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 22),
            tooltip: 'Refresh',
            onPressed: _loadTicketDetails,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFFCA5A5), size: 22),
            tooltip: 'Delete Ticket',
            onPressed: _confirmDeleteTicket,
          ),
        ],
      ),
      body: _loading
          ? const MaintenanceDetailShimmer()
          : order == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Color(0xFFDC2626)),
                      const SizedBox(height: 12),
                      Text('Ticket "${widget.orderId}" not found', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _onBackPress,
                        child: const Text('Back to Maintenance'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Card
                      Container(
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        orderNumber,
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.precision_manufacturing_outlined, size: 16, color: Color(0xFF64748B)),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Machine: $machineCode',
                                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    // Status Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isCompleted ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: isCompleted ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A)),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: isCompleted ? const Color(0xFF15803D) : const Color(0xFFB45309),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    // Type Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isBreakdown ? const Color(0xFFFEE2E2) : const Color(0xFFE0F2FE),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        type,
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          color: isBreakdown ? const Color(0xFFDC2626) : const Color(0xFF0369A1),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Text('Priority: ', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: priorityColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        priority,
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: priorityColor),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  dateStr,
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                            if (assignedTeam != null && assignedTeam.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.group_outlined, size: 14, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Assigned: $assignedTeam',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Reported Issue Box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.report_problem_outlined, color: Color(0xFFD97706), size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Reported Issue / Fault Description',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              issue.isNotEmpty ? issue : 'No detailed fault description logged.',
                              style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Resolution Block (Completed vs In Progress Form)
                      if (isCompleted)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Maintenance Completed',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text('Action Taken:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF166534))),
                              const SizedBox(height: 2),
                              Text(
                                actionTaken ?? 'Issue resolved and verified.',
                                style: const TextStyle(fontSize: 13.5, color: Color(0xFF14532D)),
                              ),
                              if (rootCause != null && rootCause.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                const Text('Root Cause:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF166534))),
                                const SizedBox(height: 2),
                                Text(
                                  rootCause,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF14532D), fontStyle: FontStyle.italic),
                                ),
                              ],
                              if (completedDateStr.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  'Completed at: $completedDateStr',
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF166534)),
                                ),
                              ],
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.build_circle_outlined, color: Color(0xFF0284C7), size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Complete Maintenance Order',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              const Text(
                                'Root Cause (Optional)',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _rootCauseController,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Bearing wear and tear, loose wiring',
                                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                              const SizedBox(height: 14),

                              const Text(
                                'Action Taken *',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _actionController,
                                maxLines: 2,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Replaced bearing, lubricated rotor, recalibrated sensors',
                                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                              const SizedBox(height: 14),

                              const Text(
                                'Parts Used (Optional)',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _partsUsedController,
                                decoration: InputDecoration(
                                  hintText: 'e.g. SKF 6204 Bearing (1x), Lubricant grease 200g',
                                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                              const SizedBox(height: 18),

                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: FilledButton.icon(
                                  onPressed: _submitting ? null : _completeMaintenance,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF0284C7),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: _submitting
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Icon(Icons.check, size: 18),
                                  label: Text(
                                    _submitting ? 'Submitting...' : 'Complete Maintenance',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),

                      // Danger Delete Button
                      OutlinedButton.icon(
                        onPressed: _submitting ? null : _confirmDeleteTicket,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          side: const BorderSide(color: Color(0xFFFECACA)),
                          backgroundColor: const Color(0xFFFEF2F2),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text(
                          'Delete Ticket',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }
}
