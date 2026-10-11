// Слой presentation (интерфейс): экран «Настройки плана» (маршрут
// '/plan/settings', открывается кнопкой на вкладке «План»). Позволяет
// поменять часы в неделю, учебные дни и дедлайн активного плана; после
// сохранения PlanService перестраивает невыполненные занятия. Форму полей
// берёт готовую — ScheduleForm из экрана онбординга schedule_screen.dart.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../domain/entities/schedule_settings.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import '../onboarding/schedule_screen.dart';

/// Изменение расписания активного плана с последующим перепланированием.
///
/// ConsumerStatefulWidget — виджет Riverpod (менеджер состояния) со своим
/// состоянием: здесь это изменённые, но ещё не сохранённые настройки.
class PlanSettingsScreen extends ConsumerStatefulWidget {
  /// Создаёт экран настроек плана.
  const PlanSettingsScreen({super.key});

  /// Создаёт объект состояния экрана.
  @override
  ConsumerState<PlanSettingsScreen> createState() => _PlanSettingsScreenState();
}

/// Состояние экрана настроек: черновик настроек и флаг сохранения.
class _PlanSettingsScreenState extends ConsumerState<PlanSettingsScreen> {
  /// Настройки, изменённые пользователем на этом экране. `null` — пока
  /// ничего не меняли, тогда берутся настройки из самого плана.
  ScheduleSettings? _settings;

  /// `true`, пока идёт сохранение и перестройка плана.
  bool _saving = false;

  /// Строит экран: заглушку без плана или форму с кнопкой сохранения.
  @override
  Widget build(BuildContext context) {
    // Активный план пользователя (`.value` — данные, если уже загружены,
    // иначе null).
    final plan = ref.watch(activePlanProvider).value;
    // Активного плана нет — показываем пустое состояние.
    if (plan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Настройки плана')),
        body: const ContentFrame(
          child: EmptyState(icon: Icons.tune, title: 'Нет активного плана'),
        ),
      );
    }
    // Что показать в форме: изменённые настройки или текущие из плана.
    final settings = _settings ?? plan.settings;
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки плана')),
      body: ContentFrame(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Название плана.
            Text(plan.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            // Пояснение, что произойдёт после сохранения.
            const Text(
              'После сохранения невыполненные занятия будут перестроены '
              'начиная с сегодняшнего дня. Выполненные останутся на месте.',
            ),
            const SizedBox(height: 16),
            // Общая форма расписания без поля «Начало обучения»: план уже
            // идёт. Изменения пока хранятся только в состоянии экрана.
            ScheduleForm(
              settings: settings,
              showStartDate: false,
              onChanged: (s) => setState(() => _settings = s),
            ),
            const SizedBox(height: 24),
            // Кнопка «Сохранить и перестроить». Неактивна во время
            // сохранения и если не выбран ни один учебный день.
            FilledButton(
              key: const Key('plan_settings_save'),
              onPressed: _saving || settings.studyDays.isEmpty
                  ? null
                  : () async {
                      // Блокируем кнопку на время сохранения.
                      setState(() => _saving = true);
                      try {
                        // Сохраняем новые настройки и сразу перестраиваем
                        // невыполненную часть плана с сегодняшнего дня.
                        final result = await ref
                            .read(planServiceProvider)
                            .updateSettings(plan, settings);
                        // Экран могли закрыть, пока шло ожидание, —
                        // тогда context использовать уже нельзя.
                        if (!context.mounted) return;
                        // Возвращаемся на предыдущий экран.
                        context.pop();
                        // Сообщение с итогом: новая дата окончания или
                        // предупреждение, что дедлайн не выполняется
                        // (и сколько часов в неделю для него нужно).
                        showSnack(
                          context,
                          result.deadlineMet
                              ? 'Расписание обновлено'
                                    '${result.finishDate == null ? '' : ', окончание ${Fmt.short(result.finishDate!)}'}'
                              : 'Расписание обновлено, но план не укладывается в дедлайн'
                                    '${result.requiredHoursPerWeek == null ? '' : ' (нужно ${Fmt.hours(result.requiredHoursPerWeek!)} ч/нед)'}',
                        );
                      } on Object catch (e) {
                        // Ошибка: снова включаем кнопку и показываем
                        // красное сообщение.
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
      ),
    );
  }
}
