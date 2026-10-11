// Вкладка «Статистика»: итоговые цифры (часы, занятия, помидоры),
// столбчатая диаграмма часов по неделям, круговая диаграмма по категориям
// и история последних действий.
// Слой: presentation (интерфейс). Открывается по маршруту '/stats' из панели
// навигации; данные берёт из провайдеров занятий и Pomodoro, графики рисует
// библиотека fl_chart.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/note.dart';
import '../../../domain/entities/session.dart';
import '../../../domain/planner/dates.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

/// Вкладка «Статистика»: итоги, графики по неделям и категориям, история.
///
/// ConsumerWidget — виджет без своего состояния, который читает провайдеры
/// Riverpod (Riverpod — библиотека, через которую экраны получают общие
/// данные). При появлении новых занятий экран перерисуется сам.
class StatsScreen extends ConsumerWidget {
  /// Создаёт вкладку статистики (параметров нет).
  const StatsScreen({super.key});

  /// Строит экран статистики. `ref` — доступ к провайдерам Riverpod.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Завершённые занятия в виде AsyncValue — «асинхронного значения»,
    // которое бывает в трёх состояниях: загрузка, ошибка или данные.
    final completedAsync = ref.watch(completedSessionsProvider);
    // Все завершённые помидоры; пока грузятся — пустой список.
    final pomodoros = ref.watch(pomodorosProvider).value ?? const [];
    // Сегодняшняя дата — нужна графику по неделям.
    final today = ref.watch(todayProvider);

    // Scaffold — каркас экрана: верхняя панель и основная область.
    return Scaffold(
      appBar: AppBar(title: const Text('Статистика')),
      // ContentFrame ограничивает ширину содержимого на широких экранах.
      body: ContentFrame(
        // when выбирает, что показать, в зависимости от состояния данных.
        child: completedAsync.when(
          // Данные ещё грузятся — индикатор загрузки.
          loading: () => const LoadingView(),
          // Ошибка загрузки — экран ошибки.
          error: (e, _) => ErrorView(error: e),
          // Данные получены — строим статистику.
          data: (completed) {
            // Нет ни занятий, ни помидоров — заглушка с подсказкой.
            if (completed.isEmpty && pomodoros.isEmpty) {
              return const EmptyState(
                key: Key('stats_empty'),
                icon: Icons.insights,
                title: 'Статистика появится после первых занятий',
                message:
                    'Отмечайте выполненные занятия на главной или в плане.',
              );
            }
            // Сумма минут всех завершённых занятий
            // (fold — свёртка списка в одно число).
            final minutes = completed.fold<int>(0, (s, e) => s + e.minutes);
            // Сумма минут фокуса во всех помидорах.
            final focus = pomodoros.fold<int>(0, (s, e) => s + e.minutes);
            // Общая история: занятия и помидоры, новые сверху.
            final history = _history(completed, pomodoros);

            // Прокручиваемый список блоков статистики с отступом 16.
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Блок 1. Три плитки с итогами в ряд. IntrinsicHeight
                // вместе со stretch делает плитки одинаковой высоты.
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Плитка «часы учёбы»: минуты переводим в часы.
                      _Tile(
                        icon: Icons.schedule,
                        value: Fmt.hours(minutes / 60),
                        label: '${Fmt.hoursWord(minutes / 60)} учёбы',
                      ),
                      const SizedBox(width: 8),
                      // Плитка «занятия»: число завершённых занятий,
                      // Fmt.plural выбирает форму слова.
                      _Tile(
                        icon: Icons.task_alt,
                        value: '${completed.length}',
                        label: Fmt.plural(
                          completed.length,
                          'занятие',
                          'занятия',
                          'занятий',
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Плитка «помидоры»: их число и, если есть,
                      // суммарное время фокуса мелкой подписью.
                      _Tile(
                        icon: Icons.timer,
                        value: '${pomodoros.length}',
                        label: Fmt.plural(
                          pomodoros.length,
                          'помидор',
                          'помидора',
                          'помидоров',
                        ),
                        caption: focus == 0 ? null : Fmt.minutes(focus),
                      ),
                    ],
                  ),
                ),
                // Блок 2. Заголовок и карточка со столбчатой диаграммой
                // часов за последние недели (высота 180).
                const SectionTitle('Часы по неделям'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
                    child: SizedBox(
                      height: 180,
                      child: _WeeklyChart(sessions: completed, today: today),
                    ),
                  ),
                ),
                // Блок 3. Круговая диаграмма по категориям — только если
                // есть хотя бы одно занятие (по помидорам её не строим).
                if (completed.isNotEmpty) ...[
                  const SectionTitle('По категориям'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _CategoryChart(sessions: completed),
                    ),
                  ),
                ],
                // Блок 4. История: не больше 30 последних записей,
                // каждая — отдельная карточка.
                const SectionTitle('История'),
                for (final h in history.take(30))
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      // Иконка по типу записи: занятие — галочка,
                      // повторение — круговая стрелка, помидор — таймер.
                      leading: Icon(switch (h.kind) {
                        HistoryKind.session => Icons.check_circle,
                        HistoryKind.review => Icons.replay_circle_filled,
                        HistoryKind.pomodoro => Icons.timer,
                      }, color: AppColors.orange),
                      // Название записи.
                      title: Text(h.title),
                      // Длительность и дата со временем завершения.
                      subtitle: Text('${h.subtitle} · ${Fmt.dateTime(h.at)}'),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Собирает общую историю из завершённых занятий [sessions]
  /// и помидоров [pomodoros] и сортирует её от новых записей к старым.
  static List<HistoryEntry> _history(
    List<StudySession> sessions,
    List<PomodoroEntry> pomodoros,
  ) {
    // Список записей истории строим из двух источников.
    final items = <HistoryEntry>[
      // Занятия: берём только те, у которых есть время завершения.
      for (final s in sessions)
        if (s.completedAt != null)
          HistoryEntry(
            title: s.displayTitle,
            subtitle: Fmt.minutes(s.minutes),
            at: s.completedAt!,
            // Повторение и обычное занятие показываются разными иконками.
            kind: s.kind == SessionKind.review
                ? HistoryKind.review
                : HistoryKind.session,
          ),
      // Помидоры: заголовок «Pomodoro» и, если была тема, «: тема».
      for (final p in pomodoros)
        HistoryEntry(
          title: 'Pomodoro${p.topicTitle == null ? '' : ': ${p.topicTitle}'}',
          subtitle: Fmt.minutes(p.minutes),
          at: p.completedAt,
          kind: HistoryKind.pomodoro,
        ),
    ];
    // Сортировка по времени по убыванию: самые свежие записи сверху.
    items.sort((a, b) => b.at.compareTo(a.at));
    return items;
  }
}

/// Плитка с итоговой цифрой: иконка, крупное значение, подпись
/// и необязательная дополнительная строка.
class _Tile extends StatelessWidget {
  /// Создаёт плитку; [caption] можно не передавать.
  const _Tile({
    required this.icon,
    required this.value,
    required this.label,
    this.caption,
  });

  /// Иконка в верхней части плитки.
  final IconData icon;

  /// Главное значение крупным шрифтом (уже в виде строки).
  final String value;

  /// Подпись под значением.
  final String label;

  /// Дополнительная мелкая строка (например, минуты фокуса);
  /// `null` — строки нет.
  final String? caption;

  /// Строит плитку. Expanded делит ширину ряда поровну между плитками.
  @override
  Widget build(BuildContext context) => Expanded(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        // Содержимое колонкой, выровнено по левому краю.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Оранжевая иконка показателя.
            Icon(icon, color: AppColors.orange),
            const SizedBox(height: 8),
            // Значение крупным жирным шрифтом.
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            // Подпись мелким шрифтом.
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            // Дополнительная строка приглушённым цветом — если задана.
            if (caption != null)
              Text(
                caption!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Столбчатая диаграмма: часы изучения за последние 6 недель.
class _WeeklyChart extends StatelessWidget {
  /// Создаёт диаграмму по списку занятий [sessions] относительно
  /// сегодняшней даты [today].
  const _WeeklyChart({required this.sessions, required this.today});

  /// Завершённые занятия, из которых считаются часы.
  final List<StudySession> sessions;

  /// Сегодняшняя дата: от неё отсчитываются недели назад.
  final DateTime today;

  /// Сколько последних недель показывать на диаграмме.
  static const weeks = 6;

  /// Считает часы по неделям и строит диаграмму BarChart из fl_chart.
  @override
  Widget build(BuildContext context) {
    // Понедельник текущей недели: weekday у понедельника равен 1,
    // поэтому отступаем назад на (weekday - 1) дней.
    final monday = addDays(today, -(today.weekday - 1));
    // Понедельники последних 6 недель — от самой старой к текущей.
    final starts = [
      for (var i = weeks - 1; i >= 0; i--) addDays(monday, -7 * i),
    ];
    // Часы по каждой неделе, сначала все нули.
    final hours = List<double>.filled(weeks, 0);
    // Раскладываем каждое занятие по неделям.
    for (final s in sessions) {
      // Пропускаем занятия без даты завершения.
      final done = s.completedAt;
      if (done == null) continue;
      // Берём только дату завершения, без времени.
      final day = dateOnly(done);
      // Ищем неделю, в которую попадает день: не раньше её понедельника
      // и раньше следующего понедельника. Добавляем минуты в часах.
      for (var i = 0; i < weeks; i++) {
        if (!day.isBefore(starts[i]) && day.isBefore(addDays(starts[i], 7))) {
          hours[i] += s.minutes / 60;
        }
      }
    }
    // Верх шкалы — ближайшее «круглое» значение, чтобы подписи оси
    // были целыми: 0, 2, 4, 6, 8, а не 0, 5, 7,8.
    final peak = hours.fold<double>(1, (m, h) => h > m ? h : m) * 1.15;
    // Шаг делений оси: чем больше максимум, тем крупнее шаг
    // (1, 2, 5 или 10 часов).
    final interval = peak <= 5
        ? 1.0
        : peak <= 10
        ? 2.0
        : peak <= 25
        ? 5.0
        : 10.0;
    // Верх оси округляем вверх до целого числа шагов.
    final maxY = (peak / interval).ceil() * interval;
    // Стиль подписей осей — мелкий текст из темы.
    final labelStyle = Theme.of(context).textTheme.bodySmall;
    // В тёмной теме тёмно-синие столбцы почти не видны на фоне карточки.
    final barColor = Theme.of(context).brightness == Brightness.dark
        ? _CategoryChart.darkNavy
        : AppColors.navy;

    // Столбчатая диаграмма из библиотеки fl_chart.
    return BarChart(
      BarChartData(
        maxY: maxY,
        // Столбцы равномерно распределены по ширине.
        alignment: BarChartAlignment.spaceAround,
        // Сетка: только горизонтальные тонкие линии на каждом делении.
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Theme.of(context).colorScheme.outlineVariant,
            strokeWidth: .5,
          ),
        ),
        // Рамку вокруг диаграммы не рисуем.
        borderData: FlBorderData(show: false),
        // Подсказка при нажатии на столбец: число часов, например «3,5 ч».
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, _, rod, _) => BarTooltipItem(
              '${Fmt.hours(rod.toY)} ч',
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        // Подписи осей: сверху и справа их нет.
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          // Слева — часы на каждом делении шкалы.
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: interval,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text(Fmt.hours(value), style: labelStyle),
              ),
            ),
          ),
          // Снизу — дата понедельника каждой недели в виде «д.мм».
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text(
                  '${starts[value.toInt()].day}.${starts[value.toInt()].month.toString().padLeft(2, '0')}',
                  style: labelStyle,
                ),
              ),
            ),
          ),
        ),
        // Сами столбцы: по одному на неделю.
        barGroups: [
          for (var i = 0; i < weeks; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                // Столбец высотой в часы недели. Текущая (последняя)
                // неделя выделена оранжевым, остальные — синим.
                // Верхние углы скруглены.
                BarChartRodData(
                  toY: hours[i],
                  width: 22,
                  color: i == weeks - 1 ? AppColors.orange : barColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Круговая диаграмма: доля времени по категориям тем.
class _CategoryChart extends StatelessWidget {
  /// Создаёт диаграмму по списку завершённых занятий [sessions].
  const _CategoryChart({required this.sessions});

  /// Завершённые занятия: их минуты суммируются по категориям.
  final List<StudySession> sessions;

  /// Замена тёмно-синего для тёмной темы.
  static const darkNavy = Color(0xFF9DB4FF);

  /// Цвета секторов по порядку; если категорий больше восьми,
  /// цвета повторяются по кругу.
  static const palette = [
    AppColors.navy,
    AppColors.orange,
    Color(0xFF4F7CFF),
    Color(0xFFFFB566),
    Color(0xFF2E9D5B),
    Color(0xFF8E5CD9),
    Color(0xFF00838F),
    Color(0xFFC62828),
  ];

  /// Считает минуты по категориям и строит диаграмму с легендой.
  @override
  Widget build(BuildContext context) {
    // Словарь «категория → сумма минут».
    final byCategory = <String, int>{};
    // Добавляем минуты каждого занятия к его категории.
    for (final s in sessions) {
      byCategory[s.category] = (byCategory[s.category] ?? 0) + s.minutes;
    }
    // Превращаем словарь в список и сортируем: самые большие
    // категории первыми.
    final entries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    // Общее число минут — для расчёта процентов.
    final total = entries.fold<int>(0, (s, e) => s + e.value);
    // Включена ли тёмная тема.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Цвет i-го сектора. В тёмной теме первый (тёмно-синий) цвет
    // заменяется на светлый darkNavy, чтобы был виден на фоне.
    Color colorAt(int i) =>
        i == 0 && isDark ? darkNavy : palette[i % palette.length];

    // Слева диаграмма, справа легенда.
    return Row(
      children: [
        // Круговая диаграмма-«бублик» размером 130×130.
        SizedBox(
          width: 130,
          height: 130,
          child: PieChart(
            PieChartData(
              // Зазор между секторами и пустой круг в центре.
              sectionsSpace: 2,
              centerSpaceRadius: 30,
              sections: [
                // Один сектор на категорию; размер — минуты,
                // подписи на самих секторах не показываем.
                for (var i = 0; i < entries.length; i++)
                  PieChartSectionData(
                    value: entries[i].value.toDouble(),
                    color: colorAt(i),
                    radius: 30,
                    showTitle: false,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Легенда занимает оставшуюся ширину.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Строка легенды на каждую категорию.
              for (var i = 0; i < entries.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      // Цветной квадратик — цвет сектора категории.
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colorAt(i),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Название категории.
                      Expanded(child: Text(entries[i].key)),
                      const SizedBox(width: 8),
                      // Доля категории в процентах, округлённая до целого.
                      Text('${(entries[i].value * 100 / total).round()}%'),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
