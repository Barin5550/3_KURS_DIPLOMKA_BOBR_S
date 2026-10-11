import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/session.dart';

/// Карточка занятия с чекбоксом «выполнено».
class SessionTile extends StatelessWidget {
  const SessionTile({
    super.key,
    required this.session,
    required this.today,
    required this.onToggle,
    this.onTap,
    this.showDate = false,
  });

  final StudySession session;
  final DateTime today;
  final VoidCallback onToggle;
  final VoidCallback? onTap;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final missed = session.isMissed(today);
    final isReview = session.kind == SessionKind.review;
    final subtitle = [
      Fmt.minutes(session.minutes),
      session.kind.label,
      if (showDate) Fmt.day(session.date),
      if (missed) 'пропущено',
    ].join(' · ');

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 12, 6),
          child: Row(
            children: [
              Checkbox(
                value: session.isDone,
                onChanged: (_) => onToggle(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              Container(
                width: 4,
                height: 36,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: missed
                      ? theme.colorScheme.error
                      : isReview
                      ? theme.colorScheme.tertiary
                      : AppColors.orange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.displayTitle,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        decoration: session.isDone
                            ? TextDecoration.lineThrough
                            : null,
                        color: session.isDone
                            ? theme.colorScheme.onSurfaceVariant
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: missed
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
