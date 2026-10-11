import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marshrut/core/utils/password_hasher.dart';
import 'package:marshrut/data/db/app_database.dart';
import 'package:marshrut/data/repositories/auth_repository_impl.dart';
import 'package:marshrut/data/repositories/note_repository_impl.dart';
import 'package:marshrut/data/repositories/plan_repository_impl.dart';
import 'package:marshrut/data/repositories/topic_repository_impl.dart';
import 'package:marshrut/domain/entities/schedule_settings.dart';
import 'package:marshrut/domain/entities/session.dart';
import 'package:marshrut/domain/entities/topic.dart';
import 'package:marshrut/domain/repositories/repositories.dart';
import 'package:marshrut/domain/usecases/plan_service.dart';

/// Тесты слоя data на настоящей SQLite в оперативной памяти.
void main() {
  // Малое число итераций PBKDF2, чтобы тесты шли быстро.
  final hasher = PasswordHasher(iterations: 1000);

  late AppDatabase db;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  group('AuthRepositoryImpl', () {
    late AuthRepositoryImpl auth;
    setUp(() => auth = AuthRepositoryImpl(db, hasher: hasher));

    Future<int> register([String email = 'user@mail.ru']) async =>
        (await auth.register(
          name: '  Алия ',
          email: email,
          password: 'secret123',
        )).id;

    test('регистрация сохраняет хэш, а не пароль', () async {
      await register();
      final row = await db.select(db.users).getSingle();
      expect(row.name, 'Алия');
      expect(row.passwordHash, isNot(contains('secret123')));
      expect(
        row.passwordHash,
        matches(RegExp(r'^pbkdf2_sha256\$1000\$[0-9a-f]{64}$')),
      );
      expect(row.salt, isNotEmpty);
    });

    test('пароль версии 1 семестра (SHA-256) принимается и '
        'пересчитывается в PBKDF2 при входе', () async {
      final id = await register();
      // Запись в формате версии 1 семестра.
      await (db.update(db.users)..where((u) => u.id.equals(id))).write(
        UsersCompanion(
          salt: const Value('old-salt'),
          passwordHash: Value(
            PasswordHasher.legacyHash('secret123', 'old-salt'),
          ),
        ),
      );

      await auth.login(email: 'user@mail.ru', password: 'secret123');

      final row = await db.select(db.users).getSingle();
      expect(row.passwordHash, startsWith(r'pbkdf2_sha256$1000$'));
      expect(row.salt, isNot('old-salt'));
      expect(hasher.verify('secret123', row.salt, row.passwordHash), isTrue);
      // После пересчёта вход по-прежнему работает.
      await auth.login(email: 'user@mail.ru', password: 'secret123');
    });

    test('email уникален без учёта регистра и пробелов', () async {
      await register();
      expect(
        () => register('  USER@mail.RU '),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('уже существует'),
          ),
        ),
      );
    });

    test('вход: верный пароль, неверный пароль, неизвестный email', () async {
      await register();
      final user = await auth.login(
        email: 'User@Mail.ru',
        password: 'secret123',
      );
      expect(user.email, 'user@mail.ru');

      for (final attempt in [
        ('user@mail.ru', 'wrong123'),
        ('nobody@mail.ru', 'secret123'),
      ]) {
        expect(
          () => auth.login(email: attempt.$1, password: attempt.$2),
          throwsA(
            isA<AppException>().having(
              (e) => e.message,
              'message',
              AuthRepositoryImpl.invalidCredentials,
            ),
          ),
        );
      }
    });

    test('смена пароля проверяет текущий и запрещает повтор', () async {
      final id = await register();
      await expectLater(
        () => auth.changePassword(
          userId: id,
          oldPassword: 'bad',
          newPassword: 'newpass123',
        ),
        throwsA(isA<AppException>()),
      );
      await expectLater(
        () => auth.changePassword(
          userId: id,
          oldPassword: 'secret123',
          newPassword: 'secret123',
        ),
        throwsA(isA<AppException>()),
      );
      await auth.changePassword(
        userId: id,
        oldPassword: 'secret123',
        newPassword: 'newpass123',
      );
      await auth.login(email: 'user@mail.ru', password: 'newpass123');
      expect(
        () => auth.login(email: 'user@mail.ru', password: 'secret123'),
        throwsA(isA<AppException>()),
      );
    });

    test('редактирование профиля не даёт занять чужой email', () async {
      final first = await register('a@mail.ru');
      await register('b@mail.ru');
      expect(
        () => auth.updateProfile(
          userId: first,
          name: 'А',
          email: 'B@mail.ru',
          avatarColor: 0,
        ),
        throwsA(isA<AppException>()),
      );
      final updated = await auth.updateProfile(
        userId: first,
        name: 'Новое имя',
        email: 'a2@mail.ru',
        avatarColor: 42,
      );
      expect(updated.name, 'Новое имя');
      expect(updated.email, 'a2@mail.ru');
      expect(updated.avatarColor, 42);
    });

    test('удаление аккаунта проверяет пароль и удаляет все данные '
        'пользователя', () async {
      final id = await register('a@mail.ru');
      final other = await register('b@mail.ru');
      final plans = PlanRepositoryImpl(db);
      final service = PlanService(plans, clock: () => DateTime(2026, 10, 12));
      final notes = NoteRepositoryImpl(db);
      final topics = TopicRepositoryImpl(db);
      for (final userId in [id, other]) {
        await service.createPlan(
          userId: userId,
          directionId: 'flutter',
          title: 'План',
          topics: const [
            Topic(id: 'dart', title: 'Dart', minutes: 60, category: 'Основы'),
          ],
          settings: ScheduleSettings(
            hoursPerWeek: 5,
            studyDays: const {1, 2, 3, 4, 5},
            startDate: DateTime(2026, 10, 12),
          ),
          knownTopicIds: const {},
        );
        await notes.createNote(userId: userId, title: 'Заметка', body: '');
        await PomodoroRepositoryImpl(db)
            .logPomodoro(userId: userId, minutes: 25);
        await topics.toggleFavorite(userId, 'dart');
      }

      await expectLater(
        () => auth.deleteAccount(userId: id, password: 'wrong123'),
        throwsA(isA<AppException>()),
      );
      expect(await db.select(db.users).get(), hasLength(2));

      await auth.deleteAccount(userId: id, password: 'secret123');

      final users = await db.select(db.users).get();
      expect(users.map((u) => u.id), [other]);
      // Данные удалённого пользователя исчезли каскадно, чужие остались.
      expect(await db.select(db.plans).get(), hasLength(1));
      expect(
        (await db.select(db.planTopics).get()).map((t) => t.planId).toSet(),
        hasLength(1),
      );
      expect(await db.select(db.notes).get(), hasLength(1));
      expect(await db.select(db.favorites).get(), hasLength(1));
      expect(await db.select(db.pomodoroLogs).get(), hasLength(1));
      await expectLater(
        () => auth.login(email: 'a@mail.ru', password: 'secret123'),
        throwsA(isA<AppException>()),
      );
    });
  });

  group('PlanRepositoryImpl и PlanService', () {
    late int userId;
    late PlanRepositoryImpl plans;
    late PlanService service;
    final today = DateTime(2026, 10, 12);

    final topics = [
      const Topic(id: 'dart', title: 'Dart', minutes: 60, category: 'Основы'),
      const Topic(
        id: 'widgets',
        title: 'Виджеты',
        minutes: 60,
        category: 'UI',
        prerequisites: ['dart'],
      ),
      const Topic(
        id: 'state',
        title: 'Состояние',
        minutes: 60,
        category: 'UI',
        prerequisites: ['widgets'],
      ),
    ];
    final settings = ScheduleSettings(
      hoursPerWeek: 7,
      studyDays: const {1, 2, 3, 4, 5, 6, 7},
      startDate: today,
    );

    setUp(() async {
      userId = (await AuthRepositoryImpl(
        db,
        hasher: hasher,
      ).register(name: 'Тест', email: 't@t.ru', password: 'secret123')).id;
      plans = PlanRepositoryImpl(db);
      service = PlanService(plans, clock: () => today);
    });

    Future<int> create(String title) => service.createPlan(
      userId: userId,
      directionId: 'flutter',
      title: title,
      topics: topics,
      settings: settings,
      knownTopicIds: const {},
    );

    test('создание плана сохраняет темы по порядку и занятия', () async {
      final id = await create('План');
      final saved = await plans.planById(id);
      expect(saved!.isActive, isTrue);
      expect(saved.settings.hoursPerWeek, 7);
      expect((await plans.planTopics(id)).map((t) => t.topicId), [
        'dart',
        'widgets',
        'state',
      ]);
      final sessions = await plans.sessions(id);
      final study = sessions.where((s) => s.kind == SessionKind.study);
      // Повторения занимают часть дневного лимита, поэтому темы могут
      // делиться на части, но суммарное время изучения сохраняется.
      expect(study.fold(0, (sum, s) => sum + s.minutes), 180);
      expect(study.map((s) => s.topicId).toSet(), {'dart', 'widgets', 'state'});
      expect(sessions.where((s) => s.kind == SessionKind.review), hasLength(9));
    });

    test('активным может быть только один план', () async {
      final first = await create('Первый');
      final second = await create('Второй');
      expect((await plans.planById(first))!.isActive, isFalse);
      expect((await plans.watchActivePlan(userId).first)!.id, second);

      await plans.setActive(userId, first);
      expect((await plans.watchActivePlan(userId).first)!.id, first);
      expect(await plans.watchPlans(userId).first, hasLength(2));
    });

    test('удаление плана удаляет темы и занятия каскадно', () async {
      final first = await create('Первый');
      final second = await create('Второй');
      await plans.deletePlan(second);

      expect(await plans.planById(second), isNull);
      expect(await plans.planTopics(second), isEmpty);
      expect(await plans.sessions(second), isEmpty);
      // Активным становится оставшийся план.
      expect((await plans.planById(first))!.isActive, isTrue);
    });

    test('переименование плана', () async {
      final id = await create('Старое');
      await plans.renamePlan(id, '  Новое  ');
      expect((await plans.planById(id))!.title, 'Новое');
    });

    test('перепланирование сохраняет выполненные занятия', () async {
      final id = await create('План');
      final first = (await plans.sessions(id)).first;
      await service.toggleSession(first);
      final doneBefore = await plans.sessionById(first.id);
      expect(doneBefore!.isDone, isTrue);
      expect(doneBefore.completedAt, isNotNull);

      final plan = (await plans.planById(id))!;
      await service.replan(plan);
      final after = await plans.sessions(id);
      expect(after.where((s) => s.isDone).map((s) => s.id), [first.id]);
      expect(
        after.where((s) => s.topicId == 'dart' && s.kind == SessionKind.study),
        hasLength(1),
        reason: 'выполненная тема не планируется заново',
      );
    });

    test('добавление и удаление темы перестраивает план', () async {
      final id = await create('План');
      final plan = (await plans.planById(id))!;
      const extra = Topic(
        id: 'custom_1',
        title: 'Своя тема',
        minutes: 30,
        category: 'Своё',
        prerequisites: ['dart'],
      );
      await service.addTopic(plan, extra);
      final ids = (await plans.planTopics(id)).map((t) => t.topicId).toList();
      expect(ids, contains('custom_1'));
      expect(ids.indexOf('custom_1') > ids.indexOf('dart'), isTrue);
      expect(() => service.addTopic(plan, extra), throwsA(isA<AppException>()));

      await service.removeTopic(plan, 'custom_1');
      expect(
        (await plans.sessions(id)).any((s) => s.topicId == 'custom_1'),
        isFalse,
      );
    });

    test('выполненные занятия попадают в историю пользователя', () async {
      final id = await create('План');
      final sessions = await plans.sessions(id);
      await plans.setSessionDone(sessions[0].id, done: true);
      await plans.setSessionDone(sessions[1].id, done: true);
      await plans.setSessionDone(sessions[1].id, done: false);
      final history = await plans.watchCompletedSessions(userId).first;
      expect(history.map((s) => s.id), [sessions[0].id]);
    });
  });

  group('TopicRepositoryImpl', () {
    late int userId;
    late TopicRepositoryImpl topics;

    setUp(() async {
      userId = (await AuthRepositoryImpl(
        db,
        hasher: hasher,
      ).register(name: 'Тест', email: 't@t.ru', password: 'secret123')).id;
      topics = TopicRepositoryImpl(db);
    });

    Future<String> create() => topics.createCustomTopic(
      userId: userId,
      directionId: 'python',
      title: ' Pandas ',
      description: 'Таблицы',
      minutes: 90,
      category: 'Данные',
      prerequisites: const ['basics'],
    );

    test('CRUD собственной темы', () async {
      final id = await create();
      expect(id, startsWith('custom_'));
      var topic = (await topics.customTopicById(id))!;
      expect(topic.title, 'Pandas');
      expect(topic.isCustom, isTrue);
      expect(topic.prerequisites, ['basics']);
      expect(await topics.directionOf(id), 'python');

      await topics.updateCustomTopic(
        topicId: id,
        title: 'NumPy',
        description: '',
        minutes: 60,
        category: 'Данные',
        prerequisites: const [],
      );
      topic = (await topics.customTopicById(id))!;
      expect(topic.title, 'NumPy');
      expect(topic.minutes, 60);
      expect(topic.prerequisites, isEmpty);

      expect(await topics.customTopics(userId, 'python'), hasLength(1));
      expect(await topics.customTopics(userId, 'flutter'), isEmpty);

      await topics.deleteCustomTopic(id);
      expect(await topics.customTopicById(id), isNull);
    });

    test('тему каталога нельзя изменить или удалить', () async {
      expect(
        () => topics.deleteCustomTopic('dart_basics'),
        throwsA(isA<AppException>()),
      );
    });

    test('избранное переключается и чистится при удалении темы', () async {
      final id = await create();
      await topics.toggleFavorite(userId, 'dart_basics');
      await topics.toggleFavorite(userId, id);
      expect(await topics.watchFavorites(userId).first, {'dart_basics', id});

      await topics.toggleFavorite(userId, 'dart_basics');
      expect(await topics.watchFavorites(userId).first, {id});

      await topics.deleteCustomTopic(id);
      expect(await topics.watchFavorites(userId).first, isEmpty);
    });
  });

  group('NoteRepositoryImpl', () {
    test('CRUD заметок и фильтр по теме', () async {
      final userId = (await AuthRepositoryImpl(
        db,
        hasher: hasher,
      ).register(name: 'Тест', email: 't@t.ru', password: 'secret123')).id;
      final notes = NoteRepositoryImpl(db);

      final general = await notes.createNote(
        userId: userId,
        title: 'Общая',
        body: 'текст',
      );
      await notes.createNote(
        userId: userId,
        title: 'По теме',
        body: 'конспект',
        topicId: 'dart',
        topicTitle: 'Dart',
      );
      expect(await notes.watchNotes(userId).first, hasLength(2));
      expect(
        (await notes.watchNotes(userId, topicId: 'dart').first).single.title,
        'По теме',
      );

      await notes.updateNote(id: general, title: 'Изменена', body: 'новый');
      final edited = (await notes.noteById(general))!;
      expect(edited.title, 'Изменена');
      expect(edited.body, 'новый');

      await notes.deleteNote(general);
      expect(await notes.noteById(general), isNull);
      expect(await notes.watchNotes(userId).first, hasLength(1));
    });
  });
}
