import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../widgets/shimmers/index.dart';
import '../../constants/permissions.dart';

// =============================================================================
// Roles & Access Control Screen
// =============================================================================

class RolesScreen extends ConsumerStatefulWidget {
  const RolesScreen({super.key});

  @override
  ConsumerState<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends ConsumerState<RolesScreen> {
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _roles = [];

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      final response = await api.getCollection('company_roles', queryParams: {'limit': 100});
      var list = List<Map<String, dynamic>>.from(response.data);

      // Auto-seed if empty
      if (list.isEmpty) {
        final now = DateTime.now().millisecondsSinceEpoch;
        for (final r in kStandardCompanyRoles) {
          try {
            final res = await api.createCollectionItem('company_roles', {
              'name': r['name'],
              'description': r['description'],
              'permissions': r['permissions'],
              'is_system': 1,
              'created_at': now,
              'updated_at': now,
            });
            list.add(res);
          } catch (_) {}
        }
      }

      if (mounted) {
        setState(() {
          _roles = list;
          _loading = false;
        });
        ref.read(companyRolesProvider.notifier).setRoles(list);
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

  void _openRoleForm({Map<String, dynamic>? existingRole}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RoleFormSheet(
        existingRole: existingRole,
        onSaved: () {
          _loadRoles();
        },
      ),
    );
  }

  void _confirmDeleteRole(Map<String, dynamic> role) {
    final roleName = role['name']?.toString() ?? 'Custom Role';
    final roleId = (role['id'] ?? role['_id'])?.toString();

    if (role['is_system'] == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot delete system role "$roleName".'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Role "$roleName"?'),
        content: const Text(
          'Are you sure you want to delete this custom role? Staff members assigned to this role may lose access permissions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () async {
              Navigator.pop(ctx);
              if (roleId == null) return;
              try {
                final api = ref.read(apiServiceProvider);
                await api.deleteCollectionItem('company_roles', roleId);
                await ref.read(companyRolesProvider.notifier).loadRoles();
                _loadRoles();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Role "$roleName" deleted successfully.'),
                      backgroundColor: const Color(0xFF16A34A),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete role: $e'),
                      backgroundColor: const Color(0xFFDC2626),
                    ),
                  );
                }
              }
            },
            child: const Text('Delete Role'),
          ),
        ],
      ),
    );
  }

  void _startRolePreview(Map<String, dynamic> role) {
    final roleName = role['name']?.toString() ?? 'Role';
    final rawPerms = role['permissions'];
    final perms = rawPerms is List ? rawPerms.map((e) => e.toString()).toList() : <String>[];

    ref.read(rolePreviewProvider.notifier).startPreview(roleName, perms);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.remove_red_eye_outlined, color: Color(0xFFD97706), size: 24),
            const SizedBox(width: 8),
            Text('Viewing as "$roleName"'),
          ],
        ),
        content: Text(
          'You are now previewing the mobile interface as "$roleName".\n\n'
          '• Home & Management modules are filtered for this role\n'
          '• Tasks tab reflects authorized activities\n'
          '• Tap "Exit Preview" in the top banner anytime to return.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Stay on Roles'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/dashboard');
            },
            child: const Text('Go to Home Screen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewState = ref.watch(rolePreviewProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final systemCount = _roles.where((r) => r['is_system'] == 1).length;
    final customCount = _roles.where((r) => r['is_system'] != 1).length;

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
              'Roles & Access Control',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            Text(
              'Configure RBAC permissions & role preview',
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
            tooltip: 'Refresh Roles',
            onPressed: _loadRoles,
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => _openRoleForm(),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New Role', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // Active Role Preview Banner
          if (previewState.isPreviewing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFFFEF3C7),
              child: Row(
                children: [
                  const Icon(Icons.visibility, size: 18, color: Color(0xFFD97706)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Previewing as: ${previewState.roleName} (${previewState.permissions.length} perms)',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      ref.read(rolePreviewProvider.notifier).exitPreview();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Exited Role Preview. Back to Admin view.')),
                      );
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.close, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Exit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Top KPI Summary Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: _buildKpiTile(
                    label: 'TOTAL ROLES',
                    value: '${_roles.length}',
                    color: const Color(0xFF0284C7),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildKpiTile(
                    label: 'SYSTEM ROLES',
                    value: '$systemCount',
                    color: const Color(0xFF10B981),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildKpiTile(
                    label: 'CUSTOM ROLES',
                    value: '$customCount',
                    color: const Color(0xFF7C3AED),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildKpiTile(
                    label: 'PERMISSIONS',
                    value: '${kAvailablePermissions.length}',
                    color: const Color(0xFFD97706),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Roles List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadRoles,
              child: _loading
                  ? const RolesScreenShimmer()
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                                const SizedBox(height: 12),
                                Text('Error loading roles: $_error', textAlign: TextAlign.center),
                                const SizedBox(height: 16),
                                FilledButton(onPressed: _loadRoles, child: const Text('Retry')),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _roles.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final role = _roles[index];
                            return _buildRoleCard(role, isDark);
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

  Widget _buildRoleCard(Map<String, dynamic> role, bool isDark) {
    final name = role['name']?.toString() ?? 'Unnamed Role';
    final desc = role['description']?.toString();
    final isSystem = role['is_system'] == 1;
    final rawPerms = role['permissions'];
    final perms = rawPerms is List ? rawPerms.map((e) => e.toString()).toList() : <String>[];

    final opsPerms = perms.where((p) => p.startsWith('home_')).length;
    final taskPerms = perms.where((p) => p.startsWith('tasks_')).length;
    final mgmtPerms = perms.where((p) => p.startsWith('mgmt_')).length;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Role Name, Badge, Actions
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
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSystem ? const Color(0xFFEFF6FF) : const Color(0xFFF5F3FF),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isSystem ? const Color(0xFFBFDBFE) : const Color(0xFFDDD6FE),
                              ),
                            ),
                            child: Text(
                              isSystem ? 'SYSTEM' : 'CUSTOM',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: isSystem ? const Color(0xFF1D4ED8) : const Color(0xFF6D28D9),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (desc != null && desc.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          desc,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit Permissions',
                      onPressed: () => _openRoleForm(existingRole: role),
                    ),
                    if (!isSystem)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                        tooltip: 'Delete Role',
                        onPressed: () => _confirmDeleteRole(role),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Permission Summary Chips
            Row(
              children: [
                _buildSummaryBadge(
                  icon: Icons.precision_manufacturing_outlined,
                  label: '$opsPerms Ops',
                  color: const Color(0xFF0284C7),
                ),
                const SizedBox(width: 8),
                _buildSummaryBadge(
                  icon: Icons.checklist_rtl_outlined,
                  label: '$taskPerms Tasks',
                  color: const Color(0xFF15803D),
                ),
                const SizedBox(width: 8),
                _buildSummaryBadge(
                  icon: Icons.business_center_outlined,
                  label: '$mgmtPerms Mgmt',
                  color: const Color(0xFF7C3AED),
                ),
                const Spacer(),
                Text(
                  '${perms.length} of ${kAvailablePermissions.length} perms',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Permission Pills preview
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...perms.take(5).map((pKey) {
                  final perm = kAvailablePermissions.firstWhere(
                    (p) => p.key == pKey,
                    orElse: () => PermissionItem(key: pKey, label: pKey, description: '', category: 'home'),
                  );
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      perm.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                      ),
                    ),
                  );
                }),
                if (perms.length > 5)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '+${perms.length - 5} more',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Card Footer: "View as this role" action button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF0284C7)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _startRolePreview(role),
                icon: const Icon(Icons.remove_red_eye_outlined, size: 16, color: Color(0xFF0284C7)),
                label: Text(
                  'Preview app as "$name"',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0284C7),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Create & Edit Role Modal Sheet
// =============================================================================

class _RoleFormSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existingRole;
  final VoidCallback onSaved;

  const _RoleFormSheet({
    this.existingRole,
    required this.onSaved,
  });

  @override
  ConsumerState<_RoleFormSheet> createState() => _RoleFormSheetState();
}

class _RoleFormSheetState extends ConsumerState<_RoleFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late Set<String> _selectedPermissions;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final role = widget.existingRole;
    _nameController = TextEditingController(text: role?['name']?.toString() ?? '');
    _descController = TextEditingController(text: role?['description']?.toString() ?? '');

    final rawPerms = role?['permissions'];
    if (rawPerms is List) {
      _selectedPermissions = rawPerms.map((e) => e.toString()).toSet();
    } else {
      _selectedPermissions = {
        'home_production',
        'home_machines',
        'tasks_production',
      };
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _togglePermission(String key) {
    setState(() {
      if (_selectedPermissions.contains(key)) {
        _selectedPermissions.remove(key);
      } else {
        _selectedPermissions.add(key);
      }
    });
  }

  void _selectAllInCategory(String category) {
    setState(() {
      for (final p in kAvailablePermissions.where((p) => p.category == category)) {
        _selectedPermissions.add(p.key);
      }
    });
  }

  void _clearCategory(String category) {
    setState(() {
      for (final p in kAvailablePermissions.where((p) => p.category == category)) {
        _selectedPermissions.remove(p.key);
      }
    });
  }

  Future<void> _submitForm() async {
    final name = _nameController.text.trim().toUpperCase();
    final desc = _descController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a role name.')),
      );
      return;
    }

    if (_selectedPermissions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one permission for this role.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final api = ref.read(apiServiceProvider);
      final role = widget.existingRole;
      final roleId = (role?['id'] ?? role?['_id'])?.toString();
      final now = DateTime.now().millisecondsSinceEpoch;

      if (role != null && roleId != null) {
        // Update existing role
        await api.updateCollectionItem('company_roles', roleId, {
          'name': name,
          'description': desc.isNotEmpty ? desc : null,
          'permissions': _selectedPermissions.toList(),
          'updated_at': now,
        });
      } else {
        // Create new role
        await api.createCollectionItem('company_roles', {
          'name': name,
          'description': desc.isNotEmpty ? desc : null,
          'permissions': _selectedPermissions.toList(),
          'is_system': 0,
          'created_at': now,
          'updated_at': now,
        });
      }

      // Update global role permissions provider so effectiveUser recalculates immediately
      await ref.read(companyRolesProvider.notifier).loadRoles();

      // If currently previewing this role, update preview state with fresh permissions
      final preview = ref.read(rolePreviewProvider);
      if (preview.isPreviewing && (preview.roleName ?? '').toUpperCase() == name.toUpperCase()) {
        ref.read(rolePreviewProvider.notifier).startPreview(name, _selectedPermissions.toList());
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Role "$name" saved successfully! Permissions applied.'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save role: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.existingRole != null;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sheet Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEdit ? 'Edit Role: ${_nameController.text}' : 'Create Custom Role',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Assign module & task permissions for this role',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 20),

          // Scrollable Form Body
          Expanded(
            child: ListView(
              children: [
                // Role Name Input
                const Text('Role Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'e.g. CNC OPERATOR or STORE KEEPER',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 14),

                // Role Description Input
                const Text('Role Description (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                TextField(
                  controller: _descController,
                  decoration: InputDecoration(
                    hintText: 'Brief summary of duties and permissions',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 18),

                // Section 1: Operations & Floor Access
                _buildPermissionCategorySection(
                  title: '1. Operations & Floor Access',
                  subtitle: 'Orders, live floor tracking, stock, machines, QC, maintenance',
                  icon: Icons.precision_manufacturing_outlined,
                  category: 'home',
                  color: const Color(0xFF0284C7),
                  isDark: isDark,
                ),
                const SizedBox(height: 14),

                // Section 2: My Tasks Activities
                _buildPermissionCategorySection(
                  title: '2. My Tasks Activities',
                  subtitle: 'Work queue, breakdown alerts, maintenance tickets, 1-tap actions',
                  icon: Icons.checklist_rtl_outlined,
                  category: 'tasks',
                  color: const Color(0xFF15803D),
                  isDark: isDark,
                ),
                const SizedBox(height: 14),

                // Section 3: Management Hub Modules
                _buildPermissionCategorySection(
                  title: '3. Management Hub Modules',
                  subtitle: 'Purchase & GRN, staff & roster, reports, dispatch, roles & config',
                  icon: Icons.business_center_outlined,
                  category: 'management',
                  color: const Color(0xFF7C3AED),
                  isDark: isDark,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Footer Action Buttons
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _saving ? null : _submitForm,
                  child: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(isEdit ? 'Save Changes' : 'Create Role', style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCategorySection({
    required String title,
    required String subtitle,
    required IconData icon,
    required String category,
    required Color color,
    required bool isDark,
  }) {
    final perms = kAvailablePermissions.where((p) => p.category == category).toList();
    final allSelected = perms.every((p) => _selectedPermissions.contains(p.key));

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Select All / Clear
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: allSelected ? () => _clearCategory(category) : () => _selectAllInCategory(category),
                  child: Text(
                    allSelected ? 'Clear All' : 'Select All',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Permission Checkbox Items
          ...perms.map((perm) {
            final checked = _selectedPermissions.contains(perm.key);
            return InkWell(
              onTap: () => _togglePermission(perm.key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: checked,
                      activeColor: color,
                      visualDensity: VisualDensity.compact,
                      onChanged: (_) => _togglePermission(perm.key),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            perm.label,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: checked ? FontWeight.w700 : FontWeight.w500,
                              color: checked
                                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                            ),
                          ),
                          Text(
                            perm.description,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
