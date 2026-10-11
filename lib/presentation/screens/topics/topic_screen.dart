// Экран одной темы (маршрут /topic/:id): название, категория и подробности
// темы (виджет TopicDetails). Для собственной темы пользователя здесь же
// кнопки «Изменить», «Удалить» и «Добавить в активный план».
// Слой: presentation (интерфейс). Открывается из списка тем
// (topics_screen.dart) через роутер core/router/app_router.dart.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/topic.dart';
import '../../../domain/repositories/repositories.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import '../plan/session_screen.dart';
import 'topic_details.dart';

/// Экран темы: описание, материалы, заметки; для своей темы — изменение,
/// удаление и добавление в активный план.
///
/// ConsumerWidget — виджет без своего состояния, читающий провайдеры
/// Riverpod (провайдер — «источник» данных, например тема по её id).
class TopicScreen extends ConsumerWidget {
  /// Создаёт экран темы с идентификатором [topicId] из адреса /topic/:id.
  const TopicScreen({super.key, required this.topicId});

  /// Идентификатор темы: из каталога или собственной (с особым префиксом).
  final String topicId;

  /// Загружает тему и строит экран по состоянию загрузки.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Тема по id: провайдер topicByIdProvider объявлен в session_screen.dart,
    // ищет тему сначала в каталоге, потом среди своих тем пользователя.
    final topicAsync = ref.watch(topicByIdProvider(topicId));
    return topicAsync.when(
      // Загрузка — пустой экран с индикатором.
      loading: () => const Scaffold(body: LoadingView()),
      // Ошибка — экран с кнопкой «назад» и текстом ошибки.
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(error: e),
      ),
      data: (topic) {
        // Тема не нашлась (например, её удалили) — пустое состояние
        // с текстом «Тема не найдена».
        if (topic == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const ContentFrame(
              child: EmptyState(
                icon: Icons.help_outline,
                title: 'Тема не найдена',
              ),
            ),
          );
        }
        // Тема найдена — основной экран.
        return Scaffold(
          // Верхняя панель: «Моя тема» для своей темы, иначе «Тема».
          appBar: AppBar(
            title: Text(topic.isCustom ? 'Моя тема' : 'Тема'),
            actions: [
              // Кнопки изменения и удаления есть только у своей темы:
              // темы каталога менять нельзя.
              if (topic.isCustom) ...[
                // Карандаш: открывает форму изменения темы. После возврата
                // провайдер сбрасывается (invalidate), чтобы тема
                // загрузилась заново уже с изменениями.
                IconButton(
                  key: const Key('edit_custom_topic'),
                  tooltip: 'Изменить',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () async {
                    await context.push('/topics/custom/${topic.id}');
                    ref.invalidate(topicByIdProvider(topicId));
                  },
                ),
                // Корзина: удаление темы с подтверждением (метод _delete).
                IconButton(
                  key: const Key('delete_custom_topic'),
                  tooltip: 'Удалить',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(context, ref, topic),
                ),
              ],
            ],
          ),
          // Тело экрана — прокручиваемый список с отступами 16.
          body: ContentFrame(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Название темы крупным шрифтом.
                Text(
                  topic.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                // Плашка (Chip) с категорией темы.
                Wrap(spacing: 8, children: [Chip(label: Text(topic.category))]),
                const SizedBox(height: 8),
                // Описание, материалы, заметки и звёздочка избранного.
                TopicDetails(topic: topic),
                const SizedBox(height: 16),
                // Для своей темы — кнопка добавления в активный план.
                if (topic.isCustom) _AddToPlanButton(topic: topic),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Удаляет свою тему после подтверждения и закрывает экран.
  Future<void> _delete(BuildContext context, WidgetRef ref, Topic topic) async {
    // Диалог «Удалить тему?»: ok = true, если пользователь согласился.
    final ok = await confirm(
      context,
      title: 'Удалить тему?',
      message:
          '«${topic.title}» будет удалена из списка тем. '
          'Занятия, уже добавленные в план, сохранятся.',
    );
    // Отказался или экран уже закрыт — ничего не делаем.
    if (!ok || !context.mounted) return;
    try {
      // Удаляем тему из базы через репозиторий тем.
      await ref.read(topicRepositoryProvider).deleteCustomTopic(topic.id);
      // Закрываем экран темы и показываем сообщение об успехе.
      if (context.mounted) {
        context.pop();
        showSnack(context, 'Тема удалена');
      }
    } on Object catch (e) {
      // Любая ошибка — красное сообщение с её текстом.
      if (context.mounted) showSnack(context, 'Ошибка: $e', error: true);
    }
  }
}

/// Кнопка «Добавить в активный план» для своей темы.
///
/// Показывается, только если у пользователя есть активный план.
class _AddToPlanButton extends ConsumerWidget {
  /// Создаёт кнопку для темы [topic].
  const _AddToPlanButton({required this.topic});

  /// Своя тема, которую добавляем в план.
  final Topic topic;

  /// Строит кнопку или пустое место, если активного плана нет.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Активный план пользователя (null — плана нет или он ещё грузится).
    final plan = ref.watch(activePlanProvider).value;
    // Нет плана — кнопку не показываем.
    if (plan == null) return const SizedBox();
    // Залитая кнопка с иконкой «добавить в список».
    return FilledButton.icon(
      key: const Key('add_topic_to_plan'),
      icon: const Icon(Icons.playlist_add),
      label: const Text('Добавить в активный план'),
      onPressed: () async {
        // Узнаём, к какому направлению относится своя тема.
        final direction = await ref
            .read(topicRepositoryProvider)
            .directionOf(topic.id);
        // Экран могли закрыть, пока ждали ответа базы.
        if (!context.mounted) return;
        // Тему другого направления в этот план добавить нельзя.
        if (direction != plan.directionId) {
          showSnack(
            context,
            'Тема относится к другому направлению, чем активный план',
            error: true,
          );
          return;
        }
        try {
          // Сервис планов добавляет тему, заново упорядочивает темы
          // с учётом зависимостей и перестраивает расписание.
          await ref.read(planServiceProvider).addTopic(plan, topic);
          if (context.mounted) {
            showSnack(context, 'Тема добавлена, план перестроен');
          }
        } on AppException catch (e) {
          // Понятная ошибка от сервиса, например «Эта тема уже есть в плане».
          if (context.mounted) showSnack(context, e.message, error: true);
        }
      },
    );
  }
}
