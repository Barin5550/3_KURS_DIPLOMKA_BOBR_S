import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

/// Все заметки пользователя с поиском.
class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesProvider(null));
    return Scaffold(
      appBar: AppBar(title: const Text('Мои заметки')),
      floatingActionButton: FloatingActionButton(
        key: const Key('add_note'),
        tooltip: 'Новая заметка',
        onPressed: () => context.push('/notes/edit'),
        child: const Icon(Icons.add),
      ),
      body: notesAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e),
        data: (notes) {
          if (notes.isEmpty) {
            return EmptyState(
              icon: Icons.sticky_note_2_outlined,
              title: 'Заметок пока нет',
              message:
                  'Создайте заметку здесь или на экране темы, чтобы она '
                  'была привязана к теме.',
              actionLabel: 'Создать заметку',
              onAction: () => context.push('/notes/edit'),
            );
          }
          final q = _search.text.trim().toLowerCase();
          final filtered = notes
              .where(
                (n) =>
                    q.isEmpty ||
                    n.title.toLowerCase().contains(q) ||
                    n.body.toLowerCase().contains(q) ||
                    (n.topicTitle?.toLowerCase().contains(q) ?? false),
              )
              .toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Поиск по заметкам',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: EmptyState(
                    icon: Icons.search_off,
                    title: 'Ничего не найдено',
                  ),
                ),
              for (final n in filtered)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(n.title),
                    subtitle: Text(
                      [
                        if (n.topicTitle != null) '📌 ${n.topicTitle}',
                        n.body,
                      ].join('\n'),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      Fmt.short(n.updatedAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    onTap: () => context.push('/notes/edit?id=${n.id}'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
