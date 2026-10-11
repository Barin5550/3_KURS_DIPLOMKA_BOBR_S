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
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedAsync = ref.watch(completedSessionsProvider);
    final pomodoros = ref.watch(pomodorosProvider).value ?? const [];
    final today = ref.watch(todayProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Статистика')),
      body: completedAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e),
        data: (completed) {
          if (completed.isEmpty && pomodoros.isEmpty) {
            return const EmptyState(
              key: Key('stats_empty'),
              icon: Icons.insights,
              title: 'Статистика появится после первых занятий',
              message: 'Отмечайте выполненные занятия на главной или в плане.',
            );
          }
          final minutes = completed.fold<int>(0, (s, e) => s + e.minutes);
          final focus = pomodoros.fold<int>(0, (s, e) => s + e.minutes);
          final history = _history(completed, pomodoros);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  _Tile(
                    icon: Icons.schedule,
                    value: Fmt.hours(minutes / 60),
                    label: 'часов изучено',
                  ),
                  const SizedBox(width: 8),
                  _Tile(
                    icon: Icons.task_alt,
                    value: '${completed.length}',
                    label: 'занятий',
                  ),
                  const SizedBox(width: 8),
                  _Tile(
                    icon: Icons.timer,
                    value: '${pomodoros.length}',
                    label: 'помидоров · ${Fmt.minutes(focus)}',
                  ),
                ],
              ),
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
              if (completed.isNotEmpty) ...[
                const SectionTitle('По категориям'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _CategoryChart(sessions: completed),
                  ),
                ),
              ],
              const SectionTitle('История'),
              for (final h in history.take(30))
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(switch (h.kind) {
                      HistoryKind.session => Icons.check_circle,
                      HistoryKind.review => Icons.replay_circle_filled,
                      HistoryKind.pomodoro => Icons.timer,
                    }, color: AppColors.orange),
                    title: Text(h.title),
                    subtitle: Text('${h.subtitle} · ${Fmt.dateTime(h.at)}'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static List<HistoryEntry> _history(
    List<StudySession> sessions,
    List<PomodoroEntry> pomodoros,
  ) {
    final items = <HistoryEntry>[
      for (final s in sessions)
        if (s.completedAt != null)
          HistoryEntry(
            title: s.displayTitle,
            subtitle: Fmt.minutes(s.minutes),
            at: s.completedAt!,
            kind: s.kind == SessionKind.review
                ? HistoryKind.review
                : HistoryKind.session,
          ),
      for (final p in pomodoros)
        HistoryEntry(
          title: 'Pomodoro${p.topicTitle == null ? '' : ': ${p.topicTitle}'}',
          subtitle: Fmt.minutes(p.minutes),
          at: p.completedAt,
          kind: HistoryKind.pomodoro,
        ),
    ];
    items.sort((a, b) => b.at.compareTo(a.at));
    return items;
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.orange),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ),
  );
}

/// Столбчатая диаграмма: часы изучения за последние 6 недель.
class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.sessions, required this.today});

  final List<StudySession> sessions;
  final DateTime today;

  static const weeks = 6;

  @override
  Widget build(BuildContext context) {
    final monday = addDays(today, -(today.weekday - 1));
    final starts = [
      for (var i = weeks - 1; i >= 0; i--) addDays(monday, -7 * i),
    ];
    final hours = List<double>.filled(weeks, 0);
    for (final s in sessions) {
      final done = s.completedAt;
      if (done == null) continue;
      final day = dateOnly(done);
      for (var i = 0; i < weeks; i++) {
        if (!day.isBefore(starts[i]) && day.isBefore(addDays(starts[i], 7))) {
          hours[i] += s.minutes / 60;
        }
      }
    }
    final maxY = hours.fold<double>(1, (m, h) => h > m ? h : m) * 1.25;
    final labelStyle = Theme.of(context).textTheme.bodySmall;

    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Theme.of(context).colorScheme.outlineVariant,
            strokeWidth: .5,
          ),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, _, rod, _) => BarTooltipItem(
              '${Fmt.hours(rod.toY)} ч',
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text(Fmt.hours(value), style: labelStyle),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
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
        barGroups: [
          for (var i = 0; i < weeks; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: hours[i],
                  width: 22,
                  color: i == weeks - 1 ? AppColors.orange : AppColors.navy,
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
  const _CategoryChart({required this.sessions});

  final List<StudySession> sessions;

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

  @override
  Widget build(BuildContext context) {
    final byCategory = <String, int>{};
    for (final s in sessions) {
      byCategory[s.category] = (byCategory[s.category] ?? 0) + s.minutes;
    }
    final entries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<int>(0, (s, e) => s + e.value);

    return Row(
      children: [
        SizedBox(
          width: 130,
          height: 130,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 30,
              sections: [
                for (var i = 0; i < entries.length; i++)
                  PieChartSectionData(
                    value: entries[i].value.toDouble(),
                    color: palette[i % palette.length],
                    radius: 30,
                    showTitle: false,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < entries.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: palette[i % palette.length],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(entries[i].key)),
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
