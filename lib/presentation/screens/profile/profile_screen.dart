// Вкладка «Профиль»: карточка пользователя, краткая статистика, переходы
// к редактированию профиля, смене пароля, заметкам и планам, выбор темы
// оформления, ежедневное напоминание, выход и удаление аккаунта.
// Слой: presentation (интерфейс). Открывается по маршруту '/profile'
// из нижней (или боковой) панели навигации главного экрана.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import 'delete_account_dialog.dart';

/// Вкладка «Профиль»: данные пользователя, настройки и выход.
///
/// ConsumerWidget — виджет без своего состояния, который может читать
/// провайдеры Riverpod (Riverpod — библиотека, через которую экраны
/// получают общие данные и контроллеры). Все данные экран берёт
/// из провайдеров и перерисовывается, когда они меняются.
class ProfileScreen extends ConsumerWidget {
  /// Создаёт вкладку профиля (параметров нет).
  const ProfileScreen({super.key});

  /// Строит экран профиля. `ref` — доступ к провайдерам Riverpod.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Текущий пользователь. ref.watch подписывает экран на изменения:
    // после редактирования профиля данные обновятся сами.
    final user = ref.watch(authControllerProvider).user;
    // Пока пользователя нет (например, в момент выхода) — индикатор загрузки.
    if (user == null) return const Scaffold(body: LoadingView());
    // Тема приложения: стили текста и цвета.
    final theme = Theme.of(context);
    // Все планы пользователя; пока данные грузятся — пустой список.
    final plans = ref.watch(plansProvider).value ?? const [];
    // Все завершённые занятия; пока данные грузятся — пустой список.
    final completed = ref.watch(completedSessionsProvider).value ?? const [];
    // Выбранная тема оформления: 'light', 'system' или 'dark'.
    final themeMode = ref.watch(themeModeProvider);
    // Умеет ли платформа ежедневные напоминания (Android и iOS — да).
    final remindersSupported = ref
        .watch(reminderServiceProvider)
        .supportsDailyReminders;
    // Сколько всего минут занимался пользователь: складываем минуты
    // всех завершённых занятий (fold — свёртка списка в одно число).
    final studiedMinutes = completed.fold<int>(0, (s, e) => s + e.minutes);

    // Scaffold — каркас экрана: верхняя панель и основная область.
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      // ContentFrame ограничивает ширину содержимого на широких экранах.
      body: ContentFrame(
        // Прокручиваемый список всех блоков профиля с отступом 16.
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Блок 1. Шапка: аватар слева, справа имя, email и дата
            // регистрации.
            Row(
              children: [
                // Круглый аватар с инициалами на цвете пользователя.
                UserAvatar(
                  initials: user.initials,
                  color: user.avatarColor,
                  radius: 34,
                ),
                const SizedBox(width: 16),
                // Expanded отдаёт тексту всё оставшееся место в строке.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Имя пользователя крупным шрифтом.
                      Text(
                        user.name,
                        key: const Key('profile_name'),
                        style: theme.textTheme.titleLarge,
                      ),
                      // Email пользователя.
                      Text(user.email, style: theme.textTheme.bodyMedium),
                      // Дата регистрации в формате дд.мм.гггг.
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
            // Блок 2. Три карточки-показателя в ряд: число планов,
            // число занятий и сколько часов занимался пользователь.
            Row(
              children: [
                // Сколько планов; Fmt.plural выбирает форму слова
                // («1 план», «2 плана», «5 планов»).
                _Metric(
                  value: '${plans.length}',
                  label: Fmt.plural(plans.length, 'план', 'плана', 'планов'),
                ),
                const SizedBox(width: 8),
                // Сколько занятий завершено.
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
                // Сколько часов: минуты переводим в часы делением на 60.
                _Metric(
                  value: Fmt.hours(studiedMinutes / 60),
                  label: Fmt.hoursWord(studiedMinutes / 60),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Блок 3. Карточка со ссылками на другие экраны,
            // строки разделены тонкими линиями (Divider).
            Card(
              child: Column(
                children: [
                  // Переход к редактированию имени, email и цвета аватара.
                  ListTile(
                    key: const Key('edit_profile'),
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text('Редактировать профиль'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/profile/edit'),
                  ),
                  const Divider(height: 1),
                  // Переход к смене пароля.
                  ListTile(
                    key: const Key('change_password'),
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Сменить пароль'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/profile/password'),
                  ),
                  const Divider(height: 1),
                  // Переход к списку заметок пользователя.
                  ListTile(
                    leading: const Icon(Icons.sticky_note_2_outlined),
                    title: const Text('Мои заметки'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/notes'),
                  ),
                  const Divider(height: 1),
                  // Переход к списку всех планов пользователя.
                  ListTile(
                    leading: const Icon(Icons.folder_copy_outlined),
                    title: const Text('Мои планы'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/plans'),
                  ),
                  const Divider(height: 1),
                  // Сервер API, с которым работает приложение (только
                  // для просмотра; адрес меняется на экране входа).
                  ListTile(
                    key: const Key('profile_server'),
                    leading: const Icon(Icons.dns_outlined),
                    title: const Text('Сервер API'),
                    subtitle: Text(ref.watch(serverUrlProvider)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Блок 4. Карточка настроек: тема оформления и напоминание.
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
                        // Строка-подпись: иконка палитры и «Тема оформления».
                        const Row(
                          children: [
                            Icon(Icons.palette_outlined),
                            SizedBox(width: 16),
                            Expanded(child: Text('Тема оформления')),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Переключатель из трёх сегментов: светлая тема,
                        // как в системе («Авто») и тёмная. Выбран сегмент,
                        // значение которого совпадает с themeMode.
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
                          // При выборе сегмента сохраняем новую тему через
                          // контроллер темы — приложение сразу перекрасится.
                          onSelectionChanged: (s) =>
                              ref.read(themeModeProvider.notifier).set(s.first),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Переключатель «Ежедневное напоминание».
                  // Подпись: если платформа не поддерживает напоминания —
                  // сообщение об этом; иначе время напоминания
                  // или «Выключено».
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
                    // Переключатель включён, только если напоминания
                    // поддерживаются и пользователь их включил.
                    value: remindersSupported && user.reminderEnabled,
                    // На неподдерживаемой платформе onChanged = null,
                    // и переключатель неактивен. Иначе включаем/выключаем
                    // напоминание, сохраняя прежнее время.
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
                  // Строка «Время напоминания» видна, только когда
                  // напоминание включено.
                  if (remindersSupported && user.reminderEnabled)
                    ListTile(
                      // Пустое место вместо иконки — для выравнивания
                      // с переключателем выше.
                      leading: const SizedBox(width: 24),
                      title: const Text('Время напоминания'),
                      // Текущее время напоминания справа, например 09:00.
                      trailing: Text(
                        _time(user.reminderHour, user.reminderMinute),
                        style: theme.textTheme.titleMedium,
                      ),
                      // По нажатию открываем системный выбор времени.
                      onTap: () async {
                        // Окно выбора времени, начальное значение —
                        // текущее время напоминания.
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                            hour: user.reminderHour,
                            minute: user.reminderMinute,
                          ),
                        );
                        // Если время выбрано (не нажали «Отмена»)
                        // и экран ещё открыт — сохраняем новое время.
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
            // Блок 5. Кнопка «Выйти» с красной рамкой и текстом.
            OutlinedButton.icon(
              key: const Key('logout_button'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Выйти'),
              onPressed: () async {
                // Сначала спрашиваем подтверждение в диалоге.
                final ok = await confirm(
                  context,
                  title: 'Выйти из аккаунта?',
                  message: 'Чтобы снова открыть план, нужно будет войти.',
                  confirmLabel: 'Выйти',
                );
                // Если пользователь согласился — выходим из аккаунта.
                // Роутер сам переведёт на экран входа.
                if (ok) {
                  await ref.read(authControllerProvider.notifier).logout();
                }
              },
            ),
            const SizedBox(height: 8),
            // Блок 6. Кнопка «Удалить аккаунт» (красный текст).
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
                // Открываем диалог удаления с вводом пароля;
                // если аккаунт удалён — показываем сообщение.
                if (await showDeleteAccountDialog(context)) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Аккаунт и данные удалены')),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            // Подпись внизу: название и версия приложения.
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

  /// Форматирует время в виде «ЧЧ:ММ», дополняя часы и минуты нулём
  /// слева (например, 9 и 5 превращаются в «09:05»).
  static String _time(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  /// Включает или выключает ежедневное напоминание на время [hour]:[minute]
  /// через AuthController и показывает сообщение о результате.
  ///
  /// Если пользователь не дал разрешение на уведомления, показывает
  /// сообщение об ошибке с просьбой разрешить их в настройках.
  Future<void> _setReminder(
    BuildContext context,
    WidgetRef ref, {
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    // Сохраняем настройку; контроллер вернёт false, если разрешения нет.
    final ok = await ref
        .read(authControllerProvider.notifier)
        .setReminder(enabled: enabled, hour: hour, minute: minute);
    // Если экран уже закрыт, сообщение показывать некуда.
    if (!context.mounted) return;
    if (!ok) {
      // Разрешения на уведомления нет — красное сообщение-подсказка.
      showSnack(
        context,
        'Разрешите уведомления в настройках устройства',
        error: true,
      );
    } else if (enabled) {
      // Напоминание включено — сообщаем, на какое время.
      showSnack(context, 'Напоминание установлено на ${_time(hour, minute)}');
    }
  }
}

/// Карточка-показатель для блока статистики профиля: крупное число
/// сверху и подпись снизу (например, «3» и «плана»).
class _Metric extends StatelessWidget {
  /// Создаёт карточку с числом [value] и подписью [label].
  const _Metric({required this.value, required this.label});

  /// Значение, которое показывается крупно (уже в виде строки).
  final String value;

  /// Подпись под значением.
  final String label;

  /// Строит карточку. Expanded делит ширину ряда поровну
  /// между тремя карточками.
  @override
  Widget build(BuildContext context) => Expanded(
    child: Card(
      // Отступ сверху и снизу внутри карточки.
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            // Значение крупным жирным шрифтом.
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            // Подпись мелким шрифтом.
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
  /// Создаёт подпись сегмента с текстом [text].
  const _SegmentLabel(this.text);

  /// Текст подписи («Светлая», «Авто», «Тёмная»).
  final String text;

  /// Строит подпись: FittedBox с BoxFit.scaleDown уменьшает текст,
  /// если он не помещается, а maxLines: 1 запрещает перенос строки.
  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(text, maxLines: 1, softWrap: false),
  );
}
