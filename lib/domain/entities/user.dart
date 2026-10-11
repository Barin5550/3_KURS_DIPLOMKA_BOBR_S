/// Пользователь приложения.
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarColor,
    required this.createdAt,
    this.reminderEnabled = false,
    this.reminderHour = 19,
    this.reminderMinute = 0,
  });

  final int id;
  final String name;
  final String email;

  /// Цвет аватара в формате 0xAARRGGBB.
  final int avatarColor;
  final DateTime createdAt;

  /// Ежедневное напоминание о занятиях.
  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
