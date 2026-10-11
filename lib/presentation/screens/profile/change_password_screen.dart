import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/validators.dart';
import '../../../domain/repositories/repositories.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

/// Смена пароля: текущий пароль, новый и его повтор.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  String? _oldError;
  bool _saving = false;

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _oldError = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .changePassword(oldPassword: _old.text, newPassword: _new.text);
      if (mounted) {
        context.pop();
        showSnack(context, 'Пароль изменён');
      }
    } on AppException catch (e) {
      if (mounted) setState(() => _oldError = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Сменить пароль')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
            FilledButton(
              key: const Key('password_save'),
              onPressed: _saving ? null : _save,
              child: const Text('Сменить пароль'),
            ),
          ],
        ),
      ),
    );
  }
}
