import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Индикатор шагов онбординга: направление → тест → расписание.
class OnboardingSteps extends StatelessWidget {
  const OnboardingSteps({super.key, required this.current});

  final int current;

  static const labels = ['Направление', 'Тест', 'Расписание'];

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.outlineVariant;
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 5,
                    decoration: BoxDecoration(
                      color: i <= current ? AppColors.orange : muted,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[i],
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
