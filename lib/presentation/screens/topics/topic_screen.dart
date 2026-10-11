import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/topic.dart';
import '../../../domain/repositories/repositories.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import '../plan/session_screen.dart';
import 'topic_details.dart';

/// Экран темы: описание, материалы, заметки; для своей темы — изменение,
/// удаление и добавление в активный план.
class TopicScreen extends ConsumerWidget {
  const TopicScreen({super.key, required this.topicId});

  final String topicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicAsync = ref.watch(topicByIdProvider(topicId));
    return topicAsync.when(
      loading: () => const Scaffold(body: LoadingView()),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(error: e),
      ),
      data: (topic) {
        if (topic == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(
              icon: Icons.help_outline,
              title: 'Тема не найдена',
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(topic.isCustom ? 'Моя тема' : 'Тема'),
            actions: [
              if (topic.isCustom) ...[
                IconButton(
                  key: const Key('edit_custom_topic'),
                  tooltip: 'Изменить',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () async {
                    await context.push('/topics/custom/${topic.id}');
                    ref.invalidate(topicByIdProvider(topicId));
                  },
                ),
                IconButton(
                  key: const Key('delete_custom_topic'),
                  tooltip: 'Удалить',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(context, ref, topic),
                ),
              ],
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                topic.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [Chip(label: Text(topic.category))]),
              const SizedBox(height: 8),
              TopicDetails(topic: topic),
              const SizedBox(height: 16),
              if (topic.isCustom) _AddToPlanButton(topic: topic),
            ],
          ),
        );
      },
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Topic topic) async {
    final ok = await confirm(
      context,
      title: 'Удалить тему?',
      message:
          '«${topic.title}» будет удалена из списка тем. '
          'Занятия, уже добавленные в план, сохранятся.',
    );
    if (!ok || !context.mounted) return;
    try {
      await ref.read(topicRepositoryProvider).deleteCustomTopic(topic.id);
      if (context.mounted) {
        context.pop();
        showSnack(context, 'Тема удалена');
      }
    } on Object catch (e) {
      if (context.mounted) showSnack(context, 'Ошибка: $e', error: true);
    }
  }
}

class _AddToPlanButton extends ConsumerWidget {
  const _AddToPlanButton({required this.topic});

  final Topic topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(activePlanProvider).value;
    if (plan == null) return const SizedBox();
    return FilledButton.icon(
      key: const Key('add_topic_to_plan'),
      icon: const Icon(Icons.playlist_add),
      label: const Text('Добавить в активный план'),
      onPressed: () async {
        final direction = await ref
            .read(topicRepositoryProvider)
            .directionOf(topic.id);
        if (!context.mounted) return;
        if (direction != plan.directionId) {
          showSnack(
            context,
            'Тема относится к другому направлению, чем активный план',
            error: true,
          );
          return;
        }
        try {
          await ref.read(planServiceProvider).addTopic(plan, topic);
          if (context.mounted) {
            showSnack(context, 'Тема добавлена, план перестроен');
          }
        } on AppException catch (e) {
          if (context.mounted) showSnack(context, e.message, error: true);
        }
      },
    );
  }
}
