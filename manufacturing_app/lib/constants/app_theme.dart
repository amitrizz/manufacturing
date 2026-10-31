import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class AppTheme {
  static const Color _lightPrimary = Color(AppConstants.primaryColor);
  static const Color _darkPrimary = Color(0xFF3B82F6);
  
  static const Color _lightBackground = Color(0xFFF8FAFC);
  static const Color _darkBackground = Color(0xFF0F172A);
  
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _darkSurface = Color(0xFF1E293B);
  
  static const Color _lightText = Color(0xFF0F172A);
  static const Color _darkText = Color(0xFFF8FAFC);
  
  static const Color _lightTextSecondary = Color(0xFF64748B);
  static const Color _darkTextSecondary = Color(0xFF94A3B8);
  
  static const Color _lightBorder = Color(0xFFE2E8F0);
  static const Color _darkBorder = Color(0xFF334155);
  
  static const Color _lightError = Color(AppConstants.dangerColor);
  static const Color _darkError = Color(0xFFF87171);
  
  static const Color _lightSuccess = Color(AppConstants.successColor);
  static const Color _darkSuccess = Color(0xFF4ADE80);
  
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: _lightPrimary,
      secondary: _lightPrimary,
      surface: _lightSurface,
      background: _lightBackground,
      error: _lightError,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _lightText,
      onBackground: _lightText,
      onError: Colors.white,
      outline: _lightBorder,
    ),
    scaffoldBackgroundColor: _lightBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: _lightSurface,
      foregroundColor: _lightText,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: _lightText,
      ),
      iconTheme: const IconThemeData(color: _lightText),
      actionsIconTheme: const IconThemeData(color: _lightText),
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: _lightSurface,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _lightBorder, width: 1),
      ),
      margin: const EdgeInsets.all(0),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _lightPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _lightPrimary,
        side: const BorderSide(color: _lightPrimary, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _lightPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _lightBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _lightPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _lightError),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _lightError, width: 2),
      ),
      labelStyle: TextStyle(color: _lightTextSecondary),
      hintStyle: TextStyle(color: _lightTextSecondary.withValues(alpha: 0.6)),
      errorStyle: TextStyle(color: _lightError, fontSize: 12),
      floatingLabelStyle: TextStyle(color: _lightPrimary),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: _lightSurface,
      selectedItemColor: _lightPrimary,
      unselectedItemColor: _lightTextSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _lightSurface,
      elevation: 3,
      surfaceTintColor: Colors.transparent,
      indicatorColor: const Color(0xFFE0F2FE),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: _lightPrimary, size: 23);
        }
        return const IconThemeData(color: _lightTextSecondary, size: 23);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _lightPrimary);
        }
        return const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _lightTextSecondary);
      }),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: _lightPrimary,
      unselectedLabelColor: _lightTextSecondary,
      indicatorColor: _lightPrimary,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: _lightBackground,
      selectedColor: _lightPrimary.withValues(alpha: 0.15),
      labelStyle: TextStyle(color: _lightTextSecondary),
      secondaryLabelStyle: const TextStyle(color: _lightPrimary),
      side: BorderSide(color: _lightBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    ),
    dividerTheme: DividerThemeData(
      color: _lightBorder,
      thickness: 1,
      space: 1,
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      titleTextStyle: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: _lightText,
      ),
      subtitleTextStyle: TextStyle(
        fontSize: 13,
        color: _lightTextSecondary,
      ),
      leadingAndTrailingTextStyle: TextStyle(
        fontSize: 13,
        color: _lightTextSecondary,
      ),
      iconColor: _lightTextSecondary,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _lightPrimary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: _lightSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: _lightText,
      ),
      contentTextStyle: TextStyle(
        fontSize: 14,
        color: _lightTextSecondary,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _darkSurface,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      actionTextColor: _lightPrimary,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: _lightPrimary,
      linearTrackColor: _lightPrimary.withValues(alpha: 0.2),
      circularTrackColor: _lightPrimary.withValues(alpha: 0.2),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: _lightPrimary,
      inactiveTrackColor: _lightPrimary.withValues(alpha: 0.2),
      thumbColor: _lightPrimary,
      overlayColor: _lightPrimary.withValues(alpha: 0.15),
      valueIndicatorColor: _lightPrimary,
      valueIndicatorTextStyle: const TextStyle(color: Colors.white),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return _lightPrimary;
        return Colors.grey.shade400;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return _lightPrimary.withValues(alpha: 0.5);
        return Colors.grey.shade300;
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return _lightPrimary;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: BorderSide(color: _lightBorder, width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return _lightPrimary;
        return _lightTextSecondary;
      }),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: _lightText,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: _lightText,
        letterSpacing: -0.3,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: _lightText,
        letterSpacing: -0.1,
      ),
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: _lightText,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: _lightText,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: _lightText,
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: _lightText,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _lightText,
      ),
      titleSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: _lightText,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: _lightText,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: _lightText,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: _lightTextSecondary,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _lightText,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: _lightTextSecondary,
      ),
      labelSmall: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: _lightTextSecondary,
      ),
    ),
  );
  
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: _darkPrimary,
      secondary: _darkPrimary,
      surface: _darkSurface,
      background: _darkBackground,
      error: _darkError,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _darkText,
      onBackground: _darkText,
      onError: Colors.black,
      outline: _darkBorder,
    ),
    scaffoldBackgroundColor: _darkBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: _darkSurface,
      foregroundColor: _darkText,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: _darkText,
      ),
      iconTheme: const IconThemeData(color: _darkText),
      actionsIconTheme: const IconThemeData(color: _darkText),
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: _darkSurface,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _darkBorder, width: 1),
      ),
      margin: const EdgeInsets.all(0),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _darkPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _darkPrimary,
        side: const BorderSide(color: _darkPrimary, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _darkPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E293B),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _darkPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _darkError),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _darkError, width: 2),
      ),
      labelStyle: TextStyle(color: _darkTextSecondary),
      hintStyle: TextStyle(color: _darkTextSecondary.withValues(alpha: 0.6)),
      errorStyle: TextStyle(color: _darkError, fontSize: 12),
      floatingLabelStyle: TextStyle(color: _darkPrimary),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: _darkSurface,
      selectedItemColor: _darkPrimary,
      unselectedItemColor: _darkTextSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _darkSurface,
      elevation: 3,
      surfaceTintColor: Colors.transparent,
      indicatorColor: const Color(0xFF1E3A8A),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: _darkPrimary, size: 23);
        }
        return const IconThemeData(color: _darkTextSecondary, size: 23);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _darkPrimary);
        }
        return const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _darkTextSecondary);
      }),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: _darkPrimary,
      unselectedLabelColor: _darkTextSecondary,
      indicatorColor: _darkPrimary,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF1E293B),
      selectedColor: _darkPrimary.withValues(alpha: 0.2),
      labelStyle: TextStyle(color: _darkTextSecondary),
      secondaryLabelStyle: const TextStyle(color: _darkPrimary),
      side: BorderSide(color: _darkBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    ),
    dividerTheme: DividerThemeData(
      color: _darkBorder,
      thickness: 1,
      space: 1,
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      titleTextStyle: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: _darkText,
      ),
      subtitleTextStyle: TextStyle(
        fontSize: 13,
        color: _darkTextSecondary,
      ),
      leadingAndTrailingTextStyle: TextStyle(
        fontSize: 13,
        color: _darkTextSecondary,
      ),
      iconColor: _darkTextSecondary,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _darkPrimary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: _darkSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: _darkText,
      ),
      contentTextStyle: TextStyle(
        fontSize: 14,
        color: _darkTextSecondary,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF1E293B),
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      actionTextColor: _darkPrimary,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: _darkPrimary,
      linearTrackColor: _darkPrimary.withValues(alpha: 0.2),
      circularTrackColor: _darkPrimary.withValues(alpha: 0.2),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: _darkPrimary,
      inactiveTrackColor: _darkPrimary.withValues(alpha: 0.2),
      thumbColor: _darkPrimary,
      overlayColor: _darkPrimary.withValues(alpha: 0.15),
      valueIndicatorColor: _darkPrimary,
      valueIndicatorTextStyle: const TextStyle(color: Colors.white),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return _darkPrimary;
        return Colors.grey.shade600;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return _darkPrimary.withValues(alpha: 0.5);
        return Colors.grey.shade700;
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return _darkPrimary;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: BorderSide(color: _darkBorder, width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return _darkPrimary;
        return _darkTextSecondary;
      }),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: _darkText,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: _darkText,
        letterSpacing: -0.3,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: _darkText,
        letterSpacing: -0.1,
      ),
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: _darkText,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: _darkText,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: _darkText,
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: _darkText,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _darkText,
      ),
      titleSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: _darkText,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: _darkText,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: _darkText,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: _darkTextSecondary,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _darkText,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: _darkTextSecondary,
      ),
      labelSmall: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: _darkTextSecondary,
      ),
    ),
  );
}