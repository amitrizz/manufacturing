import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/app_providers.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_colors.dart';
import '../../widgets/cashfree_gateway_modal.dart';


class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _baseUrl = '';
  bool _isTestingConnection = false;
  String _selectedLanguage = 'EN';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(subscriptionProvider.notifier).refreshSubscription();
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _baseUrl = prefs.getString(AppConstants.baseUrlKey) ?? AppConstants.defaultBaseUrl;
      _selectedLanguage = prefs.getString(AppConstants.languageKey) ?? 'EN';
    });
  }

  Future<void> _setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.languageKey, lang);
    setState(() => _selectedLanguage = lang);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang == 'HI' ? 'भाषा बदलकर हिंदी कर दी गई है' : 'Language set to English'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _saveBaseUrl(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.baseUrlKey, trimmed);
    ref.read(apiServiceProvider).updateBaseUrl(trimmed);
    setState(() => _baseUrl = trimmed);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('API URL updated to $trimmed')),
      );
    }
  }

  Future<void> _testConnection([String? testUrl]) async {
    setState(() => _isTestingConnection = true);
    try {
      final apiService = ref.read(apiServiceProvider);
      if (testUrl != null && testUrl.trim().isNotEmpty) {
        apiService.updateBaseUrl(testUrl.trim());
      }
      final health = await apiService.getHealth();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected! Status: ${health.status}, DB: ${health.database}, Collections: ${health.collectionsCount}'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection failed: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTestingConnection = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authStateProvider);
    final subState = ref.watch(subscriptionProvider);
    final themeMode = ref.watch(themeModeProvider);

    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final companyName = authState.userName != null && authState.userName!.isNotEmpty
        ? authState.userName!
        : 'Apex Manufacturing Ltd';
    final rawCompanyCode = authState.companyId != null && authState.companyId!.isNotEmpty
        ? authState.companyId!
        : 'APEX01';
    final companyCode = (rawCompanyCode.length == 24 && RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(rawCompanyCode))
        ? (companyName.toLowerCase().contains('google') ? 'GOOGLE' : companyName.toUpperCase().replaceAll(' ', '-').substring(0, companyName.length.clamp(0, 10)))
        : rawCompanyCode;
    final effectiveUser = ref.watch(effectiveUserProvider);
    final userRole = effectiveUser.role;
    final userName = effectiveUser.name;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Profile & Account',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.headerNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // ===================================================================
          // Active Impersonation Card
          // ===================================================================
          if (effectiveUser.isImpersonating) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.switch_account_rounded, color: Color(0xFFD97706), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Viewing as: ${effectiveUser.name}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF78350F)),
                        ),
                        Text(
                          'Role: ${effectiveUser.role} • ${effectiveUser.permissions.length} perms active',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: () {
                      ref.read(impersonationProvider.notifier).exitImpersonation();
                      ref.read(rolePreviewProvider.notifier).exitPreview();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFB45309),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Exit View'),
                  ),
                ],
              ),
            ),
          ],

          // ===================================================================
          // 1. Company Profile Card
          // ===================================================================
          Material(
            color: surfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor),
            ),
            elevation: 1,
            shadowColor: Colors.black.withValues(alpha: 0.04),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showCompanyDetailsDialog(context, companyName, companyCode, authState.userName ?? 'Admin', userRole),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.business_rounded, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            companyName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          RichText(
                            text: TextSpan(
                              style: TextStyle(fontSize: 12, color: secondaryTextColor),
                              children: [
                                const TextSpan(text: 'Company Code: '),
                                TextSpan(
                                  text: companyCode,
                                  style: TextStyle(fontWeight: FontWeight.w700, color: textColor),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.person, size: 13, color: Color(0xFF2563EB)),
                              const SizedBox(width: 4),
                              Text(
                                effectiveUser.isImpersonating
                                    ? '$userName ($userRole) • Viewing as Staff'
                                    : '$userName ($userRole)',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 20, color: Color(0xFF94A3B8)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ===================================================================
          // 2. Subscription Status Card
          // ===================================================================
          _buildSubscriptionCard(subState, isDark, surfaceColor, borderColor, textColor, secondaryTextColor),
          const SizedBox(height: 14),

          // ===================================================================
          // 3. Four Quick Action / Stat Cards in a row (or 2x2 grid on mobile)
          // ===================================================================
          _buildQuickGrid(isDark, surfaceColor, borderColor, textColor, secondaryTextColor, companyCode, subState),
          const SizedBox(height: 18),

          // ===================================================================
          // 4. App Preferences Section
          // ===================================================================
          Text(
            'App Preferences',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          _buildCardContainer(
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            children: [
              // Language
              _buildMenuRow(
                iconBg: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF),
                icon: Icons.language_rounded,
                iconColor: const Color(0xFF2563EB),
                title: 'Language / भाषा',
                subtitle: 'Choose application language',
                textColor: textColor,
                secondaryTextColor: secondaryTextColor,
                trailing: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildToggleBtn('EN', _selectedLanguage == 'EN', () => _setLanguage('EN')),
                      _buildToggleBtn('हिंदी', _selectedLanguage == 'HI', () => _setLanguage('HI')),
                    ],
                  ),
                ),
              ),
              Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),

              // Notifications
              _buildMenuRow(
                iconBg: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF),
                icon: Icons.notifications_rounded,
                iconColor: const Color(0xFF2563EB),
                title: 'Notifications',
                subtitle: 'Manage production alerts & updates',
                textColor: textColor,
                secondaryTextColor: secondaryTextColor,
                onTap: () => context.push('/settings/notifications'),
                trailing: const Icon(Icons.chevron_right, size: 18, color: Color(0xFF94A3B8)),
              ),
              Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),

              // Theme
              _buildMenuRow(
                iconBg: isDark ? const Color(0xFF78350F) : const Color(0xFFFFFBEB),
                icon: Icons.palette_rounded,
                iconColor: const Color(0xFFD97706),
                title: 'Theme',
                subtitle: 'Choose app appearance',
                textColor: textColor,
                secondaryTextColor: secondaryTextColor,
                trailing: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildToggleBtn(
                        'Light',
                        themeMode == ThemeMode.light,
                        () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light),
                      ),
                      _buildToggleBtn(
                        'Dark',
                        themeMode == ThemeMode.dark,
                        () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark),
                      ),
                      _buildToggleBtn(
                        'System',
                        themeMode == ThemeMode.system,
                        () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ===================================================================
          // 5. Tools & System Section
          // ===================================================================
          Text(
            'Tools & System',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          _buildCardContainer(
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            children: [
              // How Platform Works
              _buildMenuRow(
                iconBg: isDark ? const Color(0xFF0369A1) : const Color(0xFFE0F2FE),
                icon: Icons.hub_rounded,
                iconColor: const Color(0xFF0284C7),
                title: 'How Platform Works (Visual Guide)',
                titleColor: const Color(0xFF0284C7),
                subtitle: 'Visual flow of modules & floor pipeline',
                textColor: textColor,
                secondaryTextColor: secondaryTextColor,
                onTap: () => _showPlatformWorkflowSheet(context, isDark, surfaceColor, borderColor, textColor, secondaryTextColor),
                trailing: const Icon(Icons.chevron_right, size: 18, color: Color(0xFF0284C7)),
              ),
              Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),

              // Account Security & Roles
              if (effectiveUser.hasPermission('mgmt_roles')) ...[
                _buildMenuRow(
                  iconBg: isDark ? const Color(0xFF4C1D95) : const Color(0xFFEDE9FE),
                  icon: Icons.shield_outlined,
                  iconColor: const Color(0xFF6D28D9),
                  title: 'Account Security & Roles',
                  subtitle: 'Access roles and permissions (RBAC)',
                  textColor: textColor,
                  secondaryTextColor: secondaryTextColor,
                  onTap: () => context.push('/roles'),
                  trailing: const Icon(Icons.chevron_right, size: 18, color: Color(0xFF94A3B8)),
                ),
                Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
              ],

              // Backend API URL Configuration
              if (effectiveUser.hasPermission('mgmt_settings')) ...[
                _buildMenuRow(
                  iconBg: isDark ? const Color(0xFF0F766E) : const Color(0xFFE6FFFA),
                  icon: Icons.dns_rounded,
                  iconColor: const Color(0xFF0D9488),
                  title: 'Backend API URL',
                  subtitle: _baseUrl.isEmpty ? 'http://localhost:5000/api/v1' : _baseUrl,
                  textColor: textColor,
                  secondaryTextColor: secondaryTextColor,
                  onTap: () => _showApiConfigDialog(context, isDark, surfaceColor, borderColor, textColor, secondaryTextColor),
                  trailing: const Icon(Icons.chevron_right, size: 18, color: Color(0xFF94A3B8)),
                ),
                Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
              ],

              // Data Management & Simulator
              if (effectiveUser.hasPermission('mgmt_settings')) ...[
                _buildMenuRow(
                  iconBg: isDark ? const Color(0xFF312E81) : const Color(0xFFEEF2FF),
                  icon: Icons.storage_rounded,
                  iconColor: const Color(0xFF4F46E5),
                  title: 'Data Management & Simulator',
                  subtitle: 'Export data, reset demo data, or wipe database',
                  textColor: textColor,
                  secondaryTextColor: secondaryTextColor,
                  onTap: () => _showDataManagementSheet(context, isDark, surfaceColor, borderColor, textColor, secondaryTextColor),
                  trailing: const Icon(Icons.chevron_right, size: 18, color: Color(0xFF94A3B8)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),

          // ===================================================================
          // 6. Logout Card
          // ===================================================================
          Material(
            color: isDark ? const Color(0xFF3B0D0D) : const Color(0xFFFEF2F2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _showLogoutConfirmDialog(context, companyName),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFDC2626)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Log Out',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Sign out of this session',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 18, color: Color(0xFFDC2626)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ===========================================================================
  // Subscription Card Builder
  // ===========================================================================
  Widget _buildSubscriptionCard(
    SubscriptionState subState,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    String badgeText;
    Color badgeBg;
    Color badgeColor;
    String subtitleText;

    switch (subState.status) {
      case SubscriptionStatus.paid:
        badgeText = 'ACTIVE PRO';
        badgeBg = isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5);
        badgeColor = const Color(0xFF10B981);
        subtitleText = 'Active Pro (${subState.plan == 'PRO_ANNUAL' ? 'Annual' : 'Monthly'}) • Full offline & cloud sync';
        break;
      case SubscriptionStatus.grace:
        badgeText = 'GRACE PERIOD';
        badgeBg = isDark ? const Color(0xFF78350F) : const Color(0xFFFFFBEB);
        badgeColor = const Color(0xFFD97706);
        subtitleText = '⚠️ Grace Period (${subState.daysRemaining} Days Left)';
        break;
      case SubscriptionStatus.expired:
        badgeText = 'EXPIRED';
        badgeBg = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2);
        badgeColor = const Color(0xFFEF4444);
        subtitleText = 'Expired • Read-Only Mode enforced';
        break;
      case SubscriptionStatus.trial:
        badgeText = 'FREE TRIAL';
        badgeBg = isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5);
        badgeColor = const Color(0xFF10B981);
        subtitleText = '7-day trial with full offline capability (${subState.daysRemaining} Days Left)';
        break;
    }

    final totalDays = subState.totalDays > 0 ? subState.totalDays : 7;
    final progressFraction = (subState.daysRemaining / totalDays).clamp(0.05, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.military_tech_rounded, size: 22, color: Color(0xFF10B981)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Active Subscription',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitleText,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => _showSubscriptionPaymentSheet(
                  context,
                  subState,
                  isDark,
                  surfaceColor,
                  borderColor,
                  textColor,
                  secondaryTextColor,
                ),
                child: const Text(
                  'Renew',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Container(
              height: 5,
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progressFraction,
                child: Container(
                  color: subState.status == SubscriptionStatus.expired
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${subState.daysRemaining} Days Left',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: secondaryTextColor,
                ),
              ),
              Text(
                subState.validUntilFormatted.isNotEmpty
                    ? 'Valid till ${subState.validUntilFormatted}'
                    : 'Valid till 7 Days',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Subscription Payment & Renewal Modal Sheet (Cashfree Integration)
  // ===========================================================================
  void _showSubscriptionPaymentSheet(
    BuildContext context,
    SubscriptionState subState,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    String selectedPlan = 'PRO_ANNUAL';
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final authState = ref.read(authStateProvider);
            final companyName = authState.userName ?? 'Your Company';
            final companyCode = authState.companyId ?? 'GOOGLE';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -4)),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: borderColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFF2563EB), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Upgrade to Apex Pro',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                '$companyName (Code: $companyCode)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: secondaryTextColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Option 1: Annual Plan
                    GestureDetector(
                      onTap: () => setModalState(() => selectedPlan = 'PRO_ANNUAL'),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: selectedPlan == 'PRO_ANNUAL'
                              ? const Color(0xFF2563EB).withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selectedPlan == 'PRO_ANNUAL'
                                ? const Color(0xFF2563EB)
                                : borderColor,
                            width: selectedPlan == 'PRO_ANNUAL' ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selectedPlan == 'PRO_ANNUAL' ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: selectedPlan == 'PRO_ANNUAL' ? const Color(0xFF2563EB) : secondaryTextColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Annual Plan (365 Days)',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDCFCE7),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'SAVE 20%',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF15803D),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Full access for 1 full year • Unlimited offline syncing',
                                    style: TextStyle(fontSize: 11.5, color: secondaryTextColor),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹24,999',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: selectedPlan == 'PRO_ANNUAL' ? const Color(0xFF2563EB) : textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Option 2: Monthly Plan
                    GestureDetector(
                      onTap: () => setModalState(() => selectedPlan = 'PRO_MONTHLY'),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: selectedPlan == 'PRO_MONTHLY'
                              ? const Color(0xFF2563EB).withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selectedPlan == 'PRO_MONTHLY'
                                ? const Color(0xFF2563EB)
                                : borderColor,
                            width: selectedPlan == 'PRO_MONTHLY' ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selectedPlan == 'PRO_MONTHLY' ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: selectedPlan == 'PRO_MONTHLY' ? const Color(0xFF2563EB) : secondaryTextColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Monthly Plan (30 Days)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Flexible monthly billing • Cancel anytime',
                                    style: TextStyle(fontSize: 11.5, color: secondaryTextColor),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹2,499',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: selectedPlan == 'PRO_MONTHLY' ? const Color(0xFF2563EB) : textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Features checklist
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          _buildFeatureRow('Unlimited production orders, machines & lines'),
                          const SizedBox(height: 6),
                          _buildFeatureRow('Dynamic custom roles & staff RBAC controls'),
                          const SizedBox(height: 6),
                          _buildFeatureRow('Continuous offline capability & instant cloud sync'),
                          const SizedBox(height: 6),
                          _buildFeatureRow('Full Quality QC & Maintenance log access'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action buttons
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: isProcessing
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.payment_rounded, size: 20),
                        label: Text(
                          isProcessing
                              ? 'Opening Cashfree Gateway…'
                              : 'Pay with Cashfree PG (${selectedPlan == 'PRO_ANNUAL' ? '₹24,999' : '₹2,499'})',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        onPressed: isProcessing
                            ? null
                            : () async {
                                setModalState(() => isProcessing = true);
                                try {
                                  final order = await ref.read(subscriptionProvider.notifier).createCashfreeOrder(
                                    plan: selectedPlan,
                                    amount: selectedPlan == 'PRO_ANNUAL' ? 24999 : 2499,
                                  );

                                  final orderData = order['data'] as Map<String, dynamic>? ?? {};
                                  final orderId = orderData['orderId']?.toString() ?? 'order_${DateTime.now().millisecondsSinceEpoch}';
                                  final paymentSessionId = orderData['paymentSessionId']?.toString() ?? '';
                                  final stubMode = orderData['stubMode'] == true;

                                  if (sheetContext.mounted) {
                                    Navigator.pop(sheetContext); // Close the bottom sheet first
                                  }

                                  if (!context.mounted) return;

                                  // Launch Cashfree Gateway Checkout Modal
                                  await CashfreeGatewayModal.show(
                                    context,
                                    orderId: orderId,
                                    paymentSessionId: paymentSessionId,
                                    amount: selectedPlan == 'PRO_ANNUAL' ? 24999 : 2499,
                                    plan: selectedPlan,
                                    companyCode: companyCode,
                                    companyName: companyName,
                                    stubMode: stubMode,
                                    onSuccess: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('🎉 Subscription Activated via Cashfree! Your ${selectedPlan == 'PRO_ANNUAL' ? '1-Year Pro' : 'Monthly Pro'} plan is now active.'),
                                          backgroundColor: const Color(0xFF10B981),
                                          duration: const Duration(seconds: 4),
                                        ),
                                      );
                                    },
                                  );
                                } catch (e) {
                                  if (sheetContext.mounted) {
                                    setModalState(() => isProcessing = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Could not open Cashfree PG: $e'),
                                        backgroundColor: const Color(0xFFEF4444),
                                      ),
                                    );
                                  }
                                }
                              },
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Instant Test Mode button
                    Center(
                      child: TextButton.icon(
                        icon: const Icon(Icons.flash_on_rounded, size: 16, color: Color(0xFF10B981)),
                        label: const Text(
                          'Instant Test Activation (Dev / Sandbox)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF10B981)),
                        ),
                        onPressed: isProcessing
                            ? null
                            : () async {
                                setModalState(() => isProcessing = true);
                                try {
                                  await ref.read(subscriptionProvider.notifier).renewSubscription(plan: selectedPlan);
                                  if (sheetContext.mounted) {
                                    Navigator.pop(sheetContext);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('⚡ Instant Pro Activated for ${selectedPlan == 'PRO_ANNUAL' ? '1 Year' : '30 Days'}!'),
                                        backgroundColor: const Color(0xFF10B981),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (sheetContext.mounted) {
                                    setModalState(() => isProcessing = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Activation failed: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFeatureRow(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, size: 15, color: Color(0xFF10B981)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 4 Quick Action / Stat Cards in a row (or 2x2 grid)
  // ===========================================================================
  Widget _buildQuickGrid(
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color textColor,
    Color secondaryTextColor,
    String companyCode,
    SubscriptionState subState,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 560;

        final usersCard = _buildQuickCard(
          icon: Icons.people_rounded,
          iconBg: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF),
          iconColor: const Color(0xFF2563EB),
          label: 'Users',
          value: '6 Active',
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
          onTap: () => context.push('/staff'),
        );

        final companyCard = _buildQuickCard(
          icon: Icons.business_rounded,
          iconBg: isDark ? const Color(0xFF4C1D95) : const Color(0xFFF5F3FF),
          iconColor: const Color(0xFF7C3AED),
          label: 'Company',
          value: companyCode,
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
          onTap: () => _showCompanyDetailsDialog(context, 'Apex Manufacturing Ltd', companyCode, 'Admin', 'ADMIN'),
        );

        final planText = subState.status == SubscriptionStatus.paid
            ? 'Active Pro'
            : subState.status == SubscriptionStatus.grace
                ? 'Grace Period'
                : subState.status == SubscriptionStatus.expired
                    ? 'Expired'
                    : 'Free Trial';

        final planCard = _buildQuickCard(
          icon: Icons.description_rounded,
          iconBg: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
          iconColor: const Color(0xFF059669),
          label: 'Plan Details',
          value: planText,
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
          onTap: () => _showSubSimulationSheet(context, isDark, surfaceColor, borderColor, textColor, secondaryTextColor),
        );

        final billingCard = _buildQuickCard(
          icon: Icons.credit_card_rounded,
          iconBg: isDark ? const Color(0xFF78350F) : const Color(0xFFFFFBEB),
          iconColor: const Color(0xFFD97706),
          label: 'Billing',
          value: 'View & Manage',
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Billing Overview'),
                content: const Text('Your company account is currently on Enterprise Pro tier with unlimited offline capability. No invoices are pending payment.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                ],
              ),
            );
          },
        );

        if (isNarrow) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: usersCard),
                  const SizedBox(width: 8),
                  Expanded(child: companyCard),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: planCard),
                  const SizedBox(width: 8),
                  Expanded(child: billingCard),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: usersCard),
            const SizedBox(width: 8),
            Expanded(child: companyCard),
            const SizedBox(width: 8),
            Expanded(child: planCard),
            const SizedBox(width: 8),
            Expanded(child: billingCard),
          ],
        );
      },
    );
  }

  Widget _buildQuickCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.03),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 16, color: iconColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const Positioned(
                top: 0,
                right: 0,
                child: Icon(Icons.chevron_right, size: 14, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // Card Container & Menu Row Helpers
  // ===========================================================================
  Widget _buildCardContainer({
    required Color surfaceColor,
    required Color borderColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildMenuRow({
    required Color iconBg,
    required IconData icon,
    required Color iconColor,
    required String title,
    Color? titleColor,
    required String subtitle,
    required Color textColor,
    required Color secondaryTextColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: titleColor ?? textColor,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleBtn(String text, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // Dialogs & Modal Sheets
  // ===========================================================================
  void _showCompanyDetailsDialog(BuildContext context, String name, String code, String admin, String role) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.business_rounded, color: Color(0xFF2563EB), size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Company Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailLine('Company Name', name),
            const SizedBox(height: 8),
            _buildDetailLine('Company Code', code),
            const SizedBox(height: 8),
            _buildDetailLine('Administrator', admin),
            const SizedBox(height: 8),
            _buildDetailLine('Role Level', role),
            const SizedBox(height: 8),
            _buildDetailLine('Database Mode', 'Multi-tenant SQLite / Cloud Sync'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildDetailLine(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
      ],
    );
  }

  void _showSubSimulationSheet(
    BuildContext context,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final currentStatus = ref.watch(subscriptionProvider).status;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Simulate Subscription Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Test application behaviors across different subscription lifecycle states.',
                style: TextStyle(fontSize: 12, color: secondaryTextColor),
              ),
              const SizedBox(height: 16),
              Row(
                children: SubscriptionStatus.values.map((st) {
                  final active = currentStatus == st;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () {
                          ref.read(subscriptionProvider.notifier).simulateStatus(st);
                          Navigator.pop(ctx);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: active
                                ? const Color(0xFF2563EB)
                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: active ? const Color(0xFF2563EB) : borderColor,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            st.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: active ? Colors.white : secondaryTextColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPlatformWorkflowSheet(
    BuildContext context,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final stages = [
      {'num': '1', 'name': 'Plant Foundation', 'desc': 'Lines, Machine Fleet & Shift Staff', 'color': 0xFF0284C7},
      {'num': '2', 'name': 'Supply & Materials', 'desc': 'Suppliers, GRN Intake & Inventory Lots', 'color': 0xFFD97706},
      {'num': '3', 'name': 'Production Orders', 'desc': 'Work Orders, Job Cards & Hourly Output', 'color': 0xFF2563EB},
      {'num': '4', 'name': 'Quality Control', 'desc': 'First Piece, In-Process Checks & Re-work', 'color': 0xFF10B981},
      {'num': '5', 'name': 'Machine Maintenance', 'desc': 'Preventive Schedules, Downtime & Breakdown Repairs', 'color': 0xFF7C3AED},
      {'num': '6', 'name': 'Dispatch & Delivery', 'desc': 'Packing, Dispatch Challans & Customer Delivery', 'color': 0xFFE11D48},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.hub_rounded, color: Color(0xFF0284C7), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Platform Architecture Flow',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Interactive 6-Stage Manufacturing Execution Pipeline (MES)',
              style: TextStyle(fontSize: 12, color: secondaryTextColor),
            ),
            const SizedBox(height: 16),
            ...stages.map((st) {
              final stageColor = Color(st['color'] as int);
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: stageColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        st['num'] as String,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: stageColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            st['name'] as String,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            st['desc'] as String,
                            style: TextStyle(fontSize: 11, color: secondaryTextColor),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_rounded, size: 16, color: stageColor),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }



  void _showApiConfigDialog(
    BuildContext context,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final controller = TextEditingController(text: _baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Backend API Configuration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Endpoint URL for Node.js REST API:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'http://localhost:5000/api/v1',
                  prefixIcon: const Icon(Icons.link),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _isTestingConnection
                        ? null
                        : () async {
                            setDialogState(() => _isTestingConnection = true);
                            await _testConnection(controller.text);
                            setDialogState(() => _isTestingConnection = false);
                          },
                    icon: _isTestingConnection
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.wifi, size: 16),
                    label: Text(_isTestingConnection ? 'Testing...' : 'Test Ping'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                _saveBaseUrl(controller.text);
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDataManagementSheet(
    BuildContext context,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.storage_rounded, color: Color(0xFF4F46E5), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Data Management',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Export Data
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.download_rounded, color: Color(0xFF2563EB), size: 20),
              ),
              title: const Text('Export Database (JSON)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              subtitle: Text('Download all collections as a JSON bundle', style: TextStyle(fontSize: 11, color: secondaryTextColor)),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () {
                Navigator.pop(ctx);
                _exportData();
              },
            ),
            const Divider(height: 1),

            // Reset Demo Data
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.refresh_rounded, color: Color(0xFFD97706), size: 20),
              ),
              title: const Text('Reset Demo Data', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              subtitle: Text('Reload fresh manufacturing sample records', style: TextStyle(fontSize: 11, color: secondaryTextColor)),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () {
                Navigator.pop(ctx);
                _resetDemoData();
              },
            ),
            const Divider(height: 1),

            // Clear All Data
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626), size: 20),
              ),
              title: const Text('Delete Complete Database Data', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFDC2626))),
              subtitle: Text('Permanently wipe all orders and records', style: TextStyle(fontSize: 11, color: secondaryTextColor)),
              trailing: const Icon(Icons.chevron_right, size: 18, color: Color(0xFFDC2626)),
              onTap: () {
                Navigator.pop(ctx);
                _clearAllData();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmDialog(BuildContext context, String companyName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Are you sure you want to log out from $companyName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authStateProvider.notifier).logout();
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final data = await apiService.getAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data exported successfully! ${data['data']?.keys.length ?? 0} collections retrieved.'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  Future<void> _resetDemoData() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.resetDemoData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demo data reset successfully!'), backgroundColor: Color(0xFF10B981)),
        );
        ref.invalidate(dashboardProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reset failed: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Final Confirmation', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w800)),
        content: const Text('Are you absolutely sure? All production orders, inventory, machines, and records will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No, keep data')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('YES, DELETE EVERYTHING'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.clearAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared successfully!'), backgroundColor: Color(0xFF10B981)),
        );
        ref.invalidate(dashboardProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Clear failed: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }
}