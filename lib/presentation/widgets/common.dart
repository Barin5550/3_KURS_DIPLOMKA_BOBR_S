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
  const ContentFrame({
    super.key,
    required this.child,
    this.maxWidth = kContentMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (!constraints.hasBoundedWidth || constraints.maxWidth <= maxWidth) {
        return child;
      }
      return Center(
        child: SizedBox(
          width: maxWidth,
          height: constraints.hasBoundedHeight ? constraints.maxHeight : null,
          child: child,
        ),
      );
    },
  );
}

/// Логотип приложения: оранжевая «М» на тёмно-синем фоне с линией маршрута.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(size * .28),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: .35),
            blurRadius: size * .2,
            offset: Offset(0, size * .08),
          ),
        ],
      ),
      child: CustomPaint(painter: _RoutePainter()),
    );
  }
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * .22, h * .74)
      ..lineTo(w * .22, h * .30)
      ..lineTo(w * .50, h * .58)
      ..lineTo(w * .78, h * .30)
      ..lineTo(w * .78, h * .74);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .1
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final dot = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * .22, h * .74), w * .065, dot);
    canvas.drawCircle(Offset(w * .78, h * .74), w * .065, dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Кольцо прогресса с процентом в центре.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 88,
    this.stroke = 9,
    this.label,
  });

  final double value;
  final double size;
  final double stroke;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final clamped = value.clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          value: clamped,
          stroke: stroke,
          track: scheme.outlineVariant.withValues(alpha: .5),
        ),
        child: Center(
          child: Text(
            label ?? '${(clamped * 100).round()}%',
            style: TextStyle(
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

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.stroke,
    required this.track,
  });

  final double value;
  final double stroke;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final deflated = rect.deflate(stroke / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(deflated, 0, math.pi * 2, false, base..color = track);
    if (value > 0) {
      canvas.drawArc(
        deflated,
        -math.pi / 2,
        math.pi * 2 * value,
        false,
        base..color = AppColors.orange,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.track != track;
}

/// Пустое состояние: иконка, заголовок, пояснение и действие.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.orange),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
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
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onAction,
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
  const ErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: Icons.error_outline,
    title: 'Не удалось загрузить данные',
    message: '$error',
    actionLabel: onRetry == null ? null : 'Повторить',
    onAction: onRetry,
  );
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

/// Заголовок раздела на экране.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

/// Аватар пользователя с инициалами.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.initials,
    required this.color,
    this.radius = 28,
  });

  final String initials;
  final int color;
  final double radius;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: radius,
    backgroundColor: Color(color),
    child: Text(
      initials,
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: radius * .7,
      ),
    ),
  );
}

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
}

Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Удалить',
  bool destructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
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
  return result ?? false;
}

/// Иконка направления по имени из JSON.
IconData directionIcon(String name) => switch (name) {
  'phone_android' => Icons.phone_android,
  'code' => Icons.code,
  'translate' => Icons.translate,
  'account_tree' => Icons.account_tree,
  _ => Icons.school,
};
