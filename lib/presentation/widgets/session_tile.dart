// Виджет SessionTile — карточка одного учебного занятия в списке.
// Слой: presentation (интерфейс). Показывает название темы, длительность,
// тип занятия и чекбокс «выполнено».
// Используется на главном экране (home_screen.dart) и на экране плана
// (plan_screen.dart).
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/session.dart';

/// Карточка занятия с чекбоксом «выполнено».
///
/// Виджет без собственного состояния (StatelessWidget): все данные и
/// действия приходят снаружи через параметры конструктора.
class SessionTile extends StatelessWidget {
  /// Создаёт карточку. [session], [today] и [onToggle] обязательны,
  /// [onTap] и [showDate] — по желанию экрана, который её показывает.
  const SessionTile({
    super.key,
    required this.session,
    required this.today,
    required this.onToggle,
    this.onTap,
    this.showDate = false,
  });

  /// Занятие из базы данных, которое показывает карточка.
  final StudySession session;

  /// Сегодняшняя дата: нужна, чтобы понять, пропущено ли занятие.
  final DateTime today;

  /// Что сделать при нажатии на чекбокс (отметить или снять отметку).
  final VoidCallback onToggle;

  /// Что сделать при нажатии на саму карточку (например, открыть занятие).
  /// Если `null`, карточка не нажимается и стрелка справа не рисуется.
  final VoidCallback? onTap;

  /// Показывать ли дату занятия в подписи (нужно в списках за несколько
  /// дней).
  final bool showDate;

  /// Строит внешний вид карточки: чекбокс, цветная полоска, название,
  /// подпись и стрелка.
  @override
  Widget build(BuildContext context) {
    // Текущая тема приложения: цвета и стили текста.
    final theme = Theme.of(context);
    // Занятие пропущено, если его дата уже прошла, а отметки нет.
    final missed = session.isMissed(today);
    // Это занятие-повторение (а не изучение новой темы)?
    final isReview = session.kind == SessionKind.review;
    // Подпись под названием: части собираются в список и склеиваются
    // через «·». Дата и слово «пропущено» добавляются только при условии.
    final subtitle = [
      // Длительность, например «1 ч 30 мин».
      Fmt.minutes(session.minutes),
      // Тип занятия: «Изучение» или «Повторение».
      session.kind.label,
      // Дата занятия — только если экран попросил её показать.
      if (showDate) Fmt.day(session.date),
      // Пометка о пропуске.
      if (missed) 'пропущено',
    ].join(' · ');

    // Card — карточка с тенью и скруглёнными углами из темы.
    return Card(
      // InkWell делает карточку нажимаемой и рисует «волну» при нажатии.
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        // Внутренние отступы карточки.
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 12, 6),
          // Все элементы карточки стоят в одну строку слева направо.
          child: Row(
            children: [
              // Чекбокс «выполнено»: при нажатии вызывает onToggle.
              Checkbox(
                value: session.isDone,
                onChanged: (_) => onToggle(),
                // Слегка скруглённый квадрат чекбокса.
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              // Узкая цветная полоска-индикатор типа занятия.
              Container(
                width: 4,
                height: 36,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  // Цвет полоски: красный — пропущено,
                  // цвет tertiary из темы — повторение,
                  // оранжевый — обычное изучение.
                  color: missed
                      ? theme.colorScheme.error
                      : isReview
                      ? theme.colorScheme.tertiary
                      : AppColors.orange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Expanded занимает всё оставшееся место под тексты.
              Expanded(
                // Название и подпись стоят друг под другом.
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Название занятия (например, «Тема (часть 1 из 2)»).
                    Text(
                      session.displayTitle,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        // Выполненное занятие зачёркивается...
                        decoration: session.isDone
                            ? TextDecoration.lineThrough
                            : null,
                        // ...и становится бледнее.
                        color: session.isDone
                            ? theme.colorScheme.onSurfaceVariant
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Подпись: длительность · тип · дата · пропущено.
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        // У пропущенного занятия подпись красная.
                        color: missed
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Стрелка «>» справа — только если карточку можно нажать.
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
