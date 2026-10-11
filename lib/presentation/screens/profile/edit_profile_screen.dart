// Экран «Редактировать профиль»: смена имени, email и цвета аватара.
// Слой: presentation (интерфейс). Открывается из профиля по маршруту
// '/profile/edit'; сохранение выполняет AuthController, палитра цветов
// аватара берётся из data-слоя (avatarPalette).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/validators.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../domain/repositories/repositories.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

/// Редактирование имени, email и цвета аватара.
///
/// ConsumerStatefulWidget — виджет со своим состоянием и доступом
/// к провайдерам Riverpod (библиотека, через которую интерфейс получает
/// контроллеры и данные приложения).
class EditProfileScreen extends ConsumerStatefulWidget {
  /// Создаёт экран редактирования профиля (параметров нет).
  const EditProfileScreen({super.key});

  /// Создаёт объект состояния с полями формы и логикой сохранения.
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

/// Состояние экрана: поля формы, выбранный цвет, ошибка и флаг сохранения.
class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  /// Ключ формы: через него запускается проверка всех полей сразу.
  final _formKey = GlobalKey<FormState>();

  /// Текущий вошедший пользователь (берётся один раз при открытии экрана).
  /// `late` — значение вычисляется при первом обращении.
  late final _user = ref.read(authControllerProvider).user!;

  /// Контроллер поля «Имя», заранее заполнен текущим именем.
  late final _name = TextEditingController(text: _user.name);

  /// Контроллер поля «Email», заранее заполнен текущим email.
  late final _email = TextEditingController(text: _user.email);

  /// Выбранный цвет аватара (число в формате 0xAARRGGBB).
  /// Сначала — текущий цвет пользователя.
  late int _color = _user.avatarColor;

  /// Ошибка от репозитория под полем email (например, email уже занят);
  /// `null` — ошибки нет.
  String? _emailError;

  /// `true`, пока идёт сохранение: кнопка в это время неактивна.
  bool _saving = false;

  /// Освобождает контроллеры полей при закрытии экрана.
  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  /// Проверяет форму и сохраняет имя, email и цвет через AuthController.
  ///
  /// При успехе закрывает экран и показывает «Профиль сохранён»,
  /// при ошибке (AppException) выводит её под полем email.
  Future<void> _save() async {
    // Сбрасываем прошлую ошибку email.
    setState(() => _emailError = null);
    // Запускаем валидаторы полей; если что-то неверно — выходим.
    if (!_formKey.currentState!.validate()) return;
    // Включаем режим сохранения: кнопка станет неактивной.
    setState(() => _saving = true);
    try {
      // Просим контроллер авторизации обновить профиль пользователя.
      await ref
          .read(authControllerProvider.notifier)
          .updateProfile(
            name: _name.text,
            email: _email.text,
            avatarColor: _color,
          );
      // mounted — экран ещё открыт (его могли закрыть за время ожидания).
      if (mounted) {
        // Возвращаемся на экран профиля и показываем сообщение об успехе.
        context.pop();
        showSnack(context, 'Профиль сохранён');
      }
    } on AppException catch (e) {
      // Ошибку из репозитория показываем под полем email.
      if (mounted) setState(() => _emailError = e.message);
    } finally {
      // В любом случае выключаем режим сохранения.
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Строит экран: аватар-превью, выбор цвета, поля имени и email
  /// и кнопку «Сохранить».
  @override
  Widget build(BuildContext context) {
    // Инициалы для превью аватара: первая буква имени заглавной,
    // а если имя пустое — знак вопроса.
    final initials = _name.text.trim().isEmpty
        ? '?'
        : _name.text.trim()[0].toUpperCase();
    // Scaffold — каркас экрана: верхняя панель и основная область.
    return Scaffold(
      appBar: AppBar(title: const Text('Редактировать профиль')),
      // ContentFrame ограничивает ширину содержимого на широких экранах.
      body: ContentFrame(
        // Form объединяет поля, чтобы проверять их вместе по _formKey.
        child: Form(
          key: _formKey,
          // Прокручиваемый список элементов с отступом 16 по краям.
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Превью аватара по центру: инициалы на выбранном цвете.
              // Меняется сразу при вводе имени или выборе цвета.
              Center(
                child: UserAvatar(
                  initials: initials,
                  color: _color,
                  radius: 40,
                ),
              ),
              const SizedBox(height: 16),
              // Ряд цветных кружков для выбора цвета аватара.
              // Wrap переносит кружки на новую строку, если не помещаются.
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                children: [
                  // По одному кружку на каждый цвет из палитры.
                  for (final c in avatarPalette)
                    // Нажатие на кружок выбирает этот цвет.
                    GestureDetector(
                      onTap: () => setState(() => _color = c),
                      // Кружок цвета; у выбранного — белая галочка.
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
              // Поле «Имя». onChanged перерисовывает экран при каждом
              // вводе, чтобы инициалы в превью аватара обновлялись.
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
              // Поле «Email»: клавиатура для email, проверка формата
              // и вывод ошибки от репозитория (_emailError).
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
              // Кнопка «Сохранить»: пока идёт сохранение, неактивна.
              FilledButton(
                key: const Key('edit_save'),
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
