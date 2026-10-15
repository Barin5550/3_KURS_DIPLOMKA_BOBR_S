// Экран регистрации нового аккаунта: имя, email, пароль и повтор пароля.
// Слой: presentation (интерфейс). Открывается роутером по адресу /register
// (core/router/app_router.dart); саму регистрацию выполняет
// AuthController (presentation/providers/auth_controller.dart). После
// успеха пользователь попадает на экран входа с уже введённым email.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/validators.dart';
import '../../../domain/repositories/repositories.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

/// Экран регистрации: имя, email, пароль и его повтор с проверкой полей.
///
/// ConsumerStatefulWidget — виджет с состоянием из библиотеки Riverpod
/// (Riverpod — менеджер состояния; через `ref` экран обращается к
/// провайдерам, например к AuthController).
class RegisterScreen extends ConsumerStatefulWidget {
  /// Создаёт экран регистрации (параметров нет).
  const RegisterScreen({super.key});

  /// Создаёт объект состояния, в котором живёт логика экрана.
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

/// Состояние экрана регистрации: содержимое полей, флажки и ошибка email.
class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  /// Ключ формы: через него запускается проверка всех полей сразу.
  final _formKey = GlobalKey<FormState>();

  /// Контроллер поля «Имя».
  final _name = TextEditingController();

  /// Контроллер поля «Email».
  final _email = TextEditingController();

  /// Контроллер поля «Пароль».
  final _password = TextEditingController();

  /// Контроллер поля «Повторите пароль».
  final _confirm = TextEditingController();

  /// Скрыты ли оба поля пароля точками.
  bool _obscure = true;

  /// Идёт ли сейчас запрос регистрации (кнопка показывает индикатор).
  bool _loading = false;

  /// Ошибка регистрации, которая показывается под полем email
  /// (например, такой email уже занят), или null.
  String? _emailError;

  /// Вызывается при закрытии экрана: освобождает контроллеры полей.
  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  /// Обработчик кнопки «Создать аккаунт»: проверяет поля и регистрирует.
  Future<void> _submit() async {
    // Убираем прошлую ошибку email.
    setState(() => _emailError = null);
    // Проверяем все поля формы; при ошибках регистрация не начнётся.
    if (!_formKey.currentState!.validate()) return;
    // Включаем индикатор загрузки на кнопке.
    setState(() => _loading = true);
    try {
      // Просим AuthController создать пользователя; он вернёт
      // созданного пользователя.
      final user = await ref
          .read(authControllerProvider.notifier)
          .register(
            name: _name.text,
            email: _email.text,
            password: _password.text,
          );
      // Если экран уже закрыт, переходить некуда.
      if (!mounted) return;
      // Переходим на экран входа и передаём в адресе email и признак
      // «только что зарегистрирован»: /login?email=...&registered=1.
      context.go(
        Uri(
          path: '/login',
          queryParameters: {'email': user.email, 'registered': '1'},
        ).toString(),
      );
    } on ConnectionException catch (e) {
      // Сервер недоступен — сообщение внизу экрана, а не под полем email.
      if (mounted) showSnack(context, e.message, error: true);
    } on AppException catch (e) {
      // Ошибка уникальности email показывается прямо под полем.
      if (mounted) setState(() => _emailError = e.message);
    } on Object catch (e) {
      // Непредвиденная ошибка — красное всплывающее сообщение.
      if (mounted) showSnack(context, 'Ошибка регистрации: $e', error: true);
    } finally {
      // В любом случае выключаем индикатор загрузки.
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Строит внешний вид экрана регистрации.
  @override
  Widget build(BuildContext context) {
    // Текущая тема приложения: стили текста и цвета.
    final theme = Theme.of(context);
    return Scaffold(
      // Верхняя панель с заголовком и кнопкой «Назад».
      appBar: AppBar(
        title: const Text('Регистрация'),
        // Стрелка «Назад» всегда ведёт на экран входа.
        leading: IconButton(
          tooltip: 'Назад',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      // ContentFrame ограничивает ширину на широких экранах.
      body: ContentFrame(
        // SafeArea — отступ от выреза камеры и системных панелей.
        child: SafeArea(
          child: Center(
            // Прокрутка, чтобы форма не обрезалась под клавиатурой.
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              // Форма не шире 420 пикселей.
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                // Form объединяет поля, чтобы проверять их вместе.
                child: Form(
                  key: _formKey,
                  // Поле проверяется сразу, как только его начали
                  // редактировать, а не только по кнопке.
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  // Все элементы формы — столбиком на всю ширину.
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Пояснение над формой.
                      Text(
                        'Создайте аккаунт, чтобы получить персональный план',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 20),
                      // Поле «Имя»: каждое слово с заглавной буквы.
                      TextFormField(
                        // Ключ, по которому поле находят автотесты.
                        key: const Key('reg_name'),
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        // Кнопка «Далее» на клавиатуре — к следующему полю.
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Имя',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        // Проверка имени (core/utils/validators.dart).
                        validator: Validators.name,
                      ),
                      const SizedBox(height: 14),
                      // Поле «Email» с проверкой формата.
                      TextFormField(
                        key: const Key('reg_email'),
                        controller: _email,
                        // Клавиатура с символом «@».
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.alternate_email),
                          // Ошибка регистрации (email занят)
                          // показывается под полем.
                          errorText: _emailError,
                        ),
                        // Как только пользователь меняет email, старую
                        // ошибку «email занят» убираем.
                        onChanged: (_) {
                          if (_emailError != null) {
                            setState(() => _emailError = null);
                          }
                        },
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 14),
                      // Поле «Пароль» с подсказкой о требованиях.
                      TextFormField(
                        key: const Key('reg_password'),
                        controller: _password,
                        // Пароль скрыт точками, пока _obscure = true.
                        obscureText: _obscure,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Пароль',
                          // Серая подсказка под полем.
                          helperText: 'Не менее 8 символов, буквы и цифры',
                          prefixIcon: const Icon(Icons.lock_outline),
                          // Кнопка-«глаз»: показать или скрыть пароль
                          // (действует на оба поля пароля).
                          suffixIcon: IconButton(
                            tooltip: _obscure
                                ? 'Показать пароль'
                                : 'Скрыть пароль',
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        // Проверка сложности пароля.
                        validator: Validators.password,
                      ),
                      const SizedBox(height: 14),
                      // Поле «Повторите пароль».
                      TextFormField(
                        key: const Key('reg_confirm'),
                        controller: _confirm,
                        obscureText: _obscure,
                        // «Готово» на клавиатуре сразу отправляет форму.
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          labelText: 'Повторите пароль',
                          prefixIcon: Icon(Icons.lock_reset),
                        ),
                        // Сравнивает с текущим текстом поля «Пароль»;
                        // функция передаётся, чтобы брать свежее значение.
                        validator: Validators.confirmPassword(
                          () => _password.text,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Кнопка регистрации: пока идёт запрос, она
                      // неактивна и показывает индикатор загрузки.
                      FilledButton(
                        key: const Key('reg_submit'),
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Создать аккаунт'),
                      ),
                      const SizedBox(height: 12),
                      // Ссылка обратно на экран входа.
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Уже есть аккаунт? Войти'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
