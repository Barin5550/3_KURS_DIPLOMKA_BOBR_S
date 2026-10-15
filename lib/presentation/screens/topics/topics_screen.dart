// Вкладка «Темы» (маршрут /topics): каталог тем выбранного направления
// вместе со своими темами пользователя, поиск, фильтры по категориям,
// избранное и кнопка создания своей темы.
// Слой: presentation (интерфейс). Открывается роутером
// (core/router/app_router.dart) внутри MainShell — оболочки с вкладками.
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
///
/// Notifier — класс Riverpod, который хранит одно значение (здесь — id
/// направления) и сообщает экранам, когда оно меняется.
class SelectedDirection extends Notifier<String?> {
  /// Начальное значение: `null` — направление ещё не выбирали вручную.
  @override
  String? build() => null;

  /// Запоминает направление с id [id], выбранное пользователем.
  void select(String id) => state = id;
}

/// Провайдер выбранного направления. Он объявлен вне экрана, поэтому
/// выбор хранится, даже если сам экран вкладки создаётся заново.
final selectedDirectionProvider = NotifierProvider<SelectedDirection, String?>(
  SelectedDirection.new,
);

/// Вкладка «Темы»: каталог направления, поиск, категории, избранное, свои темы.
///
/// ConsumerStatefulWidget — виджет со своим состоянием (текст поиска,
/// выбранный фильтр), который умеет читать провайдеры Riverpod.
class TopicsScreen extends ConsumerStatefulWidget {
  /// Создаёт вкладку «Темы».
  const TopicsScreen({super.key});

  /// Создаёт объект состояния вкладки.
  @override
  ConsumerState<TopicsScreen> createState() => _TopicsScreenState();
}

/// Состояние вкладки «Темы»: строка поиска и выбранный фильтр-чип.
class _TopicsScreenState extends ConsumerState<TopicsScreen> {
  /// Контроллер строки поиска.
  final _search = TextEditingController();

  /// `null` — все темы, `избранное` и `мои` — особые фильтры, иначе — категория.
  String? _chip;

  /// Значение фильтра «Избранное».
  static const _favorites = 'избранное';

  /// Значение фильтра «Мои» (только свои темы).
  static const _mine = 'мои';

  /// Освобождает контроллер поиска при закрытии экрана.
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Загружает список направлений и строит экран для выбранного из них.
  @override
  Widget build(BuildContext context) {
    // Все направления каталога (читаются из JSON-файлов в assets/catalog).
    final directionsAsync = ref.watch(directionsProvider);
    return directionsAsync.when(
      // Загрузка — индикатор, ошибка — сообщение об ошибке.
      loading: () => const Scaffold(body: LoadingView()),
      error: (e, _) => Scaffold(body: ErrorView(error: e)),
      data: (directions) {
        // Направление активного плана (если план есть).
        final activeDirection = ref
            .watch(activePlanProvider)
            .value
            ?.directionId;
        // Какое направление показать: выбранное вручную, иначе направление
        // активного плана, иначе первое в каталоге.
        final selectedId =
            ref.watch(selectedDirectionProvider) ??
            activeDirection ??
            directions.first.id;
        // Находим направление по id (если не нашлось — берём первое).
        final direction = directions.firstWhere(
          (d) => d.id == selectedId,
          orElse: () => directions.first,
        );
        return Scaffold(
          appBar: AppBar(
            title: const Text('Темы'),
            // Под заголовком — полоса с чипами направлений высотой 56.
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: _DirectionPicker(
                directions: directions,
                selected: direction,
                // При выборе другого направления запоминаем его
                // в провайдере и сбрасываем фильтр-чип на «Все».
                onSelected: (d) {
                  ref.read(selectedDirectionProvider.notifier).select(d.id);
                  setState(() => _chip = null);
                },
              ),
            ),
          ),
          // Плавающая кнопка «Своя тема»: открывает форму новой темы
          // для текущего направления.
          floatingActionButton: FloatingActionButton.extended(
            key: const Key('add_custom_topic'),
            icon: const Icon(Icons.add),
            label: const Text('Своя тема'),
            onPressed: () =>
                context.push('/topics/custom/new?direction=${direction.id}'),
          ),
          // Тело — список тем (строится методом _list).
          body: ContentFrame(child: _list(direction)),
        );
      },
    );
  }

  /// Строит список тем направления [direction] с поиском и фильтрами.
  Widget _list(Direction direction) {
    // Свои темы пользователя в этом направлении (пока грузятся — пусто).
    final custom = ref.watch(customTopicsProvider(direction.id)).value ?? [];
    // id избранных тем.
    final favorites = ref.watch(favoritesProvider).value ?? const {};
    // Все темы: сначала каталог, потом свои.
    final all = [...direction.topics, ...custom];
    // Список категорий каталога без повторов (через множество {...}).
    final categories = {for (final t in direction.topics) t.category}.toList();
    // Поисковый запрос без пробелов по краям и в нижнем регистре.
    final query = _search.text.trim().toLowerCase();
    // Словарь «id → тема», чтобы быстро находить названия зависимостей.
    final byId = {for (final t in all) t.id: t};

    // Оставляем темы, которые проходят и фильтр-чип, и поиск.
    final filtered = all.where((t) {
      // Проверка чипа: switch по значению _chip.
      final chipOk = switch (_chip) {
        // «Все» — подходит любая тема.
        null => true,
        // «Избранное» — только отмеченные звёздочкой.
        _favorites => favorites.contains(t.id),
        // «Мои» — только свои темы.
        _mine => t.isCustom,
        // Любое другое значение — это название категории.
        final category => t.category == category,
      };
      // Поиск: пустой запрос или совпадение в названии либо описании.
      final queryOk =
          query.isEmpty ||
          t.title.toLowerCase().contains(query) ||
          t.description.toLowerCase().contains(query);
      return chipOk && queryOk;
    }).toList();

    // Прокручиваемый список; снизу отступ 96, чтобы плавающая кнопка
    // не закрывала последнюю карточку.
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        // Строка поиска. При каждом вводе экран перерисовывается
        // (setState), и список фильтруется заново.
        TextField(
          key: const Key('topics_search'),
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Поиск по названию и описанию',
            prefixIcon: const Icon(Icons.search),
            // Крестик «Очистить» появляется, только когда есть текст.
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
        // Горизонтально прокручиваемая строка фильтров-чипов:
        // «Все», «Избранное», «Мои» и по одному чипу на каждую категорию.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _chipButton('Все', null),
              _chipButton('Избранное', _favorites, icon: Icons.star_rounded),
              _chipButton('Мои', _mine),
              for (final c in categories) _chipButton(c, c),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Сколько тем найдено, например «12 тем».
        Text(
          Fmt.count(filtered.length, 'тема', 'темы', 'тем'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        // Ничего не подошло — пустое состояние, текст которого зависит
        // от выбранного фильтра («Избранное», «Мои» или поиск).
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
        // Иначе — карточка для каждой подходящей темы.
        else
          for (final t in filtered)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _TopicCard(
                topic: t,
                isFavorite: favorites.contains(t.id),
                // Названия тем, после которых изучается эта тема
                // (id переводятся в названия, ненайденные отбрасываются).
                prerequisites: t.prerequisites
                    .map((id) => byId[id]?.title)
                    .whereType<String>()
                    .toList(),
                // Звёздочка: добавить в избранное или убрать оттуда.
                onFavorite: () {
                  final userId = ref.read(currentUserIdProvider);
                  if (userId != null) {
                    runAction(
                      context,
                      () => ref
                          .read(topicRepositoryProvider)
                          .toggleFavorite(userId, t.id),
                    );
                  }
                },
                // Нажатие на карточку открывает экран темы.
                onTap: () => context.push('/topic/${t.id}'),
              ),
            ),
      ],
    );
  }

  /// Один чип-фильтр с подписью [label]. [value] — значение для `_chip`,
  /// [icon] — необязательная иконка слева.
  Widget _chipButton(String label, String? value, {IconData? icon}) => Padding(
    padding: const EdgeInsets.only(right: 8),
    // ChoiceChip — чип с выбором одного варианта из нескольких.
    child: ChoiceChip(
      avatar: icon == null ? null : Icon(icon, size: 18),
      label: Text(label),
      // Чип подсвечен, если его значение совпадает с текущим фильтром.
      selected: _chip == value,
      // Нажатие делает этот фильтр текущим и перерисовывает список.
      onSelected: (_) => setState(() => _chip = value),
    ),
  );
}

/// Полоса выбора направления в нижней части AppBar: по чипу на каждое
/// направление каталога.
class _DirectionPicker extends StatelessWidget {
  /// Создаёт полосу выбора направления.
  const _DirectionPicker({
    required this.directions,
    required this.selected,
    required this.onSelected,
  });

  /// Все направления каталога.
  final List<Direction> directions;

  /// Направление, которое сейчас выбрано.
  final Direction selected;

  /// Что сделать, когда пользователь нажал на другое направление.
  final ValueChanged<Direction> onSelected;

  /// Строит горизонтальный список чипов направлений.
  @override
  Widget build(BuildContext context) {
    // Подложка чипа рисуется цветом canvasColor (белым) — делаем её
    // прозрачной, чтобы полупрозрачные чипы были видны на синей панели.
    return Theme(
      data: Theme.of(context).copyWith(canvasColor: Colors.transparent),
      child: SizedBox(
        height: 56,
        // Горизонтальный список, который можно листать вбок.
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          children: [
            // Чип для каждого направления.
            for (final d in directions)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  key: Key('pick_${d.id}'),
                  // Иконка направления: оранжевая у выбранного,
                  // полупрозрачная белая у остальных.
                  avatar: Icon(
                    directionIcon(d.icon),
                    size: 18,
                    color: d.id == selected.id
                        ? AppColors.orange
                        : Colors.white70,
                  ),
                  label: Text(d.title),
                  selected: d.id == selected.id,
                  // Галочку у выбранного чипа не показываем.
                  showCheckmark: false,
                  // Текст: тёмно-синий у выбранного, белый у остальных.
                  labelStyle: TextStyle(
                    color: d.id == selected.id ? AppColors.navy : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  // Material 3: цвет чипа задаётся по состояниям через color.
                  color: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? Colors.white
                        : Colors.white.withValues(alpha: .12),
                  ),
                  // Без рамки вокруг чипа.
                  side: BorderSide.none,
                  // Нажатие сообщает экрану о выборе направления.
                  onSelected: (_) => onSelected(d),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Карточка темы в списке: название (с пометкой «моя» для своей темы),
/// категория и время, темы-зависимости и звёздочка избранного.
class _TopicCard extends StatelessWidget {
  /// Создаёт карточку; данные и действия передаёт список тем.
  const _TopicCard({
    required this.topic,
    required this.isFavorite,
    required this.prerequisites,
    required this.onFavorite,
    required this.onTap,
  });

  /// Тема, которую показывает карточка.
  final Topic topic;

  /// Отмечена ли тема как избранная.
  final bool isFavorite;

  /// Названия тем, после которых изучается эта тема.
  final List<String> prerequisites;

  /// Действие при нажатии на звёздочку.
  final VoidCallback onFavorite;

  /// Действие при нажатии на саму карточку.
  final VoidCallback onTap;

  /// Строит карточку.
  @override
  Widget build(BuildContext context) {
    // Текущая тема оформления (стили и цвета).
    final theme = Theme.of(context);
    return Card(
      // InkWell делает карточку нажимаемой и рисует «волну» при нажатии.
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          // Слева — текстовая колонка, справа — звёздочка.
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Название темы и, для своей темы, оранжевая метка «моя».
                    Row(
                      children: [
                        // Flexible позволяет длинному названию переноситься,
                        // не выталкивая метку за край.
                        Flexible(
                          child: Text(
                            topic.title,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        // Метка «моя» — маленькая оранжевая плашка.
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
                    // «Категория · 2 ч» — категория и оценка времени.
                    Text(
                      '${topic.category} · ${Fmt.minutes(topic.minutes)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    // «После: ...» — темы-зависимости (не больше двух строк).
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
              // Звёздочка избранного: закрашенная оранжевая или контурная.
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
