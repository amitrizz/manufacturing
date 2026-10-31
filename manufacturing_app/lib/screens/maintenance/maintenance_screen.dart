import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../utils/formatters.dart';
import '../../widgets/shimmers/index.dart';

class MaintenanceScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;
  const MaintenanceScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen> {
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _machines = [];

  String _searchQuery = '';
  String _selectedFilter = 'ALL'; // ALL, OPEN, BREAKDOWN, PREVENTIVE, CORRECTIVE, COMPLETED
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
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

      // Fetch machines and maintenance orders concurrently
      final results = await Future.wait([
        apiService.getCollection('maintenance_orders', queryParams: {'limit': 200}).then((r) => r.data).catchError((_) => <Map<String, dynamic>>[]),
        apiService.getCollection('machines', queryParams: {'limit': 100}).then((r) => r.data).catchError((_) => <Map<String, dynamic>>[]),
      ]);

      final rawOrders = results[0];
      final machineList = results[1];

      // Build machine lookup map
      final machineMap = <String, Map<String, dynamic>>{};
      for (final m in machineList) {
        final id = m['id']?.toString() ?? m['_id']?.toString() ?? '';
        if (id.isNotEmpty) machineMap[id] = m;
      }

      // Enrich orders with machine code if missing
      final enrichedOrders = rawOrders.map((o) {
        final mId = o['machine_id']?.toString() ?? '';
        final m = machineMap[mId];
        final existingCode = o['machine_code']?.toString() ?? '';
        return {
          ...o,
          'id': o['id'] ?? o['_id'] ?? '',
          'machine_code': existingCode.isNotEmpty ? existingCode : (m?['code'] ?? m?['name'] ?? mId),
          'machine_name': m?['name'] ?? '',
        };
      }).toList();

      // Sort newest first
      enrichedOrders.sort((a, b) {
        final tA = (a['created_at'] ?? 0) as num;
        final tB = (b['created_at'] ?? 0) as num;
        return tB.compareTo(tA);
      });

      if (mounted) {
        setState(() {
          _orders = enrichedOrders;
          _machines = machineList;
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

  // Filtered orders
  List<Map<String, dynamic>> get _filteredOrders {
    return _orders.where((o) {
      // Filter tab
      final status = (o['status']?.toString() ?? 'OPEN').toUpperCase();
      final type = (o['type']?.toString() ?? o['order_type']?.toString() ?? 'PREVENTIVE').toUpperCase();

      if (_selectedFilter == 'OPEN' && status == 'COMPLETED') return false;
      if (_selectedFilter == 'COMPLETED' && status != 'COMPLETED') return false;
      if (_selectedFilter == 'BREAKDOWN' && type != 'BREAKDOWN') return false;
      if (_selectedFilter == 'PREVENTIVE' && type != 'PREVENTIVE') return false;
      if (_selectedFilter == 'CORRECTIVE' && type != 'CORRECTIVE') return false;

      // Search query
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final num = (o['order_number']?.toString() ?? '').toLowerCase();
        final mCode = (o['machine_code']?.toString() ?? '').toLowerCase();
        final issue = (o['issue']?.toString() ?? o['description']?.toString() ?? '').toLowerCase();
        return num.contains(q) || mCode.contains(q) || issue.contains(q);
      }

      return true;
    }).toList();
  }

  int get _openCount => _orders.where((o) => (o['status']?.toString() ?? '').toUpperCase() != 'COMPLETED').length;
  int get _breakdownCount => _orders.where((o) => (o['type']?.toString() ?? '').toUpperCase() == 'BREAKDOWN').length;
  int get _completedCount => _orders.where((o) => (o['status']?.toString() ?? '').toUpperCase() == 'COMPLETED').length;

  void _onBackPress() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/management');
    }
  }

  void _showCreateOrderModal() {
    if (_machines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No machines found. Please create or configure a machine first.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => _NewTicketSheet(
        machines: _machines,
        existingCount: _orders.length,
        onCreated: _loadData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filteredOrders;

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
          'Machine Maintenance',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 22),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: _showCreateOrderModal,
              icon: const Icon(Icons.add, size: 18, color: Colors.white),
              label: const Text(
                'New Ticket',
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

              // Search Bar
              _buildSearchBar(),
              const SizedBox(height: 12),

              // Filter Chips
              _buildFilterChips(),
              const SizedBox(height: 16),

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
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12),
                        ),
                      ),
                      TextButton(
                        onPressed: _loadData,
                        child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Orders List
              if (_loading && _orders.isEmpty)
                AppShimmer(
                  child: Column(
                    children: List.generate(4, (_) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ShimmerBox(width: 90, height: 16, borderRadius: 4),
                              ShimmerBox(width: 65, height: 18, borderRadius: 10),
                            ],
                          ),
                          SizedBox(height: 8),
                          ShimmerBox(width: 220, height: 17, borderRadius: 4),
                          SizedBox(height: 6),
                          ShimmerBox(width: 170, height: 13, borderRadius: 4),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  ShimmerBox(width: 22, height: 22, borderRadius: 11),
                                  SizedBox(width: 6),
                                  ShimmerBox(width: 80, height: 12, borderRadius: 4),
                                ],
                              ),
                              ShimmerBox(width: 85, height: 28, borderRadius: 6),
                            ],
                          ),
                        ],
                      ),
                    )),
                  ),
                )
              else if (filtered.isEmpty)
                _buildEmptyState()
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _buildTicketCard(item);
                  },
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // Header Summary Banner
  Widget _buildHeaderBanner() {
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
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Icon(Icons.build_rounded, color: Color(0xFF0284C7), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Maintenance Tickets',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_orders.length} tickets total • $_openCount open • $_breakdownCount breakdowns',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildMiniBadge('$_openCount Open', const Color(0xFFFEF3C7), const Color(0xFFB45309)),
              const SizedBox(width: 6),
              _buildMiniBadge('$_completedCount Done', const Color(0xFFDCFCE7), const Color(0xFF15803D)),
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

  // Search Bar
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'Search tickets by order #, machine, or fault...',
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
    );
  }

  // Filter Chips Row
  Widget _buildFilterChips() {
    final filters = ['ALL', 'OPEN', 'BREAKDOWN', 'PREVENTIVE', 'CORRECTIVE', 'COMPLETED'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              selected: isSelected,
              label: Text(
                f,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
              selectedColor: const Color(0xFF0A1E38),
              backgroundColor: Colors.white,
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF0A1E38) : const Color(0xFFE2E8F0),
                ),
              ),
              onSelected: (_) => setState(() => _selectedFilter = f),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Single Ticket Card (matching frontend MaintenanceScreen.tsx)
  Widget _buildTicketCard(Map<String, dynamic> item) {
    final ticketId = item['id']?.toString() ?? item['_id']?.toString() ?? '';
    final orderNumber = item['order_number']?.toString() ?? 'MNT-${ticketId.substring(0, ticketId.length.clamp(0, 6))}';
    final machineCode = item['machine_code']?.toString() ?? 'Machine';
    final type = (item['type']?.toString() ?? item['order_type']?.toString() ?? 'PREVENTIVE').toUpperCase();
    final status = (item['status']?.toString() ?? 'OPEN').toUpperCase();
    final priority = (item['priority']?.toString() ?? 'MEDIUM').toUpperCase();
    final issue = item['issue']?.toString() ?? item['description']?.toString() ?? '';

    final isCompleted = status == 'COMPLETED';
    final isBreakdown = type == 'BREAKDOWN';

    final timestamp = (item['created_at']) as num?;
    String dateStr = 'Recently logged';
    if (timestamp != null && timestamp > 0) {
      dateStr = Formatters.formatDateTime(DateTime.fromMillisecondsSinceEpoch(timestamp.toInt()));
    }

    return InkWell(
      onTap: () => context.push('/maintenance/$ticketId'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
            // Top Row: Order Number & Machine Code + Badges
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        orderNumber,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Machine: $machineCode',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
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
                    const SizedBox(width: 6),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isCompleted ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: isCompleted ? const Color(0xFF15803D) : const Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Issue Text
            if (issue.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                issue,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.3),
              ),
            ],

            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 8),

            // Footer Row: Priority and Created Timestamp
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Priority: $priority',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: (priority == 'CRITICAL' || priority == 'HIGH')
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF64748B),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      dateStr,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 16, color: Color(0xFFCBD5E1)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Icon(Icons.build_outlined, size: 40, color: Color(0xFF94A3B8)),
          SizedBox(height: 12),
          Text(
            'No Maintenance Tickets Found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          SizedBox(height: 6),
          Text(
            'No tickets match the selected filter. Click "+ New Ticket" to log a maintenance order.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

// Modal Sheet for New Maintenance Ticket (Clean Sub-Widget)
class _NewTicketSheet extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> machines;
  final int existingCount;
  final VoidCallback onCreated;

  const _NewTicketSheet({
    required this.machines,
    required this.existingCount,
    required this.onCreated,
  });

  @override
  ConsumerState<_NewTicketSheet> createState() => _NewTicketSheetState();
}

class _NewTicketSheetState extends ConsumerState<_NewTicketSheet> {
  late String _selectedMachineId;
  String _orderType = 'PREVENTIVE';
  String _priority = 'MEDIUM';
  final _issueController = TextEditingController();
  final _teamController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedMachineId = widget.machines.isNotEmpty
        ? (widget.machines.first['id']?.toString() ?? widget.machines.first['_id']?.toString() ?? '')
        : '';
  }

  @override
  void dispose() {
    _issueController.dispose();
    _teamController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final issueText = _issueController.text.trim();
    if (_selectedMachineId.isEmpty || issueText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a machine and enter an issue description.'),
          backgroundColor: Color(0xFFD97706),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final apiService = ref.read(apiServiceProvider);
      final now = DateTime.now().millisecondsSinceEpoch;
      final seq = (widget.existingCount + 1).toString().padLeft(4, '0');
      final orderNumber = 'MNT-$seq';
      final ticketId = 'mnt_${now}_$seq';

      // Create maintenance order in MongoDB
      await apiService.createCollectionItem('maintenance_orders', {
        '_id': ticketId,
        'id': ticketId,
        'order_number': orderNumber,
        'machine_id': _selectedMachineId,
        'type': _orderType,
        'issue': issueText,
        'priority': _priority,
        'assigned_team': _teamController.text.trim().isNotEmpty ? _teamController.text.trim() : null,
        'status': 'OPEN',
        'created_at': now,
        'updated_at': now,
      });

      // If BREAKDOWN, update machine status
      if (_orderType == 'BREAKDOWN') {
        try {
          await apiService.updateMachineStatus(_selectedMachineId, 'BREAKDOWN', reason: issueText);
        } catch (_) {}
      }

      // Activity Log
      try {
        await apiService.createCollectionItem('activity_history', {
          'event_type': 'MAINTENANCE_CREATED',
          'title': 'Maintenance order $orderNumber created',
          'description': issueText,
          'reference_type': 'maintenance_order',
          'reference_id': ticketId,
          'timestamp': now,
          'created_at': now,
        });
      } catch (_) {}

      ref.invalidate(maintenanceOrdersProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Maintenance ticket $orderNumber created successfully!'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
        widget.onCreated();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create ticket: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                const Text(
                  'New Maintenance Ticket',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Machine Selector
            const Text(
              'Select Machine *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.machines.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, idx) {
                  final m = widget.machines[idx];
                  final id = m['id']?.toString() ?? m['_id']?.toString() ?? '';
                  final isSelected = _selectedMachineId == id;
                  final code = m['code'] ?? 'MCH';
                  final name = m['name'] ?? '';
                  return InkWell(
                    onTap: () => setState(() => _selectedMachineId = id),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0A1E38) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0A1E38) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        '$code ($name)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // Ticket Type Selector
            const Text(
              'Ticket Type *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 6),
            Row(
              children: ['PREVENTIVE', 'CORRECTIVE', 'BREAKDOWN'].map((t) {
                final isSelected = _orderType == t;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _orderType = t),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (t == 'BREAKDOWN' ? const Color(0xFFDC2626) : const Color(0xFF0A1E38))
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? (t == 'BREAKDOWN' ? const Color(0xFFDC2626) : const Color(0xFF0A1E38))
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        t,
                        style: TextStyle(
                          fontSize: 11.5,
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

            // Priority Selector
            const Text(
              'Priority *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 6),
            Row(
              children: ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'].map((p) {
                final isSelected = _priority == p;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _priority = p),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0A1E38) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0A1E38) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        p,
                        style: TextStyle(
                          fontSize: 11.5,
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

            // Issue Description
            const Text(
              'Issue / Fault Description *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _issueController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Describe machine issue or reason for maintenance',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 14),

            // Assigned Team / Technician
            const Text(
              'Assigned Team / Technician (Optional)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _teamController,
              decoration: InputDecoration(
                hintText: 'e.g. Electrical Team, Mech Team, Rahul (Technician)',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _submitting ? null : () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _submitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Create Ticket', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}