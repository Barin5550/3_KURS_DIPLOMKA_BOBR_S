import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../domain/entities/schedule_settings.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import '../onboarding/schedule_screen.dart';

/// Изменение расписания активного плана с последующим перепланированием.
class PlanSettingsScreen extends ConsumerStatefulWidget {
  const PlanSettingsScreen({super.key});

  @override
  ConsumerState<PlanSettingsScreen> createState() => _PlanSettingsScreenState();
}

class _PlanSettingsScreenState extends ConsumerState<PlanSettingsScreen> {
  ScheduleSettings? _settings;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(activePlanProvider).value;
    if (plan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Настройки плана')),
        body: const EmptyState(icon: Icons.tune, title: 'Нет активного плана'),
      );
    }
    final settings = _settings ?? plan.settings;
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки плана')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(plan.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text(
            'После сохранения невыполненные занятия будут перестроены '
            'начиная с сегодняшнего дня. Выполненные останутся на месте.',
          ),
          const SizedBox(height: 16),
          ScheduleForm(
            settings: settings,
            showStartDate: false,
            onChanged: (s) => setState(() => _settings = s),
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('plan_settings_save'),
            onPressed: _saving || settings.studyDays.isEmpty
                ? null
                : () async {
                    setState(() => _saving = true);
                    try {
                      final result = await ref
                          .read(planServiceProvider)
                          .updateSettings(plan, settings);
                      if (!context.mounted) return;
                      context.pop();
                      showSnack(
                        context,
                        result.deadlineMet
                            ? 'Расписание обновлено'
                                  '${result.finishDate == null ? '' : ', окончание ${Fmt.short(result.finishDate!)}'}'
                            : 'Расписание обновлено, но план не укладывается в дедлайн'
                                  '${result.requiredHoursPerWeek == null ? '' : ' (нужно ${Fmt.hours(result.requiredHoursPerWeek!)} ч/нед)'}',
                      );
                    } on Object catch (e) {
                      if (context.mounted) {
                        setState(() => _saving = false);
                        showSnack(context, 'Ошибка: $e', error: true);
                      }
                    }
                  },
            child: const Text('Сохранить и перестроить'),
          ),
        ],
      ),
    );
  }
}
