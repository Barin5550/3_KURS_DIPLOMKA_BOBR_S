import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/planner/dates.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

/// Режим таймера: длительность фокуса и перерыва в минутах.
class PomodoroMode {
  const PomodoroMode(this.focus, this.rest);

  final int focus;
  final int rest;

  String get label => '$focus / $rest';
}

/// Таймер Pomodoro: интервал фокуса, затем короткий перерыв.
///
/// Оставшееся время считается от момента окончания интервала, а не
/// уменьшением счётчика, поэтому таймер не «отстаёт», если тики Timer
/// приходят с задержкой.
class PomodoroScreen extends ConsumerStatefulWidget {
  const PomodoroScreen({super.key, this.topicTitle});

  final String? topicTitle;

  static const modes = [PomodoroMode(25, 5), PomodoroMode(50, 10)];

  @override
  ConsumerState<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends ConsumerState<PomodoroScreen> {
  PomodoroMode _mode = PomodoroScreen.modes.first;
  bool _isFocus = true;
  Timer? _timer;
  DateTime? _endsAt;
  Duration _remaining = Duration(minutes: PomodoroScreen.modes.first.focus);

  Duration get _total => Duration(minutes: _isFocus ? _mode.focus : _mode.rest);
  bool get _running => _timer != null;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _endsAt = DateTime.now().add(_remaining);
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
    setState(() {});
  }

  void _pause() {
    _timer?.cancel();
    _timer = null;
    setState(() {});
  }

  void _reset() {
    _timer?.cancel();
    _timer = null;
    setState(() => _remaining = _total);
  }

  void _tick() {
    final left = _endsAt!.difference(DateTime.now());
    if (left <= Duration.zero) {
      _complete();
    } else {
      setState(() => _remaining = left);
    }
  }

  Future<void> _complete() async {
    _timer?.cancel();
    _timer = null;
    final wasFocus = _isFocus;
    setState(() {
      _isFocus = !_isFocus;
      _remaining = _total;
    });
    final reminders = ref.read(reminderServiceProvider);
    if (wasFocus) {
      final userId = ref.read(currentUserIdProvider);
      if (userId != null) {
        await ref
            .read(pomodoroRepositoryProvider)
            .logPomodoro(
              userId: userId,
              minutes: _mode.focus,
              topicTitle: widget.topicTitle,
            );
      }
      await reminders.showNow(
        title: 'Помидор завершён 🍅',
        body: 'Отличная работа! Сделайте перерыв ${_mode.rest} минут.',
      );
    } else {
      await reminders.showNow(
        title: 'Перерыв окончен',
        body: 'Возвращаемся к учёбе?',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = ref.watch(todayProvider);
    final todayCount = (ref.watch(pomodorosProvider).value ?? const [])
        .where((p) => isSameDay(p.completedAt, today))
        .length;
    final progress = 1 - _remaining.inMilliseconds / _total.inMilliseconds;
    final minutes = _remaining.inMinutes;
    final seconds = _remaining.inSeconds % 60;
    final color = _isFocus ? AppColors.orange : AppColors.success;

    return Scaffold(
      appBar: AppBar(title: const Text('Pomodoro')),
      body: ContentFrame(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: SegmentedButton<PomodoroMode>(
                segments: [
                  for (final m in PomodoroScreen.modes)
                    ButtonSegment(value: m, label: Text('${m.label} мин')),
                ],
                selected: {_mode},
                onSelectionChanged: _running
                    ? null
                    : (s) => setState(() {
                        _mode = s.first;
                        _isFocus = true;
                        _remaining = _total;
                      }),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isFocus ? 'Фокус' : 'Перерыв',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(color: color),
            ),
            if (widget.topicTitle != null)
              Text(
                widget.topicTitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            const SizedBox(height: 24),
            Center(
              child: SizedBox(
                width: 240,
                height: 240,
                child: CustomPaint(
                  painter: _TimerPainter(
                    progress: progress.clamp(0, 1),
                    color: color,
                    track: theme.colorScheme.outlineVariant.withValues(
                      alpha: .4,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                      key: const Key('pomodoro_time'),
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('pomodoro_start'),
                    icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                    label: Text(_running ? 'Пауза' : 'Старт'),
                    onPressed: _running ? _pause : _start,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Сброс'),
                    onPressed: _reset,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _complete,
              child: Text(
                _isFocus ? 'Завершить фокус досрочно' : 'Пропустить перерыв',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              todayCount == 0
                  ? 'Сегодня помидоров пока нет'
                  : 'Сегодня: ${'🍅' * math.min(todayCount, 12)} '
                        '(${Fmt.count(todayCount, 'помидор', 'помидора', 'помидоров')})',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Техника Pomodoro: работайте без отвлечений до сигнала таймера, '
              'затем отдохните. После четырёх интервалов сделайте длинный перерыв.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimerPainter extends CustomPainter {
  _TimerPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(8);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = track);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      paint..color = color,
    );
  }

  @override
  bool shouldRepaint(_TimerPainter old) =>
      old.progress != progress || old.color != color;
}
