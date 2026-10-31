import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'constants/app_constants.dart';
import 'constants/app_theme.dart';
import 'providers/app_providers.dart';
import 'services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations for mobile devices
  if (!kIsWeb) {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } catch (_) {}
  }
  
  // Initialize logger
  try {
    Logger.init();
  } catch (_) {}
  
  // Initialize API service
  try {
    await ApiService.instance.initialize();
  } catch (e) {
    debugPrint('ApiService initialization error: $e');
  }
  
  runApp(
    const ProviderScope(
      child: ManufacturingApp(),
    ),
  );
}

class ManufacturingApp extends ConsumerWidget {
  const ManufacturingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}