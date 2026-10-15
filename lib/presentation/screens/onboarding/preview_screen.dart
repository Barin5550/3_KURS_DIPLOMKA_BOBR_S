// Слой presentation (интерфейс): последний экран онбординга — предпросмотр
// плана (маршрут '/onboarding/preview'). По черновику (направление, ответы
// теста, расписание) PlanService рассчитывает план без сохранения; экран
// показывает сводку, предупреждение о дедлайне и порядок тем, а по кнопке
// «Начать обучение» сохраняет план в базу и уводит на главную.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/plan.dart';
import '../../../domain/planner/topological_sort.dart';
import '../../providers/onboarding_controller.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

/// Предпросмотр сгенерированного плана перед сохранением.
///
/// ConsumerStatefulWidget — виджет Riverpod (менеджер состояния) со своим
/// состоянием: здесь это флаг «идёт сохранение».
class PreviewScreen extends ConsumerStatefulWidget {
  /// Создаёт экран предпросмотра.
  const PreviewScreen({super.key});

  /// Создаёт объект состояния экрана.
  @override
  ConsumerState<PreviewScreen> createState() => _PreviewScreenState();
}

/// Состояние экрана предпросмотра: расчёт плана и его сохранение.
class _PreviewScreenState extends ConsumerState<PreviewScreen> {
  /// `true`, пока план сохраняется: кнопка показывает индикатор
  /// и не нажимается повторно.
  bool _saving = false;

  /// Сохраняет план в базу данных и переходит на главный экран.
  ///
  /// Параметр [result] в теле не используется: PlanService.createPlan
  /// сам заново рассчитывает план по тем же данным черновика.
  Future<void> _save(PlanResult result) async {
    // Черновик плана, id вошедшего пользователя и выбранное направление.
    final draft = ref.read(onboardingProvider);
    final userId = ref.read(currentUserIdProvider);
    final direction = draft.direction;
    // Без пользователя или направления сохранять нечего.
    if (userId == null || direction == null) return;
    // Включаем индикатор сохранения на кнопке.
    setState(() => _saving = true);
    try {
      // Получаем темы направления (каталог + свои темы пользователя);
      // `.future` — дождаться готового значения асинхронного провайдера.
      final topics = await ref.read(
        directionTopicsProvider(direction.id).future,
      );
      // Генерируем и сохраняем план; новый план становится активным.
      // В план не попадут темы, известные по результатам теста.
      await ref
          .read(planServiceProvider)
          .createPlan(
            userId: userId,
            directionId: direction.id,
            title: direction.title,
            topics: topics,
            settings: draft.settings,
            knownTopicIds: draft.knownTopicIds,
          );
      // Очищаем черновик, чтобы следующий план начинался с нуля.
      ref.read(onboardingProvider.notifier).reset();
      // mounted — экран ещё на месте (его не закрыли, пока шло ожидание);
      // только тогда можно пользоваться context.
      if (mounted) {
        // Переход на главную и всплывающее сообщение об успехе.
        context.go('/home');
        showSnack(context, 'План сохранён. Удачи в обучении!');
      }
    } on Object catch (e) {
      // Любая ошибка: выключаем индикатор и показываем красное сообщение.
      if (mounted) {
        setState(() => _saving = false);
        showSnack(context, 'Не удалось сохранить план: $e', error: true);
      }
    }
  }

  /// Строит экран: загружает темы направления и рассчитывает по ним план.
  @override
  Widget build(BuildContext context) {
    // Черновик плана; watch — пересчитать план, если черновик изменится
    // (например, после кнопки «Установить N ч/нед»).
    final draft = ref.watch(onboardingProvider);
    final direction = draft.direction;
    // Направление не выбрано — показываем простую заглушку.
    if (direction == null) {
      return const Scaffold(
        body: ContentFrame(
          child: Center(child: Text('Направление не выбрано')),
        ),
      );
    }
    // Асинхронная загрузка тем направления (загрузка / ошибка / данные).
    final topicsAsync = ref.watch(directionTopicsProvider(direction.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Ваш план готов')),
      body: ContentFrame(
        child: topicsAsync.when(
          // Темы ещё грузятся — индикатор загрузки.
          loading: () => const LoadingView(),
          // Ошибка загрузки — сообщение об ошибке.
          error: (e, _) => ErrorView(error: e),
          // Темы готовы — считаем план.
          data: (topics) {
            final PlanResult result;
            try {
              // Расчёт плана без сохранения в базу: порядок тем,
              // занятия по дням, дата окончания, проверка дедлайна.
              result = ref
                  .read(planServiceProvider)
                  .preview(
                    topics: topics,
                    settings: draft.settings,
                    knownTopicIds: draft.knownTopicIds,
                  );
            } on CycleDetectedException catch (e) {
              // Топологическая сортировка (упорядочивание тем так, чтобы
              // каждая шла после тем, от которых зависит) невозможна,
              // если зависимости образуют цикл — показываем ошибку.
              return ErrorView(error: e);
            }
            // Отрисовка результата отдельным виджетом.
            return _PreviewBody(
              title: direction.title,
              result: result,
              saving: _saving,
              // Кнопка «Начать обучение» — сохранить план.
              onSave: () => _save(result),
              // Кнопка «Установить N ч/нед» — меняем часы в черновике,
              // после чего экран сам пересчитает план.
              onApplyHours: (hours) => ref
                  .read(onboardingProvider.notifier)
                  .updateSettings(draft.settings.copyWith(hoursPerWeek: hours)),
            );
          },
        ),
      ),
    );
  }
}

/// Содержимое предпросмотра: сводка, предупреждение о дедлайне, список
/// тем по порядку и закреплённая внизу кнопка сохранения.
class _PreviewBody extends StatelessWidget {
  /// Создаёт тело предпросмотра по готовому результату расчёта.
  const _PreviewBody({
    required this.title,
    required this.result,
    required this.saving,
    required this.onSave,
    required this.onApplyHours,
  });

  /// Название плана (совпадает с названием направления).
  final String title;

  /// Рассчитанный план: темы, занятия, дата окончания, дедлайн.
  final PlanResult result;

  /// Идёт ли сейчас сохранение (для индикатора на кнопке).
  final bool saving;

  /// Вызывается по кнопке «Начать обучение».
  final VoidCallback onSave;

  /// Вызывается с нужным числом часов в неделю, чтобы успеть к дедлайну.
  final ValueChanged<double> onApplyHours;

  /// Строит список с карточками и нижнюю панель с кнопкой.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Тёмная ли сейчас тема — от этого зависят цвета кружков с номерами.
    final isDark = theme.brightness == Brightness.dark;
    // Дата окончания плана (null, если все темы уже изучены).
    final finish = result.finishDate;
    // Сколько часов в неделю нужно, чтобы успеть к дедлайну.
    final required = result.requiredHoursPerWeek;

    // Кнопка «Начать обучение» закреплена внизу: список тем длинный,
    // и прокручивать его до конца ради сохранения неудобно.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Прокручиваемая часть занимает всё место над кнопкой.
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Карточка-сводка по плану.
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Название плана.
                      Text(title, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 12),
                      // Сколько тем в плане и сколько исключено по тесту
                      // (вторая часть пишется, только если такие есть).
                      _Stat(
                        icon: Icons.list_alt,
                        text:
                            '${Fmt.count(result.orderedTopics.length, 'тема', 'темы', 'тем')} в плане'
                            '${result.excludedTopics.isEmpty ? '' : ', ${result.excludedTopics.length} исключено по тесту'}',
                      ),
                      // Общее время: изучение новых тем + повторения.
                      _Stat(
                        icon: Icons.schedule,
                        text:
                            '${Fmt.minutes(result.studyMinutes)} изучения + '
                            '${Fmt.minutes(result.reviewMinutes)} повторений',
                      ),
                      // Дата окончания плана.
                      _Stat(
                        icon: Icons.flag,
                        text: finish == null
                            ? 'Все темы уже изучены'
                            : 'Окончание: ${Fmt.short(finish)}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Жёлтая карточка-предупреждение, если план не успевает
              // к дедлайну.
              if (!result.deadlineMet)
                Card(
                  key: const Key('deadline_warning'),
                  color: AppColors.warning.withValues(alpha: .15),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Заголовок предупреждения со значком.
                        const Row(
                          children: [
                            Icon(Icons.warning_amber, color: AppColors.warning),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'План не укладывается в дедлайн',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Совет: сколько часов в неделю нужно, или, если
                        // успеть невозможно, предложение перенести дедлайн.
                        Text(
                          required == null
                              ? 'Даже 84 часов в неделю не хватит. Перенесите дедлайн.'
                              : 'Чтобы успеть, нужно ${Fmt.hours(required)} ч в неделю.',
                        ),
                        // Кнопка, которая сразу подставляет нужные часы
                        // в расписание (план пересчитается).
                        if (required != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              key: const Key('apply_hours'),
                              onPressed: () => onApplyHours(required),
                              child: Text(
                                'Установить ${Fmt.hours(required)} ч/нед',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              // Заголовок списка тем.
              const SectionTitle('Порядок тем'),
              // Темы в порядке изучения: номер в кружке, название,
              // категория и длительность.
              for (var i = 0; i < result.orderedTopics.length; i++)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  // В тёмной теме тёмно-синий круг сливается с фоном,
                  // поэтому там он светло-синий с тёмной цифрой.
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: isDark
                        ? theme.colorScheme.tertiary
                        : AppColors.navy,
                    // Порядковый номер темы (с единицы).
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: isDark ? AppColors.navyDeep : Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  title: Text(result.orderedTopics[i].title),
                  subtitle: Text(
                    '${result.orderedTopics[i].category} · '
                    '${Fmt.minutes(result.orderedTopics[i].minutes)}',
                  ),
                ),
              const SizedBox(height: 16),
              // Кнопка возврата на шаг «Расписание» (закрывает этот экран).
              OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('Изменить расписание'),
              ),
            ],
          ),
        ),
        // Тонкая линия над нижней панелью.
        const Divider(height: 1),
        // SafeArea не даёт кнопке залезть под системную полосу внизу
        // экрана; сверху отступ не нужен (top: false).
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            // Кнопка сохранения: неактивна во время сохранения и если
            // в плане нет ни одной темы.
            child: FilledButton(
              key: const Key('preview_save'),
              onPressed: saving || result.orderedTopics.isEmpty ? null : onSave,
              // Во время сохранения вместо текста — крутящийся индикатор.
              child: saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Начать обучение'),
            ),
          ),
        ),
      ],
    );
  }
}

/// Строка сводки: оранжевая иконка и текст рядом с ней.
class _Stat extends StatelessWidget {
  /// Создаёт строку сводки с иконкой [icon] и текстом [text].
  const _Stat({required this.icon, required this.text});

  /// Иконка слева.
  final IconData icon;

  /// Текст строки.
  final String text;

  /// Строит строку «иконка + текст» с отступом снизу.
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        // Иконка в фирменном оранжевом цвете.
        Icon(icon, size: 20, color: AppColors.orange),
        const SizedBox(width: 10),
        // Текст занимает остальное место и переносится при нехватке.
        Expanded(child: Text(text)),
      ],
    ),
  );
}
