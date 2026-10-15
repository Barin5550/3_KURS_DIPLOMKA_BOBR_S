// Экран «Сменить пароль»: форма из трёх полей (текущий пароль, новый пароль
// и его повтор) и кнопка сохранения.
// Слой: presentation (интерфейс). Открывается из профиля по маршруту
// '/profile/password'; саму смену пароля выполняет AuthController.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/validators.dart';
import '../../../domain/repositories/repositories.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

/// Смена пароля: текущий пароль, новый и его повтор.
///
/// Это ConsumerStatefulWidget — виджет со своим изменяемым состоянием,
/// которому доступны провайдеры Riverpod (Riverpod — библиотека, через
/// которую экраны получают общие данные и контроллеры приложения).
class ChangePasswordScreen extends ConsumerStatefulWidget {
  /// Создаёт экран смены пароля (параметров нет).
  const ChangePasswordScreen({super.key});

  /// Создаёт объект состояния, в котором живут поля формы и логика.
  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

/// Состояние экрана смены пароля: контроллеры полей, ошибка и флаг загрузки.
class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  /// Ключ формы: через него запускается проверка всех полей сразу.
  final _formKey = GlobalKey<FormState>();

  /// Контроллер поля «Текущий пароль» (хранит введённый текст).
  final _old = TextEditingController();

  /// Контроллер поля «Новый пароль».
  final _new = TextEditingController();

  /// Контроллер поля «Повторите новый пароль».
  final _confirm = TextEditingController();

  /// Ошибка от репозитория (например, неверный текущий пароль).
  /// Показывается под полем текущего пароля; `null` — ошибки нет.
  String? _oldError;

  /// `true`, пока идёт сохранение: кнопка в это время неактивна.
  bool _saving = false;

  /// Освобождает контроллеры полей, когда экран закрывается,
  /// чтобы не было утечек памяти.
  @override
  void dispose() {
    // Каждый TextEditingController нужно закрыть вручную.
    _old.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  /// Проверяет форму и меняет пароль через AuthController.
  ///
  /// При успехе закрывает экран и показывает сообщение «Пароль изменён»,
  /// при ошибке (AppException) выводит её текст под полем текущего пароля.
  Future<void> _save() async {
    // Сбрасываем прошлую ошибку, чтобы она не висела при повторной попытке.
    setState(() => _oldError = null);
    // Запускаем валидаторы всех полей; если хоть одно неверно — выходим.
    if (!_formKey.currentState!.validate()) return;
    // Включаем режим сохранения: кнопка станет неактивной.
    setState(() => _saving = true);
    try {
      // Берём контроллер авторизации из провайдера и просим сменить пароль.
      await ref
          .read(authControllerProvider.notifier)
          .changePassword(oldPassword: _old.text, newPassword: _new.text);
      // mounted — экран ещё открыт (за время ожидания его могли закрыть).
      if (mounted) {
        // Возвращаемся на предыдущий экран (профиль).
        context.pop();
        // Всплывающее сообщение внизу экрана об успехе.
        showSnack(context, 'Пароль изменён');
      }
    } on AppException catch (e) {
      // Ошибка из репозитория (например, неверный текущий пароль):
      // показываем её текст под полем «Текущий пароль».
      if (mounted) setState(() => _oldError = e.message);
    } finally {
      // В любом случае выключаем режим сохранения.
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Строит интерфейс экрана: шапку и форму с тремя полями и кнопкой.
  @override
  Widget build(BuildContext context) {
    // Scaffold — каркас экрана: верхняя панель и основная область.
    return Scaffold(
      // Верхняя панель с заголовком и кнопкой «назад».
      appBar: AppBar(title: const Text('Сменить пароль')),
      // ContentFrame ограничивает ширину содержимого на широких экранах.
      body: ContentFrame(
        // Form объединяет поля, чтобы проверять их вместе по _formKey.
        child: Form(
          key: _formKey,
          // Прокручиваемый список полей с отступом 16 по краям.
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Поле «Текущий пароль»: символы скрыты, достаточно непустого
              // значения; сюда же выводится ошибка от репозитория.
              TextFormField(
                key: const Key('old_password'),
                controller: _old,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Текущий пароль',
                  errorText: _oldError,
                ),
                validator: Validators.loginPassword,
              ),
              const SizedBox(height: 12),
              // Поле «Новый пароль»: проверяется по правилам сложности
              // (не менее 8 символов, буквы и цифры), есть подсказка.
              TextFormField(
                key: const Key('new_password'),
                controller: _new,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Новый пароль',
                  helperText: 'Не менее 8 символов, буквы и цифры',
                ),
                validator: Validators.password,
              ),
              const SizedBox(height: 12),
              // Поле повтора: валидатор сравнивает его с текстом нового
              // пароля (функция () => _new.text берёт актуальное значение).
              TextFormField(
                key: const Key('confirm_password'),
                controller: _confirm,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Повторите новый пароль',
                ),
                validator: Validators.confirmPassword(() => _new.text),
              ),
              const SizedBox(height: 24),
              // Кнопка сохранения: пока идёт запрос, onPressed = null,
              // и кнопка неактивна (защита от двойного нажатия).
              FilledButton(
                key: const Key('password_save'),
                onPressed: _saving ? null : _save,
                child: const Text('Сменить пароль'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
