// Общие виджеты и функции интерфейса, которые повторяются на многих экранах:
// рамка ширины, логотип, кольцо прогресса, пустое состояние, ошибка,
// загрузка, заголовок раздела, аватар, всплывающее сообщение и диалог.
// Слой: presentation (интерфейс). Подключается почти всеми экранами из
// lib/presentation/screens/.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Ширина, начиная с которой вместо нижней панели показывается боковая
/// (Material 3: окно «expanded» — планшет, телефон в горизонтальной
/// ориентации, окно Windows).
const kWideLayoutBreakpoint = 840.0;

/// Максимальная ширина содержимого экрана.
const kContentMaxWidth = 720.0;

/// Ограничивает ширину содержимого на широких экранах: на телефоне экран
/// остаётся как есть, а в окне Windows или на планшете строки не растягиваются
/// на всю ширину, а выстраиваются колонкой по центру.
class ContentFrame extends StatelessWidget {
  /// Создаёт рамку вокруг [child]; [maxWidth] по умолчанию 720.
  const ContentFrame({
    super.key,
    required this.child,
    this.maxWidth = kContentMaxWidth,
  });

  /// Содержимое экрана, которое нужно ограничить по ширине.
  final Widget child;

  /// Предельная ширина содержимого в логических пикселях.
  final double maxWidth;

  /// Решает, нужно ли ограничивать ширину, и строит результат.
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    // LayoutBuilder сообщает, сколько места выделил родитель
    // (constraints — ограничения по ширине и высоте).
    builder: (context, constraints) {
      // Ширина не ограничена или экран и так узкий — ничего не меняем.
      if (!constraints.hasBoundedWidth || constraints.maxWidth <= maxWidth) {
        return child;
      }
      // Широкий экран: ставим содержимое по центру с шириной maxWidth.
      return Center(
        child: SizedBox(
          width: maxWidth,
          // Высоту сохраняем такой же, как у родителя (если она известна),
          // чтобы прокручиваемые списки внутри работали правильно.
          height: constraints.hasBoundedHeight ? constraints.maxHeight : null,
          child: child,
        ),
      );
    },
  );
}

/// Логотип приложения: оранжевая «М» на тёмно-синем фоне с линией маршрута.
class AppLogo extends StatelessWidget {
  /// Создаёт логотип; [size] — длина стороны квадрата (по умолчанию 96).
  const AppLogo({super.key, this.size = 96});

  /// Сторона квадратного логотипа в логических пикселях.
  final double size;

  /// Рисует скруглённый тёмно-синий квадрат с тенью, а внутри — букву «М».
  @override
  Widget build(BuildContext context) {
    // Квадратный контейнер-фон логотипа.
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        // Тёмно-синий фон из палитры приложения.
        color: AppColors.navy,
        // Радиус скругления пропорционален размеру логотипа.
        borderRadius: BorderRadius.circular(size * .28),
        // Мягкая полупрозрачная тень снизу.
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: .35),
            blurRadius: size * .2,
            offset: Offset(0, size * .08),
          ),
        ],
      ),
      // Саму букву «М» рисует _RoutePainter на холсте.
      child: CustomPaint(painter: _RoutePainter()),
    );
  }
}

/// Художник (CustomPainter) для логотипа: рисует букву «М» как линию
/// маршрута с белыми точками начала и конца.
class _RoutePainter extends CustomPainter {
  /// Рисует логотип на холсте [canvas] размером [size].
  @override
  void paint(Canvas canvas, Size size) {
    // Ширина и высота холста; все координаты считаются в долях от них,
    // поэтому логотип выглядит одинаково при любом размере.
    final w = size.width;
    final h = size.height;
    // Ломаная линия в форме буквы «М»: снизу вверх, вниз к середине,
    // снова вверх и вниз.
    final path = Path()
      ..moveTo(w * .22, h * .74)
      ..lineTo(w * .22, h * .30)
      ..lineTo(w * .50, h * .58)
      ..lineTo(w * .78, h * .30)
      ..lineTo(w * .78, h * .74);
    // Обводим линию толстой оранжевой кистью со скруглёнными концами
    // и углами.
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .1
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    // Белая заливка для точек.
    final dot = Paint()..color = Colors.white;
    // Две белые точки на концах «М» — начало и конец маршрута.
    canvas.drawCircle(Offset(w * .22, h * .74), w * .065, dot);
    canvas.drawCircle(Offset(w * .78, h * .74), w * .065, dot);
  }

  /// Логотип никогда не меняется, поэтому перерисовывать его не нужно.
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Кольцо прогресса с процентом в центре.
class ProgressRing extends StatelessWidget {
  /// Создаёт кольцо; [value] — доля от 0 до 1.
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 88,
    this.stroke = 9,
    this.label,
  });

  /// Прогресс от 0.0 до 1.0 (значения вне диапазона обрезаются).
  final double value;

  /// Диаметр кольца.
  final double size;

  /// Толщина линии кольца.
  final double stroke;

  /// Текст в центре вместо процента (если `null`, показывается «NN%»).
  final String? label;

  /// Строит кольцо и подпись в его центре.
  @override
  Widget build(BuildContext context) {
    // Набор цветов текущей темы.
    final scheme = Theme.of(context).colorScheme;
    // Ограничиваем значение диапазоном 0…1, чтобы дуга не вышла за круг.
    final clamped = value.clamp(0.0, 1.0);
    // Квадрат размером size × size под кольцо.
    return SizedBox(
      width: size,
      height: size,
      // Само кольцо рисует _RingPainter.
      child: CustomPaint(
        painter: _RingPainter(
          value: clamped,
          stroke: stroke,
          // Цвет «дорожки» — бледного полного круга под прогрессом.
          track: scheme.outlineVariant.withValues(alpha: .5),
        ),
        // Текст по центру кольца.
        child: Center(
          child: Text(
            // Своя подпись или процент, округлённый до целого.
            label ?? '${(clamped * 100).round()}%',
            style: TextStyle(
              // Размер шрифта пропорционален размеру кольца.
              fontSize: size * .22,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

/// Художник для [ProgressRing]: рисует бледный полный круг и поверх него
/// оранжевую дугу, длина которой равна прогрессу.
class _RingPainter extends CustomPainter {
  /// Принимает прогресс, толщину линии и цвет дорожки.
  _RingPainter({
    required this.value,
    required this.stroke,
    required this.track,
  });

  /// Прогресс от 0 до 1.
  final double value;

  /// Толщина линии.
  final double stroke;

  /// Цвет фонового круга (дорожки).
  final Color track;

  /// Рисует кольцо на холсте.
  @override
  void paint(Canvas canvas, Size size) {
    // Прямоугольник на весь холст.
    final rect = Offset.zero & size;
    // Уменьшаем его на половину толщины, чтобы линия не обрезалась краем.
    final deflated = rect.deflate(stroke / 2);
    // Общая кисть: только обводка заданной толщины с круглыми концами.
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    // Полный круг (угол 2π) цветом дорожки.
    canvas.drawArc(deflated, 0, math.pi * 2, false, base..color = track);
    // Дугу прогресса рисуем, только если прогресс больше нуля.
    if (value > 0) {
      canvas.drawArc(
        deflated,
        // Начало дуги — сверху (на 12 часов), угол −π/2.
        -math.pi / 2,
        // Длина дуги — доля полного круга, равная прогрессу.
        math.pi * 2 * value,
        false,
        base..color = AppColors.orange,
      );
    }
  }

  /// Перерисовывать нужно, только если изменился прогресс или цвет
  /// дорожки.
  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.track != track;
}

/// Пустое состояние: иконка, заголовок, пояснение и действие.
class EmptyState extends StatelessWidget {
  /// Создаёт заглушку; обязательны только [icon] и [title].
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  /// Большая иконка в оранжевом круге.
  final IconData icon;

  /// Главная строка, например «Пока нет заметок».
  final String title;

  /// Пояснение под заголовком (необязательно).
  final String? message;

  /// Подпись на кнопке действия (необязательно).
  final String? actionLabel;

  /// Что сделать при нажатии на кнопку. Кнопка показывается, только если
  /// заданы и [actionLabel], и [onAction].
  final VoidCallback? onAction;

  /// Строит заглушку по центру экрана.
  @override
  Widget build(BuildContext context) {
    // Текущая тема приложения: стили текста и цвета.
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        // Элементы друг под другом; колонка занимает минимум высоты.
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Иконка в бледно-оранжевом круге.
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.orange),
            ),
            const SizedBox(height: 16),
            // Заголовок по центру.
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            // Пояснение серым цветом — только если оно передано.
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            // Кнопка действия — только если есть и подпись, и обработчик.
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onAction,
                // Минимальный размер кнопки 200 × 48.
                style: FilledButton.styleFrom(minimumSize: const Size(200, 48)),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Ошибка загрузки данных с кнопкой повтора.
class ErrorView extends StatelessWidget {
  /// Создаёт экран ошибки; [onRetry] — что сделать по кнопке «Повторить».
  const ErrorView({super.key, required this.error, this.onRetry});

  /// Сама ошибка: её текст показывается пользователю.
  final Object error;

  /// Повторная загрузка. Если `null`, кнопки «Повторить» не будет.
  final VoidCallback? onRetry;

  /// Переиспользует [EmptyState] с иконкой ошибки.
  @override
  Widget build(BuildContext context) => EmptyState(
    icon: Icons.error_outline,
    title: 'Не удалось загрузить данные',
    // Текст ошибки превращаем в строку.
    message: '$error',
    // Кнопка появится, только если передан обработчик повтора.
    actionLabel: onRetry == null ? null : 'Повторить',
    onAction: onRetry,
  );
}

/// Индикатор загрузки по центру экрана (крутящийся круг).
class LoadingView extends StatelessWidget {
  /// Создаёт индикатор загрузки.
  const LoadingView({super.key});

  /// Возвращает стандартный CircularProgressIndicator по центру.
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

/// Заголовок раздела на экране.
class SectionTitle extends StatelessWidget {
  /// Создаёт заголовок с текстом [text] и, при желании, виджетом справа.
  const SectionTitle(this.text, {super.key, this.trailing});

  /// Текст заголовка.
  final String text;

  /// Виджет справа от заголовка (например, кнопка «Все»), необязательно.
  final Widget? trailing;

  /// Строит строку: заголовок слева, [trailing] справа.
  @override
  Widget build(BuildContext context) => Padding(
    // Отступы сверху и снизу от заголовка.
    padding: const EdgeInsets.only(top: 8, bottom: 8),
    child: Row(
      children: [
        // Текст занимает всё свободное место слева.
        Expanded(
          child: Text(
            text,
            // Стиль titleMedium из темы, но жирнее.
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        // `?trailing` добавит виджет в список, только если он не null.
        ?trailing,
      ],
    ),
  );
}

/// Аватар пользователя с инициалами.
class UserAvatar extends StatelessWidget {
  /// Создаёт аватар с инициалами [initials] на фоне цвета [color].
  const UserAvatar({
    super.key,
    required this.initials,
    required this.color,
    this.radius = 28,
  });

  /// Инициалы пользователя, например «АБ».
  final String initials;

  /// Цвет фона в виде числа ARGB (так он хранится в профиле).
  final int color;

  /// Радиус круга аватара.
  final double radius;

  /// Строит круглый аватар с белыми инициалами.
  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: radius,
    // Число превращаем в объект Color.
    backgroundColor: Color(color),
    child: Text(
      initials,
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        // Размер шрифта пропорционален размеру аватара.
        fontSize: radius * .7,
      ),
    ),
  );
}

/// Показывает внизу экрана всплывающее сообщение (SnackBar) с текстом
/// [message]. Если [error] = true, фон сообщения красный.
void showSnack(BuildContext context, String message, {bool error = false}) {
  // ScaffoldMessenger управляет всплывающими сообщениями экрана.
  ScaffoldMessenger.of(context)
    // Сначала убираем предыдущее сообщение, чтобы они не копились.
    ..hideCurrentSnackBar()
    // Затем показываем новое.
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        // Цвет ошибки из темы; null — обычный цвет SnackBar.
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
}

/// Показывает диалог подтверждения с кнопками «Отмена» и [confirmLabel].
///
/// Возвращает `true`, если пользователь подтвердил действие, и `false`,
/// если отменил или закрыл диалог. При [destructive] = true кнопка
/// подтверждения красная (для удаления).
Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Удалить',
  bool destructive = true,
}) async {
  // Открываем диалог и ждём, какое значение он вернёт при закрытии.
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        // «Отмена» закрывает диалог и возвращает false.
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Отмена'),
        ),
        // Кнопка подтверждения закрывает диалог и возвращает true.
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          // Для опасного действия текст кнопки окрашивается в цвет ошибки.
          style: destructive
              ? TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                )
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  // Если диалог закрыли тапом мимо него, result будет null — это «нет».
  return result ?? false;
}

/// Иконка направления по имени из JSON.
///
/// В каталоге направлений иконка записана строкой; здесь строка
/// переводится в иконку Flutter. Неизвестное имя — иконка «школа».
IconData directionIcon(String name) => switch (name) {
  'phone_android' => Icons.phone_android,
  'code' => Icons.code,
  'translate' => Icons.translate,
  'account_tree' => Icons.account_tree,
  _ => Icons.school,
};
