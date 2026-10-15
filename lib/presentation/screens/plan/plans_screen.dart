// Слой presentation (интерфейс): экран «Мои планы» (маршрут '/plans',
// открывается кнопкой на вкладке «План»). Показывает все планы
// пользователя карточками с прогрессом; через меню карточки план можно
// сделать активным, переименовать, перестроить с сегодняшнего дня или
// удалить. Кнопка «Новый план» запускает онбординг.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/plan.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

/// «Мои планы»: несколько планов, выбор активного, переименование, удаление.
///
/// ConsumerWidget — виджет Riverpod (менеджер состояния), который через
/// `ref` читает провайдеры — общие источники данных приложения.
class PlansScreen extends ConsumerWidget {
  /// Создаёт экран «Мои планы».
  const PlansScreen({super.key});

  /// Строит экран: список карточек планов и плавающую кнопку «Новый план».
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Поток всех планов пользователя: список обновляется сам при
    // изменениях в базе (создание, удаление, переименование).
    final plansAsync = ref.watch(plansProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Мои планы')),
      // Плавающая кнопка справа внизу: создание нового плана через
      // онбординг.
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('new_plan'),
        icon: const Icon(Icons.add),
        label: const Text('Новый план'),
        onPressed: () => context.push('/onboarding'),
      ),
      body: ContentFrame(
        child: plansAsync.when(
          // Планы загружаются — индикатор.
          loading: () => const LoadingView(),
          // Ошибка загрузки — сообщение.
          error: (e, _) => ErrorView(error: e),
          // Планов нет — пустое состояние; есть — список карточек.
          data: (plans) => plans.isEmpty
              ? const EmptyState(
                  icon: Icons.folder_open,
                  title: 'Планов пока нет',
                  message: 'Нажмите «Новый план», чтобы создать первый.',
                )
              : ListView(
                  // Большой отступ снизу (96), чтобы последнюю карточку
                  // не закрывала плавающая кнопка.
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  children: [
                    // По карточке на каждый план.
                    for (final p in plans)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _PlanCard(plan: p),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Пункты меню карточки плана: сделать активным, переименовать,
/// перестроить, удалить.
enum _PlanAction { activate, rename, replan, delete }

/// Карточка одного плана: название, расписание, прогресс и меню действий.
class _PlanCard extends ConsumerWidget {
  /// Создаёт карточку для плана [plan].
  const _PlanCard({required this.plan});

  /// План, который показывает карточка.
  final StudyPlan plan;

  /// Строит карточку. Активный план обведён оранжевой рамкой;
  /// нажатие на неактивный план делает его активным.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Прогресс плана (выполненные занятия, доля); null, пока считается.
    final progress = ref.watch(planProgressProvider(plan.id)).value;
    return Card(
      // У активного плана — оранжевая рамка толщиной 2, у остальных —
      // обычная форма карточки.
      shape: plan.isActive
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.orange, width: 2),
            )
          : null,
      // InkWell делает карточку нажимаемой. У активного плана нажатие
      // отключено (null) — он и так активный.
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        // Ошибку запроса (например, нет связи) покажет runAction.
        onTap: plan.isActive
            ? null
            : () => runAction(context, () => _activate(context, ref)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Верхняя строка: название, отметка «активный» и меню.
              Row(
                children: [
                  // Название плана занимает всё свободное место.
                  Expanded(
                    child: Text(plan.title, style: theme.textTheme.titleMedium),
                  ),
                  // Чип «активный» только у активного плана.
                  if (plan.isActive)
                    const Chip(
                      label: Text('активный'),
                      visualDensity: VisualDensity.compact,
                    ),
                  // Меню «три точки» с действиями над планом; выбор
                  // пункта обрабатывает метод _onAction.
                  PopupMenuButton<_PlanAction>(
                    key: Key('plan_menu_${plan.id}'),
                    onSelected: (a) => _onAction(context, ref, a),
                    itemBuilder: (_) => [
                      // «Сделать активным» — только для неактивного плана.
                      if (!plan.isActive)
                        const PopupMenuItem(
                          value: _PlanAction.activate,
                          child: Text('Сделать активным'),
                        ),
                      const PopupMenuItem(
                        value: _PlanAction.rename,
                        child: Text('Переименовать'),
                      ),
                      const PopupMenuItem(
                        value: _PlanAction.replan,
                        child: Text('Перестроить с сегодняшнего дня'),
                      ),
                      const PopupMenuItem(
                        value: _PlanAction.delete,
                        child: Text('Удалить'),
                      ),
                    ],
                  ),
                ],
              ),
              // Строка расписания: часы в неделю, учебные дни по порядку
              // («Пн, Ср, Пт») и дедлайн, если он задан.
              Text(
                '${Fmt.hours(plan.settings.hoursPerWeek)} ч/нед · '
                '${(plan.settings.studyDays.toList()..sort()).map((d) => weekdayShort[d - 1]).join(', ')}'
                '${plan.settings.deadline == null ? '' : ' · до ${Fmt.short(plan.settings.deadline!)}'}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              // Полоса прогресса плана (0, пока прогресс не посчитан).
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: LinearProgressIndicator(
                  value: progress?.ratio ?? 0,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 4),
              // Подпись прогресса: процент и «N из M занятий».
              Text(
                progress == null
                    ? ''
                    : '${(progress.ratio * 100).round()}% · '
                          '${progress.doneSessions} из ${progress.totalSessions} ${Fmt.plural(progress.totalSessions, 'занятия', 'занятий', 'занятий')}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Делает этот план активным и сообщает об этом пользователю.
  Future<void> _activate(BuildContext context, WidgetRef ref) async {
    // Отмечаем план активным в базе (у пользователя один активный план).
    await ref.read(planRepositoryProvider).setActive(plan.userId, plan.id);
    // Сообщение показываем, только если экран ещё открыт.
    if (context.mounted) showSnack(context, '«${plan.title}» теперь активный');
  }

  /// Выполняет пункт меню [action], выбранный в меню карточки.
  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    _PlanAction action,
  ) async {
    // Репозиторий планов — слой доступа к базе данных.
    final repo = ref.read(planRepositoryProvider);
    try {
      switch (action) {
        // «Сделать активным».
        case _PlanAction.activate:
          await _activate(context, ref);
        // «Переименовать»: спрашиваем новое название в диалоге и, если
        // пользователь не нажал «Отмена», сохраняем его.
        case _PlanAction.rename:
          final title = await _askTitle(context, plan.title);
          if (title != null) await repo.renamePlan(plan.id, title);
        // «Перестроить»: PlanService заново раскладывает невыполненные
        // занятия начиная с сегодняшнего дня.
        case _PlanAction.replan:
          final result = await ref.read(planServiceProvider).replan(plan);
          // Сообщение с новой датой окончания (если она есть).
          if (context.mounted) {
            showSnack(
              context,
              result.finishDate == null
                  ? 'План перестроен'
                  : 'План перестроен, окончание ${Fmt.short(result.finishDate!)}',
            );
          }
        // «Удалить»: сначала просим подтверждение, потом удаляем план
        // вместе со всеми занятиями.
        case _PlanAction.delete:
          final ok = await confirm(
            context,
            title: 'Удалить план?',
            message:
                '«${plan.title}» и все его занятия будут удалены без возможности восстановления.',
          );
          if (ok) {
            await repo.deletePlan(plan.id);
            if (context.mounted) showSnack(context, 'План удалён');
          }
      }
    } on Object catch (e) {
      // Любая ошибка любого действия — красное сообщение с текстом ошибки.
      if (context.mounted) showSnack(context, 'Ошибка: $e', error: true);
    }
  }

  /// Открывает диалог переименования с текущим названием [initial].
  /// Возвращает новое название или `null`, если диалог закрыли без
  /// сохранения.
  Future<String?> _askTitle(BuildContext context, String initial) =>
      showDialog<String>(
        context: context,
        builder: (_) => _RenameDialog(initial: initial),
      );
}

/// Диалог переименования плана. Контроллер поля живёт вместе с диалогом
/// и освобождается в [State.dispose], уже после анимации закрытия.
class _RenameDialog extends StatefulWidget {
  /// Создаёт диалог; [initial] — текущее название плана.
  const _RenameDialog({required this.initial});

  /// Название, которое изначально стоит в поле ввода.
  final String initial;

  /// Создаёт объект состояния диалога.
  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

/// Состояние диалога переименования: поле ввода и его проверка.
class _RenameDialogState extends State<_RenameDialog> {
  /// Контроллер поля ввода, заполненный текущим названием. `late` —
  /// создаётся при первом обращении, когда `widget` уже доступен.
  late final _controller = TextEditingController(text: widget.initial);

  /// Ключ формы — через него запускается проверка поля (validate).
  final _formKey = GlobalKey<FormState>();

  /// Освобождает контроллер поля, когда диалог убран с экрана.
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Строит диалог: поле названия и кнопки «Отмена» / «Сохранить».
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Название плана'),
    // Форма с одним полем ввода названия.
    content: Form(
      key: _formKey,
      // Поле названия: сразу получает фокус (открывается клавиатура);
      // Validators.title не пропускает пустое название и длиннее
      // 80 символов.
      child: TextFormField(
        key: const Key('rename_field'),
        controller: _controller,
        autofocus: true,
        validator: Validators.title,
      ),
    ),
    actions: [
      // «Отмена» закрывает диалог без результата (вернётся null).
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Отмена'),
      ),
      // «Сохранить»: если поле прошло проверку, закрываем диалог
      // и возвращаем название без пробелов по краям.
      TextButton(
        key: const Key('rename_save'),
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            Navigator.of(context).pop(_controller.text.trim());
          }
        },
        child: const Text('Сохранить'),
      ),
    ],
  );
}
