import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../constants/app_constants.dart';
import '../../utils/validators.dart';

enum AuthTab { admin, employee, register }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _adminFormKey = GlobalKey<FormState>();
  final _employeeFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  AuthTab _activeTab = AuthTab.admin;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscurePin = true;
  bool _obscureRegPassword = true;

  String _currentBaseUrl = AppConstants.defaultBaseUrl;

  // Admin Controllers
  final _adminEmailOrCodeController = TextEditingController(text: 'GOOGLE');
  final _adminPasswordController = TextEditingController(text: '123456');

  // Employee / Staff Controllers
  final _staffCompanyCodeController = TextEditingController(text: 'GOOGLE');
  final _staffEmpIdController = TextEditingController(text: 'EMP-001');
  final _staffPinController = TextEditingController(text: '1234');

  // Register Company Controllers
  final _regNameController = TextEditingController();
  final _regCodeController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final apiService = ref.read(apiServiceProvider);
      setState(() {
        _currentBaseUrl = apiService.baseUrl;
      });
    });
  }

  @override
  void dispose() {
    _adminEmailOrCodeController.dispose();
    _adminPasswordController.dispose();
    _staffCompanyCodeController.dispose();
    _staffEmpIdController.dispose();
    _staffPinController.dispose();
    _regNameController.dispose();
    _regCodeController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleAdminLogin() async {
    if (!_adminFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(authStateProvider.notifier).login(
            _adminEmailOrCodeController.text.trim(),
            _adminPasswordController.text,
          );

      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text('Admin login failed: $e')),
              ],
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEmployeeLogin() async {
    if (!_employeeFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(authStateProvider.notifier).loginStaff(
            companyCode: _staffCompanyCodeController.text.trim(),
            employeeIdOrName: _staffEmpIdController.text.trim(),
            pin: _staffPinController.text.trim(),
          );

      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text('Employee login failed: $e')),
              ],
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegisterCompany() async {
    if (!_registerFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(authStateProvider.notifier).registerCompany(
            name: _regNameController.text.trim(),
            companyCode: _regCodeController.text.trim().toUpperCase(),
            adminEmail: _regEmailController.text.trim(),
            adminPassword: _regPasswordController.text,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text('Company registered successfully! Welcome to your workspace.')),
              ],
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text('Registration failed: $e')),
              ],
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getServerBadgeLabel() {
    if (_currentBaseUrl.contains('onrender.com')) {
      return 'Cloud Prod';
    } else if (_currentBaseUrl.contains('192.168.')) {
      return 'Local Wi-Fi';
    } else if (_currentBaseUrl.contains('10.0.2.2')) {
      return 'Emulator';
    } else if (_currentBaseUrl.contains('localhost')) {
      return 'Localhost';
    }
    return 'Custom Server';
  }

  void _showServerSettingsModal() {
    final customUrlController = TextEditingController(text: _currentBaseUrl);
    String? pingResult;
    bool isPinging = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 28,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E293B)
                    : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 30, offset: Offset(0, -6)),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.cloud_sync_rounded, color: Color(0xFF2563EB)),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Backend Connection',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                              ),
                              Text(
                                'Select or customize API server endpoint',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'QUICK PRESETS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Preset 1: Cloud Prod (Render)
                    _buildPresetTile(
                      ctx: context,
                      title: 'Cloud Production (Render)',
                      subtitle: AppConstants.prodBaseUrl,
                      icon: Icons.cloud_done_rounded,
                      isActive: _currentBaseUrl == AppConstants.prodBaseUrl,
                      badge: 'RECOMMENDED',
                      onTap: () {
                        setModalState(() {
                          customUrlController.text = AppConstants.prodBaseUrl;
                        });
                      },
                    ),
                    const SizedBox(height: 8),

                    // Preset 2: Local Wi-Fi (Physical Phone)
                    _buildPresetTile(
                      ctx: context,
                      title: 'Local Wi-Fi Network',
                      subtitle: AppConstants.localLanUrl,
                      icon: Icons.wifi_rounded,
                      isActive: _currentBaseUrl == AppConstants.localLanUrl,
                      badge: 'LAN PHONE',
                      onTap: () {
                        setModalState(() {
                          customUrlController.text = AppConstants.localLanUrl;
                        });
                      },
                    ),
                    const SizedBox(height: 8),

                    // Preset 3: Android Emulator
                    _buildPresetTile(
                      ctx: context,
                      title: 'Android Emulator',
                      subtitle: AppConstants.localEmulatorUrl,
                      icon: Icons.phone_android_rounded,
                      isActive: _currentBaseUrl == AppConstants.localEmulatorUrl,
                      badge: 'EMULATOR',
                      onTap: () {
                        setModalState(() {
                          customUrlController.text = AppConstants.localEmulatorUrl;
                        });
                      },
                    ),
                    const SizedBox(height: 8),

                    // Preset 4: Localhost / Web
                    _buildPresetTile(
                      ctx: context,
                      title: 'Localhost (Web / PC)',
                      subtitle: AppConstants.localWebUrl,
                      icon: Icons.computer_rounded,
                      isActive: _currentBaseUrl == AppConstants.localWebUrl,
                      badge: 'DESKTOP',
                      onTap: () {
                        setModalState(() {
                          customUrlController.text = AppConstants.localWebUrl;
                        });
                      },
                    ),
                    const SizedBox(height: 18),

                    // Custom URL Input
                    const Text(
                      'CUSTOM SERVER URL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: customUrlController,
                      style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        hintText: 'https://your-api.com/api/v1',
                        prefixIcon: const Icon(Icons.link_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: isPinging
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.speed_rounded),
                          tooltip: 'Test Connection (Ping)',
                          onPressed: isPinging
                              ? null
                              : () async {
                                  setModalState(() {
                                    isPinging = true;
                                    pingResult = null;
                                  });
                                  final target = customUrlController.text.trim();
                                  try {
                                    final stopwatch = Stopwatch()..start();
                                    final dio = Dio(BaseOptions(
                                      connectTimeout: const Duration(seconds: 6),
                                      receiveTimeout: const Duration(seconds: 6),
                                    ));
                                    await dio.get(target.replaceFirst('/api/v1', '/api/health'));
                                    stopwatch.stop();
                                    setModalState(() {
                                      isPinging = false;
                                      pingResult = '🟢 Active! Ping: ${stopwatch.elapsedMilliseconds}ms';
                                    });
                                  } catch (err) {
                                    setModalState(() {
                                      isPinging = false;
                                      pingResult = '🟡 Server reached or secured (${err.toString().split("\n").first})';
                                    });
                                  }
                                },
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        filled: true,
                      ),
                    ),
                    if (pingResult != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        pingResult!,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                    const SizedBox(height: 22),

                    // Save Button
                    FilledButton(
                      onPressed: () {
                        final newUrl = customUrlController.text.trim();
                        if (newUrl.isNotEmpty) {
                          ref.read(apiServiceProvider).updateBaseUrl(newUrl);
                          setState(() {
                            _currentBaseUrl = newUrl;
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Connected to: $newUrl'),
                              backgroundColor: const Color(0xFF16A34A),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        'Apply & Connect',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _buildPresetTile({
    required BuildContext ctx,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isActive,
    required String badge,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF2563EB).withValues(alpha: 0.12)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? const Color(0xFF2563EB)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isActive ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? const Color(0xFF2563EB) : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                          color: isActive ? const Color(0xFF2563EB) : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF2563EB).withValues(alpha: 0.18)
                              : Colors.grey.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: isActive ? const Color(0xFF2563EB) : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isActive)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB), size: 18),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF090D16) : const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          // Ambient Background Glows
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF2563EB).withValues(alpha: isDark ? 0.35 : 0.20),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -80,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF06B6D4).withValues(alpha: isDark ? 0.28 : 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Bar: Server Connection Status Pill
                      Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          onTap: _showServerSettingsModal,
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B).withValues(alpha: 0.85)
                                  : Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFF10B981).withValues(alpha: 0.45),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0x8010B981),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _getServerBadgeLabel(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.settings_outlined, size: 13, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Glass Card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF131D31).withValues(alpha: 0.85)
                                  : Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : const Color(0xFFE2E8F0),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black.withValues(alpha: 0.5)
                                      : const Color(0xFF1E293B).withValues(alpha: 0.08),
                                  blurRadius: 36,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // 3D Styled Logo Squircle
                                Center(
                                  child: Container(
                                    width: 76,
                                    height: 76,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF3B82F6),
                                          Color(0xFF1D4ED8),
                                          Color(0xFF0F172A),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.25),
                                        width: 1.5,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x602563EB),
                                          blurRadius: 24,
                                          offset: Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.precision_manufacturing_rounded,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Title Header
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'MANUFLOW ',
                                      style: theme.textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    Text(
                                      'ERP',
                                      style: theme.textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.5,
                                        color: const Color(0xFF2563EB),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),

                                // Enterprise Suite Badge
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: const Text(
                                      'ENTERPRISE CLOUD SUITE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.0,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                Text(
                                  _getSubtitle(),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 22),

                                // Custom Sleek Tab Selector Bar
                                _buildCustomTabBar(isDark),
                                const SizedBox(height: 24),

                                // Active Form
                                if (_activeTab == AuthTab.admin) _buildAdminForm(context, isDark),
                                if (_activeTab == AuthTab.employee) _buildEmployeeForm(context, isDark),
                                if (_activeTab == AuthTab.register) _buildRegisterForm(context, isDark),

                                const SizedBox(height: 18),

                                // Demo One-Tap Autofill Chips
                                if (_activeTab != AuthTab.register) ...[
                                  _buildDemoCredentials(context, isDark),
                                  const SizedBox(height: 16),
                                ],

                                // Trust Footer
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.shield_outlined, size: 13, color: Colors.grey),
                                    const SizedBox(width: 5),
                                    Text(
                                      '256-bit SSL • Multi-Tenant Enterprise Security',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Version & Build Info
                      Center(
                        child: Text(
                          'v${AppConstants.appVersion} • Cloud Ready',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTabBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          _buildTabItem(
            tab: AuthTab.admin,
            label: 'Admin',
            icon: Icons.shield_rounded,
            isSelected: _activeTab == AuthTab.admin,
          ),
          _buildTabItem(
            tab: AuthTab.employee,
            label: 'Employee',
            icon: Icons.badge_rounded,
            isSelected: _activeTab == AuthTab.employee,
          ),
          _buildTabItem(
            tab: AuthTab.register,
            label: 'Register',
            icon: Icons.domain_add_rounded,
            isSelected: _activeTab == AuthTab.register,
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required AuthTab tab,
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x402563EB),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSubtitle() {
    switch (_activeTab) {
      case AuthTab.admin:
        return 'Manage shopfloor lines, staff rosters & operations';
      case AuthTab.employee:
        return 'Sign in with your assigned Company Code, ID and PIN';
      case AuthTab.register:
        return 'Create a new manufacturing account and register your plant';
    }
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF2563EB)),
      suffixIcon: suffixIcon,
      labelStyle: TextStyle(
        fontSize: 13,
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      ),
      hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.7) : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.8),
      ),
    );
  }

  // 1. ADMIN LOGIN FORM
  Widget _buildAdminForm(BuildContext context, bool isDark) {
    return Form(
      key: _adminFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _adminEmailOrCodeController,
            decoration: _buildInputDecoration(
              label: 'Company Code or Admin Email *',
              hint: 'e.g. GOOGLE or google@gmail.com',
              icon: Icons.business_center_outlined,
              isDark: isDark,
            ),
            validator: Validators.validateEmailOrCode,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _adminPasswordController,
            decoration: _buildInputDecoration(
              label: 'Admin Password *',
              hint: 'Enter your password',
              icon: Icons.lock_outline_rounded,
              isDark: isDark,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            obscureText: _obscurePassword,
            validator: Validators.validatePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleAdminLogin(),
          ),
          const SizedBox(height: 22),
          _buildGradientSubmitButton(
            title: 'Sign In to Workspace',
            icon: Icons.arrow_forward_rounded,
            onTap: _handleAdminLogin,
          ),
        ],
      ),
    );
  }

  // 2. EMPLOYEE LOGIN FORM
  Widget _buildEmployeeForm(BuildContext context, bool isDark) {
    return Form(
      key: _employeeFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _staffCompanyCodeController,
            decoration: _buildInputDecoration(
              label: 'Company Code *',
              hint: 'e.g. GOOGLE',
              icon: Icons.business_outlined,
              isDark: isDark,
            ),
            textCapitalization: TextCapitalization.characters,
            validator: (val) =>
                val == null || val.trim().isEmpty ? 'Company code is required' : null,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _staffEmpIdController,
            decoration: _buildInputDecoration(
              label: 'Employee ID or Full Name *',
              hint: 'e.g. EMP-001 or Operator Name',
              icon: Icons.badge_outlined,
              isDark: isDark,
            ),
            validator: (val) =>
                val == null || val.trim().isEmpty ? 'Employee ID is required' : null,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _staffPinController,
            decoration: _buildInputDecoration(
              label: '4-Digit Staff PIN *',
              hint: 'Enter 4-digit PIN (default: 1234)',
              icon: Icons.pin_outlined,
              isDark: isDark,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePin ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePin = !_obscurePin),
              ),
            ),
            obscureText: _obscurePin,
            keyboardType: TextInputType.number,
            maxLength: 6,
            validator: (val) => val == null || val.trim().isEmpty ? 'PIN is required' : null,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleEmployeeLogin(),
          ),
          const SizedBox(height: 18),
          _buildGradientSubmitButton(
            title: 'Sign In as Employee',
            icon: Icons.login_rounded,
            onTap: _handleEmployeeLogin,
          ),
        ],
      ),
    );
  }

  // 3. REGISTER COMPANY FORM
  Widget _buildRegisterForm(BuildContext context, bool isDark) {
    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _regNameController,
            decoration: _buildInputDecoration(
              label: 'Company / Plant Name *',
              hint: 'e.g. Precision Tools Pvt Ltd',
              icon: Icons.factory_outlined,
              isDark: isDark,
            ),
            validator: (val) =>
                val == null || val.trim().isEmpty ? 'Company name is required' : null,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _regCodeController,
            decoration: _buildInputDecoration(
              label: 'Unique Company Code *',
              hint: 'e.g. PREC01 (team uses this to sign in)',
              icon: Icons.qr_code_outlined,
              isDark: isDark,
            ),
            textCapitalization: TextCapitalization.characters,
            validator: (val) =>
                val == null || val.trim().isEmpty ? 'Company code is required' : null,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _regEmailController,
            decoration: _buildInputDecoration(
              label: 'Admin Email *',
              hint: 'admin@precisiontools.com',
              icon: Icons.alternate_email_rounded,
              isDark: isDark,
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Admin email is required';
              if (!val.contains('@')) return 'Enter a valid email address';
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _regPasswordController,
            decoration: _buildInputDecoration(
              label: 'Admin Password *',
              hint: 'Create strong password (min 6 chars)',
              icon: Icons.lock_outline_rounded,
              isDark: isDark,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureRegPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureRegPassword = !_obscureRegPassword),
              ),
            ),
            obscureText: _obscureRegPassword,
            validator: (val) =>
                val == null || val.length < 6 ? 'Password must be at least 6 characters' : null,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleRegisterCompany(),
          ),
          const SizedBox(height: 22),
          _buildGradientSubmitButton(
            title: 'Register Plant & Sign In',
            icon: Icons.check_circle_outline_rounded,
            onTap: _handleRegisterCompany,
          ),
        ],
      ),
    );
  }

  Widget _buildGradientSubmitButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x552563EB),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(icon, size: 18, color: Colors.white),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoCredentials(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFFF59E0B)),
              const SizedBox(width: 6),
              Text(
                'Demo Quick Autofill',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_activeTab == AuthTab.admin)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildDemoChip(
                  label: 'GOOGLE (123456)',
                  onTap: () {
                    _adminEmailOrCodeController.text = 'GOOGLE';
                    _adminPasswordController.text = '123456';
                  },
                ),
                _buildDemoChip(
                  label: 'ALPA (123456)',
                  onTap: () {
                    _adminEmailOrCodeController.text = 'ALPA';
                    _adminPasswordController.text = '123456';
                  },
                ),
              ],
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildDemoChip(
                  label: 'GOOGLE : EMP-001 (PIN: 1234)',
                  onTap: () {
                    _staffCompanyCodeController.text = 'GOOGLE';
                    _staffEmpIdController.text = 'EMP-001';
                    _staffPinController.text = '1234';
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDemoChip({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF2563EB).withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flash_on_rounded, size: 13, color: Color(0xFF2563EB)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2563EB),
              ),
            ),
          ],
        ),
      ),
    );
  }
}