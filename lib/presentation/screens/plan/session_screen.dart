// Слой presentation (интерфейс): карточка одного занятия (маршрут
// '/session/:id', открывается из списка занятий). Показывает тему, дату,
// длительность, подсказку для повторения, описание темы с материалами
// и заметками (TopicDetails), кнопки «Отметить выполненным» и «Pomodoro».
// Здесь же объявлен topicByIdProvider, который использует и TopicScreen.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/session.dart';
import '../../../domain/entities/topic.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import '../topics/topic_details.dart';

/// Провайдер (источник данных Riverpod) одного занятия по его id.
///
/// `family` — провайдер с параметром (id занятия), `autoDispose` — он
/// освобождается, когда экран закрыт. Отдаёт поток (Stream): новое
/// значение приходит каждый раз, когда занятия плана меняются в базе.
/// `null` — занятие не найдено.
final _sessionProvider = StreamProvider.autoDispose.family<StudySession?, int>((
  ref,
  id,
) async* {
  // Подписываемся на занятия плана, чтобы экран обновлялся при отметке.
  final repo = ref.watch(planRepositoryProvider);
  // Сначала один раз читаем занятие, чтобы узнать, к какому плану оно
  // относится.
  final first = await repo.sessionById(id);
  // Такого занятия нет — отдаём null и завершаем поток.
  if (first == null) {
    yield null;
    return;
  }
  // yield* пересылает все значения другого потока: следим за списком
  // занятий плана и выбираем из него нужное (null, если оно исчезло,
  // например после перестройки плана).
  yield* repo
      .watchSessions(first.planId)
      .map((list) => list.where((s) => s.id == id).firstOrNull);
});

/// Карточка занятия: описание темы, материалы, заметки, Pomodoro.
///
/// ConsumerWidget — виджет Riverpod, который через `ref` читает провайдеры.
class SessionScreen extends ConsumerWidget {
  /// Создаёт экран для занятия с идентификатором [sessionId].
  const SessionScreen({super.key, required this.sessionId});

  /// Идентификатор занятия в базе (берётся из адреса '/session/:id').
  final int sessionId;

  /// Строит экран: загрузка, ошибка, «не найдено» или содержимое.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Подписываемся на занятие; экран обновится при его изменении.
    final sessionAsync = ref.watch(_sessionProvider(sessionId));
    return Scaffold(
      appBar: AppBar(title: const Text('Занятие')),
      body: ContentFrame(
        child: sessionAsync.when(
          // Данные ещё грузятся — индикатор.
          loading: () => const LoadingView(),
          // Ошибка загрузки — сообщение.
          error: (e, _) => ErrorView(error: e),
          data: (session) {
            // Занятия нет — объясняем возможную причину.
            if (session == null) {
              return const EmptyState(
                icon: Icons.event_busy,
                title: 'Занятие не найдено',
                message: 'Возможно, план был перестроен или удалён.',
              );
            }
            // Занятие есть — показываем его содержимое.
            return _SessionBody(session: session);
          },
        ),
      ),
    );
  }
}

/// Содержимое карточки занятия: чипы, заголовок, дата, описание темы
/// и кнопки действий.
class _SessionBody extends ConsumerWidget {
  /// Создаёт содержимое для занятия [session].
  const _SessionBody({required this.session});

  /// Занятие, которое показывается на экране.
  final StudySession session;

  /// Строит прокручиваемый список с информацией о занятии.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Сегодняшняя дата — чтобы подсветить пропущенное занятие.
    final today = ref.watch(todayProvider);
    // Полные данные темы (описание, материалы); null, пока не загружены.
    final topic = ref.watch(topicByIdProvider(session.topicId)).value;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Чипы: категория темы и тип занятия (изучение / повторение).
        Wrap(
          spacing: 8,
          children: [
            Chip(label: Text(session.category)),
            // Иконка зависит от типа: стрелка-повтор или шапочка.
            Chip(
              avatar: Icon(
                session.kind == SessionKind.review
                    ? Icons.replay
                    : Icons.school,
                size: 18,
              ),
              label: Text(session.kind.label),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Название темы занятия.
        Text(session.topicTitle, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        // Дата, длительность и, если тема разбита на несколько дней,
        // номер части. Пропущенное занятие подсвечивается красным.
        Text(
          '${Fmt.dayWithWeekday(session.date)} · ${Fmt.minutes(session.minutes)}'
          '${session.totalParts > 1 ? ' · часть ${session.part} из ${session.totalParts}' : ''}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: session.isMissed(today) ? theme.colorScheme.error : null,
          ),
        ),
        // Для занятия-повторения — карточка с советом, как повторять.
        if (session.kind == SessionKind.review) ...[
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.lightbulb_outline, color: AppColors.orange),
              title: Text('Как повторять'),
              subtitle: Text(
                'Вспомните главное без подсказок, затем сверьтесь с заметками '
                'и материалами. Повторение через 1, 3 и 7 дней помогает '
                'перевести знания в долговременную память.',
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        // Описание темы, материалы и заметки (общий виджет TopicDetails);
        // пока тема не загрузилась — пустое место.
        if (topic != null) TopicDetails(topic: topic) else const SizedBox(),
        const SizedBox(height: 16),
        // Кнопка отметки: ставит или снимает «выполнено».
        FilledButton.icon(
          key: const Key('session_toggle'),
          icon: Icon(session.isDone ? Icons.undo : Icons.check),
          label: Text(
            session.isDone ? 'Отменить отметку' : 'Отметить выполненным',
          ),
          onPressed: () async {
            // Переключаем отметку на сервере через PlanService; при ошибке
            // runAction покажет причину.
            final ok = await runAction(
              context,
              () => ref.read(planServiceProvider).toggleSession(session),
            );
            // Похвала, только если занятие было невыполненным (значит,
            // его только что отметили) и экран ещё открыт.
            if (ok && context.mounted && !session.isDone) {
              showSnack(context, 'Отлично! Занятие выполнено');
            }
          },
        ),
        const SizedBox(height: 8),
        // Кнопка запуска таймера Pomodoro (чередование отрезков работы
        // и коротких перерывов); название темы передаётся в адресе
        // как параметр topic.
        OutlinedButton.icon(
          icon: const Icon(Icons.timer_outlined),
          label: const Text('Pomodoro по этой теме'),
          onPressed: () => context.push(
            Uri(
              path: '/pomodoro',
              queryParameters: {'topic': session.topicTitle},
            ).toString(),
          ),
        ),
      ],
    );
  }
}

/// Тема по идентификатору: ищем в каталоге, затем среди своих тем.
///
/// FutureProvider — провайдер с одноразовой асинхронной загрузкой;
/// `family` — с параметром (id темы). Используется также в TopicScreen.
final topicByIdProvider = FutureProvider.autoDispose.family<Topic?, String>((
  ref,
  topicId,
) async {
  // Ждём загрузки всех направлений каталога.
  final directions = await ref.watch(directionsProvider.future);
  // Ищем тему по очереди в каждом направлении.
  for (final d in directions) {
    final t = d.topicById(topicId);
    if (t != null) return t;
  }
  // В каталоге нет — ищем среди тем, созданных пользователем (или null).
  return ref.watch(topicRepositoryProvider).customTopicById(topicId);
});
