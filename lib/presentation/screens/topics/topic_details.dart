import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/topic.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

/// Описание темы, материалы и заметки. Используется на экранах темы и занятия.
class TopicDetails extends ConsumerWidget {
  const TopicDetails({super.key, required this.topic});

  final Topic topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notes = ref.watch(notesProvider(topic.id)).value ?? const [];
    final favorites = ref.watch(favoritesProvider).value ?? const {};
    final isFavorite = favorites.contains(topic.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('О теме', style: theme.textTheme.titleMedium)),
            IconButton(
              key: const Key('favorite_toggle'),
              tooltip: isFavorite ? 'Убрать из избранного' : 'В избранное',
              icon: Icon(
                isFavorite ? Icons.star : Icons.star_border,
                color: isFavorite ? AppColors.orange : null,
              ),
              onPressed: () {
                final userId = ref.read(currentUserIdProvider);
                if (userId != null) {
                  ref
                      .read(topicRepositoryProvider)
                      .toggleFavorite(userId, topic.id);
                }
              },
            ),
          ],
        ),
        Text(
          topic.description.isEmpty ? 'Описание не задано' : topic.description,
        ),
        const SizedBox(height: 8),
        Text(
          'Оценка времени: ${Fmt.minutes(topic.minutes)}',
          style: theme.textTheme.bodySmall,
        ),
        if (topic.resources.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Материалы', style: theme.textTheme.titleMedium),
          for (final r in topic.resources)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(r.title),
              subtitle: Text(r.url),
              trailing: IconButton(
                tooltip: 'Скопировать ссылку',
                icon: const Icon(Icons.copy),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: r.url));
                  if (context.mounted) showSnack(context, 'Ссылка скопирована');
                },
              ),
            ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                'Заметки (${notes.length})',
                style: theme.textTheme.titleMedium,
              ),
            ),
            TextButton.icon(
              key: const Key('add_topic_note'),
              icon: const Icon(Icons.add),
              label: const Text('Добавить'),
              onPressed: () => context.push(
                Uri(
                  path: '/notes/edit',
                  queryParameters: {
                    'topicId': topic.id,
                    'topicTitle': topic.title,
                  },
                ).toString(),
              ),
            ),
          ],
        ),
        if (notes.isEmpty)
          Text(
            'Записывайте главное своими словами: так материал запоминается лучше.',
            style: theme.textTheme.bodySmall,
          )
        else
          for (final n in notes)
            Card(
              child: ListTile(
                title: Text(n.title),
                subtitle: Text(
                  n.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => context.push('/notes/edit?id=${n.id}'),
              ),
            ),
      ],
    );
  }
}
