import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/repositories/repositories.dart';
import '../../providers/providers.dart';

/// Диалог удаления аккаунта. Удаление необратимо, поэтому пароль вводится
/// повторно. Возвращает `true`, если аккаунт удалён.
Future<bool> showDeleteAccountDialog(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    ) ??
    false;

class _DeleteAccountDialog extends ConsumerStatefulWidget {
  const _DeleteAccountDialog();

  @override
  ConsumerState<_DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<_DeleteAccountDialog> {
  final _password = TextEditingController();
  String? _error;
  bool _deleting = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_password.text.isEmpty) {
      setState(() => _error = 'Введите пароль');
      return;
    }
    setState(() {
      _error = null;
      _deleting = true;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .deleteAccount(_password.text);
      if (mounted) Navigator.of(context).pop(true);
    } on AppException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _deleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, color: error),
      title: const Text('Удалить аккаунт?'),
      // На широком экране без ограничения диалог растягивается
      // и текст вытягивается в одну длинную строку.
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Будут удалены все планы, занятия, заметки, свои темы и '
              'статистика. Отменить удаление нельзя.',
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('delete_password_field'),
              controller: _password,
              obscureText: true,
              autofocus: true,
              enabled: !_deleting,
              decoration: InputDecoration(
                labelText: 'Пароль',
                prefixIcon: const Icon(Icons.lock_outline),
                errorText: _error,
              ),
              onSubmitted: (_) => _delete(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _deleting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Отмена'),
        ),
        TextButton(
          key: const Key('delete_account_confirm'),
          onPressed: _deleting ? null : _delete,
          style: TextButton.styleFrom(foregroundColor: error),
          child: _deleting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Удалить'),
        ),
      ],
    );
  }
}
