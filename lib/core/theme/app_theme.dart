import 'package:flutter/material.dart';

/// Фирменные цвета «Маршрута»: тёмно-синий и оранжевый.
abstract final class AppColors {
  /// Тёмно-синий — основа интерфейса (доверие, спокойствие).
  static const navy = Color(0xFF1A3A8F);
  static const navyDark = Color(0xFF0F1D3D);
  static const navyDeep = Color(0xFF0A1430);

  /// Оранжевый — акцент для действий и прогресса (энергия, мотивация).
  static const orange = Color(0xFFF57C00);
  static const orangeLight = Color(0xFFFFA040);

  static const success = Color(0xFF2E9D5B);
  static const warning = Color(0xFFE09A00);
}

/// Светлая и тёмная темы Material 3.
///
/// Палитра строится от тёмно-синего seed-цвета через [ColorScheme.fromSeed],
/// затем основные роли переопределяются фирменными цветами:
/// в светлой теме primary — тёмно-синий, secondary — оранжевый;
/// в тёмной теме фон тёмно-синий, а primary — оранжевый, чтобы кнопки
/// оставались контрастными.
abstract final class AppTheme {
  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.navy,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.navy,
          onPrimary: Colors.white,
          secondary: AppColors.orange,
          onSecondary: Colors.white,
          tertiary: AppColors.orange,
          secondaryContainer: const Color(0xFFFFE3C4),
          onSecondaryContainer: const Color(0xFF4A2500),
        );
    return _build(scheme);
  }

  static ThemeData dark() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.navy,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.orangeLight,
          onPrimary: const Color(0xFF3A1D00),
          primaryContainer: AppColors.navy,
          onPrimaryContainer: Colors.white,
          secondary: AppColors.orange,
          onSecondary: Colors.white,
          tertiary: const Color(0xFF9DB4FF),
          surface: AppColors.navyDark,
          surfaceContainerLowest: AppColors.navyDeep,
          surfaceContainerLow: const Color(0xFF13234A),
          surfaceContainer: const Color(0xFF172952),
          surfaceContainerHigh: const Color(0xFF1C305E),
          surfaceContainerHighest: const Color(0xFF22386A),
        );
    return _build(scheme);
  }

  static ThemeData _build(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(16);
    // Базовая типографика платформы (Roboto на Android, Segoe UI в Windows):
    // от неё наследуются стили AppBar, кнопок и навигации.
    final text = ThemeData(useMaterial3: true, colorScheme: scheme).textTheme;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.navyDeep : AppColors.navy,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: text.titleLarge!.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isDark ? scheme.surfaceContainerLow : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .6)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? scheme.surfaceContainer
            : scheme.surfaceContainerLowest,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.orange, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          textStyle: text.labelLarge!.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: isDark ? AppColors.orangeLight : AppColors.navy,
          side: BorderSide(
            color: isDark ? AppColors.orangeLight : AppColors.navy,
          ),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? AppColors.orangeLight : AppColors.orange,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppColors.navyDeep : Colors.white,
        indicatorColor: AppColors.orange.withValues(alpha: isDark ? .35 : .18),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium!.copyWith(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isDark ? AppColors.navyDeep : Colors.white,
        indicatorColor: AppColors.orange.withValues(alpha: isDark ? .35 : .18),
        selectedLabelTextStyle: text.labelMedium!.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.orangeLight : AppColors.navy,
        ),
        unselectedLabelTextStyle: text.labelMedium!.copyWith(
          fontSize: 12,
          color: scheme.onSurfaceVariant,
        ),
      ),
      chipTheme: ChipThemeData(
        selectedColor: AppColors.orange.withValues(alpha: isDark ? .35 : .18),
        checkmarkColor: isDark ? AppColors.orangeLight : AppColors.orange,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.orange,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? AppColors.orange : null,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? AppColors.orange : null,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
