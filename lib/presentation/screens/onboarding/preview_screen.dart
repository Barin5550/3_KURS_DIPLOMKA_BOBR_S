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
class PreviewScreen extends ConsumerStatefulWidget {
  const PreviewScreen({super.key});

  @override
  ConsumerState<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends ConsumerState<PreviewScreen> {
  bool _saving = false;

  Future<void> _save(PlanResult result) async {
    final draft = ref.read(onboardingProvider);
    final userId = ref.read(currentUserIdProvider);
    final direction = draft.direction;
    if (userId == null || direction == null) return;
    setState(() => _saving = true);
    try {
      final topics = await ref.read(
        directionTopicsProvider(direction.id).future,
      );
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
      ref.read(onboardingProvider.notifier).reset();
      if (mounted) {
        context.go('/home');
        showSnack(context, 'План сохранён. Удачи в обучении!');
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showSnack(context, 'Не удалось сохранить план: $e', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingProvider);
    final direction = draft.direction;
    if (direction == null) {
      return const Scaffold(
        body: Center(child: Text('Направление не выбрано')),
      );
    }
    final topicsAsync = ref.watch(directionTopicsProvider(direction.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Ваш план готов')),
      body: topicsAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e),
        data: (topics) {
          final PlanResult result;
          try {
            result = ref
                .read(planServiceProvider)
                .preview(
                  topics: topics,
                  settings: draft.settings,
                  knownTopicIds: draft.knownTopicIds,
                );
          } on CycleDetectedException catch (e) {
            return ErrorView(error: e);
          }
          return _PreviewBody(
            title: direction.title,
            result: result,
            saving: _saving,
            onSave: () => _save(result),
            onApplyHours: (hours) => ref
                .read(onboardingProvider.notifier)
                .updateSettings(draft.settings.copyWith(hoursPerWeek: hours)),
          );
        },
      ),
    );
  }
}

class _PreviewBody extends StatelessWidget {
  const _PreviewBody({
    required this.title,
    required this.result,
    required this.saving,
    required this.onSave,
    required this.onApplyHours,
  });

  final String title;
  final PlanResult result;
  final bool saving;
  final VoidCallback onSave;
  final ValueChanged<double> onApplyHours;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finish = result.finishDate;
    final required = result.requiredHoursPerWeek;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                _Stat(
                  icon: Icons.list_alt,
                  text:
                      '${Fmt.count(result.orderedTopics.length, 'тема', 'темы', 'тем')} в плане'
                      '${result.excludedTopics.isEmpty ? '' : ', ${result.excludedTopics.length} исключено по тесту'}',
                ),
                _Stat(
                  icon: Icons.schedule,
                  text:
                      '${Fmt.minutes(result.studyMinutes)} изучения + '
                      '${Fmt.minutes(result.reviewMinutes)} повторений',
                ),
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
        if (!result.deadlineMet)
          Card(
            key: const Key('deadline_warning'),
            color: AppColors.warning.withValues(alpha: .15),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Text(
                    required == null
                        ? 'Даже 84 часов в неделю не хватит. Перенесите дедлайн.'
                        : 'Чтобы успеть, нужно ${Fmt.hours(required)} ч в неделю.',
                  ),
                  if (required != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        key: const Key('apply_hours'),
                        onPressed: () => onApplyHours(required),
                        child: Text('Установить ${Fmt.hours(required)} ч/нед'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        const SectionTitle('Порядок тем'),
        for (var i = 0; i < result.orderedTopics.length; i++)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.navy,
              child: Text(
                '${i + 1}',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            title: Text(result.orderedTopics[i].title),
            subtitle: Text(
              '${result.orderedTopics[i].category} · '
              '${Fmt.minutes(result.orderedTopics[i].minutes)}',
            ),
          ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('preview_save'),
          onPressed: saving || result.orderedTopics.isEmpty ? null : onSave,
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
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => context.pop(),
          child: const Text('Изменить расписание'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Icon(icon, size: 20, color: AppColors.orange),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
