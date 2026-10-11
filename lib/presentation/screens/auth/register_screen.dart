import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/validators.dart';
import '../../../domain/repositories/repositories.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

/// Экран регистрации: имя, email, пароль и его повтор с проверкой полей.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _emailError;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _emailError = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = await ref
          .read(authControllerProvider.notifier)
          .register(
            name: _name.text,
            email: _email.text,
            password: _password.text,
          );
      if (!mounted) return;
      context.go(
        Uri(
          path: '/login',
          queryParameters: {'email': user.email, 'registered': '1'},
        ).toString(),
      );
    } on AppException catch (e) {
      // Ошибка уникальности email показывается прямо под полем.
      if (mounted) setState(() => _emailError = e.message);
    } on Object catch (e) {
      if (mounted) showSnack(context, 'Ошибка регистрации: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Регистрация'),
        leading: IconButton(
          tooltip: 'Назад',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: ContentFrame(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Создайте аккаунт, чтобы получить персональный план',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        key: const Key('reg_name'),
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Имя',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: Validators.name,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const Key('reg_email'),
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.alternate_email),
                          errorText: _emailError,
                        ),
                        onChanged: (_) {
                          if (_emailError != null) {
                            setState(() => _emailError = null);
                          }
                        },
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const Key('reg_password'),
                        controller: _password,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Пароль',
                          helperText: 'Не менее 8 символов, буквы и цифры',
                          prefixIcon: const Icon(Icons.lock_outline),
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
                        validator: Validators.password,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const Key('reg_confirm'),
                        controller: _confirm,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          labelText: 'Повторите пароль',
                          prefixIcon: Icon(Icons.lock_reset),
                        ),
                        validator: Validators.confirmPassword(
                          () => _password.text,
                        ),
                      ),
                      const SizedBox(height: 24),
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
