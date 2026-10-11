import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/plan.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

/// «Мои планы»: несколько планов, выбор активного, переименование, удаление.
class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(plansProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Мои планы')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('new_plan'),
        icon: const Icon(Icons.add),
        label: const Text('Новый план'),
        onPressed: () => context.push('/onboarding'),
      ),
      body: ContentFrame(
        child: plansAsync.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(error: e),
          data: (plans) => plans.isEmpty
              ? const EmptyState(
                  icon: Icons.folder_open,
                  title: 'Планов пока нет',
                  message: 'Нажмите «Новый план», чтобы создать первый.',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  children: [
                    for (final p in plans)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _PlanCard(plan: p),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

enum _PlanAction { activate, rename, replan, delete }

class _PlanCard extends ConsumerWidget {
  const _PlanCard({required this.plan});

  final StudyPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progress = ref.watch(planProgressProvider(plan.id)).value;
    return Card(
      shape: plan.isActive
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.orange, width: 2),
            )
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: plan.isActive ? null : () => _activate(context, ref),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(plan.title, style: theme.textTheme.titleMedium),
                  ),
                  if (plan.isActive)
                    const Chip(
                      label: Text('активный'),
                      visualDensity: VisualDensity.compact,
                    ),
                  PopupMenuButton<_PlanAction>(
                    key: Key('plan_menu_${plan.id}'),
                    onSelected: (a) => _onAction(context, ref, a),
                    itemBuilder: (_) => [
                      if (!plan.isActive)
                        const PopupMenuItem(
                          value: _PlanAction.activate,
                          child: Text('Сделать активным'),
                        ),
                      const PopupMenuItem(
                        value: _PlanAction.rename,
                        child: Text('Переименовать'),
                      ),
                      const PopupMenuItem(
                        value: _PlanAction.replan,
                        child: Text('Перестроить с сегодняшнего дня'),
                      ),
                      const PopupMenuItem(
                        value: _PlanAction.delete,
                        child: Text('Удалить'),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                '${Fmt.hours(plan.settings.hoursPerWeek)} ч/нед · '
                '${(plan.settings.studyDays.toList()..sort()).map((d) => weekdayShort[d - 1]).join(', ')}'
                '${plan.settings.deadline == null ? '' : ' · до ${Fmt.short(plan.settings.deadline!)}'}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: LinearProgressIndicator(
                  value: progress?.ratio ?? 0,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                progress == null
                    ? ''
                    : '${(progress.ratio * 100).round()}% · '
                          '${progress.doneSessions} из ${progress.totalSessions} занятий',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _activate(BuildContext context, WidgetRef ref) async {
    await ref.read(planRepositoryProvider).setActive(plan.userId, plan.id);
    if (context.mounted) showSnack(context, '«${plan.title}» теперь активный');
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    _PlanAction action,
  ) async {
    final repo = ref.read(planRepositoryProvider);
    try {
      switch (action) {
        case _PlanAction.activate:
          await _activate(context, ref);
        case _PlanAction.rename:
          final title = await _askTitle(context, plan.title);
          if (title != null) await repo.renamePlan(plan.id, title);
        case _PlanAction.replan:
          final result = await ref.read(planServiceProvider).replan(plan);
          if (context.mounted) {
            showSnack(
              context,
              result.finishDate == null
                  ? 'План перестроен'
                  : 'План перестроен, окончание ${Fmt.short(result.finishDate!)}',
            );
          }
        case _PlanAction.delete:
          final ok = await confirm(
            context,
            title: 'Удалить план?',
            message:
                '«${plan.title}» и все его занятия будут удалены без возможности восстановления.',
          );
          if (ok) {
            await repo.deletePlan(plan.id);
            if (context.mounted) showSnack(context, 'План удалён');
          }
      }
    } on Object catch (e) {
      if (context.mounted) showSnack(context, 'Ошибка: $e', error: true);
    }
  }

  Future<String?> _askTitle(BuildContext context, String initial) {
    final controller = TextEditingController(text: initial);
    final formKey = GlobalKey<FormState>();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Название плана'),
        content: Form(
          key: formKey,
          child: TextFormField(
            key: const Key('rename_field'),
            controller: controller,
            autofocus: true,
            validator: Validators.title,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            key: const Key('rename_save'),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(controller.text.trim());
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }
}
