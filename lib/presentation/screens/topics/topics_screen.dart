import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/direction.dart';
import '../../../domain/entities/topic.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

/// Выбранное направление на вкладке «Темы».
class SelectedDirection extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String id) => state = id;
}

final selectedDirectionProvider = NotifierProvider<SelectedDirection, String?>(
  SelectedDirection.new,
);

/// Вкладка «Темы»: каталог направления, поиск, категории, избранное, свои темы.
class TopicsScreen extends ConsumerStatefulWidget {
  const TopicsScreen({super.key});

  @override
  ConsumerState<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends ConsumerState<TopicsScreen> {
  final _search = TextEditingController();

  /// `null` — все темы, `★` — избранное, `мои` — свои, иначе — категория.
  String? _chip;

  static const _favorites = '★';
  static const _mine = 'мои';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final directionsAsync = ref.watch(directionsProvider);
    return directionsAsync.when(
      loading: () => const Scaffold(body: LoadingView()),
      error: (e, _) => Scaffold(body: ErrorView(error: e)),
      data: (directions) {
        final activeDirection = ref
            .watch(activePlanProvider)
            .value
            ?.directionId;
        final selectedId =
            ref.watch(selectedDirectionProvider) ??
            activeDirection ??
            directions.first.id;
        final direction = directions.firstWhere(
          (d) => d.id == selectedId,
          orElse: () => directions.first,
        );
        return Scaffold(
          appBar: AppBar(
            title: const Text('Темы'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: _DirectionPicker(
                directions: directions,
                selected: direction,
                onSelected: (d) {
                  ref.read(selectedDirectionProvider.notifier).select(d.id);
                  setState(() => _chip = null);
                },
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            key: const Key('add_custom_topic'),
            icon: const Icon(Icons.add),
            label: const Text('Своя тема'),
            onPressed: () =>
                context.push('/topics/custom/new?direction=${direction.id}'),
          ),
          body: ContentFrame(child: _list(direction)),
        );
      },
    );
  }

  Widget _list(Direction direction) {
    final custom = ref.watch(customTopicsProvider(direction.id)).value ?? [];
    final favorites = ref.watch(favoritesProvider).value ?? const {};
    final all = [...direction.topics, ...custom];
    final categories = {for (final t in direction.topics) t.category}.toList();
    final query = _search.text.trim().toLowerCase();
    final byId = {for (final t in all) t.id: t};

    final filtered = all.where((t) {
      final chipOk = switch (_chip) {
        null => true,
        _favorites => favorites.contains(t.id),
        _mine => t.isCustom,
        final category => t.category == category,
      };
      final queryOk =
          query.isEmpty ||
          t.title.toLowerCase().contains(query) ||
          t.description.toLowerCase().contains(query);
      return chipOk && queryOk;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        TextField(
          key: const Key('topics_search'),
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Поиск по названию и описанию',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Очистить',
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(_search.clear),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _chipButton('Все', null),
              _chipButton('★ Избранное', _favorites),
              _chipButton('Мои', _mine),
              for (final c in categories) _chipButton(c, c),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          Fmt.count(filtered.length, 'тема', 'темы', 'тем'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 32),
            child: EmptyState(
              icon: _chip == _favorites ? Icons.star_border : Icons.search_off,
              title: _chip == _favorites
                  ? 'В избранном пока пусто'
                  : _chip == _mine
                  ? 'Своих тем пока нет'
                  : 'Ничего не найдено',
              message: _chip == _favorites
                  ? 'Нажмите на звёздочку у темы, чтобы добавить её сюда'
                  : _chip == _mine
                  ? 'Добавьте тему, которой нет в каталоге, кнопкой «Своя тема»'
                  : 'Попробуйте изменить запрос',
            ),
          )
        else
          for (final t in filtered)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _TopicCard(
                topic: t,
                isFavorite: favorites.contains(t.id),
                prerequisites: t.prerequisites
                    .map((id) => byId[id]?.title)
                    .whereType<String>()
                    .toList(),
                onFavorite: () {
                  final userId = ref.read(currentUserIdProvider);
                  if (userId != null) {
                    ref
                        .read(topicRepositoryProvider)
                        .toggleFavorite(userId, t.id);
                  }
                },
                onTap: () => context.push('/topic/${t.id}'),
              ),
            ),
      ],
    );
  }

  Widget _chipButton(String label, String? value) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: _chip == value,
      onSelected: (_) => setState(() => _chip = value),
    ),
  );
}

class _DirectionPicker extends StatelessWidget {
  const _DirectionPicker({
    required this.directions,
    required this.selected,
    required this.onSelected,
  });

  final List<Direction> directions;
  final Direction selected;
  final ValueChanged<Direction> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          for (final d in directions)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                key: Key('pick_${d.id}'),
                avatar: Icon(
                  directionIcon(d.icon),
                  size: 18,
                  color: d.id == selected.id
                      ? AppColors.orange
                      : Colors.white70,
                ),
                label: Text(d.title),
                selected: d.id == selected.id,
                showCheckmark: false,
                labelStyle: TextStyle(
                  color: d.id == selected.id ? AppColors.navy : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                selectedColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: .12),
                side: BorderSide.none,
                onSelected: (_) => onSelected(d),
              ),
            ),
        ],
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.topic,
    required this.isFavorite,
    required this.prerequisites,
    required this.onFavorite,
    required this.onTap,
  });

  final Topic topic;
  final bool isFavorite;
  final List<String> prerequisites;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            topic.title,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        if (topic.isCustom) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.orange.withValues(alpha: .15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'моя',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.orange,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${topic.category} · ${Fmt.minutes(topic.minutes)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (prerequisites.isNotEmpty)
                      Text(
                        'После: ${prerequisites.join(', ')}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: isFavorite ? 'Убрать из избранного' : 'В избранное',
                icon: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  color: isFavorite ? AppColors.orange : null,
                ),
                onPressed: onFavorite,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
