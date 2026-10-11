// Диалог «Удалить аккаунт?»: предупреждает, что удаление необратимо,
// и просит ещё раз ввести пароль для подтверждения.
// Слой: presentation (интерфейс). Вызывается с экрана профиля через
// showDeleteAccountDialog(); удаление выполняет AuthController.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/repositories/repositories.dart';
import '../../providers/providers.dart';

/// Диалог удаления аккаунта. Удаление необратимо, поэтому пароль вводится
/// повторно. Возвращает `true`, если аккаунт удалён.
Future<bool> showDeleteAccountDialog(BuildContext context) async =>
    // showDialog показывает окно поверх экрана и ждёт, пока его закроют.
    // Если диалог закрыли без результата (тапом мимо окна), вернётся null,
    // и оператор ?? заменит его на false.
    await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    ) ??
    false;

/// Сам диалог удаления. ConsumerStatefulWidget — виджет со своим
/// состоянием и доступом к провайдерам Riverpod (библиотека, через которую
/// интерфейс получает контроллеры и данные приложения).
class _DeleteAccountDialog extends ConsumerStatefulWidget {
  /// Создаёт диалог (параметров нет).
  const _DeleteAccountDialog();

  /// Создаёт объект состояния с полем пароля и логикой удаления.
  @override
  ConsumerState<_DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

/// Состояние диалога: введённый пароль, текст ошибки и флаг удаления.
class _DeleteAccountDialogState extends ConsumerState<_DeleteAccountDialog> {
  /// Контроллер поля пароля (хранит введённый текст).
  final _password = TextEditingController();

  /// Текст ошибки под полем пароля; `null` — ошибки нет.
  String? _error;

  /// `true`, пока идёт удаление: поле и кнопки в это время отключены.
  bool _deleting = false;

  /// Освобождает контроллер поля при закрытии диалога.
  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  /// Проверяет, что пароль введён, и удаляет аккаунт через AuthController.
  ///
  /// При успехе закрывает диалог с результатом `true`, при ошибке
  /// (например, неверный пароль) показывает её текст под полем.
  Future<void> _delete() async {
    // Пустой пароль не отправляем — сразу показываем подсказку.
    if (_password.text.isEmpty) {
      setState(() => _error = 'Введите пароль');
      return;
    }
    // Сбрасываем старую ошибку и включаем режим удаления.
    setState(() {
      _error = null;
      _deleting = true;
    });
    try {
      // Просим контроллер авторизации удалить аккаунт с этим паролем.
      await ref
          .read(authControllerProvider.notifier)
          .deleteAccount(_password.text);
      // Если диалог ещё открыт — закрываем его с результатом true.
      if (mounted) Navigator.of(context).pop(true);
    } on AppException catch (e) {
      // Ошибка из репозитория: показываем текст и снова включаем поле
      // и кнопки, чтобы можно было ввести пароль ещё раз.
      if (mounted) {
        setState(() {
          _error = e.message;
          _deleting = false;
        });
      }
    }
  }

  /// Строит окно диалога: иконка, заголовок, предупреждение, поле пароля
  /// и две кнопки — «Отмена» и «Удалить».
  @override
  Widget build(BuildContext context) {
    // Цвет ошибки из темы (красный) — для иконки и кнопки «Удалить».
    final error = Theme.of(context).colorScheme.error;
    // AlertDialog — стандартное окно-предупреждение Material.
    return AlertDialog(
      // Иконка предупреждения красного цвета над заголовком.
      icon: Icon(Icons.warning_amber_rounded, color: error),
      title: const Text('Удалить аккаунт?'),
      // На широком экране без ограничения диалог растягивается
      // и текст вытягивается в одну длинную строку.
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        // Колонка по высоте содержимого, элементы прижаты к левому краю.
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Текст-предупреждение о том, какие данные пропадут.
            const Text(
              'Будут удалены все планы, занятия, заметки, свои темы и '
              'статистика. Отменить удаление нельзя.',
            ),
            const SizedBox(height: 16),
            // Поле пароля: символы скрыты, курсор ставится сразу,
            // во время удаления поле отключено. Нажатие Enter
            // на клавиатуре тоже запускает удаление.
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
      // Кнопки внизу диалога.
      actions: [
        // «Отмена»: закрывает диалог с результатом false.
        // Во время удаления неактивна.
        TextButton(
          onPressed: _deleting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Отмена'),
        ),
        // «Удалить»: красная кнопка, запускает _delete. Пока идёт
        // удаление, вместо текста показывает маленький индикатор загрузки.
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
