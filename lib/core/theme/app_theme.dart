// Файл app_theme.dart — внешний вид приложения: фирменные цвета и темы.
// Слой: core (общий для всех экранов). AppColors используют экраны и
// виджеты для отдельных акцентов, а AppTheme.light()/dark() подключаются
// в MarshrutApp (app.dart) как светлая и тёмная темы.
import 'package:flutter/material.dart';

/// Фирменные цвета «Маршрута»: тёмно-синий и оранжевый.
///
/// `abstract final` — у класса нельзя создать объект и от него нельзя
/// наследоваться: это просто «папка» для констант.
abstract final class AppColors {
  /// Тёмно-синий — основа интерфейса (доверие, спокойствие).
  static const navy = Color(0xFF1A3A8F);

  /// Более тёмный синий — фон поверхностей в тёмной теме.
  static const navyDark = Color(0xFF0F1D3D);

  /// Самый тёмный синий — фон шапки и навигации в тёмной теме.
  static const navyDeep = Color(0xFF0A1430);

  /// Оранжевый — акцент для действий и прогресса (энергия, мотивация).
  static const orange = Color(0xFFF57C00);

  /// Светло-оранжевый — основной цвет кнопок и акцентов в тёмной теме.
  static const orangeLight = Color(0xFFFFA040);

  /// Зелёный — цвет успеха (галочки «готово», перерыв в таймере Помодоро).
  static const success = Color(0xFF2E9D5B);

  /// Жёлто-оранжевый — цвет предупреждений (плашки с иконкой внимания).
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
  /// Светлая тема приложения.
  static ThemeData light() {
    // Схема цветов Material 3: из одного seed-цвета Flutter сам вычисляет
    // весь набор оттенков, а copyWith заменяет нужные роли своими.
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.navy,
          brightness: Brightness.light,
        ).copyWith(
          // Основной цвет — тёмно-синий, текст на нём белый.
          primary: AppColors.navy,
          onPrimary: Colors.white,
          // Дополнительные акценты — оранжевые.
          secondary: AppColors.orange,
          onSecondary: Colors.white,
          tertiary: AppColors.orange,
          // Светло-оранжевая подложка и тёмно-коричневый текст на ней.
          secondaryContainer: const Color(0xFFFFE3C4),
          onSecondaryContainer: const Color(0xFF4A2500),
        );
    // Общие настройки виджетов собираются в _build.
    return _build(scheme);
  }

  /// Тёмная тема приложения.
  static ThemeData dark() {
    // Та же схема от тёмно-синего цвета, но в тёмном варианте.
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.navy,
          brightness: Brightness.dark,
        ).copyWith(
          // На тёмном фоне основной цвет — светло-оранжевый
          // (так кнопки заметнее), текст на нём тёмный.
          primary: AppColors.orangeLight,
          onPrimary: const Color(0xFF3A1D00),
          // Тёмно-синие контейнеры с белым текстом.
          primaryContainer: AppColors.navy,
          onPrimaryContainer: Colors.white,
          secondary: AppColors.orange,
          onSecondary: Colors.white,
          // Светло-голубой третичный цвет.
          tertiary: const Color(0xFF9DB4FF),
          // Фон и «слои» поверхностей: от самого тёмного к более светлому
          // синему — чем выше слой, тем он светлее.
          surface: AppColors.navyDark,
          surfaceContainerLowest: AppColors.navyDeep,
          surfaceContainerLow: const Color(0xFF13234A),
          surfaceContainer: const Color(0xFF172952),
          surfaceContainerHigh: const Color(0xFF1C305E),
          surfaceContainerHighest: const Color(0xFF22386A),
        );
    // Общие настройки виджетов собираются в _build.
    return _build(scheme);
  }

  /// Собирает [ThemeData] из схемы цветов: задаёт единый стиль шапки,
  /// карточек, полей ввода, кнопок, навигации и других виджетов.
  ///
  /// Общий для светлой и тёмной темы; различия выбираются по `isDark`.
  static ThemeData _build(ColorScheme scheme) {
    // Тёмная ли это тема — от этого зависят некоторые цвета ниже.
    final isDark = scheme.brightness == Brightness.dark;
    // Общий радиус скругления углов для карточек и кнопок.
    final radius = BorderRadius.circular(16);
    // Базовая типографика платформы (Roboto на Android, Segoe UI в Windows):
    // от неё наследуются стили AppBar, кнопок и навигации.
    final text = ThemeData(useMaterial3: true, colorScheme: scheme).textTheme;
    // Итоговая тема со стилями отдельных виджетов.
    return ThemeData(
      // Включаем дизайн Material 3 и нашу схему цветов.
      useMaterial3: true,
      colorScheme: scheme,
      // Цвет фона всех экранов.
      scaffoldBackgroundColor: scheme.surface,
      // Шапка экрана (AppBar): синий фон, белый текст, без тени,
      // заголовок слева.
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.navyDeep : AppColors.navy,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
        // Заголовок шапки: 20 пт, полужирный, белый.
        titleTextStyle: text.titleLarge!.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      // Карточки: плоские, без внешних отступов, со скруглёнными углами
      // и тонкой полупрозрачной рамкой.
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isDark ? scheme.surfaceContainerLow : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .6)),
        ),
      ),
      // Поля ввода: залитый фон и рамка со скруглением 14.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? scheme.surfaceContainer
            : scheme.surfaceContainerLowest,
        // Рамка по умолчанию.
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        // Рамка обычного (не выбранного) поля — бледная.
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        // Рамка поля, в котором стоит курсор, — оранжевая и толще.
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.orange, width: 2),
        ),
      ),
      // Главные кнопки (FilledButton): оранжевые, во всю ширину,
      // высотой 52, с полужирным текстом 16.
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
      // Второстепенные кнопки с рамкой (OutlinedButton): высота 48,
      // синие в светлой теме и светло-оранжевые в тёмной.
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
      // Текстовые кнопки-ссылки (TextButton): оранжевый текст.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? AppColors.orangeLight : AppColors.orange,
        ),
      ),
      // Круглая плавающая кнопка действия: оранжевая с белой иконкой.
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
      ),
      // Нижняя панель навигации (на телефоне): полупрозрачный оранжевый
      // индикатор выбранной вкладки.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppColors.navyDeep : Colors.white,
        indicatorColor: AppColors.orange.withValues(alpha: isDark ? .35 : .18),
        // Подпись вкладки: у выбранной — полужирная, у остальных — обычная.
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium!.copyWith(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
          ),
        ),
      ),
      // Боковая панель навигации (NavigationRail) — те же цвета,
      // что и у нижней панели.
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isDark ? AppColors.navyDeep : Colors.white,
        indicatorColor: AppColors.orange.withValues(alpha: isDark ? .35 : .18),
        // Подпись выбранного пункта: полужирная и цветная.
        selectedLabelTextStyle: text.labelMedium!.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.orangeLight : AppColors.navy,
        ),
        // Подпись остальных пунктов: приглушённый цвет.
        unselectedLabelTextStyle: text.labelMedium!.copyWith(
          fontSize: 12,
          color: scheme.onSurfaceVariant,
        ),
      ),
      // Чипы (кнопки-«таблетки» для выбора): оранжевая подложка
      // и галочка у выбранного, скругление 12.
      chipTheme: ChipThemeData(
        selectedColor: AppColors.orange.withValues(alpha: isDark ? .35 : .18),
        checkmarkColor: isDark ? AppColors.orangeLight : AppColors.orange,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      // Индикаторы прогресса (полосы и круги загрузки) — оранжевые.
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.orange,
      ),
      // Флажки (Checkbox): отмеченный — оранжевый, иначе цвет по умолчанию.
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? AppColors.orange : null,
        ),
      ),
      // Переключатели (Switch): во включённом состоянии белый кружок
      // на оранжевой дорожке, в выключенном — цвета по умолчанию.
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
      // Всплывающие уведомления (SnackBar) «парят» над низом экрана,
      // а не прилипают к нему.
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
