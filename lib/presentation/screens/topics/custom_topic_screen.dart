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
class CustomTopicScreen extends ConsumerStatefulWidget {
  const CustomTopicScreen({super.key, this.topicId, this.directionId});

  /// `null` — создание новой темы.
  final String? topicId;
  final String? directionId;

  @override
  ConsumerState<CustomTopicScreen> createState() => _CustomTopicScreenState();
}

class _CustomTopicScreenState extends ConsumerState<CustomTopicScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _hours = TextEditingController(text: '2');
  final _category = TextEditingController(text: 'Мои темы');
  final Set<String> _prerequisites = {};
  String? _directionId;
  bool _loaded = false;
  bool _saving = false;

  bool get _isEdit => widget.topicId != null;

  @override
  void initState() {
    super.initState();
    _directionId = widget.directionId;
    if (_isEdit) {
      _load();
    } else {
      _loaded = true;
    }
  }

  Future<void> _load() async {
    final repo = ref.read(topicRepositoryProvider);
    final topic = await repo.customTopicById(widget.topicId!);
    final direction = await repo.directionOf(widget.topicId!);
    if (!mounted) return;
    if (topic != null) {
      _title.text = topic.title;
      _description.text = topic.description;
      _hours.text = Fmt.hours(topic.hours);
      _category.text = topic.category;
      _prerequisites.addAll(topic.prerequisites);
      _directionId = direction;
    }
    setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _hours.dispose();
    _category.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = ref.read(currentUserIdProvider);
    final directionId = _directionId;
    if (userId == null || directionId == null) return;
    setState(() => _saving = true);
    final repo = ref.read(topicRepositoryProvider);
    final minutes = (Validators.parseHours(_hours.text) * 60).round();
    try {
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
      if (mounted) {
        context.pop();
        showSnack(context, _isEdit ? 'Тема сохранена' : 'Тема добавлена');
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showSnack(context, 'Не удалось сохранить: $e', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final directionId = _directionId;
    final direction = directionId == null
        ? null
        : ref.watch(directionProvider(directionId)).value;

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Изменить тему' : 'Новая тема')),
      body: ContentFrame(
        child: !_loaded
            ? const LoadingView()
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (direction != null)
                      Text(
                        'Направление: ${direction.title}',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('topic_title'),
                      controller: _title,
                      decoration: const InputDecoration(labelText: 'Название'),
                      validator: Validators.title,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _description,
                      minLines: 2,
                      maxLines: 5,
                      decoration: const InputDecoration(labelText: 'Описание'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
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
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final Topic t in direction.topics)
                            FilterChip(
                              label: Text(t.title),
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
