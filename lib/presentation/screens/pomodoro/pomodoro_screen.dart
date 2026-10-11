// Экран таймера Pomodoro: интервал фокуса (учёбы), затем перерыв.
// Завершённые интервалы фокуса записываются в базу и попадают в статистику.
// Слой: presentation (интерфейс). Открывается по маршруту '/pomodoro'
// с главного экрана и из карточки занятия (тогда передаётся тема).
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
  /// Создаёт режим с [focus] минутами работы и [rest] минутами отдыха.
  const PomodoroMode(this.focus, this.rest);

  /// Длительность интервала фокуса (учёбы) в минутах.
  final int focus;

  /// Длительность перерыва в минутах.
  final int rest;

  /// Подпись режима для переключателя, например «25 / 5».
  String get label => '$focus / $rest';
}

/// Таймер Pomodoro: интервал фокуса, затем короткий перерыв.
///
/// Оставшееся время считается от момента окончания интервала, а не
/// уменьшением счётчика, поэтому таймер не «отстаёт», если тики Timer
/// приходят с задержкой.
///
/// ConsumerStatefulWidget — виджет со своим состоянием и доступом
/// к провайдерам Riverpod (библиотека, через которую интерфейс получает
/// общие данные и репозитории приложения).
class PomodoroScreen extends ConsumerStatefulWidget {
  /// Создаёт экран таймера. [topicTitle] — название темы, если таймер
  /// запущен из карточки занятия (из параметра адреса `topic`).
  const PomodoroScreen({super.key, this.topicTitle});

  /// Тема, по которой идёт работа; `null`, если таймер запущен без темы.
  final String? topicTitle;

  /// Доступные режимы: 25 минут фокуса / 5 отдыха и 50 / 10.
  static const modes = [PomodoroMode(25, 5), PomodoroMode(50, 10)];

  /// Создаёт объект состояния, в котором работает таймер.
  @override
  ConsumerState<PomodoroScreen> createState() => _PomodoroScreenState();
}

/// Состояние таймера: режим, фаза (фокус или перерыв) и оставшееся время.
class _PomodoroScreenState extends ConsumerState<PomodoroScreen> {
  /// Выбранный режим; по умолчанию первый (25 / 5).
  PomodoroMode _mode = PomodoroScreen.modes.first;

  /// `true` — идёт фокус, `false` — перерыв.
  bool _isFocus = true;

  /// Периодический таймер, который «тикает» 4 раза в секунду.
  /// `null`, когда таймер не запущен (стоит на паузе или сброшен).
  Timer? _timer;

  /// Момент времени, когда закончится текущий интервал.
  DateTime? _endsAt;

  /// Сколько времени осталось до конца интервала (показывается на экране).
  Duration _remaining = Duration(minutes: PomodoroScreen.modes.first.focus);

  /// Полная длительность текущего интервала: фокуса или перерыва.
  Duration get _total => Duration(minutes: _isFocus ? _mode.focus : _mode.rest);

  /// Запущен ли таймер сейчас (есть ли активный Timer).
  bool get _running => _timer != null;

  /// Останавливает таймер при закрытии экрана, чтобы он не тикал
  /// впустую и не вызывал setState у закрытого экрана.
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Запускает (или продолжает после паузы) отсчёт.
  void _start() {
    // Запоминаем, когда интервал закончится: сейчас + оставшееся время.
    _endsAt = DateTime.now().add(_remaining);
    // Каждые 250 мс вызываем _tick, чтобы обновлять цифры на экране.
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
    // Перерисовываем экран: кнопка «Старт» сменится на «Пауза».
    setState(() {});
  }

  /// Ставит таймер на паузу; оставшееся время сохраняется в [_remaining].
  void _pause() {
    // Останавливаем и забываем таймер.
    _timer?.cancel();
    _timer = null;
    // Перерисовываем: кнопка «Пауза» сменится на «Старт».
    setState(() {});
  }

  /// Сбрасывает таймер: останавливает его и возвращает полное время
  /// текущего интервала.
  void _reset() {
    _timer?.cancel();
    _timer = null;
    setState(() => _remaining = _total);
  }

  /// Один «тик» таймера: пересчитывает оставшееся время.
  void _tick() {
    // Сколько осталось: разница между моментом окончания и текущим временем.
    final left = _endsAt!.difference(DateTime.now());
    // Время вышло — завершаем интервал.
    if (left <= Duration.zero) {
      _complete();
    } else {
      // Иначе обновляем цифры и кольцо на экране.
      setState(() => _remaining = left);
    }
  }

  /// Завершает текущий интервал (по таймеру или досрочно кнопкой)
  /// и переключает фазу: фокус → перерыв или перерыв → фокус.
  ///
  /// После фокуса записывает «помидор» в базу и показывает уведомление
  /// о перерыве; после перерыва — уведомление о возврате к учёбе.
  Future<void> _complete() async {
    // Останавливаем таймер.
    _timer?.cancel();
    _timer = null;
    // Запоминаем, какая фаза закончилась, до переключения.
    final wasFocus = _isFocus;
    // Переключаем фазу и выставляем полное время новой фазы.
    setState(() {
      _isFocus = !_isFocus;
      _remaining = _total;
    });
    // Сервис уведомлений (показывает системные оповещения).
    final reminders = ref.read(reminderServiceProvider);
    if (wasFocus) {
      // Закончился фокус. Берём id вошедшего пользователя.
      final userId = ref.read(currentUserIdProvider);
      // Если пользователь известен — сохраняем завершённый интервал
      // (минуты и тему) в базу через репозиторий Pomodoro.
      if (userId != null) {
        await ref
            .read(pomodoroRepositoryProvider)
            .logPomodoro(
              userId: userId,
              minutes: _mode.focus,
              topicTitle: widget.topicTitle,
            );
      }
      // Уведомление: помидор завершён, пора отдохнуть.
      await reminders.showNow(
        title: 'Помидор завершён 🍅',
        body: 'Отличная работа! Сделайте перерыв ${_mode.rest} минут.',
      );
    } else {
      // Закончился перерыв — уведомление о возврате к учёбе.
      await reminders.showNow(
        title: 'Перерыв окончен',
        body: 'Возвращаемся к учёбе?',
      );
    }
  }

  /// Строит экран: выбор режима, название фазы, круглый таймер,
  /// кнопки управления и счётчик помидоров за сегодня.
  @override
  Widget build(BuildContext context) {
    // Тема приложения: стили текста и цвета.
    final theme = Theme.of(context);
    // Сегодняшняя дата (без времени) из провайдера.
    final today = ref.watch(todayProvider);
    // Сколько помидоров завершено сегодня: берём все записи
    // и оставляем только те, что завершены в тот же день.
    final todayCount = (ref.watch(pomodorosProvider).value ?? const [])
        .where((p) => isSameDay(p.completedAt, today))
        .length;
    // Доля прошедшего времени от 0 до 1 — для заполнения кольца.
    final progress = 1 - _remaining.inMilliseconds / _total.inMilliseconds;
    // Оставшиеся минуты и секунды для надписи «ММ:СС».
    final minutes = _remaining.inMinutes;
    final seconds = _remaining.inSeconds % 60;
    // Цвет фазы: оранжевый — фокус, зелёный — перерыв.
    final color = _isFocus ? AppColors.orange : AppColors.success;

    // Scaffold — каркас экрана: верхняя панель и основная область.
    return Scaffold(
      appBar: AppBar(title: const Text('Pomodoro')),
      // ContentFrame ограничивает ширину содержимого на широких экранах.
      body: ContentFrame(
        // Прокручиваемый список элементов с отступом 24.
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Переключатель режима (25 / 5 или 50 / 10 минут).
            Center(
              child: SegmentedButton<PomodoroMode>(
                segments: [
                  // По одному сегменту на каждый режим из списка modes.
                  for (final m in PomodoroScreen.modes)
                    ButtonSegment(value: m, label: Text('${m.label} мин')),
                ],
                selected: {_mode},
                // Пока таймер идёт, менять режим нельзя (null — неактивно).
                // При выборе режима начинаем заново с фазы фокуса.
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
            // Название текущей фазы цветом фазы: «Фокус» или «Перерыв».
            Text(
              _isFocus ? 'Фокус' : 'Перерыв',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(color: color),
            ),
            // Название темы под фазой — только если тема передана.
            if (widget.topicTitle != null)
              Text(
                widget.topicTitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            const SizedBox(height: 24),
            // Круглый таймер 240×240: кольцо прогресса и время в центре.
            Center(
              child: SizedBox(
                width: 240,
                height: 240,
                // CustomPaint рисует кольцо с помощью _TimerPainter.
                child: CustomPaint(
                  painter: _TimerPainter(
                    // clamp ограничивает прогресс диапазоном от 0 до 1.
                    progress: progress.clamp(0, 1),
                    color: color,
                    // Цвет «дорожки» — бледное полное кольцо под прогрессом.
                    track: theme.colorScheme.outlineVariant.withValues(
                      alpha: .4,
                    ),
                  ),
                  // Оставшееся время «ММ:СС» крупным шрифтом в центре.
                  // tabularFigures — цифры одинаковой ширины, чтобы текст
                  // не дёргался при смене секунд.
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
            // Ряд из двух кнопок одинаковой ширины.
            Row(
              children: [
                // Кнопка «Старт»/«Пауза»: иконка и текст зависят от того,
                // идёт ли таймер.
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('pomodoro_start'),
                    icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                    label: Text(_running ? 'Пауза' : 'Старт'),
                    onPressed: _running ? _pause : _start,
                  ),
                ),
                const SizedBox(width: 12),
                // Кнопка «Сброс»: возвращает полное время интервала.
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
            // Кнопка досрочного завершения фазы: во время фокуса —
            // «Завершить фокус досрочно», во время перерыва — «Пропустить».
            TextButton(
              onPressed: _complete,
              child: Text(
                _isFocus ? 'Завершить фокус досрочно' : 'Пропустить перерыв',
              ),
            ),
            const SizedBox(height: 16),
            // Счётчик помидоров за сегодня («Сегодня: 3 помидора»).
            Text(
              todayCount == 0
                  ? 'Сегодня помидоров пока нет'
                  : 'Сегодня: ${Fmt.count(todayCount, 'помидор', 'помидора', 'помидоров')}',
              textAlign: TextAlign.center,
            ),
            // Если сегодня были помидоры — ряд иконок, по одной
            // на помидор, но не больше 12.
            if (todayCount > 0) ...[
              const SizedBox(height: 4),
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  for (var i = 0; i < math.min(todayCount, 12); i++)
                    const Icon(Icons.timer, size: 20, color: AppColors.orange),
                ],
              ),
            ],
            const SizedBox(height: 8),
            // Короткая подсказка о том, как работает техника Pomodoro.
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

/// Рисует кольцо таймера: бледную полную окружность («дорожку»)
/// и поверх неё цветную дугу прогресса.
///
/// CustomPainter — класс Flutter для рисования своей графики на холсте
/// (Canvas).
class _TimerPainter extends CustomPainter {
  /// Создаёт рисовальщик с долей прогресса и цветами дуги и дорожки.
  _TimerPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  /// Доля прошедшего времени от 0 до 1 (какая часть кольца закрашена).
  final double progress;

  /// Цвет дуги прогресса (зависит от фазы).
  final Color color;

  /// Цвет фоновой окружности.
  final Color track;

  /// Рисует кольцо на холсте размера [size].
  @override
  void paint(Canvas canvas, Size size) {
    // Область рисования: весь размер, уменьшенный на 8 с каждой стороны,
    // чтобы толстая линия не обрезалась по краям.
    final rect = (Offset.zero & size).deflate(8);
    // Кисть: только контур, толщина 14, закруглённые концы линии.
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    // Полная окружность (угол 2π) цветом дорожки.
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = track);
    // Дуга прогресса: начинается сверху (угол -π/2) и идёт по часовой
    // стрелке на долю progress от полного круга.
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      paint..color = color,
    );
  }

  /// Перерисовывать кольцо нужно, только если изменился прогресс или цвет.
  @override
  bool shouldRepaint(_TimerPainter old) =>
      old.progress != progress || old.color != color;
}
