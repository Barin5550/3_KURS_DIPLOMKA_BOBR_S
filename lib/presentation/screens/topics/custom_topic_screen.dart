// Форма создания и изменения собственной темы пользователя
// (маршруты /topics/custom/new и /topics/custom/:id).
// Слой: presentation (интерфейс). Открывается кнопкой «Своя тема» на вкладке
// «Темы» (topics_screen.dart) и карандашом на экране темы (topic_screen.dart).
// Сохраняет тему в базу через репозиторий тем (topicRepositoryProvider).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/topic.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

/// Создание и изменение собственной темы.
///
/// Можно указать, после каких тем каталога её изучать: генератор плана
/// учтёт эти зависимости при топологической сортировке.
///
/// Топологическая сортировка — упорядочивание тем так, чтобы каждая тема
/// шла после тех, от которых она зависит.
///
/// ConsumerStatefulWidget — виджет со своим состоянием (поля формы),
/// который умеет читать провайдеры Riverpod.
class CustomTopicScreen extends ConsumerStatefulWidget {
  /// Создаёт форму. Для изменения передаётся [topicId], для новой темы —
  /// [directionId] (направление, к которому тема будет относиться).
  const CustomTopicScreen({super.key, this.topicId, this.directionId});

  /// `null` — создание новой темы.
  final String? topicId;

  /// Направление новой темы (берётся из адреса ?direction=...).
  final String? directionId;

  /// Создаёт объект состояния формы.
  @override
  ConsumerState<CustomTopicScreen> createState() => _CustomTopicScreenState();
}

/// Состояние формы: контроллеры полей, выбранные зависимости и флаги
/// загрузки и сохранения.
class _CustomTopicScreenState extends ConsumerState<CustomTopicScreen> {
  /// Ключ формы: через него запускается проверка всех полей сразу.
  final _formKey = GlobalKey<FormState>();

  /// Текст поля «Название».
  final _title = TextEditingController();

  /// Текст поля «Описание».
  final _description = TextEditingController();

  /// Текст поля «Часы» (по умолчанию 2 часа).
  final _hours = TextEditingController(text: '2');

  /// Текст поля «Категория» (по умолчанию «Мои темы»).
  final _category = TextEditingController(text: 'Мои темы');

  /// id тем каталога, после которых нужно изучать эту тему.
  final Set<String> _prerequisites = {};

  /// Направление темы: из параметров экрана или из базы при изменении.
  String? _directionId;

  /// `true`, когда данные темы загружены и форму можно показывать.
  bool _loaded = false;

  /// `true`, пока идёт сохранение: кнопка «Сохранить» неактивна.
  bool _saving = false;

  /// Режим изменения существующей темы (а не создания новой).
  bool get _isEdit => widget.topicId != null;

  /// Вызывается один раз при создании состояния: запоминает направление
  /// и, если тема изменяется, запускает загрузку её данных.
  @override
  void initState() {
    super.initState();
    // Направление, переданное экрану (для новой темы).
    _directionId = widget.directionId;
    // При изменении грузим тему из базы, иначе форма сразу готова.
    if (_isEdit) {
      _load();
    } else {
      _loaded = true;
    }
  }

  /// Загружает изменяемую тему из базы и заполняет поля формы.
  Future<void> _load() async {
    // Репозиторий тем — класс, который читает и пишет темы в базе.
    final repo = ref.read(topicRepositoryProvider);
    // Сама тема и её направление.
    final topic = await repo.customTopicById(widget.topicId!);
    final direction = await repo.directionOf(widget.topicId!);
    // Экран закрыли, пока шла загрузка, — дальше ничего не делаем.
    if (!mounted) return;
    // Переносим данные темы в поля формы.
    if (topic != null) {
      _title.text = topic.title;
      _description.text = topic.description;
      // Часы показываем в виде «1,5» (с запятой).
      _hours.text = Fmt.hours(topic.hours);
      _category.text = topic.category;
      _prerequisites.addAll(topic.prerequisites);
      _directionId = direction;
    }
    // Перерисовываем экран: вместо индикатора появится форма.
    setState(() => _loaded = true);
  }

  /// Освобождает контроллеры полей, когда экран закрывается.
  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _hours.dispose();
    _category.dispose();
    super.dispose();
  }

  /// Проверяет форму и сохраняет тему: создаёт новую или обновляет
  /// существующую, затем закрывает экран.
  Future<void> _save() async {
    // Проверяем все поля; если есть ошибки, они покажутся под полями.
    if (!_formKey.currentState!.validate()) return;
    // Нужны id пользователя и направление, без них сохранить нельзя.
    final userId = ref.read(currentUserIdProvider);
    final directionId = _directionId;
    if (userId == null || directionId == null) return;
    // Блокируем кнопку на время сохранения.
    setState(() => _saving = true);
    final repo = ref.read(topicRepositoryProvider);
    // Часы из поля переводим в минуты (в базе время хранится в минутах).
    final minutes = (Validators.parseHours(_hours.text) * 60).round();
    try {
      // Режим изменения — обновляем существующую тему.
      if (_isEdit) {
        await repo.updateCustomTopic(
          topicId: widget.topicId!,
          title: _title.text,
          description: _description.text,
          minutes: minutes,
          category: _category.text,
          prerequisites: _prerequisites.toList(),
        );
      } else {
        // Режим создания — добавляем новую тему пользователю.
        await repo.createCustomTopic(
          userId: userId,
          directionId: directionId,
          title: _title.text,
          description: _description.text,
          minutes: minutes,
          category: _category.text,
          prerequisites: _prerequisites.toList(),
        );
      }
      // Успех: закрываем форму и показываем сообщение.
      if (mounted) {
        context.pop();
        showSnack(context, _isEdit ? 'Тема сохранена' : 'Тема добавлена');
      }
    } on Object catch (e) {
      // Ошибка: снова включаем кнопку и показываем красное сообщение.
      if (mounted) {
        setState(() => _saving = false);
        showSnack(context, 'Не удалось сохранить: $e', error: true);
      }
    }
  }

  /// Строит форму: направление, название, описание, часы, категория,
  /// выбор тем-зависимостей и кнопка «Сохранить».
  @override
  Widget build(BuildContext context) {
    // Направление темы и его данные из каталога (название и список тем).
    final directionId = _directionId;
    final direction = directionId == null
        ? null
        : ref.watch(directionProvider(directionId)).value;

    return Scaffold(
      // Заголовок зависит от режима: изменение или создание.
      appBar: AppBar(title: Text(_isEdit ? 'Изменить тему' : 'Новая тема')),
      body: ContentFrame(
        // Пока данные не загружены — индикатор, потом — форма.
        child: !_loaded
            ? const LoadingView()
            // Form объединяет поля, чтобы проверить их все одной командой.
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Подпись «Направление: ...», если направление известно.
                    if (direction != null)
                      Text(
                        'Направление: ${direction.title}',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    const SizedBox(height: 12),
                    // Поле «Название» с проверкой: не пустое, до 80 символов.
                    TextFormField(
                      key: const Key('topic_title'),
                      controller: _title,
                      decoration: const InputDecoration(labelText: 'Название'),
                      validator: Validators.title,
                    ),
                    const SizedBox(height: 12),
                    // Поле «Описание» на 2–5 строк, необязательное.
                    TextFormField(
                      controller: _description,
                      minLines: 2,
                      maxLines: 5,
                      decoration: const InputDecoration(labelText: 'Описание'),
                    ),
                    const SizedBox(height: 12),
                    // Строка из двух полей: «Часы» (узкое) и «Категория»
                    // (в два раза шире, flex: 2).
                    Row(
                      children: [
                        Expanded(
                          // Поле «Часы»: цифровая клавиатура с дробной
                          // частью, проверка — число от 0,5 до 100.
                          child: TextFormField(
                            key: const Key('topic_hours'),
                            controller: _hours,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Часы',
                              suffixText: 'ч',
                            ),
                            validator: Validators.hours,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          // Поле «Категория»: обязательно к заполнению.
                          child: TextFormField(
                            controller: _category,
                            decoration: const InputDecoration(
                              labelText: 'Категория',
                            ),
                            validator: (v) =>
                                Validators.requiredText(v, field: 'категорию'),
                          ),
                        ),
                      ],
                    ),
                    // Блок «Изучать после тем» — выбор зависимостей
                    // из тем каталога этого направления.
                    if (direction != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Изучать после тем',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Генератор плана поставит тему после выбранных',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      // Wrap переносит чипы на новую строку, если не влезают.
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          // FilterChip для каждой темы каталога: нажатие
                          // добавляет её id в зависимости или убирает оттуда.
                          for (final Topic t in direction.topics)
                            FilterChip(
                              label: Text(
                                t.title,
                                overflow: TextOverflow.ellipsis,
                              ),
                              selected: _prerequisites.contains(t.id),
                              onSelected: (on) => setState(
                                () => on
                                    ? _prerequisites.add(t.id)
                                    : _prerequisites.remove(t.id),
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    // Кнопка «Сохранить»: неактивна, пока идёт сохранение.
                    FilledButton(
                      key: const Key('topic_save'),
                      onPressed: _saving ? null : _save,
                      child: const Text('Сохранить'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
