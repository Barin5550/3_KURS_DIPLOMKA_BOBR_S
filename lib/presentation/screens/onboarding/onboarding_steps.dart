// Слой presentation (интерфейс): маленький виджет-индикатор шагов мастера
// создания плана (онбординга). Показывает три полоски: «Направление»,
// «Тест», «Расписание» и подсвечивает пройденные шаги оранжевым.
// Используется экранами DirectionScreen, DiagnosticScreen и ScheduleScreen.
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Индикатор шагов онбординга: направление → тест → расписание.
///
/// Виджет без состояния (StatelessWidget): всё, что он рисует, зависит
/// только от номера текущего шага [current], который передаёт экран.
class OnboardingSteps extends StatelessWidget {
  /// Создаёт индикатор; [current] — номер текущего шага, начиная с 0.
  const OnboardingSteps({super.key, required this.current});

  /// Номер текущего шага: 0 — направление, 1 — тест, 2 — расписание.
  final int current;

  /// Подписи под полосками, по одной на каждый шаг.
  static const labels = ['Направление', 'Тест', 'Расписание'];

  /// Строит ряд из трёх полосок с подписями.
  @override
  Widget build(BuildContext context) {
    // Приглушённый цвет темы для ещё не пройденных шагов.
    final muted = Theme.of(context).colorScheme.outlineVariant;
    // Все шаги стоят в одну строку.
    return Row(
      children: [
        // Для каждого шага создаём свою колонку «полоска + подпись».
        for (var i = 0; i < labels.length; i++)
          // Expanded делит ширину строки поровну между шагами.
          Expanded(
            child: Padding(
              // Отступ справа между шагами, у последнего шага его нет.
              padding: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Полоска шага: плавно (за 300 мс) меняет цвет, когда
                  // пользователь переходит на следующий шаг.
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 5,
                    decoration: BoxDecoration(
                      // Пройденные и текущий шаг — оранжевые, остальные —
                      // приглушённые.
                      color: i <= current ? AppColors.orange : muted,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Подпись шага под полоской.
                  Text(
                    labels[i],
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      // Текущий шаг выделяем жирным шрифтом.
                      fontWeight: i == current ? FontWeight.w700 : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
