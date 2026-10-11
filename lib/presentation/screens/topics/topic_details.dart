// Блок подробностей темы: описание, оценка времени, учебные материалы
// и заметки пользователя по этой теме, плюс кнопка «В избранное».
// Слой: presentation (интерфейс). Это не отдельный экран, а часть экранов:
// его вставляют экран темы (topic_screen.dart) и экран занятия
// (plan/session_screen.dart).
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
///
/// ConsumerWidget — виджет без своего состояния, который читает провайдеры
/// Riverpod (провайдер — «источник» данных: заметки, избранное и т. д.).
class TopicDetails extends ConsumerWidget {
  /// Создаёт блок подробностей для темы [topic].
  const TopicDetails({super.key, required this.topic});

  /// Тема, подробности которой показываются.
  final Topic topic;

  /// Строит колонку: «О теме» со звёздочкой, описание, материалы, заметки.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Текущая тема оформления (стили текста).
    final theme = Theme.of(context);
    // Заметки пользователя по этой теме; пока не загрузились — пустой список.
    final notes = ref.watch(notesProvider(topic.id)).value ?? const [];
    // Множество id избранных тем; пока не загрузилось — пустое.
    final favorites = ref.watch(favoritesProvider).value ?? const {};
    // Отмечена ли эта тема как избранная.
    final isFavorite = favorites.contains(topic.id);

    // Колонка, растягивающая дочерние элементы на всю ширину.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Строка: заголовок «О теме» слева и звёздочка избранного справа.
        Row(
          children: [
            Expanded(child: Text('О теме', style: theme.textTheme.titleMedium)),
            // Кнопка-звёздочка: закрашенная оранжевая, если тема в избранном.
            IconButton(
              key: const Key('favorite_toggle'),
              tooltip: isFavorite ? 'Убрать из избранного' : 'В избранное',
              icon: Icon(
                isFavorite ? Icons.star : Icons.star_border,
                color: isFavorite ? AppColors.orange : null,
              ),
              onPressed: () {
                // id вошедшего пользователя (null, если никто не вошёл).
                final userId = ref.read(currentUserIdProvider);
                // Добавляем тему в избранное или убираем её оттуда
                // через репозиторий тем (запись в базе данных).
                if (userId != null) {
                  ref
                      .read(topicRepositoryProvider)
                      .toggleFavorite(userId, topic.id);
                }
              },
            ),
          ],
        ),
        // Описание темы или заглушка, если описания нет.
        Text(
          topic.description.isEmpty ? 'Описание не задано' : topic.description,
        ),
        const SizedBox(height: 8),
        // Сколько времени займёт тема, например «1 ч 30 мин».
        Text(
          'Оценка времени: ${Fmt.minutes(topic.minutes)}',
          style: theme.textTheme.bodySmall,
        ),
        // Раздел «Материалы» — только если у темы есть ссылки.
        if (topic.resources.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Материалы', style: theme.textTheme.titleMedium),
          // Строка списка для каждого материала: название и адрес ссылки.
          for (final r in topic.resources)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(r.title),
              subtitle: Text(r.url),
              // Кнопка справа копирует ссылку в буфер обмена.
              trailing: IconButton(
                tooltip: 'Скопировать ссылку',
                icon: const Icon(Icons.copy),
                onPressed: () async {
                  // Кладём адрес в системный буфер обмена.
                  await Clipboard.setData(ClipboardData(text: r.url));
                  // Сообщаем об этом, если виджет ещё на экране.
                  if (context.mounted) showSnack(context, 'Ссылка скопирована');
                },
              ),
            ),
        ],
        const SizedBox(height: 16),
        // Строка: заголовок «Заметки (N)» и кнопка «Добавить».
        Row(
          children: [
            Expanded(
              child: Text(
                'Заметки (${notes.length})',
                style: theme.textTheme.titleMedium,
              ),
            ),
            // Кнопка «Добавить» открывает редактор новой заметки и передаёт
            // ему id и название темы в параметрах адреса (?topicId=...),
            // чтобы заметка привязалась к этой теме.
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
        // Заметок нет — подсказка, зачем их вести.
        if (notes.isEmpty)
          Text(
            'Записывайте главное своими словами: так материал запоминается лучше.',
            style: theme.textTheme.bodySmall,
          )
        // Иначе — карточка на каждую заметку: заголовок и две строки текста.
        else
          for (final n in notes)
            Card(
              child: ListTile(
                title: Text(n.title),
                // Текст заметки обрезается до двух строк с многоточием.
                subtitle: Text(
                  n.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // Нажатие открывает заметку в редакторе по её id.
                onTap: () => context.push('/notes/edit?id=${n.id}'),
              ),
            ),
      ],
    );
  }
}
