// Слой presentation (интерфейс): первый шаг онбординга — мастера создания
// нового плана. Экран показывает список направлений обучения из каталога;
// по нажатию направление запоминается в черновике плана и открывается
// диагностический тест. Открывается по маршруту '/onboarding' (app_router).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../providers/onboarding_controller.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import 'onboarding_steps.dart';

/// Шаг 1 онбординга: выбор направления обучения.
///
/// ConsumerWidget — виджет из библиотеки Riverpod (менеджер состояния),
/// который через `ref` может читать провайдеры — общие источники данных.
class DirectionScreen extends ConsumerWidget {
  /// Создаёт экран выбора направления.
  const DirectionScreen({super.key});

  /// Строит экран: шапку, индикатор шагов и карточки направлений.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Подписываемся на список направлений: он грузится асинхронно,
    // поэтому приходит как AsyncValue (загрузка / ошибка / данные).
    final directions = ref.watch(directionsProvider);
    return Scaffold(
      // Верхняя панель с заголовком экрана.
      appBar: AppBar(
        title: const Text('Новый план'),
        // Если вернуться назад некуда (экран открыт первым), показываем
        // крестик, который уводит на главную; иначе — обычную стрелку.
        leading: context.canPop()
            ? null
            : IconButton(
                tooltip: 'Закрыть',
                icon: const Icon(Icons.close),
                onPressed: () => context.go('/home'),
              ),
      ),
      // ContentFrame ограничивает ширину содержимого на широких экранах.
      body: ContentFrame(
        // when выбирает, что показать в зависимости от состояния загрузки.
        child: directions.when(
          // Пока каталог загружается — индикатор загрузки.
          loading: () => const LoadingView(),
          // При ошибке — сообщение и кнопка «Повторить», которая
          // сбрасывает провайдер и запускает загрузку заново.
          error: (e, _) => ErrorView(
            error: e,
            onRetry: () => ref.invalidate(directionsProvider),
          ),
          // Данные готовы — показываем прокручиваемый список.
          data: (list) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Индикатор шагов: сейчас первый шаг (номер 0).
              const OnboardingSteps(current: 0),
              const SizedBox(height: 16),
              // Заголовок-вопрос экрана.
              Text(
                'Что вы хотите изучить?',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              // Пояснение под заголовком.
              Text(
                'Приложение построит маршрут по темам с учётом их зависимостей',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              // Для каждого направления из каталога — своя карточка.
              for (final d in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    // InkWell делает карточку нажимаемой (с эффектом волны).
                    child: InkWell(
                      // Ключ нужен автотестам, чтобы найти нужную карточку.
                      key: Key('direction_${d.id}'),
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        // Запоминаем выбранное направление в черновике
                        // плана (OnboardingController).
                        ref
                            .read(onboardingProvider.notifier)
                            .selectDirection(d);
                        // Переходим ко второму шагу — диагностическому тесту.
                        context.push('/onboarding/test');
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        // Содержимое карточки: иконка, тексты, стрелка.
                        child: Row(
                          children: [
                            // Цветной квадрат с иконкой направления;
                            // цвет и имя иконки берутся из каталога.
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
                            // Тексты занимают всё оставшееся место.
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Название направления.
                                  Text(
                                    d.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  // Краткое описание направления.
                                  Text(
                                    d.description,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                  const SizedBox(height: 6),
                                  // Сводка: число тем с правильным
                                  // окончанием («5 тем») и примерный
                                  // объём в часах (минуты / 60).
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
                            // Стрелка справа подсказывает, что карточка
                            // открывает следующий шаг.
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
      ),
    );
  }
}
