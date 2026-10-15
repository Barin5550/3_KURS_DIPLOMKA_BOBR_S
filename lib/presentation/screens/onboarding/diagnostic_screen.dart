// Слой presentation (интерфейс): второй шаг онбординга — диагностический
// тест. Задаёт по одному вопросу на ключевую тему выбранного направления,
// сохраняет ответы в черновик плана (OnboardingController) и показывает
// итог: какие темы пользователь уже знает и не будет изучать заново.
// Открывается по маршруту '/onboarding/test' после DirectionScreen.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/onboarding_controller.dart';
import '../../widgets/common.dart';
import 'onboarding_steps.dart';

/// Шаг 2 онбординга: диагностический тест.
///
/// По одному вопросу на ключевую тему направления. Вариант «Не знаю»
/// честнее случайного ответа: тема останется в плане.
///
/// ConsumerStatefulWidget — виджет Riverpod (менеджер состояния) со своим
/// изменяемым состоянием: здесь это номер вопроса и флаг «тест пройден».
class DiagnosticScreen extends ConsumerStatefulWidget {
  /// Создаёт экран теста.
  const DiagnosticScreen({super.key});

  /// Создаёт объект состояния, в котором живёт логика экрана.
  @override
  ConsumerState<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

/// Состояние экрана теста: какой вопрос показан и закончен ли тест.
class _DiagnosticScreenState extends ConsumerState<DiagnosticScreen> {
  /// Номер текущего вопроса (с нуля).
  int _index = 0;

  /// `true`, когда пользователь ответил на последний вопрос и нажал
  /// «Завершить» — тогда вместо вопросов показывается результат.
  bool _finished = false;

  /// Строит один из трёх вариантов экрана: заглушку (нет направления),
  /// результат теста или текущий вопрос.
  @override
  Widget build(BuildContext context) {
    // Черновик плана: выбранное направление и уже данные ответы.
    // watch — экран перестроится при любом изменении черновика.
    final draft = ref.watch(onboardingProvider);
    final direction = draft.direction;
    // Направление ещё не выбрано (например, страницу открыли по ссылке) —
    // предлагаем вернуться на первый шаг.
    if (direction == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Диагностика')),
        body: ContentFrame(
          child: Center(
            // Кнопка-ссылка возвращает на экран выбора направления.
            child: TextButton(
              onPressed: () => context.go('/onboarding'),
              child: const Text('Сначала выберите направление'),
            ),
          ),
        ),
      );
    }

    // Темы направления, у которых есть проверочный вопрос.
    final questions = direction.diagnosticTopics;
    final theme = Theme.of(context);

    // Тест пройден или вопросов нет вовсе — показываем экран результата.
    if (_finished || questions.isEmpty) {
      // Темы, которые по ответам считаются известными (вместе с темами,
      // от которых они зависят) — считает OnboardingDraft.knownTopicIds.
      final known = draft.knownTopicIds;
      return Scaffold(
        appBar: AppBar(title: const Text('Результат теста')),
        body: ContentFrame(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Индикатор шагов: второй шаг (номер 1).
              const OnboardingSteps(current: 1),
              const SizedBox(height: 24),
              // Большая иконка: ракета для новичка, кубок, если что-то
              // уже известно.
              Icon(
                known.isEmpty ? Icons.rocket_launch : Icons.emoji_events,
                size: 64,
                color: AppColors.orange,
              ),
              const SizedBox(height: 12),
              // Заголовок результата: сколько тем пользователь знает.
              Text(
                known.isEmpty
                    ? 'Начнём с самых основ'
                    : 'Вы уже знаете ${Fmt.count(known.length, 'тему', 'темы', 'тем')}',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              // Пояснение: либо все темы войдут в план, либо ниже список
              // тем, которые из плана будут исключены.
              Text(
                known.isEmpty
                    ? 'Все ${Fmt.count(direction.topics.length, 'тема', 'темы', 'тем')} войдут в план.'
                    : 'Эти темы и всё, что нужно знать до них, не попадут в план:',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Список известных тем с зелёной галочкой (в порядке,
              // в котором темы идут в направлении).
              for (final t in direction.topics.where(
                (t) => known.contains(t.id),
              ))
                ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                  ),
                  title: Text(t.title),
                ),
              const SizedBox(height: 16),
              // Главная кнопка: переход к третьему шагу — расписанию.
              FilledButton(
                key: const Key('test_continue'),
                onPressed: () => context.push('/onboarding/schedule'),
                child: const Text('Далее: расписание'),
              ),
              // Кнопка «пройти заново»: возвращает к первому вопросу.
              // Уже данные ответы остаются в черновике и будут отмечены.
              TextButton(
                onPressed: () => setState(() {
                  _finished = false;
                  _index = 0;
                }),
                child: const Text('Пройти тест заново'),
              ),
            ],
          ),
        ),
      );
    }

    // Режим вопроса: тема текущего вопроса и сам вопрос.
    // `!` — вопрос точно есть, так как diagnosticTopics содержит только
    // темы с вопросом.
    final topic = questions[_index];
    final question = topic.question!;
    // Ранее выбранный вариант для этой темы (null — ещё не отвечали,
    // -1 — «Не знаю»).
    final selected = draft.answers[topic.id];

    return Scaffold(
      appBar: AppBar(title: const Text('Диагностика')),
      body: ContentFrame(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Индикатор шагов: второй шаг (номер 1).
            const OnboardingSteps(current: 1),
            const SizedBox(height: 16),
            // Полоса прогресса теста: доля пройденных вопросов.
            LinearProgressIndicator(
              value: (_index + 1) / questions.length,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
            // Подпись «Вопрос N из M» и название проверяемой темы.
            Text(
              'Вопрос ${_index + 1} из ${questions.length} · тема «${topic.title}»',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 12),
            // Текст вопроса крупным шрифтом.
            Text(question.text, style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            // RadioGroup объединяет радиокнопки вариантов в одну группу:
            // хранит выбранное значение и сообщает о новом выборе.
            RadioGroup<int>(
              groupValue: selected,
              onChanged: (v) {
                // Сохраняем выбранный вариант в черновик плана.
                if (v != null) {
                  ref.read(onboardingProvider.notifier).answer(topic.id, v);
                }
              },
              child: Column(
                children: [
                  // Варианты ответа из вопроса; значение — номер варианта.
                  for (var i = 0; i < question.options.length; i++)
                    _OptionTile(
                      key: Key('option_$i'),
                      value: i,
                      label: question.options[i],
                      selected: selected == i,
                    ),
                  // Дополнительный вариант «Не знаю» со значением -1:
                  // такой ответ считается неверным, тема останется в плане.
                  _OptionTile(
                    key: const Key('option_unknown'),
                    value: -1,
                    label: 'Не знаю',
                    selected: selected == -1,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Кнопки навигации между вопросами.
            Row(
              children: [
                // «Назад» показывается со второго вопроса.
                if (_index > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _index--),
                      child: const Text('Назад'),
                    ),
                  ),
                // Промежуток между кнопками, только если есть «Назад».
                if (_index > 0) const SizedBox(width: 12),
                // «Далее» / «Завершить»: неактивна, пока не выбран ответ.
                Expanded(
                  child: FilledButton(
                    key: const Key('test_next'),
                    onPressed: selected == null
                        ? null
                        : () => setState(() {
                            // На последнем вопросе завершаем тест,
                            // иначе переходим к следующему вопросу.
                            if (_index == questions.length - 1) {
                              _finished = true;
                            } else {
                              _index++;
                            }
                          }),
                    // Текст кнопки зависит от того, последний ли вопрос.
                    child: Text(
                      _index == questions.length - 1 ? 'Завершить' : 'Далее',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Кнопка для новичков: пропускает тест (все темы попадут
            // в план) и сразу ведёт к расписанию.
            TextButton(
              key: const Key('test_skip'),
              onPressed: () {
                ref.read(onboardingProvider.notifier).skipTest();
                context.push('/onboarding/schedule');
              },
              child: const Text('Я новичок — пропустить тест'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Один вариант ответа: радиокнопка с текстом в рамке со скруглёнными
/// углами. Выбранный вариант подсвечивается оранжевым.
class _OptionTile extends StatelessWidget {
  /// Создаёт строку варианта ответа.
  const _OptionTile({
    super.key,
    required this.value,
    required this.label,
    required this.selected,
  });

  /// Значение варианта: номер варианта или -1 для «Не знаю».
  final int value;

  /// Текст варианта ответа.
  final String label;

  /// Выбран ли этот вариант (для подсветки рамки и фона).
  final bool selected;

  /// Строит рамку с радиокнопкой внутри.
  @override
  Widget build(BuildContext context) {
    // Цветовая схема темы — для цвета рамки невыбранного варианта.
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      // Отступ снизу между вариантами.
      padding: const EdgeInsets.only(bottom: 8),
      // Material задаёт фон и форму, чтобы эффект нажатия не выходил за
      // скруглённые углы.
      child: Material(
        // Выбранный вариант — с полупрозрачным оранжевым фоном.
        color: selected
            ? AppColors.orange.withValues(alpha: .14)
            : Colors.transparent,
        // Скруглённая рамка: оранжевая у выбранного варианта.
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? AppColors.orange : scheme.outlineVariant,
          ),
        ),
        // Обрезаем содержимое по форме рамки.
        clipBehavior: Clip.antiAlias,
        // Строка с радиокнопкой; выбор передаётся в ближайший RadioGroup.
        child: RadioListTile<int>(value: value, title: Text(label)),
      ),
    );
  }
}
