// Экран «Мои заметки» (маршрут /notes): все заметки пользователя с поиском
// и кнопкой создания новой заметки.
// Слой: presentation (интерфейс). Открывается из профиля
// (profile/profile_screen.dart); нажатие на заметку ведёт в редактор
// (note_edit_screen.dart).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

/// Все заметки пользователя с поиском.
///
/// ConsumerStatefulWidget — виджет со своим состоянием (текст поиска),
/// который умеет читать провайдеры Riverpod (источники данных приложения).
class NotesScreen extends ConsumerStatefulWidget {
  /// Создаёт экран заметок.
  const NotesScreen({super.key});

  /// Создаёт объект состояния экрана.
  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

/// Состояние экрана заметок: хранит контроллер строки поиска.
class _NotesScreenState extends ConsumerState<NotesScreen> {
  /// Контроллер строки поиска по заметкам.
  final _search = TextEditingController();

  /// Освобождает контроллер поиска при закрытии экрана.
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Строит экран: верхняя панель, кнопка «+» и список заметок.
  @override
  Widget build(BuildContext context) {
    // Все заметки пользователя: null вместо id темы — без фильтра по теме.
    // Репозиторий отдаёт их отсортированными: недавно изменённые сверху.
    final notesAsync = ref.watch(notesProvider(null));
    return Scaffold(
      appBar: AppBar(title: const Text('Мои заметки')),
      // Круглая плавающая кнопка «+»: открывает редактор новой заметки.
      floatingActionButton: FloatingActionButton(
        key: const Key('add_note'),
        tooltip: 'Новая заметка',
        onPressed: () => context.push('/notes/edit'),
        child: const Icon(Icons.add),
      ),
      body: ContentFrame(
        // Загрузка — индикатор, ошибка — сообщение, данные — список.
        child: notesAsync.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(error: e),
          data: (notes) {
            // Заметок ещё нет совсем — пустое состояние с кнопкой
            // «Создать заметку».
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
            // Поисковый запрос без пробелов по краям, в нижнем регистре.
            final q = _search.text.trim().toLowerCase();
            // Оставляем заметки, где запрос встречается в заголовке,
            // тексте или названии темы (если заметка к теме привязана).
            final filtered = notes
                .where(
                  (n) =>
                      q.isEmpty ||
                      n.title.toLowerCase().contains(q) ||
                      n.body.toLowerCase().contains(q) ||
                      (n.topicTitle?.toLowerCase().contains(q) ?? false),
                )
                .toList();
            // Прокручиваемый список; снизу отступ 96 под плавающую кнопку.
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                // Строка поиска: при вводе экран перерисовывается
                // (setState) и список фильтруется заново.
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Поиск по заметкам',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 12),
                // По запросу ничего не нашлось — «Ничего не найдено».
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: EmptyState(
                      icon: Icons.search_off,
                      title: 'Ничего не найдено',
                    ),
                  ),
                // Карточка для каждой найденной заметки.
                for (final n in filtered)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      // Заголовок заметки.
                      title: Text(n.title),
                      // Подпись: «Тема: ...» (если есть) и текст заметки,
                      // склеенные через перенос строки, не больше 3 строк.
                      subtitle: Text(
                        [
                          if (n.topicTitle != null) 'Тема: ${n.topicTitle}',
                          n.body,
                        ].join('\n'),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Справа — дата последнего изменения (дд.мм.гггг).
                      trailing: Text(
                        Fmt.short(n.updatedAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      // Нажатие открывает заметку в редакторе по её id.
                      onTap: () => context.push('/notes/edit?id=${n.id}'),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
