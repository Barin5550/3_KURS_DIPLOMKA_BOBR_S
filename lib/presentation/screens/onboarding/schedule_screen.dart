import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../domain/entities/schedule_settings.dart';
import '../../providers/onboarding_controller.dart';
import '../../providers/providers.dart';
import 'onboarding_steps.dart';

/// Шаг 3 онбординга: часы в неделю, учебные дни и дедлайн.
class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(onboardingProvider).settings;
    final controller = ref.read(onboardingProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Расписание')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const OnboardingSteps(current: 2),
          const SizedBox(height: 16),
          ScheduleForm(
            settings: settings,
            onChanged: controller.updateSettings,
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('schedule_generate'),
            onPressed: settings.studyDays.isEmpty
                ? null
                : () => context.push('/onboarding/preview'),
            child: const Text('Сформировать план'),
          ),
        ],
      ),
    );
  }
}

/// Форма параметров расписания. Используется в онбординге и в настройках
/// существующего плана.
class ScheduleForm extends ConsumerWidget {
  const ScheduleForm({
    super.key,
    required this.settings,
    required this.onChanged,
    this.showStartDate = true,
  });

  final ScheduleSettings settings;
  final ValueChanged<ScheduleSettings> onChanged;
  final bool showStartDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final today = ref.watch(todayProvider);
    final deadline = settings.deadline;

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
        Text('Сколько часов в неделю?', style: theme.textTheme.titleMedium),
        Row(
          children: [
            Expanded(
              child: Slider(
                key: const Key('hours_slider'),
                value: settings.hoursPerWeek.clamp(1, 40),
                min: 1,
                max: 40,
                divisions: 78,
                label: '${Fmt.hours(settings.hoursPerWeek)} ч',
                onChanged: (v) => onChanged(
                  settings.copyWith(hoursPerWeek: (v * 2).round() / 2),
                ),
              ),
            ),
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
        if (settings.studyDays.isNotEmpty)
          Text(
            '≈ ${Fmt.minutes(settings.dailyLimitMinutes)} в учебный день',
            style: theme.textTheme.bodySmall,
          ),
        const SizedBox(height: 20),
        Text('Учебные дни', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var day = 1; day <= 7; day++)
              FilterChip(
                key: Key('day_$day'),
                label: Text(weekdayShort[day - 1]),
                selected: settings.studyDays.contains(day),
                onSelected: (on) {
                  final days = {...settings.studyDays};
                  on ? days.add(day) : days.remove(day);
                  onChanged(settings.copyWith(studyDays: days));
                },
              ),
          ],
        ),
        if (settings.studyDays.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Выберите хотя бы один день',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        const SizedBox(height: 20),
        if (showStartDate)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.play_circle_outline),
            title: const Text('Начало обучения'),
            subtitle: Text(Fmt.short(settings.startDate)),
            trailing: const Icon(Icons.edit_calendar),
            onTap: () async {
              final date = await pick(settings.startDate, today);
              if (date != null) onChanged(settings.copyWith(startDate: date));
            },
          ),
        SwitchListTile(
          key: const Key('deadline_switch'),
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.flag_outlined),
          title: const Text('Есть дедлайн'),
          subtitle: Text(
            deadline == null ? 'Без срока' : 'До ${Fmt.short(deadline)}',
          ),
          value: deadline != null,
          onChanged: (on) => onChanged(
            on
                ? settings.copyWith(deadline: defaultDeadline(today))
                : settings.copyWith(clearDeadline: true),
          ),
        ),
        if (deadline != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.edit_calendar),
              label: const Text('Изменить дату дедлайна'),
              onPressed: () async {
                final date = await pick(deadline, settings.startDate);
                if (date != null) onChanged(settings.copyWith(deadline: date));
              },
            ),
          ),
      ],
    );
  }
}
