// Редактор заметки (маршрут /notes/edit): создание новой заметки, изменение
// и удаление существующей. Заметка может быть привязана к теме.
// Слой: presentation (интерфейс). Открывается со списка заметок
// (notes_screen.dart) и из блока заметок темы (topics/topic_details.dart).
// Данные пишет в базу через репозиторий заметок (noteRepositoryProvider).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/validators.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

/// Создание, изменение и удаление заметки.
///
/// ConsumerStatefulWidget — виджет со своим состоянием (поля формы),
/// который умеет читать провайдеры Riverpod (источники данных приложения).
class NoteEditScreen extends ConsumerStatefulWidget {
  /// Создаёт редактор. Параметры приходят из адреса: ?id=... для
  /// существующей заметки, ?topicId=...&topicTitle=... для заметки к теме.
  const NoteEditScreen({super.key, this.noteId, this.topicId, this.topicTitle});

  /// `null` — новая заметка.
  final int? noteId;

  /// id темы, к которой привязывается новая заметка (может быть `null`).
  final String? topicId;

  /// Название этой темы — показывается над полями и сохраняется в заметке.
  final String? topicTitle;

  /// Создаёт объект состояния редактора.
  @override
  ConsumerState<NoteEditScreen> createState() => _NoteEditScreenState();
}

/// Состояние редактора: контроллеры полей и флаги загрузки и сохранения.
class _NoteEditScreenState extends ConsumerState<NoteEditScreen> {
  /// Ключ формы: через него проверяются все поля сразу.
  final _formKey = GlobalKey<FormState>();

  /// Текст поля «Заголовок».
  final _title = TextEditingController();

  /// Текст поля «Текст».
  final _body = TextEditingController();

  /// Название темы, к которой привязана заметка (для плашки сверху).
  String? _topicTitle;

  /// `true`, когда данные заметки загружены и форму можно показать.
  bool _loaded = false;

  /// `true`, пока идёт сохранение: кнопка «Сохранить» неактивна.
  bool _saving = false;

  /// Режим изменения существующей заметки (а не создания новой).
  bool get _isEdit => widget.noteId != null;

  /// Вызывается один раз при создании состояния: запоминает тему
  /// и, если заметка изменяется, запускает её загрузку.
  @override
  void initState() {
    super.initState();
    // Название темы, переданное экрану (для новой заметки к теме).
    _topicTitle = widget.topicTitle;
    // Существующую заметку грузим из базы, новая форма готова сразу.
    if (_isEdit) {
      _load();
    } else {
      _loaded = true;
    }
  }

  /// Загружает заметку из базы и заполняет поля формы.
  Future<void> _load() async {
    // Заметка по id через репозиторий заметок.
    final note = await ref
        .read(noteRepositoryProvider)
        .noteById(widget.noteId!);
    // Экран закрыли, пока шла загрузка, — выходим.
    if (!mounted) return;
    // Переносим заголовок, текст и тему заметки в форму.
    if (note != null) {
      _title.text = note.title;
      _body.text = note.body;
      _topicTitle = note.topicTitle;
    }
    // Перерисовываем экран: вместо индикатора появится форма.
    setState(() => _loaded = true);
  }

  /// Освобождает контроллеры полей при закрытии экрана.
  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  /// Проверяет форму и сохраняет заметку (новую или изменённую),
  /// затем закрывает экран.
  Future<void> _save() async {
    // Проверяем поля; ошибки покажутся под ними.
    if (!_formKey.currentState!.validate()) return;
    // Без вошедшего пользователя сохранять некуда.
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    // Блокируем кнопку на время сохранения.
    setState(() => _saving = true);
    final repo = ref.read(noteRepositoryProvider);
    try {
      if (_isEdit) {
        // Изменение: обновляем заголовок и текст существующей заметки.
        await repo.updateNote(
          id: widget.noteId!,
          title: _title.text,
          body: _body.text,
        );
      } else {
        // Создание: новая заметка пользователя, при необходимости
        // привязанная к теме.
        await repo.createNote(
          userId: userId,
          title: _title.text,
          body: _body.text,
          topicId: widget.topicId,
          topicTitle: widget.topicTitle,
        );
      }
      // Успех: закрываем редактор и показываем сообщение.
      if (mounted) {
        context.pop();
        showSnack(context, 'Заметка сохранена');
      }
    } on Object catch (e) {
      // Ошибка: снова включаем кнопку и показываем красное сообщение.
      if (mounted) {
        setState(() => _saving = false);
        showSnack(context, 'Не удалось сохранить: $e', error: true);
      }
    }
  }

  /// Удаляет заметку после подтверждения и закрывает экран.
  Future<void> _delete() async {
    // Диалог «Удалить заметку?»: ok = true, если пользователь согласился.
    final ok = await confirm(
      context,
      title: 'Удалить заметку?',
      message: 'Заметку нельзя будет восстановить.',
    );
    // Отказался или экран уже закрыт — ничего не делаем.
    if (!ok || !mounted) return;
    // Удаляем заметку на сервере; при ошибке runAction покажет причину.
    final deleted = await runAction(
      context,
      () => ref.read(noteRepositoryProvider).deleteNote(widget.noteId!),
    );
    // Закрываем редактор и сообщаем об удалении.
    if (deleted && mounted) {
      context.pop();
      showSnack(context, 'Заметка удалена');
    }
  }

  /// Строит редактор: панель с кнопкой удаления, плашка темы, поля
  /// «Заголовок» и «Текст» и кнопка «Сохранить».
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Заголовок зависит от режима: «Заметка» или «Новая заметка».
        title: Text(_isEdit ? 'Заметка' : 'Новая заметка'),
        actions: [
          // Корзина — только у существующей заметки.
          if (_isEdit)
            IconButton(
              key: const Key('delete_note'),
              tooltip: 'Удалить',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: ContentFrame(
        // Пока заметка грузится — индикатор, потом — форма.
        child: !_loaded
            ? const LoadingView()
            // Form объединяет поля, чтобы проверить их одной командой.
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Плашка с булавкой и названием темы, если заметка
                    // привязана к теме.
                    if (_topicTitle != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Chip(
                          avatar: const Icon(Icons.push_pin, size: 18),
                          label: Text(_topicTitle!),
                        ),
                      ),
                    // Поле «Заголовок»: не пустое, не длиннее 80 символов.
                    TextFormField(
                      key: const Key('note_title'),
                      controller: _title,
                      decoration: const InputDecoration(labelText: 'Заголовок'),
                      validator: Validators.title,
                    ),
                    const SizedBox(height: 12),
                    // Поле «Текст»: многострочное (от 6 до 16 строк),
                    // обязательно к заполнению.
                    TextFormField(
                      key: const Key('note_body'),
                      controller: _body,
                      minLines: 6,
                      maxLines: 16,
                      decoration: const InputDecoration(
                        labelText: 'Текст',
                        alignLabelWithHint: true,
                      ),
                      validator: (v) =>
                          Validators.requiredText(v, field: 'текст заметки'),
                    ),
                    const SizedBox(height: 24),
                    // Кнопка «Сохранить»: неактивна, пока идёт сохранение.
                    FilledButton(
                      key: const Key('note_save'),
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
