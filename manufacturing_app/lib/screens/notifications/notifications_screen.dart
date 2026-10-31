import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../widgets/shimmers/index.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _filter = 'all'; // 'all', 'unread', 'critical', 'warning'
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      final response = await api.getCollection('notifications', queryParams: {'limit': 100});
      var list = List<Map<String, dynamic>>.from(response.data);

      // Auto-seed demo alerts if empty so the user can immediately test!
      if (list.isEmpty) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final demoAlerts = [
          {
            'title': 'Machine Breakdown Reported',
            'body': 'CNC Milling Station CNC-01 reported high temperature shutdown. Operator assigned maintenance request.',
            'severity': 'CRITICAL',
            'type': 'CRITICAL',
            'reference_type': 'machine',
            'reference_id': 'mach-cnc-01',
            'is_read': 0,
            'created_at': now - 1000 * 60 * 12, // 12 mins ago
          },
          {
            'title': 'Raw Material Low Stock Warning',
            'body': 'Aluminum Ingot 6061 is below reorder threshold (12 pcs remaining, minimum is 20 pcs). Purchase requisition advised.',
            'severity': 'WARNING',
            'type': 'WARNING',
            'reference_type': 'material',
            'reference_id': 'mat-001',
            'is_read': 0,
            'created_at': now - 1000 * 60 * 45, // 45 mins ago
          },
          {
            'title': 'Defective Parts Sent to Rework Queue',
            'body': 'Order ORD-9021 failed QC dimension test (5 parts out of tolerance). Rework order RWK-104 initiated.',
            'severity': 'WARNING',
            'type': 'WARNING',
            'reference_type': 'quality',
            'reference_id': 'ORD-9021',
            'is_read': 0,
            'created_at': now - 1000 * 60 * 120, // 2 hours ago
          },
          {
            'title': 'Dispatch Challan Ready for Shipment',
            'body': 'Delivery Challan DSP-1001 for Tata Motors Ltd has been packed and verified. Awaiting transport departure.',
            'severity': 'INFO',
            'type': 'INFO',
            'reference_type': 'dispatch',
            'reference_id': 'DSP-1001',
            'is_read': 1,
            'created_at': now - 1000 * 60 * 360, // 6 hours ago
          },
        ];

        for (final a in demoAlerts) {
          try {
            final res = await api.createCollectionItem('notifications', a);
            list.add(res);
          } catch (_) {}
        }
      }

      // Sort newest first
      list.sort((a, b) {
        final ta = (a['created_at'] as num?)?.toInt() ?? 0;
        final tb = (b['created_at'] as num?)?.toInt() ?? 0;
        return tb.compareTo(ta);
      });

      if (mounted) {
        setState(() {
          _notifications = list;
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

  void _onBackPress() {
    if (Navigator.of(context).canPop()) {
      context.pop();
    } else {
      context.go('/management');
    }
  }

  Future<void> _markAllRead() async {
    final unread = _notifications.where((n) => n['is_read'] != 1).toList();
    if (unread.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications are already marked as read.')),
      );
      return;
    }

    try {
      final api = ref.read(apiServiceProvider);
      final now = DateTime.now().millisecondsSinceEpoch;
      await Future.wait(
        unread.map((n) {
          final id = (n['id'] ?? n['_id'])?.toString();
          if (id != null) {
            return api.updateCollectionItem('notifications', id, {
              'is_read': 1,
              'updated_at': now,
            }).then<Map<String, dynamic>>((val) => val).catchError((_) => <String, dynamic>{});
          }
          return Future.value(<String, dynamic>{});
        }),
      );

      if (!mounted) return;
      setState(() {
        for (final n in _notifications) {
          n['is_read'] = 1;
        }
      });

      ref.invalidate(notificationsProvider);
      ref.invalidate(dashboardProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read.'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleNotificationTap(Map<String, dynamic> notif) async {
    final id = (notif['id'] ?? notif['_id'])?.toString();
    final isRead = notif['is_read'] == 1;

    // Mark as read in background if unread
    if (!isRead && id != null) {
      try {
        final api = ref.read(apiServiceProvider);
        await api.updateCollectionItem('notifications', id, {
          'is_read': 1,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });
        if (mounted) {
          setState(() {
            notif['is_read'] = 1;
          });
        }
        ref.invalidate(notificationsProvider);
        ref.invalidate(dashboardProvider);
      } catch (_) {}
    }

    if (!mounted) return;

    // Navigate to reference
    final refType = notif['reference_type']?.toString().toLowerCase();
    final refId = notif['reference_id']?.toString();

    if (refType == 'machine') {
      if (refId != null && refId.isNotEmpty) {
        context.push('/machines/$refId');
      } else {
        context.push('/machines');
      }
    } else if (refType == 'material') {
      context.push('/inventory/materials');
    } else if (refType == 'order' || refType == 'production') {
      context.push('/production/orders');
    } else if (refType == 'quality' || refType == 'rework') {
      context.push('/quality/inspections');
    } else if (refType == 'maintenance') {
      context.push('/maintenance');
    } else if (refType == 'dispatch') {
      context.push('/dispatch/orders');
    } else {
      // Default info dialog if no specific entity
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(notif['title']?.toString() ?? 'Notification Details'),
          content: Text(notif['body']?.toString() ?? notif['message']?.toString() ?? ''),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  Future<void> _deleteNotification(Map<String, dynamic> notif) async {
    final id = (notif['id'] ?? notif['_id'])?.toString();
    if (id == null) return;

    try {
      final api = ref.read(apiServiceProvider);
      await api.deleteCollectionItem('notifications', id);
      setState(() {
        _notifications.removeWhere((n) => (n['id'] ?? n['_id'])?.toString() == id);
      });
      ref.invalidate(notificationsProvider);
      ref.invalidate(dashboardProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification dismissed.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _createSimulatedAlert() async {
    final types = ['CRITICAL', 'WARNING', 'INFO'];
    final titles = [
      'Motor Current Spike on Press PR-02',
      'Hydraulic Oil Level Below Safe Threshold',
      'Material Shortage: Copper Coil 2.5mm',
      'Batch Quality Audit Completed (98.5% Pass)',
      'Scheduled Preventive Maintenance Due in 24h',
    ];

    final now = DateTime.now().millisecondsSinceEpoch;
    final randomTitle = titles[now % titles.length];
    final randomType = types[now % types.length];

    try {
      final api = ref.read(apiServiceProvider);
      final created = await api.createCollectionItem('notifications', {
        'title': randomTitle,
        'body': 'Automated telemetry alert generated by plant sensors at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}.',
        'severity': randomType,
        'type': randomType,
        'reference_type': 'machine',
        'is_read': 0,
        'created_at': now,
        'updated_at': now,
      });

      setState(() {
        _notifications.insert(0, created);
      });

      ref.invalidate(notificationsProvider);
      ref.invalidate(dashboardProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Simulated alert added: "$randomTitle"'),
            backgroundColor: const Color(0xFF0284C7),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate alert: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatTimeAgo(dynamic timestamp) {
    if (timestamp == null) return '';
    final num? ms = timestamp is num ? timestamp : num.tryParse(timestamp.toString());
    if (ms == null) return '';

    final diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms.toInt()));
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final unreadCount = _notifications.where((n) => n['is_read'] != 1).length;
    final criticalCount = _notifications.where((n) {
      final s = (n['severity'] ?? n['type'])?.toString().toUpperCase();
      return s == 'CRITICAL' || s == 'ALERT';
    }).length;
    final warningCount = _notifications.where((n) {
      final s = (n['severity'] ?? n['type'])?.toString().toUpperCase();
      return s == 'WARNING';
    }).length;

    // Filter items
    var displayList = _notifications;
    if (_filter == 'unread') {
      displayList = _notifications.where((n) => n['is_read'] != 1).toList();
    } else if (_filter == 'critical') {
      displayList = _notifications.where((n) {
        final s = (n['severity'] ?? n['type'])?.toString().toUpperCase();
        return s == 'CRITICAL' || s == 'ALERT';
      }).toList();
    } else if (_filter == 'warning') {
      displayList = _notifications.where((n) {
        final s = (n['severity'] ?? n['type'])?.toString().toUpperCase();
        return s == 'WARNING';
      }).toList();
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1E38),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
          tooltip: 'Back to Management',
          onPressed: _onBackPress,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alerts & Notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            Text(
              'Real-time plant alarms & audit events',
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Colors.white, size: 20),
            tooltip: 'Mark All Read',
            onPressed: _markAllRead,
          ),
          IconButton(
            icon: const Icon(Icons.add_alert_outlined, color: Colors.white, size: 20),
            tooltip: 'Simulate Test Alert',
            onPressed: _createSimulatedAlert,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
            tooltip: 'Refresh Alerts',
            onPressed: _loadNotifications,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Top KPI Banner
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: _buildKpiTile(
                    label: 'TOTAL ALERTS',
                    value: '${_notifications.length}',
                    color: const Color(0xFF0284C7),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildKpiTile(
                    label: 'UNREAD',
                    value: '$unreadCount',
                    color: unreadCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF10B981),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildKpiTile(
                    label: 'CRITICAL',
                    value: '$criticalCount',
                    color: const Color(0xFFDC2626),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildKpiTile(
                    label: 'WARNINGS',
                    value: '$warningCount',
                    color: const Color(0xFFD97706),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Filter Segment Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All (${_notifications.length})', _filter == 'all', () {
                    setState(() => _filter = 'all');
                  }),
                  const SizedBox(width: 8),
                  _buildFilterChip('Unread ($unreadCount)', _filter == 'unread', () {
                    setState(() => _filter = 'unread');
                  }),
                  const SizedBox(width: 8),
                  _buildFilterChip('Critical ($criticalCount)', _filter == 'critical', () {
                    setState(() => _filter = 'critical');
                  }),
                  const SizedBox(width: 8),
                  _buildFilterChip('Warnings ($warningCount)', _filter == 'warning', () {
                    setState(() => _filter = 'warning');
                  }),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Notifications List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadNotifications,
              child: _loading
                  ? const NotificationsScreenShimmer()
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                                const SizedBox(height: 12),
                                Text('Error loading alerts: $_error', textAlign: TextAlign.center),
                                const SizedBox(height: 16),
                                FilledButton(onPressed: _loadNotifications, child: const Text('Retry')),
                              ],
                            ),
                          ),
                        )
                      : displayList.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.verified_user_outlined, size: 48, color: Color(0xFF10B981)),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'All Systems Normal',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _filter != 'all'
                                        ? 'No notifications match the "$_filter" filter.'
                                        : 'No active breakdown or critical plant alarms.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  OutlinedButton.icon(
                                    onPressed: _createSimulatedAlert,
                                    icon: const Icon(Icons.add_alert_outlined, size: 16),
                                    label: const Text('Simulate Test Alert'),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: displayList.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final notif = displayList[index];
                                return _buildNotificationCard(notif, isDark);
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiTile({
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notif, bool isDark) {
    final title = notif['title']?.toString() ?? 'System Notification';
    final body = notif['body']?.toString() ?? notif['message']?.toString() ?? '';
    final severity = (notif['severity'] ?? notif['type'] ?? 'INFO').toString().toUpperCase();
    final isRead = notif['is_read'] == 1;
    final timeStr = _formatTimeAgo(notif['created_at']);
    final refType = notif['reference_type']?.toString();

    Color accentColor = const Color(0xFF0284C7);
    IconData iconData = Icons.info_outline;

    if (severity == 'CRITICAL' || severity == 'ALERT') {
      accentColor = const Color(0xFFDC2626);
      iconData = Icons.error_outline;
    } else if (severity == 'WARNING') {
      accentColor = const Color(0xFFD97706);
      iconData = Icons.warning_amber_rounded;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: !isRead
              ? accentColor.withValues(alpha: 0.8)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: !isRead ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _handleNotificationTap(notif),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Container
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(iconData, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),

              // Title, Body, Metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: !isRead ? FontWeight.w800 : FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            margin: const EdgeInsets.only(left: 6, top: 2),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Bottom Row: Time and Deep Link hint
                    Row(
                      children: [
                        if (timeStr.isNotEmpty) ...[
                          Icon(Icons.access_time, size: 12, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (refType != null && refType.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Open ${refType.toUpperCase()} →',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Dismiss Button
              IconButton(
                icon: const Icon(Icons.close, size: 16, color: Color(0xFF94A3B8)),
                tooltip: 'Dismiss alert',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _deleteNotification(notif),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
