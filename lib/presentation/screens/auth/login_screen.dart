// Экран входа в аккаунт: поля email и пароль, флажок «Запомнить меня»,
// кнопка «Войти», ссылка на регистрацию и адрес сервера API.
// Слой: presentation (интерфейс). Открывается роутером по адресу /login
// (core/router/app_router.dart); сам вход выполняет AuthController
// (presentation/providers/auth_controller.dart).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/validators.dart';
import '../../../domain/repositories/repositories.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/server_address.dart';

/// Экран авторизации: email, пароль, «Запомнить меня», переход к регистрации.
///
/// ConsumerStatefulWidget — виджет с состоянием из библиотеки Riverpod
/// (Riverpod — менеджер состояния; через `ref` экран обращается к
/// провайдерам, например к AuthController).
class LoginScreen extends ConsumerStatefulWidget {
  /// Создаёт экран входа. Параметры приходят из адреса страницы:
  /// `/login?email=...&registered=1`.
  const LoginScreen({
    super.key,
    this.initialEmail,
    this.justRegistered = false,
  });

  /// Email, который нужно заранее подставить в поле (после регистрации).
  final String? initialEmail;

  /// true, если пользователь только что зарегистрировался: тогда экран
  /// показывает сообщение «Аккаунт создан».
  final bool justRegistered;

  /// Создаёт объект состояния, в котором живёт логика экрана.
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

/// Состояние экрана входа: содержимое полей, флажки и ошибка.
class _LoginScreenState extends ConsumerState<LoginScreen> {
  /// Ключ формы: через него запускается проверка всех полей сразу.
  final _formKey = GlobalKey<FormState>();

  /// Контроллер поля email; изначально в нём email из параметра экрана.
  late final _email = TextEditingController(text: widget.initialEmail);

  /// Контроллер поля пароля.
  final _password = TextEditingController();

  /// Флажок «Запомнить меня» (по умолчанию включён).
  bool _remember = true;

  /// Скрыт ли пароль точками (true) или показан открытым текстом.
  bool _obscure = true;

  /// Идёт ли сейчас запрос входа (тогда кнопка показывает индикатор).
  bool _loading = false;

  /// Текст ошибки входа, который показывается над кнопкой (или null).
  String? _error;

  /// Вызывается один раз при появлении экрана.
  @override
  void initState() {
    super.initState();
    // После регистрации показываем подсказку «Аккаунт создан».
    if (widget.justRegistered) {
      // SnackBar можно показать только после первой отрисовки экрана,
      // поэтому откладываем вызов до конца кадра.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Проверяем, что экран ещё открыт.
        if (mounted) {
          showSnack(context, 'Аккаунт создан. Войдите, чтобы продолжить');
        }
      });
    }
  }

  /// Вызывается при закрытии экрана: освобождает контроллеры полей.
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Обработчик кнопки «Войти»: проверяет поля и выполняет вход.
  Future<void> _submit() async {
    // Убираем старую ошибку с экрана.
    setState(() => _error = null);
    // Проверяем все поля формы; если есть ошибки, они покажутся под
    // полями, и вход не начнётся.
    if (!_formKey.currentState!.validate()) return;
    // Сообщение «Аккаунт создан» после входа не нужно: иначе оно
    // закрывает кнопку внизу следующего экрана.
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    // Включаем индикатор загрузки на кнопке.
    setState(() => _loading = true);
    try {
      // Просим AuthController выполнить вход с введёнными данными.
      await ref
          .read(authControllerProvider.notifier)
          .login(
            email: _email.text,
            password: _password.text,
            remember: _remember,
          );
      // Переход на главную выполнит redirect роутера.
    } on AppException catch (e) {
      // Ожидаемая ошибка (например, неверный пароль): показываем её текст.
      if (mounted) setState(() => _error = e.message);
    } on Object catch (e) {
      // Любая другая непредвиденная ошибка.
      if (mounted) setState(() => _error = 'Не удалось войти: $e');
    } finally {
      // В любом случае выключаем индикатор загрузки.
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Строит внешний вид экрана входа.
  @override
  Widget build(BuildContext context) {
    // Текущая тема приложения: стили текста и цвета.
    final theme = Theme.of(context);
    return Scaffold(
      // ContentFrame ограничивает ширину на широких экранах.
      body: ContentFrame(
        // SafeArea — отступ от выреза камеры и системных панелей.
        child: SafeArea(
          child: Center(
            // Прокрутка, чтобы форма не обрезалась, когда открыта
            // клавиатура или экран маленький.
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              // Форма не шире 420 пикселей.
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                // Form объединяет поля, чтобы проверять их вместе.
                child: Form(
                  key: _formKey,
                  // Все элементы формы — столбиком на всю ширину.
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Логотип приложения сверху по центру.
                      const Center(child: AppLogo(size: 72)),
                      const SizedBox(height: 20),
                      // Заголовок экрана.
                      Text(
                        'С возвращением!',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Подзаголовок серым цветом.
                      Text(
                        'Войдите, чтобы продолжить обучение',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Поле ввода email с проверкой формата.
                      TextFormField(
                        // Ключ, по которому поле находят автотесты.
                        key: const Key('login_email'),
                        controller: _email,
                        // Клавиатура с символом «@».
                        keyboardType: TextInputType.emailAddress,
                        // Кнопка «Далее» на клавиатуре — к полю пароля.
                        textInputAction: TextInputAction.next,
                        // Подсказка системе для автозаполнения email.
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.alternate_email),
                        ),
                        // Проверка формата email (core/utils/validators).
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 14),
                      // Поле ввода пароля.
                      TextFormField(
                        key: const Key('login_password'),
                        controller: _password,
                        // Пароль скрыт точками, пока _obscure = true.
                        obscureText: _obscure,
                        // Кнопка «Готово» на клавиатуре сразу
                        // запускает вход.
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Пароль',
                          prefixIcon: const Icon(Icons.lock_outline),
                          // Кнопка-«глаз» справа: показать или
                          // скрыть пароль.
                          suffixIcon: IconButton(
                            tooltip: _obscure
                                ? 'Показать пароль'
                                : 'Скрыть пароль',
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            // Переключаем _obscure и перерисовываем.
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        // При входе пароль проверяется только на
                        // непустоту.
                        validator: Validators.loginPassword,
                      ),
                      // Флажок «Запомнить меня»: если включён, при
                      // следующем запуске вход выполнится сам.
                      CheckboxListTile(
                        value: _remember,
                        onChanged: (v) => setState(() => _remember = v ?? true),
                        title: const Text('Запомнить меня'),
                        // Квадратик слева от текста.
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      // Красная плашка с текстом ошибки — только если
                      // вход не удался.
                      if (_error != null)
                        Container(
                          key: const Key('login_error'),
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          // Иконка ошибки и текст в одну строку.
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: theme.colorScheme.onErrorContainer,
                              ),
                              const SizedBox(width: 8),
                              // Текст ошибки переносится на новые
                              // строки, если не помещается.
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: TextStyle(
                                    color: theme.colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Кнопка входа: пока идёт запрос, она неактивна и
                      // показывает индикатор загрузки вместо текста.
                      FilledButton(
                        key: const Key('login_submit'),
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
                            : const Text('Войти'),
                      ),
                      const SizedBox(height: 12),
                      // Ссылка на экран регистрации (/register).
                      TextButton(
                        key: const Key('go_register'),
                        onPressed: () => context.go('/register'),
                        child: const Text('Нет аккаунта? Зарегистрироваться'),
                      ),
                      // Адрес сервера API: все данные приложение получает
                      // с сервера, поэтому адрес можно проверить и
                      // изменить прямо здесь.
                      const ServerAddressButton(),
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
