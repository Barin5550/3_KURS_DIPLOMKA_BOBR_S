// Слой presentation (интерфейс): вкладка «План» нижней навигации (маршрут
// '/plan'). Показывает все занятия активного плана, сгруппированные по
// дням, с прогрессом, поиском по темам и фильтрами (enum SessionFilter).
// Отсюда открываются настройки плана, список «Мои планы» и карточка
// занятия. Данные берёт из провайдеров providers.dart.
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
///
/// Каждое значение хранит подпись для чипа ([label]) и умеет проверять,
/// подходит ли под фильтр конкретное занятие ([matches]).
enum SessionFilter {
  /// Все занятия плана.
  all('Все'),

  /// Только занятия на сегодня.
  today('Сегодня'),

  /// Невыполненные занятия с сегодняшнего дня и позже.
  upcoming('Предстоящие'),

  /// Пропущенные: дата прошла, а отметки нет.
  missed('Пропущенные'),

  /// Уже выполненные занятия.
  done('Выполненные'),

  /// Только занятия-повторения.
  reviews('Повторения');

  /// Связывает значение фильтра с его подписью.
  const SessionFilter(this.label);

  /// Подпись фильтра на чипе.
  final String label;

  /// Подходит ли занятие [s] под этот фильтр, если сегодня — [today].
  bool matches(StudySession s, DateTime today) => switch (this) {
    // «Все» пропускает любое занятие.
    all => true,
    // Полное имя SessionFilter.today нужно, потому что параметр метода
    // тоже называется today. Совпадает ли день занятия с сегодняшним.
    SessionFilter.today => isSameDay(s.date, today),
    // Не выполнено и дата не раньше сегодняшней.
    upcoming => !s.isDone && !s.date.isBefore(today),
    // Пропущено — проверку делает само занятие.
    missed => s.isMissed(today),
    // Отмечено выполненным.
    done => s.isDone,
    // Тип занятия — повторение.
    reviews => s.kind == SessionKind.review,
  };
}

/// Вкладка «План»: все занятия активного плана по дням, поиск и фильтры.
///
/// ConsumerStatefulWidget — виджет Riverpod (менеджер состояния) со своим
/// состоянием: здесь это текст поиска и выбранный фильтр.
class PlanScreen extends ConsumerStatefulWidget {
  /// Создаёт вкладку «План».
  const PlanScreen({super.key});

  /// Создаёт объект состояния экрана.
  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

/// Состояние вкладки «План»: поиск, фильтр и построение списка занятий.
class _PlanScreenState extends ConsumerState<PlanScreen> {
  /// Контроллер поля поиска: хранит введённый текст.
  final _search = TextEditingController();

  /// Выбранный фильтр; по умолчанию — «Предстоящие».
  SessionFilter _filter = SessionFilter.upcoming;

  /// Освобождает контроллер поиска, когда экран закрывается.
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Строит экран: шапку с кнопками и содержимое в зависимости от того,
  /// есть ли активный план.
  @override
  Widget build(BuildContext context) {
    // Активный план как AsyncValue (загрузка / ошибка / данные).
    final planAsync = ref.watch(activePlanProvider);
    // Сам план, если уже загружен (нужен для заголовка и кнопок).
    final plan = planAsync.value;
    return Scaffold(
      appBar: AppBar(
        // Заголовок — название плана, а пока его нет — просто «План».
        title: Text(plan?.title ?? 'План'),
        actions: [
          // Кнопка настроек расписания — только если план есть.
          if (plan != null)
            IconButton(
              key: const Key('plan_settings'),
              tooltip: 'Настройки плана',
              icon: const Icon(Icons.tune),
              onPressed: () => context.push('/plan/settings'),
            ),
          // Кнопка перехода к списку всех планов пользователя.
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
          // План загружается — индикатор.
          loading: () => const LoadingView(),
          // Ошибка загрузки — сообщение.
          error: (e, _) => ErrorView(error: e),
          // Плана нет — пустое состояние с кнопкой «Создать план»
          // (ведёт в онбординг); план есть — список занятий.
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

  /// Строит прокручиваемый список занятий плана [plan]: прогресс, поиск,
  /// чипы фильтров и занятия, сгруппированные по датам.
  Widget _sessions(StudyPlan plan) {
    // Поток занятий плана: список обновляется сам при изменениях в базе.
    final sessionsAsync = ref.watch(planSessionsProvider(plan.id));
    // Сегодняшняя дата — для фильтров и подписи «Сегодня».
    final today = ref.watch(todayProvider);
    return sessionsAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(error: e),
      data: (all) {
        // Текст поиска без пробелов по краям и в нижнем регистре,
        // чтобы поиск не зависел от регистра букв.
        final query = _search.text.trim().toLowerCase();
        // Оставляем занятия, которые подходят под фильтр и содержат
        // текст поиска в названии темы (пустой поиск пропускает всё).
        final filtered = all
            .where((s) => _filter.matches(s, today))
            .where(
              (s) =>
                  query.isEmpty || s.topicTitle.toLowerCase().contains(query),
            )
            .toList();
        // Прогресс считаем по всем занятиям, а не только по найденным.
        final progress = PlanProgress.fromSessions(all, today);

        // Группируем отфильтрованные занятия по дате. Map в Dart
        // сохраняет порядок добавления, поэтому дни идут в том порядке,
        // в каком занятия пришли из базы.
        final groups = <DateTime, List<StudySession>>{};
        for (final s in filtered) {
          groups.putIfAbsent(s.date, () => []).add(s);
        }

        // CustomScrollView собирает прокрутку из «слайверов» — кусков
        // прокручиваемой области (шапка, пустое состояние, список).
        return CustomScrollView(
          slivers: [
            // Верхняя часть: прогресс, поиск и фильтры.
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverList.list(
                children: [
                  // Полоса прогресса: доля выполненных минут изучения.
                  LinearProgressIndicator(
                    value: progress.ratio,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 6),
                  // Подпись «Выполнено N из M занятий» и, если есть,
                  // число пропущенных.
                  Text(
                    'Выполнено ${progress.doneSessions} из ${progress.totalSessions} ${Fmt.plural(progress.totalSessions, 'занятия', 'занятий', 'занятий')}'
                    '${progress.missedSessions > 0 ? ' · пропущено ${progress.missedSessions}' : ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  // Поле поиска по названиям тем. Каждое изменение текста
                  // перерисовывает экран, и список фильтруется заново.
                  TextField(
                    key: const Key('plan_search'),
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Поиск по темам',
                      prefixIcon: const Icon(Icons.search),
                      // Крестик очистки появляется, только когда в поле
                      // есть текст.
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
                  // Ряд чипов-фильтров; прокручивается вбок, если не
                  // помещается по ширине.
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // По чипу на каждое значение SessionFilter.
                        for (final f in SessionFilter.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            // Выбор чипа меняет текущий фильтр.
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
            // Ничего не подошло — пустое состояние на всё оставшееся место.
            if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                // Текст зависит от того, искали ли что-то: «нет занятий
                // в разделе» или «ничего не найдено».
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
            // Иначе — список занятий по дням.
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList.list(
                  children: [
                    // Для каждого дня: заголовок с датой, затем занятия.
                    for (final entry in groups.entries) ...[
                      // Заголовок дня: «Сегодня, 5 октября» или дата
                      // с днём недели.
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 6),
                        child: Text(
                          isSameDay(entry.key, today)
                              ? 'Сегодня, ${Fmt.day(entry.key)}'
                              : Fmt.dayWithWeekday(entry.key),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      // Карточки занятий этого дня.
                      for (final s in entry.value)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          // Галочка отмечает/снимает выполнение через
                          // PlanService, нажатие открывает карточку
                          // занятия.
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
