import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../domain/entities/plan.dart';
import '../../../domain/entities/session.dart';
import '../../../domain/planner/dates.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/session_tile.dart';

/// Фильтры списка занятий.
enum SessionFilter {
  all('Все'),
  today('Сегодня'),
  upcoming('Предстоящие'),
  missed('Пропущенные'),
  done('Выполненные'),
  reviews('Повторения');

  const SessionFilter(this.label);
  final String label;

  bool matches(StudySession s, DateTime today) => switch (this) {
    all => true,
    SessionFilter.today => isSameDay(s.date, today),
    upcoming => !s.isDone && !s.date.isBefore(today),
    missed => s.isMissed(today),
    done => s.isDone,
    reviews => s.kind == SessionKind.review,
  };
}

/// Вкладка «План»: все занятия активного плана по дням, поиск и фильтры.
class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  final _search = TextEditingController();
  SessionFilter _filter = SessionFilter.upcoming;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(activePlanProvider);
    final plan = planAsync.value;
    return Scaffold(
      appBar: AppBar(
        title: Text(plan?.title ?? 'План'),
        actions: [
          if (plan != null)
            IconButton(
              key: const Key('plan_settings'),
              tooltip: 'Настройки плана',
              icon: const Icon(Icons.tune),
              onPressed: () => context.push('/plan/settings'),
            ),
          IconButton(
            key: const Key('my_plans'),
            tooltip: 'Мои планы',
            icon: const Icon(Icons.folder_copy_outlined),
            onPressed: () => context.push('/plans'),
          ),
        ],
      ),
      body: ContentFrame(
        child: planAsync.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(error: e),
          data: (plan) => plan == null
              ? EmptyState(
                  icon: Icons.calendar_month,
                  title: 'Плана пока нет',
                  message:
                      'Создайте план, и здесь появится расписание по дням.',
                  actionLabel: 'Создать план',
                  onAction: () => context.push('/onboarding'),
                )
              : _sessions(plan),
        ),
      ),
    );
  }

  Widget _sessions(StudyPlan plan) {
    final sessionsAsync = ref.watch(planSessionsProvider(plan.id));
    final today = ref.watch(todayProvider);
    return sessionsAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(error: e),
      data: (all) {
        final query = _search.text.trim().toLowerCase();
        final filtered = all
            .where((s) => _filter.matches(s, today))
            .where(
              (s) =>
                  query.isEmpty || s.topicTitle.toLowerCase().contains(query),
            )
            .toList();
        final progress = PlanProgress.fromSessions(all, today);

        final groups = <DateTime, List<StudySession>>{};
        for (final s in filtered) {
          groups.putIfAbsent(s.date, () => []).add(s);
        }

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverList.list(
                children: [
                  LinearProgressIndicator(
                    value: progress.ratio,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Выполнено ${progress.doneSessions} из ${progress.totalSessions} ${Fmt.plural(progress.totalSessions, 'занятия', 'занятий', 'занятий')}'
                    '${progress.missedSessions > 0 ? ' · пропущено ${progress.missedSessions}' : ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('plan_search'),
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Поиск по темам',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Очистить',
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(_search.clear),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final f in SessionFilter.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              key: Key('filter_${f.name}'),
                              label: Text(f.label),
                              selected: _filter == f,
                              onSelected: (_) => setState(() => _filter = f),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.search_off,
                  title: query.isEmpty
                      ? 'Нет занятий в разделе «${_filter.label}»'
                      : 'Ничего не найдено',
                  message: query.isEmpty
                      ? null
                      : 'Попробуйте изменить запрос или фильтр',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList.list(
                  children: [
                    for (final entry in groups.entries) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 6),
                        child: Text(
                          isSameDay(entry.key, today)
                              ? 'Сегодня, ${Fmt.day(entry.key)}'
                              : Fmt.dayWithWeekday(entry.key),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      for (final s in entry.value)
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
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
