// Адрес сервера API на экране входа (слой presentation, общий виджет).
// Кнопка показывает, к какому серверу подключено приложение, и открывает
// окно, где адрес можно изменить. Перед сохранением приложение проверяет
// связь с сервером (GET /api/health), поэтому неверный адрес не сохранится.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/repositories.dart';
import '../providers/providers.dart';
import 'common.dart';

/// Кнопка «Сервер: адрес» под формой входа.
class ServerAddressButton extends ConsumerWidget {
  /// Создаёт кнопку адреса сервера.
  const ServerAddressButton({super.key});

  /// Строит кнопку с текущим адресом сервера.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Текущий адрес; кнопка перерисуется, когда он изменится.
    final url = ref.watch(serverUrlProvider);
    return TextButton.icon(
      key: const Key('server_settings'),
      icon: const Icon(Icons.dns_outlined),
      // Схему «http://» не показываем, чтобы строка была короче.
      label: Text('Сервер: ${url.replaceFirst(RegExp('^https?://'), '')}'),
      onPressed: () => _open(context, ref),
    );
  }

  /// Открывает окно смены адреса; если адрес сохранён — сообщает об этом
  /// и пробует войти по сохранённой сессии.
  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => const ServerAddressDialog(),
    );
    if (saved != true || !context.mounted) return;
    showSnack(context, 'Связь с сервером есть, адрес сохранён');
    // Если пользователь отмечал «Запомнить меня», войдём без пароля.
    await ref.read(authControllerProvider.notifier).restoreSession();
  }
}

/// Окно «Сервер API»: поле адреса и кнопка «Проверить и сохранить».
class ServerAddressDialog extends ConsumerStatefulWidget {
  /// Создаёт окно адреса сервера.
  const ServerAddressDialog({super.key});

  /// Создаёт объект состояния окна.
  @override
  ConsumerState<ServerAddressDialog> createState() =>
      _ServerAddressDialogState();
}

/// Состояние окна: текст поля, проверка связи и ошибка.
class _ServerAddressDialogState extends ConsumerState<ServerAddressDialog> {
  /// Поле адреса; сначала в нём текущий адрес.
  late final _url = TextEditingController(text: ref.read(serverUrlProvider));

  /// Идёт ли сейчас проверка связи.
  bool _checking = false;

  /// Почему адрес не подошёл (показывается под полем) или null.
  String? _error;

  /// Освобождает контроллер поля при закрытии окна.
  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  /// Проверяет связь с сервером и сохраняет адрес.
  Future<void> _save() async {
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      await ref.read(serverUrlProvider.notifier).change(_url.text);
      // Сервер ответил — закрываем окно с результатом «сохранено».
      if (mounted) Navigator.of(context).pop(true);
    } on AppException catch (e) {
      // Сервер не ответил: показываем причину под полем.
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  /// Строит окно.
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Сервер API'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Подсказка, где взять адрес.
        const Text(
          'Адрес компьютера, на котором запущен сервер «Маршрут». Его '
          'показывает окно сервера, например http://192.168.1.5:8080.',
        ),
        const SizedBox(height: 16),
        // Поле адреса с клавиатурой для ссылок.
        TextField(
          key: const Key('server_url_field'),
          controller: _url,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: 'Адрес сервера',
            errorText: _error,
            errorMaxLines: 4,
          ),
          onSubmitted: (_) => _save(),
        ),
      ],
    ),
    actions: [
      // Закрыть окно без изменений.
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('Отмена'),
      ),
      // Проверить связь и сохранить; во время проверки — индикатор.
      FilledButton(
        key: const Key('server_url_save'),
        onPressed: _checking ? null : _save,
        child: _checking
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : const Text('Проверить и сохранить'),
      ),
    ],
  );
}
