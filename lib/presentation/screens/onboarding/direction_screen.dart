import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../providers/onboarding_controller.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import 'onboarding_steps.dart';

/// Шаг 1 онбординга: выбор направления обучения.
class DirectionScreen extends ConsumerWidget {
  const DirectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final directions = ref.watch(directionsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Новый план'),
        leading: context.canPop()
            ? null
            : IconButton(
                tooltip: 'Закрыть',
                icon: const Icon(Icons.close),
                onPressed: () => context.go('/home'),
              ),
      ),
      body: directions.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(directionsProvider),
        ),
        data: (list) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const OnboardingSteps(current: 0),
            const SizedBox(height: 16),
            Text(
              'Что вы хотите изучить?',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Приложение построит маршрут по темам с учётом их зависимостей',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            for (final d in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: InkWell(
                    key: Key('direction_${d.id}'),
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      ref.read(onboardingProvider.notifier).selectDirection(d);
                      context.push('/onboarding/test');
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Color(d.colorValue),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              directionIcon(d.icon),
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  d.description,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${Fmt.count(d.topics.length, 'тема', 'темы', 'тем')}'
                                  ' · ≈ ${Fmt.hours(d.totalMinutes / 60)} ч',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
