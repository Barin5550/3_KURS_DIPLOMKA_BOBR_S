import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/plan.dart';
import '../../../domain/entities/session.dart';
import '../../../domain/planner/dates.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/session_tile.dart';

/// Главная: приветствие, прогресс активного плана и задачи на сегодня.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final planAsync = ref.watch(activePlanProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Привет, ${user?.name.split(' ').first ?? ''}!'),
        actions: [
          IconButton(
            tooltip: 'Pomodoro',
            icon: const Icon(Icons.timer_outlined),
            onPressed: () => context.push('/pomodoro'),
          ),
        ],
      ),
      body: ContentFrame(
        child: planAsync.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(
            error: e,
            onRetry: () => ref.invalidate(activePlanProvider),
          ),
          data: (plan) => plan == null
              ? EmptyState(
                  key: const Key('home_empty'),
                  icon: Icons.route,
                  title: 'У вас пока нет плана',
                  message:
                      'Выберите направление, пройдите короткий тест и укажите, '
                      'сколько времени готовы уделять учёбе.',
                  actionLabel: 'Создать план',
                  onAction: () => context.push('/onboarding'),
                )
              : _HomeBody(plan: plan),
        ),
      ),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.plan});

  final StudyPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(planSessionsProvider(plan.id));
    final today = ref.watch(todayProvider);

    return sessionsAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(error: e),
      data: (sessions) {
        final progress = PlanProgress.fromSessions(sessions, today);
        final todays = sessions.where((s) => isSameDay(s.date, today)).toList();
        final next = sessions
            .where((s) => !s.isDone && s.date.isAfter(today))
            .firstOrNull;
        final streak = _streak(sessions, today);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ProgressCard(
              plan: plan,
              progress: progress,
              streak: streak,
              today: today,
            ),
            if (progress.missedSessions > 0) ...[
              const SizedBox(height: 12),
              _MissedBanner(plan: plan, missed: progress.missedSessions),
            ],
            const SizedBox(height: 8),
            SectionTitle(
              'Сегодня, ${Fmt.day(today)}',
              trailing: todays.isEmpty
                  ? null
                  : Text(
                      '${todays.where((s) => s.isDone).length} из ${todays.length}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
            ),
            if (todays.isEmpty)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.weekend_outlined),
                  title: const Text('Сегодня занятий нет'),
                  subtitle: Text(
                    next == null
                        ? 'Все занятия плана выполнены!'
                        : 'Следующее: ${Fmt.dayWithWeekday(next.date)}',
                  ),
                ),
              )
            else
              for (final s in todays)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SessionTile(
                    session: s,
                    today: today,
                    onToggle: () =>
                        ref.read(planServiceProvider).toggleSession(s),
                    onTap: () => context.push('/session/${s.id}'),
                  ),
                ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.timer_outlined),
              label: const Text('Запустить Pomodoro'),
              onPressed: () => context.push('/pomodoro'),
            ),
          ],
        );
      },
    );
  }

  /// Серия дней подряд (до сегодняшнего), в которые выполнено хотя бы
  /// одно занятие.
  static int _streak(List<StudySession> sessions, DateTime today) {
    final days = sessions
        .where((s) => s.completedAt != null)
        .map((s) => dateOnly(s.completedAt!))
        .toSet();
    var streak = 0;
    var day = days.contains(today) ? today : addDays(today, -1);
    while (days.contains(day)) {
      streak++;
      day = addDays(day, -1);
    }
    return streak;
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.plan,
    required this.progress,
    required this.streak,
    required this.today,
  });

  final StudyPlan plan;
  final PlanProgress progress;
  final int streak;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final deadline = plan.settings.deadline;
    final finish = progress.finishDate;
    final white70 = Colors.white.withValues(alpha: .75);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, AppColors.navyDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme
                  .copyWith(onSurface: Colors.white),
            ),
            child: ProgressRing(value: progress.ratio, size: 92),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${Fmt.hours(progress.doneStudyMinutes / 60)} из '
                  '${Fmt.hours(progress.totalStudyMinutes / 60)} ч',
                  style: TextStyle(color: white70),
                ),
                Row(
                  children: [
                    Text(
                      'Серия: ${Fmt.count(streak, 'день', 'дня', 'дней')}',
                      style: TextStyle(color: white70),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.local_fire_department,
                      size: 16,
                      color: streak > 0 ? AppColors.orangeLight : white70,
                    ),
                  ],
                ),
                if (deadline != null)
                  Text(
                    'До дедлайна ${Fmt.count(daysBetween(today, deadline).clamp(0, 9999), 'день', 'дня', 'дней')}',
                    style: TextStyle(color: white70),
                  )
                else if (finish != null)
                  Text(
                    'Окончание: ${Fmt.short(finish)}',
                    style: TextStyle(color: white70),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MissedBanner extends ConsumerStatefulWidget {
  const _MissedBanner({required this.plan, required this.missed});

  final StudyPlan plan;
  final int missed;

  @override
  ConsumerState<_MissedBanner> createState() => _MissedBannerState();
}

class _MissedBannerState extends ConsumerState<_MissedBanner> {
  bool _busy = false;

  Future<void> _replan() async {
    setState(() => _busy = true);
    try {
      final result = await ref.read(planServiceProvider).replan(widget.plan);
      if (!mounted) return;
      final finish = result.finishDate;
      showSnack(
        context,
        result.deadlineMet
            ? 'План перестроен${finish == null ? '' : ', окончание ${Fmt.short(finish)}'}'
            : 'План перестроен, но не укладывается в дедлайн',
      );
    } on Object catch (e) {
      if (mounted) showSnack(context, 'Ошибка: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('missed_banner'),
      color: AppColors.warning.withValues(alpha: .15),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            const Icon(Icons.warning_amber, color: AppColors.warning),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Пропущено ${Fmt.count(widget.missed, 'занятие', 'занятия', 'занятий')}',
              ),
            ),
            FilledButton(
              key: const Key('replan_button'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              onPressed: _busy ? null : _replan,
              child: const Text('Перестроить'),
            ),
          ],
        ),
      ),
    );
  }
}
