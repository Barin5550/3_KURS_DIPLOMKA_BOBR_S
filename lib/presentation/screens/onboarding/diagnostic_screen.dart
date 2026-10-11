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
class DiagnosticScreen extends ConsumerStatefulWidget {
  const DiagnosticScreen({super.key});

  @override
  ConsumerState<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends ConsumerState<DiagnosticScreen> {
  int _index = 0;
  bool _finished = false;

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingProvider);
    final direction = draft.direction;
    if (direction == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Диагностика')),
        body: ContentFrame(
          child: Center(
            child: TextButton(
              onPressed: () => context.go('/onboarding'),
              child: const Text('Сначала выберите направление'),
            ),
          ),
        ),
      );
    }

    final questions = direction.diagnosticTopics;
    final theme = Theme.of(context);

    if (_finished || questions.isEmpty) {
      final known = draft.knownTopicIds;
      return Scaffold(
        appBar: AppBar(title: const Text('Результат теста')),
        body: ContentFrame(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const OnboardingSteps(current: 1),
              const SizedBox(height: 24),
              Icon(
                known.isEmpty ? Icons.rocket_launch : Icons.emoji_events,
                size: 64,
                color: AppColors.orange,
              ),
              const SizedBox(height: 12),
              Text(
                known.isEmpty
                    ? 'Начнём с самых основ'
                    : 'Вы уже знаете ${Fmt.count(known.length, 'тему', 'темы', 'тем')}',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                known.isEmpty
                    ? 'Все ${Fmt.count(direction.topics.length, 'тема', 'темы', 'тем')} войдут в план.'
                    : 'Эти темы и всё, что нужно знать до них, не попадут в план:',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
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
              FilledButton(
                key: const Key('test_continue'),
                onPressed: () => context.push('/onboarding/schedule'),
                child: const Text('Далее: расписание'),
              ),
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

    final topic = questions[_index];
    final question = topic.question!;
    final selected = draft.answers[topic.id];

    return Scaffold(
      appBar: AppBar(title: const Text('Диагностика')),
      body: ContentFrame(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const OnboardingSteps(current: 1),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: (_index + 1) / questions.length,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
            Text(
              'Вопрос ${_index + 1} из ${questions.length} · тема «${topic.title}»',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 12),
            Text(question.text, style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            RadioGroup<int>(
              groupValue: selected,
              onChanged: (v) {
                if (v != null) {
                  ref.read(onboardingProvider.notifier).answer(topic.id, v);
                }
              },
              child: Column(
                children: [
                  for (var i = 0; i < question.options.length; i++)
                    _OptionTile(
                      key: Key('option_$i'),
                      value: i,
                      label: question.options[i],
                      selected: selected == i,
                    ),
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
            Row(
              children: [
                if (_index > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _index--),
                      child: const Text('Назад'),
                    ),
                  ),
                if (_index > 0) const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const Key('test_next'),
                    onPressed: selected == null
                        ? null
                        : () => setState(() {
                            if (_index == questions.length - 1) {
                              _finished = true;
                            } else {
                              _index++;
                            }
                          }),
                    child: Text(
                      _index == questions.length - 1 ? 'Завершить' : 'Далее',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
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

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    super.key,
    required this.value,
    required this.label,
    required this.selected,
  });

  final int value;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? AppColors.orange.withValues(alpha: .14)
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? AppColors.orange : scheme.outlineVariant,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: RadioListTile<int>(value: value, title: Text(label)),
      ),
    );
  }
}
