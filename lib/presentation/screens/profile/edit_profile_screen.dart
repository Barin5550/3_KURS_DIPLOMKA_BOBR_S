import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/validators.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../domain/repositories/repositories.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

/// Редактирование имени, email и цвета аватара.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _user = ref.read(authControllerProvider).user!;
  late final _name = TextEditingController(text: _user.name);
  late final _email = TextEditingController(text: _user.email);
  late int _color = _user.avatarColor;
  String? _emailError;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _emailError = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .updateProfile(
            name: _name.text,
            email: _email.text,
            avatarColor: _color,
          );
      if (mounted) {
        context.pop();
        showSnack(context, 'Профиль сохранён');
      }
    } on AppException catch (e) {
      if (mounted) setState(() => _emailError = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = _name.text.trim().isEmpty
        ? '?'
        : _name.text.trim()[0].toUpperCase();
    return Scaffold(
      appBar: AppBar(title: const Text('Редактировать профиль')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: UserAvatar(initials: initials, color: _color, radius: 40),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              children: [
                for (final c in avatarPalette)
                  GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(c),
                      child: c == _color
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              key: const Key('edit_name'),
              controller: _name,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Имя',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: Validators.name,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('edit_email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.alternate_email),
                errorText: _emailError,
              ),
              validator: Validators.email,
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('edit_save'),
              onPressed: _saving ? null : _save,
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}
