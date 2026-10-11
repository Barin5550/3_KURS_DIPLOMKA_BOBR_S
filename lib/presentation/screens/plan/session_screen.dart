import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/session.dart';
import '../../../domain/entities/topic.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import '../topics/topic_details.dart';

final _sessionProvider = StreamProvider.autoDispose.family<StudySession?, int>((
  ref,
  id,
) async* {
  // Подписываемся на занятия плана, чтобы экран обновлялся при отметке.
  final repo = ref.watch(planRepositoryProvider);
  final first = await repo.sessionById(id);
  if (first == null) {
    yield null;
    return;
  }
  yield* repo
      .watchSessions(first.planId)
      .map((list) => list.where((s) => s.id == id).firstOrNull);
});

/// Карточка занятия: описание темы, материалы, заметки, Pomodoro.
class SessionScreen extends ConsumerWidget {
  const SessionScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(_sessionProvider(sessionId));
    return Scaffold(
      appBar: AppBar(title: const Text('Занятие')),
      body: ContentFrame(
        child: sessionAsync.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(error: e),
          data: (session) {
            if (session == null) {
              return const EmptyState(
                icon: Icons.event_busy,
                title: 'Занятие не найдено',
                message: 'Возможно, план был перестроен или удалён.',
              );
            }
            return _SessionBody(session: session);
          },
        ),
      ),
    );
  }
}

class _SessionBody extends ConsumerWidget {
  const _SessionBody({required this.session});

  final StudySession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final today = ref.watch(todayProvider);
    final topic = ref.watch(topicByIdProvider(session.topicId)).value;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 8,
          children: [
            Chip(label: Text(session.category)),
            Chip(
              avatar: Icon(
                session.kind == SessionKind.review
                    ? Icons.replay
                    : Icons.school,
                size: 18,
              ),
              label: Text(session.kind.label),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(session.topicTitle, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          '${Fmt.dayWithWeekday(session.date)} · ${Fmt.minutes(session.minutes)}'
          '${session.totalParts > 1 ? ' · часть ${session.part} из ${session.totalParts}' : ''}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: session.isMissed(today) ? theme.colorScheme.error : null,
          ),
        ),
        if (session.kind == SessionKind.review) ...[
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.lightbulb_outline, color: AppColors.orange),
              title: Text('Как повторять'),
              subtitle: Text(
                'Вспомните главное без подсказок, затем сверьтесь с заметками '
                'и материалами. Повторение через 1, 3 и 7 дней помогает '
                'перевести знания в долговременную память.',
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (topic != null) TopicDetails(topic: topic) else const SizedBox(),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const Key('session_toggle'),
          icon: Icon(session.isDone ? Icons.undo : Icons.check),
          label: Text(
            session.isDone ? 'Отменить отметку' : 'Отметить выполненным',
          ),
          onPressed: () async {
            await ref.read(planServiceProvider).toggleSession(session);
            if (context.mounted && !session.isDone) {
              showSnack(context, 'Отлично! Занятие выполнено');
            }
          },
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.timer_outlined),
          label: const Text('Pomodoro по этой теме'),
          onPressed: () => context.push(
            Uri(
              path: '/pomodoro',
              queryParameters: {'topic': session.topicTitle},
            ).toString(),
          ),
        ),
      ],
    );
  }
}

/// Тема по идентификатору: ищем в каталоге, затем среди своих тем.
final topicByIdProvider = FutureProvider.autoDispose.family<Topic?, String>((
  ref,
  topicId,
) async {
  final directions = await ref.watch(directionsProvider.future);
  for (final d in directions) {
    final t = d.topicById(topicId);
    if (t != null) return t;
  }
  return ref.watch(topicRepositoryProvider).customTopicById(topicId);
});
