import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../constants/permissions.dart';

/// Top persistent banner displayed across the app when an admin/manager is
/// impersonating a staff member or previewing a role.
class ImpersonationBanner extends ConsumerWidget {
  const ImpersonationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveUser = ref.watch(effectiveUserProvider);

    if (!effectiveUser.isImpersonating) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          border: Border(
            bottom: BorderSide(color: const Color(0xFFF59E0B).withValues(alpha: 0.6), width: 1.5),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD97706).withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              // Animated icon indicator
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.switch_account_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),

              // Staff & Role Info
              Expanded(
                child: InkWell(
                  onTap: () => _showPermissionsInfo(context, effectiveUser),
                  borderRadius: BorderRadius.circular(6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Viewing as: ${effectiveUser.name}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF78350F),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB45309),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              effectiveUser.role.replaceAll('_', ' '),
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '${effectiveUser.permissions.length} perms active • Tap to view',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF92400E),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.info_outline, size: 12, color: Color(0xFF92400E)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Exit Impersonation Button
              FilledButton.icon(
                onPressed: () {
                  ref.read(impersonationProvider.notifier).exitImpersonation();
                  ref.read(rolePreviewProvider.notifier).exitPreview();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Exited staff view. Returned to ${effectiveUser.originalAdminName ?? "Admin"} session.',
                      ),
                      backgroundColor: const Color(0xFF0A1E38),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB45309),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                icon: const Icon(Icons.close_rounded, size: 14),
                label: const Text(
                  'Exit View',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPermissionsInfo(BuildContext context, EffectiveUser user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: Color(0xFFB45309), size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Active Permissions: ${user.role}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'You are currently viewing the system through ${user.name}\'s profile. Only features authorized for the ${user.role} role are accessible.',
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: kAvailablePermissions.map((perm) {
                    final isGranted = user.hasPermission(perm.key);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            isGranted ? Icons.check_circle_rounded : Icons.cancel_outlined,
                            size: 18,
                            color: isGranted ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              perm.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isGranted ? FontWeight.w700 : FontWeight.w500,
                                color: isGranted ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                          Text(
                            isGranted ? 'Allowed' : 'Locked',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isGranted ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
