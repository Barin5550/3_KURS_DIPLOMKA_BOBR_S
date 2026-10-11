import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import 'delete_account_dialog.dart';

/// Вкладка «Профиль»: данные пользователя, настройки и выход.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    if (user == null) return const Scaffold(body: LoadingView());
    final theme = Theme.of(context);
    final plans = ref.watch(plansProvider).value ?? const [];
    final completed = ref.watch(completedSessionsProvider).value ?? const [];
    final themeMode = ref.watch(themeModeProvider);
    final remindersSupported = ref
        .watch(reminderServiceProvider)
        .supportsDailyReminders;
    final studiedMinutes = completed.fold<int>(0, (s, e) => s + e.minutes);

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: ContentFrame(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                UserAvatar(
                  initials: user.initials,
                  color: user.avatarColor,
                  radius: 34,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        key: const Key('profile_name'),
                        style: theme.textTheme.titleLarge,
                      ),
                      Text(user.email, style: theme.textTheme.bodyMedium),
                      Text(
                        'С нами с ${Fmt.short(user.createdAt)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _Metric(
                  value: '${plans.length}',
                  label: Fmt.plural(plans.length, 'план', 'плана', 'планов'),
                ),
                const SizedBox(width: 8),
                _Metric(
                  value: '${completed.length}',
                  label: Fmt.plural(
                    completed.length,
                    'занятие',
                    'занятия',
                    'занятий',
                  ),
                ),
                const SizedBox(width: 8),
                _Metric(
                  value: Fmt.hours(studiedMinutes / 60),
                  label: Fmt.hoursWord(studiedMinutes / 60),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    key: const Key('edit_profile'),
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text('Редактировать профиль'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/profile/edit'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    key: const Key('change_password'),
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Сменить пароль'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/profile/password'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.sticky_note_2_outlined),
                    title: const Text('Мои заметки'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/notes'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.folder_copy_outlined),
                    title: const Text('Мои планы'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/plans'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  // Подпись над переключателем: в одну строку с ним
                  // на узком экране текст переносился посреди слова.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.palette_outlined),
                            SizedBox(width: 16),
                            Expanded(child: Text('Тема оформления')),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SegmentedButton<String>(
                          showSelectedIcon: false,
                          style: SegmentedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          segments: const [
                            ButtonSegment(
                              value: 'light',
                              label: _SegmentLabel('Светлая'),
                            ),
                            ButtonSegment(
                              value: 'system',
                              label: _SegmentLabel('Авто'),
                              tooltip: 'Как в системе',
                            ),
                            ButtonSegment(
                              value: 'dark',
                              label: _SegmentLabel('Тёмная'),
                            ),
                          ],
                          selected: {themeMode},
                          onSelectionChanged: (s) =>
                              ref.read(themeModeProvider.notifier).set(s.first),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    key: const Key('reminder_switch'),
                    secondary: const Icon(Icons.notifications_outlined),
                    title: const Text('Ежедневное напоминание'),
                    subtitle: Text(
                      !remindersSupported
                          ? 'Доступно в версии для Android и iOS'
                          : user.reminderEnabled
                          ? 'Каждый день в ${_time(user.reminderHour, user.reminderMinute)}'
                          : 'Выключено',
                    ),
                    value: remindersSupported && user.reminderEnabled,
                    onChanged: remindersSupported
                        ? (on) => _setReminder(
                            context,
                            ref,
                            enabled: on,
                            hour: user.reminderHour,
                            minute: user.reminderMinute,
                          )
                        : null,
                  ),
                  if (remindersSupported && user.reminderEnabled)
                    ListTile(
                      leading: const SizedBox(width: 24),
                      title: const Text('Время напоминания'),
                      trailing: Text(
                        _time(user.reminderHour, user.reminderMinute),
                        style: theme.textTheme.titleMedium,
                      ),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                            hour: user.reminderHour,
                            minute: user.reminderMinute,
                          ),
                        );
                        if (time != null && context.mounted) {
                          await _setReminder(
                            context,
                            ref,
                            enabled: true,
                            hour: time.hour,
                            minute: time.minute,
                          );
                        }
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              key: const Key('logout_button'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Выйти'),
              onPressed: () async {
                final ok = await confirm(
                  context,
                  title: 'Выйти из аккаунта?',
                  message: 'Чтобы снова открыть план, нужно будет войти.',
                  confirmLabel: 'Выйти',
                );
                if (ok) {
                  await ref.read(authControllerProvider.notifier).logout();
                }
              },
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              key: const Key('delete_account_button'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              icon: const Icon(Icons.delete_forever_outlined),
              label: const Text('Удалить аккаунт'),
              onPressed: () async {
                // Мессенджер общий для приложения: сообщение будет видно и
                // после перехода на экран входа.
                final messenger = ScaffoldMessenger.of(context);
                if (await showDeleteAccountDialog(context)) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Аккаунт и данные удалены')),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Маршрут 1.0 · курсовой проект ПМ07',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _time(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  Future<void> _setReminder(
    BuildContext context,
    WidgetRef ref, {
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    final ok = await ref
        .read(authControllerProvider.notifier)
        .setReminder(enabled: enabled, hour: hour, minute: minute);
    if (!context.mounted) return;
    if (!ok) {
      showSnack(
        context,
        'Разрешите уведомления в настройках устройства',
        error: true,
      );
    } else if (enabled) {
      showSnack(context, 'Напоминание установлено на ${_time(hour, minute)}');
    }
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ),
  );
}

/// Подпись сегмента в одну строку: на узком экране или с крупным
/// системным шрифтом текст уменьшается, а не переносится по буквам.
class _SegmentLabel extends StatelessWidget {
  const _SegmentLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(text, maxLines: 1, softWrap: false),
  );
}
