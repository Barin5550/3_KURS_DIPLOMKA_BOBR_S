// Главный экран (вкладка «Главная», маршрут /home).
// Слой: presentation (интерфейс). Показывает приветствие, карточку прогресса
// активного плана, баннер о пропущенных занятиях и занятия на сегодня.
// Экран открывает роутер (core/router/app_router.dart) внутри MainShell —
// оболочки с нижней панелью вкладок.
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
///
/// ConsumerWidget — виджет без своего состояния, который умеет читать
/// провайдеры Riverpod (Riverpod — библиотека, через которую экраны получают
/// данные и сервисы; провайдер — «источник» одного вида данных).
class HomeScreen extends ConsumerWidget {
  /// Создаёт главный экран. Параметров нет: все данные берутся из провайдеров.
  const HomeScreen({super.key});

  /// Строит экран: верхнюю панель и тело в зависимости от того, есть ли
  /// у пользователя активный план.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Текущий вошедший пользователь (нужен для приветствия по имени).
    final user = ref.watch(authControllerProvider).user;
    // Активный план пользователя. AsyncValue — «загрузка / ошибка / данные».
    final planAsync = ref.watch(activePlanProvider);

    // Scaffold — каркас экрана: верхняя панель и тело.
    return Scaffold(
      // Верхняя панель с приветствием и кнопкой таймера.
      appBar: AppBar(
        // «Привет, Имя!» — берётся только первое слово из имени пользователя.
        title: Text('Привет, ${user?.name.split(' ').first ?? ''}!'),
        actions: [
          // Кнопка с иконкой таймера: открывает экран Pomodoro.
          IconButton(
            tooltip: 'Pomodoro',
            icon: const Icon(Icons.timer_outlined),
            onPressed: () => context.push('/pomodoro'),
          ),
        ],
      ),
      // ContentFrame ограничивает ширину содержимого на широких экранах.
      body: ContentFrame(
        // when — выбираем, что показать, по состоянию загрузки плана.
        child: planAsync.when(
          // План ещё загружается — крутится индикатор.
          loading: () => const LoadingView(),
          // Ошибка загрузки: сообщение и кнопка «Повторить», которая
          // сбрасывает провайдер и заставляет загрузить план заново.
          error: (e, _) => ErrorView(
            error: e,
            onRetry: () => ref.invalidate(activePlanProvider),
          ),
          // План загружен: если его нет — пустое состояние с призывом
          // создать план, иначе — основное содержимое главной.
          data: (plan) => plan == null
              // Плана нет: иконка, пояснение и кнопка «Создать план».
              // Она ведёт на онбординг — пошаговую настройку плана
              // (направление, тест, расписание).
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
              // План есть: показываем прогресс и занятия на сегодня.
              : _HomeBody(plan: plan),
        ),
      ),
    );
  }
}

/// Основное содержимое главной, когда активный план есть: карточка
/// прогресса, баннер пропусков, занятия на сегодня и кнопка Pomodoro.
class _HomeBody extends ConsumerWidget {
  /// Создаёт тело главной для плана [plan].
  const _HomeBody({required this.plan});

  /// Активный учебный план пользователя.
  final StudyPlan plan;

  /// Загружает занятия плана и строит из них список блоков главной.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Все занятия этого плана (поток из базы: обновляется сам при изменениях).
    final sessionsAsync = ref.watch(planSessionsProvider(plan.id));
    // Сегодняшняя дата без времени суток.
    final today = ref.watch(todayProvider);

    // Показываем загрузку, ошибку или данные по состоянию списка занятий.
    return sessionsAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(error: e),
      data: (sessions) {
        // Сводка по плану: сколько минут сделано, сколько пропущено и т. д.
        final progress = PlanProgress.fromSessions(sessions, today);
        // Занятия, назначенные на сегодня.
        final todays = sessions.where((s) => isSameDay(s.date, today)).toList();
        // Ближайшее невыполненное занятие после сегодняшнего дня
        // (firstOrNull вернёт null, если таких нет).
        final next = sessions
            .where((s) => !s.isDone && s.date.isAfter(today))
            .firstOrNull;
        // Серия: сколько дней подряд пользователь занимался.
        final streak = _streak(sessions, today);

        // Прокручиваемый список блоков главной с отступом 16 по краям.
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Синяя карточка с кольцом прогресса, часами и серией.
            _ProgressCard(
              plan: plan,
              progress: progress,
              streak: streak,
              today: today,
            ),
            // Если есть пропущенные занятия — жёлтый баннер с кнопкой
            // «Перестроить» (оператор ... вставляет сразу два виджета).
            if (progress.missedSessions > 0) ...[
              const SizedBox(height: 12),
              _MissedBanner(plan: plan, missed: progress.missedSessions),
            ],
            const SizedBox(height: 8),
            // Заголовок «Сегодня, 5 октября»; справа — счётчик
            // «выполнено X из Y», если на сегодня есть занятия.
            SectionTitle(
              'Сегодня, ${Fmt.day(today)}',
              trailing: todays.isEmpty
                  ? null
                  : Text(
                      '${todays.where((s) => s.isDone).length} из ${todays.length}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
            ),
            // На сегодня занятий нет — карточка «выходной» с датой
            // следующего занятия или сообщением, что план выполнен.
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
            // Иначе — карточка для каждого сегодняшнего занятия.
            else
              for (final s in todays)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  // SessionTile — карточка занятия с чекбоксом.
                  child: SessionTile(
                    session: s,
                    today: today,
                    // Чекбокс: отметить занятие выполненным или снять
                    // отметку через сервис планов.
                    onToggle: () =>
                        ref.read(planServiceProvider).toggleSession(s),
                    // Нажатие на карточку открывает экран занятия.
                    onTap: () => context.push('/session/${s.id}'),
                  ),
                ),
            const SizedBox(height: 12),
            // Кнопка с рамкой «Запустить Pomodoro» — открывает таймер.
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
    // Множество дат (без времени), в которые были выполнены занятия.
    final days = sessions
        .where((s) => s.completedAt != null)
        .map((s) => dateOnly(s.completedAt!))
        .toSet();
    // Счётчик дней серии.
    var streak = 0;
    // Начинаем с сегодня, если сегодня уже занимались, иначе со вчера:
    // так серия не обнуляется утром, пока пользователь ещё не занимался.
    var day = days.contains(today) ? today : addDays(today, -1);
    // Идём назад по дням, пока в каждый день было занятие.
    while (days.contains(day)) {
      streak++;
      day = addDays(day, -1);
    }
    return streak;
  }
}

/// Синяя карточка прогресса: кольцо с процентом, название плана, часы,
/// серия дней и дедлайн (или дата окончания плана).
class _ProgressCard extends StatelessWidget {
  /// Создаёт карточку; все данные передаёт [_HomeBody].
  const _ProgressCard({
    required this.plan,
    required this.progress,
    required this.streak,
    required this.today,
  });

  /// План, для которого показывается прогресс.
  final StudyPlan plan;

  /// Посчитанная сводка по занятиям плана.
  final PlanProgress progress;

  /// Сколько дней подряд пользователь занимался.
  final int streak;

  /// Сегодняшняя дата (для расчёта дней до дедлайна).
  final DateTime today;

  /// Строит карточку с градиентным фоном.
  @override
  Widget build(BuildContext context) {
    // Дедлайн из настроек плана (может быть не задан).
    final deadline = plan.settings.deadline;
    // Дата последнего учебного занятия плана.
    final finish = progress.finishDate;
    // Полупрозрачный белый цвет для второстепенного текста на синем фоне.
    final white70 = Colors.white.withValues(alpha: .75);
    // Контейнер с отступами, сине-тёмно-синим градиентом и скруглением 20.
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
      // Слева кольцо прогресса, справа — колонка с текстом.
      child: Row(
        children: [
          // Theme подменяет цвет текста внутри кольца на белый,
          // чтобы процент был виден на тёмном фоне.
          Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme
                  .copyWith(onSurface: Colors.white),
            ),
            // Кольцо прогресса: доля выполненных учебных минут.
            child: ProgressRing(value: progress.ratio, size: 92),
          ),
          const SizedBox(width: 16),
          // Expanded — колонка занимает всё оставшееся место в строке.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Название плана крупным белым жирным шрифтом.
                Text(
                  plan.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                // «12 из 40 ч» — сколько часов изучено из всего плана.
                Text(
                  '${Fmt.hours(progress.doneStudyMinutes / 60)} из '
                  '${Fmt.hours(progress.totalStudyMinutes / 60)} ч',
                  style: TextStyle(color: white70),
                ),
                // Строка «Серия: N дней» с иконкой огня.
                Row(
                  children: [
                    // Fmt.count склоняет слово: 1 день, 2 дня, 5 дней.
                    Text(
                      'Серия: ${Fmt.count(streak, 'день', 'дня', 'дней')}',
                      style: TextStyle(color: white70),
                    ),
                    const SizedBox(width: 4),
                    // Огонёк оранжевый, если серия больше нуля, иначе бледный.
                    Icon(
                      Icons.local_fire_department,
                      size: 16,
                      color: streak > 0 ? AppColors.orangeLight : white70,
                    ),
                  ],
                ),
                // Если задан дедлайн — сколько дней до него осталось
                // (clamp не даёт числу уйти ниже нуля после дедлайна).
                if (deadline != null)
                  Text(
                    'До дедлайна ${Fmt.count(daysBetween(today, deadline).clamp(0, 9999), 'день', 'дня', 'дней')}',
                    style: TextStyle(color: white70),
                  )
                // Дедлайна нет — показываем дату окончания плана.
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

/// Баннер «Пропущено N занятий» с кнопкой «Перестроить» план.
///
/// ConsumerStatefulWidget — виджет со своим состоянием (флаг «идёт
/// перестройка»), который тоже может читать провайдеры.
class _MissedBanner extends ConsumerStatefulWidget {
  /// Создаёт баннер для плана [plan] с числом пропусков [missed].
  const _MissedBanner({required this.plan, required this.missed});

  /// План, который будет перестроен.
  final StudyPlan plan;

  /// Количество пропущенных занятий.
  final int missed;

  /// Создаёт объект состояния баннера.
  @override
  ConsumerState<_MissedBanner> createState() => _MissedBannerState();
}

/// Состояние баннера: хранит флаг занятости и запускает перестройку плана.
class _MissedBannerState extends ConsumerState<_MissedBanner> {
  /// `true`, пока идёт перестройка: кнопка в это время неактивна.
  bool _busy = false;

  /// Перестраивает невыполненную часть плана и показывает результат
  /// во всплывающем сообщении (SnackBar).
  Future<void> _replan() async {
    // Блокируем кнопку, чтобы не запустить перестройку дважды.
    setState(() => _busy = true);
    try {
      // Сервис планов заново раскладывает пропущенные и будущие занятия.
      final result = await ref.read(planServiceProvider).replan(widget.plan);
      // Если экран уже закрыт, context использовать нельзя — выходим.
      if (!mounted) return;
      // Новая дата окончания плана после перестройки.
      final finish = result.finishDate;
      // Сообщение: план перестроен (с датой окончания) или предупреждение,
      // что в дедлайн он больше не укладывается.
      showSnack(
        context,
        result.deadlineMet
            ? 'План перестроен${finish == null ? '' : ', окончание ${Fmt.short(finish)}'}'
            : 'План перестроен, но не укладывается в дедлайн',
      );
    } on Object catch (e) {
      // Любая ошибка — красное сообщение с её текстом.
      if (mounted) showSnack(context, 'Ошибка: $e', error: true);
    } finally {
      // В любом случае снова включаем кнопку (если экран ещё открыт).
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Строит баннер: иконка предупреждения, текст и кнопка.
  @override
  Widget build(BuildContext context) {
    // Карточка с бледно-жёлтым фоном (цвет предупреждения, 15% яркости).
    return Card(
      key: const Key('missed_banner'),
      color: AppColors.warning.withValues(alpha: .15),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            // Жёлтый значок предупреждения.
            const Icon(Icons.warning_amber, color: AppColors.warning),
            const SizedBox(width: 12),
            // Текст «Пропущено N занятий» с правильным склонением.
            Expanded(
              child: Text(
                'Пропущено ${Fmt.count(widget.missed, 'занятие', 'занятия', 'занятий')}',
              ),
            ),
            const SizedBox(width: 8),
            // Кнопка «Перестроить»: пока идёт перестройка (_busy),
            // onPressed равен null и кнопка неактивна.
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
