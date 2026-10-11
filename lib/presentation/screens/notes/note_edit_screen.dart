import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/validators.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

/// Создание, изменение и удаление заметки.
class NoteEditScreen extends ConsumerStatefulWidget {
  const NoteEditScreen({super.key, this.noteId, this.topicId, this.topicTitle});

  /// `null` — новая заметка.
  final int? noteId;
  final String? topicId;
  final String? topicTitle;

  @override
  ConsumerState<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends ConsumerState<NoteEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  String? _topicTitle;
  bool _loaded = false;
  bool _saving = false;

  bool get _isEdit => widget.noteId != null;

  @override
  void initState() {
    super.initState();
    _topicTitle = widget.topicTitle;
    if (_isEdit) {
      _load();
    } else {
      _loaded = true;
    }
  }

  Future<void> _load() async {
    final note = await ref
        .read(noteRepositoryProvider)
        .noteById(widget.noteId!);
    if (!mounted) return;
    if (note != null) {
      _title.text = note.title;
      _body.text = note.body;
      _topicTitle = note.topicTitle;
    }
    setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    setState(() => _saving = true);
    final repo = ref.read(noteRepositoryProvider);
    try {
      if (_isEdit) {
        await repo.updateNote(
          id: widget.noteId!,
          title: _title.text,
          body: _body.text,
        );
      } else {
        await repo.createNote(
          userId: userId,
          title: _title.text,
          body: _body.text,
          topicId: widget.topicId,
          topicTitle: widget.topicTitle,
        );
      }
      if (mounted) {
        context.pop();
        showSnack(context, 'Заметка сохранена');
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showSnack(context, 'Не удалось сохранить: $e', error: true);
      }
    }
  }

  Future<void> _delete() async {
    final ok = await confirm(
      context,
      title: 'Удалить заметку?',
      message: 'Заметку нельзя будет восстановить.',
    );
    if (!ok || !mounted) return;
    await ref.read(noteRepositoryProvider).deleteNote(widget.noteId!);
    if (mounted) {
      context.pop();
      showSnack(context, 'Заметка удалена');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Заметка' : 'Новая заметка'),
        actions: [
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
        child: !_loaded
            ? const LoadingView()
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_topicTitle != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Chip(
                          avatar: const Icon(Icons.push_pin, size: 18),
                          label: Text(_topicTitle!),
                        ),
                      ),
                    TextFormField(
                      key: const Key('note_title'),
                      controller: _title,
                      decoration: const InputDecoration(labelText: 'Заголовок'),
                      validator: Validators.title,
                    ),
                    const SizedBox(height: 12),
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
