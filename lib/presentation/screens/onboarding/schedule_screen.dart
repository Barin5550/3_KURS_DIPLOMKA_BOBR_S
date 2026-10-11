// Слой presentation (интерфейс): третий шаг онбординга — расписание.
// Здесь лежат два виджета: ScheduleScreen (сам экран шага, маршрут
// '/onboarding/schedule') и ScheduleForm — форма «часы в неделю, учебные
// дни, дата начала, дедлайн», которую также использует PlanSettingsScreen
// для изменения расписания уже созданного плана.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../domain/entities/schedule_settings.dart';
import '../../providers/onboarding_controller.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import 'onboarding_steps.dart';

/// Шаг 3 онбординга: часы в неделю, учебные дни и дедлайн.
///
/// ConsumerWidget — виджет Riverpod (менеджер состояния), который через
/// `ref` читает провайдеры; здесь — черновик плана из onboardingProvider.
class ScheduleScreen extends ConsumerWidget {
  /// Создаёт экран шага «Расписание».
  const ScheduleScreen({super.key});

  /// Строит экран: индикатор шагов, форму расписания и кнопку генерации.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Текущие настройки расписания из черновика плана; watch — экран
    // перерисуется, когда пользователь что-то поменяет в форме.
    final settings = ref.watch(onboardingProvider).settings;
    // Контроллер черновика — через него форма сохраняет изменения.
    final controller = ref.read(onboardingProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Расписание')),
      body: ContentFrame(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Индикатор шагов: третий шаг (номер 2).
            const OnboardingSteps(current: 2),
            const SizedBox(height: 16),
            // Форма расписания; каждое изменение сразу уходит в черновик.
            ScheduleForm(
              settings: settings,
              onChanged: controller.updateSettings,
            ),
            const SizedBox(height: 24),
            // Кнопка перехода к предпросмотру плана. Неактивна, пока не
            // выбран ни один учебный день — без них план не построить.
            FilledButton(
              key: const Key('schedule_generate'),
              onPressed: settings.studyDays.isEmpty
                  ? null
                  : () => context.push('/onboarding/preview'),
              child: const Text('Сформировать план'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Форма параметров расписания. Используется в онбординге и в настройках
/// существующего плана.
///
/// Форма сама ничего не хранит: получает текущие [settings] и при каждом
/// изменении отдаёт новый объект настроек через [onChanged].
class ScheduleForm extends ConsumerWidget {
  /// Создаёт форму; [showStartDate] — показывать ли поле даты начала.
  const ScheduleForm({
    super.key,
    required this.settings,
    required this.onChanged,
    this.showStartDate = true,
  });

  /// Текущие значения расписания, которые отображает форма.
  final ScheduleSettings settings;

  /// Вызывается с обновлённой копией настроек после любого изменения.
  final ValueChanged<ScheduleSettings> onChanged;

  /// Показывать ли выбор даты начала обучения. В настройках уже
  /// существующего плана его скрывают (передают `false`).
  final bool showStartDate;

  /// Строит поля формы: слайдер часов, дни недели, дату начала и дедлайн.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Сегодняшняя дата из провайдера (её можно подменить в тестах).
    final today = ref.watch(todayProvider);
    // Дедлайн выносим в переменную: null означает «без срока».
    final deadline = settings.deadline;

    // Вспомогательная функция: открывает календарь выбора даты.
    // [first] — самая ранняя дата, которую можно выбрать; если начальная
    // дата раньше неё, календарь откроется на [first]. Выбрать можно до
    // 1 января года «сегодня + 3». Календарь на русском языке.
    Future<DateTime?> pick(DateTime initial, DateTime first) => showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : initial,
      firstDate: first,
      lastDate: DateTime(today.year + 3),
      locale: const Locale('ru'),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Блок «часы в неделю».
        Text('Сколько часов в неделю?', style: theme.textTheme.titleMedium),
        Row(
          children: [
            // Слайдер от 1 до 40 часов с шагом полчаса
            // (78 делений = (40 − 1) / 0,5).
            Expanded(
              child: Slider(
                key: const Key('hours_slider'),
                // clamp не даёт значению выйти за границы слайдера.
                value: settings.hoursPerWeek.clamp(1, 40),
                min: 1,
                max: 40,
                divisions: 78,
                // Подсказка над ползунком во время перетаскивания.
                label: '${Fmt.hours(settings.hoursPerWeek)} ч',
                // Округляем до 0,5 часа и отдаём новые настройки наверх.
                onChanged: (v) => onChanged(
                  settings.copyWith(hoursPerWeek: (v * 2).round() / 2),
                ),
              ),
            ),
            // Текущее значение часов справа от слайдера.
            SizedBox(
              width: 64,
              child: Text(
                '${Fmt.hours(settings.hoursPerWeek)} ч',
                textAlign: TextAlign.end,
                style: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
        // Подсказка, сколько это примерно минут в один учебный день
        // (только если дни выбраны, иначе делить не на что).
        if (settings.studyDays.isNotEmpty)
          Text(
            '≈ ${Fmt.minutes(settings.dailyLimitMinutes)} в учебный день',
            style: theme.textTheme.bodySmall,
          ),
        const SizedBox(height: 20),
        // Блок «учебные дни».
        Text('Учебные дни', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        // Wrap переносит чипы на следующую строку, если не хватает места.
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Семь чипов-переключателей: 1 — понедельник … 7 — воскресенье.
            for (var day = 1; day <= 7; day++)
              FilterChip(
                key: Key('day_$day'),
                // Короткое название дня: «Пн», «Вт» и т. д.
                label: Text(weekdayShort[day - 1]),
                selected: settings.studyDays.contains(day),
                onSelected: (on) {
                  // Копируем множество дней, чтобы не менять старое.
                  final days = {...settings.studyDays};
                  // Включили чип — добавляем день, выключили — убираем.
                  on ? days.add(day) : days.remove(day);
                  onChanged(settings.copyWith(studyDays: days));
                },
              ),
          ],
        ),
        // Если не выбран ни один день — красное предупреждение.
        if (settings.studyDays.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Выберите хотя бы один день',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        const SizedBox(height: 20),
        // Строка «Начало обучения»: по нажатию открывает календарь.
        // Раньше сегодняшнего дня дату выбрать нельзя.
        if (showStartDate)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.play_circle_outline),
            title: const Text('Начало обучения'),
            subtitle: Text(Fmt.short(settings.startDate)),
            trailing: const Icon(Icons.edit_calendar),
            onTap: () async {
              final date = await pick(settings.startDate, today);
              // Если пользователь не закрыл календарь — сохраняем дату.
              if (date != null) onChanged(settings.copyWith(startDate: date));
            },
          ),
        // Переключатель «Есть дедлайн».
        SwitchListTile(
          key: const Key('deadline_switch'),
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.flag_outlined),
          title: const Text('Есть дедлайн'),
          // Под заголовком — текущая дата дедлайна или «Без срока».
          subtitle: Text(
            deadline == null ? 'Без срока' : 'До ${Fmt.short(deadline)}',
          ),
          value: deadline != null,
          // Включили — ставим дедлайн по умолчанию (через 90 дней),
          // выключили — убираем дедлайн совсем.
          onChanged: (on) => onChanged(
            on
                ? settings.copyWith(deadline: defaultDeadline(today))
                : settings.copyWith(clearDeadline: true),
          ),
        ),
        // Кнопка изменения даты дедлайна (только если дедлайн включён).
        // Дедлайн нельзя поставить раньше даты начала обучения.
        if (deadline != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.edit_calendar),
              label: const Text('Изменить дату дедлайна'),
              onPressed: () async {
                final date = await pick(deadline, settings.startDate);
                // Сохраняем новую дату, если она выбрана.
                if (date != null) onChanged(settings.copyWith(deadline: date));
              },
            ),
          ),
      ],
    );
  }
}
