// Описание базы данных SQLite через библиотеку drift (слой data, папка db).
// drift — пакет для работы с SQLite: по таблицам, описанным классами Dart,
// он генерирует код запросов (файл app_database.g.dart, вручную не правится).
// Базу открывает сервер API (bin/marshrut_server.dart), а работают с ней
// репозитории lib/data/repositories. Приложение к базе напрямую не обращается:
// все данные оно получает от сервера через API.

import 'package:drift/drift.dart';

// Подключаем сгенерированную часть этого файла (код запросов drift).
part 'app_database.g.dart';

// Таблицы базы данных SQLite. Код запросов генерирует drift:
//   dart run build_runner build
// Сгенерированный файл app_database.g.dart хранится в репозитории, поэтому
// для запуска приложения генерация не нужна.

/// Пользователи. Пароль хранится только в виде хэша PBKDF2-HMAC-SHA256 с солью
/// (записи версии 1 семестра с хэшем SHA-256 пересчитываются при входе).
///
/// Каждый геттер класса — столбец таблицы. Аннотация `@DataClassName`
/// задаёт имя класса одной строки таблицы (здесь UserRow), который
/// сгенерирует drift.
@DataClassName('UserRow')
class Users extends Table {
  /// Уникальный номер пользователя; база назначает его сама
  /// (autoIncrement — каждая новая запись получает следующий номер).
  IntColumn get id => integer().autoIncrement()();

  /// Имя пользователя (от 2 до 40 символов).
  TextColumn get name => text().withLength(min: 2, max: 40)();

  /// Email — уникальный (два аккаунта с одним email создать нельзя).
  TextColumn get email => text().unique()();

  /// Хэш пароля — результат необратимого преобразования пароля.
  /// Сам пароль в базе не хранится.
  TextColumn get passwordHash => text()();

  /// Соль — случайная строка, которая добавляется к паролю перед
  /// хэшированием, чтобы одинаковые пароли давали разные хэши.
  TextColumn get salt => text()();

  /// Цвет аватара, записанный числом.
  IntColumn get avatarColor => integer()();

  /// Включено ли ежедневное напоминание (по умолчанию выключено).
  BoolColumn get reminderEnabled =>
      boolean().withDefault(const Constant(false))();

  /// Час ежедневного напоминания (по умолчанию 19).
  IntColumn get reminderHour => integer().withDefault(const Constant(19))();

  /// Минуты ежедневного напоминания (по умолчанию 0).
  IntColumn get reminderMinute => integer().withDefault(const Constant(0))();

  /// Дата и время регистрации.
  DateTimeColumn get createdAt => dateTime()();
}

/// Планы обучения. У пользователя может быть несколько планов, один активный.
@DataClassName('PlanRow')
class Plans extends Table {
  /// Уникальный номер плана (назначается автоматически).
  IntColumn get id => integer().autoIncrement()();

  /// Владелец плана — ссылка (внешний ключ) на таблицу Users. При удалении
  /// пользователя его планы удаляются автоматически (каскадно).
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();

  /// id направления из каталога, по которому построен план.
  TextColumn get directionId => text()();

  /// Название плана.
  TextColumn get title => text()();

  /// Сколько часов в неделю пользователь готов учиться.
  RealColumn get hoursPerWeek => real()();

  /// Учебные дни через запятую: «1,3,5» (1 — понедельник).
  TextColumn get studyDays => text()();

  /// Дата начала обучения.
  DateTimeColumn get startDate => dateTime()();

  /// Дедлайн. nullable — значение может отсутствовать (план без дедлайна).
  DateTimeColumn get deadline => dateTime().nullable()();

  /// Темы, исключённые по тесту, через запятую.
  TextColumn get knownTopicIds => text().withDefault(const Constant(''))();

  /// Активный ли это план (по умолчанию — да).
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Дата и время создания плана.
  DateTimeColumn get createdAt => dateTime()();
}

/// Темы в составе плана — снимок, чтобы план не зависел от изменений каталога.
@DataClassName('PlanTopicRow')
class PlanTopics extends Table {
  /// Уникальный номер записи (назначается автоматически).
  IntColumn get id => integer().autoIncrement()();

  /// План, к которому относится тема; удаляется вместе с планом.
  IntColumn get planId =>
      integer().references(Plans, #id, onDelete: KeyAction.cascade)();

  /// id темы (из каталога или собственной темы пользователя).
  TextColumn get topicId => text()();

  /// Название темы.
  TextColumn get title => text()();

  /// Категория темы.
  TextColumn get category => text()();

  /// Длительность изучения темы в минутах.
  IntColumn get minutes => integer()();

  /// Уровень сложности темы (влияет на порядок при сортировке Кана).
  IntColumn get level => integer()();

  /// id тем-зависимостей через запятую (пустая строка — зависимостей нет).
  TextColumn get prerequisites => text().withDefault(const Constant(''))();

  /// Позиция темы в порядке изучения.
  IntColumn get position => integer()();
}

/// Занятия плана (изучение темы или повторение) на конкретную дату.
@DataClassName('SessionRow')
class Sessions extends Table {
  /// Уникальный номер занятия (назначается автоматически).
  IntColumn get id => integer().autoIncrement()();

  /// План, к которому относится занятие; удаляется вместе с планом.
  IntColumn get planId =>
      integer().references(Plans, #id, onDelete: KeyAction.cascade)();

  /// id темы занятия.
  TextColumn get topicId => text()();

  /// Название темы (копия, чтобы не искать тему при показе списка).
  TextColumn get topicTitle => text()();

  /// Категория темы.
  TextColumn get category => text()();

  /// Дата занятия.
  DateTimeColumn get date => dateTime()();

  /// Длительность занятия в минутах.
  IntColumn get minutes => integer()();

  /// «study» или «review».
  TextColumn get kind => text()();

  /// Номер части темы (по умолчанию 1).
  IntColumn get part => integer().withDefault(const Constant(1))();

  /// Сколько всего частей у темы (по умолчанию 1).
  IntColumn get totalParts => integer().withDefault(const Constant(1))();

  /// Выполнено ли занятие (по умолчанию — нет).
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();

  /// Когда занятие отмечено выполненным; пусто, если ещё не выполнено.
  DateTimeColumn get completedAt => dateTime().nullable()();
}

/// Собственные темы пользователя.
@DataClassName('CustomTopicRow')
class CustomTopics extends Table {
  /// Уникальный номер темы (назначается автоматически).
  IntColumn get id => integer().autoIncrement()();

  /// Автор темы; темы удаляются вместе с пользователем.
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();

  /// Направление, в которое пользователь добавил тему.
  TextColumn get directionId => text()();

  /// Название темы.
  TextColumn get title => text()();

  /// Описание темы (по умолчанию пустое).
  TextColumn get description => text().withDefault(const Constant(''))();

  /// Длительность изучения в минутах.
  IntColumn get minutes => integer()();

  /// Категория темы.
  TextColumn get category => text()();

  /// id тем-зависимостей через запятую.
  TextColumn get prerequisites => text().withDefault(const Constant(''))();

  /// Дата и время создания темы.
  DateTimeColumn get createdAt => dateTime()();
}

/// Заметки пользователя.
@DataClassName('NoteRow')
class Notes extends Table {
  /// Уникальный номер заметки (назначается автоматически).
  IntColumn get id => integer().autoIncrement()();

  /// Автор заметки; заметки удаляются вместе с пользователем.
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();

  /// Заголовок заметки.
  TextColumn get title => text()();

  /// Текст заметки.
  TextColumn get body => text()();

  /// id темы, к которой привязана заметка (может отсутствовать).
  TextColumn get topicId => text().nullable()();

  /// Название этой темы (может отсутствовать).
  TextColumn get topicTitle => text().nullable()();

  /// Когда заметка создана.
  DateTimeColumn get createdAt => dateTime()();

  /// Когда заметку изменяли последний раз.
  DateTimeColumn get updatedAt => dateTime()();
}

/// Избранные темы.
@DataClassName('FavoriteRow')
class Favorites extends Table {
  /// Пользователь; записи удаляются вместе с ним.
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();

  /// id избранной темы.
  TextColumn get topicId => text()();

  /// Когда тема добавлена в избранное.
  DateTimeColumn get createdAt => dateTime()();

  /// Составной первичный ключ: пара (пользователь, тема) уникальна,
  /// поэтому одну тему нельзя добавить в избранное дважды.
  @override
  Set<Column> get primaryKey => {userId, topicId};
}

/// Завершённые интервалы Pomodoro.
@DataClassName('PomodoroLogRow')
class PomodoroLogs extends Table {
  /// Уникальный номер записи (назначается автоматически).
  IntColumn get id => integer().autoIncrement()();

  /// Пользователь; записи удаляются вместе с ним.
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();

  /// Длительность интервала в минутах.
  IntColumn get minutes => integer()();

  /// Тема, над которой шла работа (может отсутствовать).
  TextColumn get topicTitle => text().nullable()();

  /// Когда интервал завершён.
  DateTimeColumn get completedAt => dateTime()();
}

/// Токены входа в API. После входа сервер выдаёт приложению случайный
/// токен, а приложение отправляет его с каждым запросом. В таблице хранится
/// только хэш SHA-256 токена: даже по копии базы войти не получится.
@DataClassName('ApiTokenRow')
class ApiTokens extends Table {
  /// Хэш SHA-256 токена (64 шестнадцатеричных символа).
  TextColumn get tokenHash => text()();

  /// Пользователь, которому выдан токен; токены удаляются вместе с ним.
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();

  /// Когда токен выдан: по этой дате сервер отбрасывает старые токены.
  DateTimeColumn get createdAt => dateTime()();

  /// Первичный ключ — сам хэш токена.
  @override
  Set<Column> get primaryKey => {tokenHash};
}

/// База данных приложения.
///
/// Аннотация `@DriftDatabase` перечисляет все таблицы; по ней drift
/// генерирует базовый класс `_$AppDatabase` с доступом к таблицам.
@DriftDatabase(
  tables: [
    Users,
    Plans,
    PlanTopics,
    Sessions,
    CustomTopics,
    Notes,
    Favorites,
    PomodoroLogs,
    ApiTokens,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Принимает executor — «движок», через который drift работает с SQLite.
  /// На сервере это файл базы на компьютере (создаётся в
  /// bin/marshrut_server.dart), в тестах — база в памяти.
  AppDatabase(super.executor);

  /// Версия схемы базы. Её увеличивают при изменении таблиц, чтобы drift
  /// запустил миграцию (обновление структуры старой базы).
  /// Версия 2 добавила таблицу токенов API.
  @override
  int get schemaVersion => 2;

  /// Стратегия миграции: что делать при создании и открытии базы.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    // При первом запуске создаём все таблицы.
    onCreate: (m) => m.createAll(),
    // База старой версии: добавляем таблицы, которых в ней ещё нет.
    onUpgrade: (m, from, to) async {
      // В версии 1 не было таблицы токенов API.
      if (from < 2) await m.createTable(apiTokens);
    },
    // Выполняется перед каждым открытием базы.
    beforeOpen: (details) async {
      // Включаем проверку внешних ключей (каскадное удаление планов и занятий).
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
