// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, UserRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 2,
      maxTextLength: 40,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _passwordHashMeta = const VerificationMeta(
    'passwordHash',
  );
  @override
  late final GeneratedColumn<String> passwordHash = GeneratedColumn<String>(
    'password_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saltMeta = const VerificationMeta('salt');
  @override
  late final GeneratedColumn<String> salt = GeneratedColumn<String>(
    'salt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avatarColorMeta = const VerificationMeta(
    'avatarColor',
  );
  @override
  late final GeneratedColumn<int> avatarColor = GeneratedColumn<int>(
    'avatar_color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reminderEnabledMeta = const VerificationMeta(
    'reminderEnabled',
  );
  @override
  late final GeneratedColumn<bool> reminderEnabled = GeneratedColumn<bool>(
    'reminder_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("reminder_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _reminderHourMeta = const VerificationMeta(
    'reminderHour',
  );
  @override
  late final GeneratedColumn<int> reminderHour = GeneratedColumn<int>(
    'reminder_hour',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(19),
  );
  static const VerificationMeta _reminderMinuteMeta = const VerificationMeta(
    'reminderMinute',
  );
  @override
  late final GeneratedColumn<int> reminderMinute = GeneratedColumn<int>(
    'reminder_minute',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    email,
    passwordHash,
    salt,
    avatarColor,
    reminderEnabled,
    reminderHour,
    reminderMinute,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('password_hash')) {
      context.handle(
        _passwordHashMeta,
        passwordHash.isAcceptableOrUnknown(
          data['password_hash']!,
          _passwordHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_passwordHashMeta);
    }
    if (data.containsKey('salt')) {
      context.handle(
        _saltMeta,
        salt.isAcceptableOrUnknown(data['salt']!, _saltMeta),
      );
    } else if (isInserting) {
      context.missing(_saltMeta);
    }
    if (data.containsKey('avatar_color')) {
      context.handle(
        _avatarColorMeta,
        avatarColor.isAcceptableOrUnknown(
          data['avatar_color']!,
          _avatarColorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_avatarColorMeta);
    }
    if (data.containsKey('reminder_enabled')) {
      context.handle(
        _reminderEnabledMeta,
        reminderEnabled.isAcceptableOrUnknown(
          data['reminder_enabled']!,
          _reminderEnabledMeta,
        ),
      );
    }
    if (data.containsKey('reminder_hour')) {
      context.handle(
        _reminderHourMeta,
        reminderHour.isAcceptableOrUnknown(
          data['reminder_hour']!,
          _reminderHourMeta,
        ),
      );
    }
    if (data.containsKey('reminder_minute')) {
      context.handle(
        _reminderMinuteMeta,
        reminderMinute.isAcceptableOrUnknown(
          data['reminder_minute']!,
          _reminderMinuteMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      passwordHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password_hash'],
      )!,
      salt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}salt'],
      )!,
      avatarColor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}avatar_color'],
      )!,
      reminderEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reminder_enabled'],
      )!,
      reminderHour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_hour'],
      )!,
      reminderMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_minute'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class UserRow extends DataClass implements Insertable<UserRow> {
  final int id;
  final String name;
  final String email;
  final String passwordHash;
  final String salt;
  final int avatarColor;
  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;
  final DateTime createdAt;
  const UserRow({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.salt,
    required this.avatarColor,
    required this.reminderEnabled,
    required this.reminderHour,
    required this.reminderMinute,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['email'] = Variable<String>(email);
    map['password_hash'] = Variable<String>(passwordHash);
    map['salt'] = Variable<String>(salt);
    map['avatar_color'] = Variable<int>(avatarColor);
    map['reminder_enabled'] = Variable<bool>(reminderEnabled);
    map['reminder_hour'] = Variable<int>(reminderHour);
    map['reminder_minute'] = Variable<int>(reminderMinute);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      name: Value(name),
      email: Value(email),
      passwordHash: Value(passwordHash),
      salt: Value(salt),
      avatarColor: Value(avatarColor),
      reminderEnabled: Value(reminderEnabled),
      reminderHour: Value(reminderHour),
      reminderMinute: Value(reminderMinute),
      createdAt: Value(createdAt),
    );
  }

  factory UserRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      email: serializer.fromJson<String>(json['email']),
      passwordHash: serializer.fromJson<String>(json['passwordHash']),
      salt: serializer.fromJson<String>(json['salt']),
      avatarColor: serializer.fromJson<int>(json['avatarColor']),
      reminderEnabled: serializer.fromJson<bool>(json['reminderEnabled']),
      reminderHour: serializer.fromJson<int>(json['reminderHour']),
      reminderMinute: serializer.fromJson<int>(json['reminderMinute']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'email': serializer.toJson<String>(email),
      'passwordHash': serializer.toJson<String>(passwordHash),
      'salt': serializer.toJson<String>(salt),
      'avatarColor': serializer.toJson<int>(avatarColor),
      'reminderEnabled': serializer.toJson<bool>(reminderEnabled),
      'reminderHour': serializer.toJson<int>(reminderHour),
      'reminderMinute': serializer.toJson<int>(reminderMinute),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  UserRow copyWith({
    int? id,
    String? name,
    String? email,
    String? passwordHash,
    String? salt,
    int? avatarColor,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    DateTime? createdAt,
  }) => UserRow(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    passwordHash: passwordHash ?? this.passwordHash,
    salt: salt ?? this.salt,
    avatarColor: avatarColor ?? this.avatarColor,
    reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    reminderHour: reminderHour ?? this.reminderHour,
    reminderMinute: reminderMinute ?? this.reminderMinute,
    createdAt: createdAt ?? this.createdAt,
  );
  UserRow copyWithCompanion(UsersCompanion data) {
    return UserRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
      passwordHash: data.passwordHash.present
          ? data.passwordHash.value
          : this.passwordHash,
      salt: data.salt.present ? data.salt.value : this.salt,
      avatarColor: data.avatarColor.present
          ? data.avatarColor.value
          : this.avatarColor,
      reminderEnabled: data.reminderEnabled.present
          ? data.reminderEnabled.value
          : this.reminderEnabled,
      reminderHour: data.reminderHour.present
          ? data.reminderHour.value
          : this.reminderHour,
      reminderMinute: data.reminderMinute.present
          ? data.reminderMinute.value
          : this.reminderMinute,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('salt: $salt, ')
          ..write('avatarColor: $avatarColor, ')
          ..write('reminderEnabled: $reminderEnabled, ')
          ..write('reminderHour: $reminderHour, ')
          ..write('reminderMinute: $reminderMinute, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    email,
    passwordHash,
    salt,
    avatarColor,
    reminderEnabled,
    reminderHour,
    reminderMinute,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.email == this.email &&
          other.passwordHash == this.passwordHash &&
          other.salt == this.salt &&
          other.avatarColor == this.avatarColor &&
          other.reminderEnabled == this.reminderEnabled &&
          other.reminderHour == this.reminderHour &&
          other.reminderMinute == this.reminderMinute &&
          other.createdAt == this.createdAt);
}

class UsersCompanion extends UpdateCompanion<UserRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> email;
  final Value<String> passwordHash;
  final Value<String> salt;
  final Value<int> avatarColor;
  final Value<bool> reminderEnabled;
  final Value<int> reminderHour;
  final Value<int> reminderMinute;
  final Value<DateTime> createdAt;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.passwordHash = const Value.absent(),
    this.salt = const Value.absent(),
    this.avatarColor = const Value.absent(),
    this.reminderEnabled = const Value.absent(),
    this.reminderHour = const Value.absent(),
    this.reminderMinute = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String email,
    required String passwordHash,
    required String salt,
    required int avatarColor,
    this.reminderEnabled = const Value.absent(),
    this.reminderHour = const Value.absent(),
    this.reminderMinute = const Value.absent(),
    required DateTime createdAt,
  }) : name = Value(name),
       email = Value(email),
       passwordHash = Value(passwordHash),
       salt = Value(salt),
       avatarColor = Value(avatarColor),
       createdAt = Value(createdAt);
  static Insertable<UserRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? email,
    Expression<String>? passwordHash,
    Expression<String>? salt,
    Expression<int>? avatarColor,
    Expression<bool>? reminderEnabled,
    Expression<int>? reminderHour,
    Expression<int>? reminderMinute,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (salt != null) 'salt': salt,
      if (avatarColor != null) 'avatar_color': avatarColor,
      if (reminderEnabled != null) 'reminder_enabled': reminderEnabled,
      if (reminderHour != null) 'reminder_hour': reminderHour,
      if (reminderMinute != null) 'reminder_minute': reminderMinute,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  UsersCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? email,
    Value<String>? passwordHash,
    Value<String>? salt,
    Value<int>? avatarColor,
    Value<bool>? reminderEnabled,
    Value<int>? reminderHour,
    Value<int>? reminderMinute,
    Value<DateTime>? createdAt,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      salt: salt ?? this.salt,
      avatarColor: avatarColor ?? this.avatarColor,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (passwordHash.present) {
      map['password_hash'] = Variable<String>(passwordHash.value);
    }
    if (salt.present) {
      map['salt'] = Variable<String>(salt.value);
    }
    if (avatarColor.present) {
      map['avatar_color'] = Variable<int>(avatarColor.value);
    }
    if (reminderEnabled.present) {
      map['reminder_enabled'] = Variable<bool>(reminderEnabled.value);
    }
    if (reminderHour.present) {
      map['reminder_hour'] = Variable<int>(reminderHour.value);
    }
    if (reminderMinute.present) {
      map['reminder_minute'] = Variable<int>(reminderMinute.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('salt: $salt, ')
          ..write('avatarColor: $avatarColor, ')
          ..write('reminderEnabled: $reminderEnabled, ')
          ..write('reminderHour: $reminderHour, ')
          ..write('reminderMinute: $reminderMinute, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PlansTable extends Plans with TableInfo<$PlansTable, PlanRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _directionIdMeta = const VerificationMeta(
    'directionId',
  );
  @override
  late final GeneratedColumn<String> directionId = GeneratedColumn<String>(
    'direction_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hoursPerWeekMeta = const VerificationMeta(
    'hoursPerWeek',
  );
  @override
  late final GeneratedColumn<double> hoursPerWeek = GeneratedColumn<double>(
    'hours_per_week',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _studyDaysMeta = const VerificationMeta(
    'studyDays',
  );
  @override
  late final GeneratedColumn<String> studyDays = GeneratedColumn<String>(
    'study_days',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deadlineMeta = const VerificationMeta(
    'deadline',
  );
  @override
  late final GeneratedColumn<DateTime> deadline = GeneratedColumn<DateTime>(
    'deadline',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _knownTopicIdsMeta = const VerificationMeta(
    'knownTopicIds',
  );
  @override
  late final GeneratedColumn<String> knownTopicIds = GeneratedColumn<String>(
    'known_topic_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    directionId,
    title,
    hoursPerWeek,
    studyDays,
    startDate,
    deadline,
    knownTopicIds,
    isActive,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlanRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('direction_id')) {
      context.handle(
        _directionIdMeta,
        directionId.isAcceptableOrUnknown(
          data['direction_id']!,
          _directionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_directionIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('hours_per_week')) {
      context.handle(
        _hoursPerWeekMeta,
        hoursPerWeek.isAcceptableOrUnknown(
          data['hours_per_week']!,
          _hoursPerWeekMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_hoursPerWeekMeta);
    }
    if (data.containsKey('study_days')) {
      context.handle(
        _studyDaysMeta,
        studyDays.isAcceptableOrUnknown(data['study_days']!, _studyDaysMeta),
      );
    } else if (isInserting) {
      context.missing(_studyDaysMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('deadline')) {
      context.handle(
        _deadlineMeta,
        deadline.isAcceptableOrUnknown(data['deadline']!, _deadlineMeta),
      );
    }
    if (data.containsKey('known_topic_ids')) {
      context.handle(
        _knownTopicIdsMeta,
        knownTopicIds.isAcceptableOrUnknown(
          data['known_topic_ids']!,
          _knownTopicIdsMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      directionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      hoursPerWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}hours_per_week'],
      )!,
      studyDays: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}study_days'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      deadline: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deadline'],
      ),
      knownTopicIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}known_topic_ids'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PlansTable createAlias(String alias) {
    return $PlansTable(attachedDatabase, alias);
  }
}

class PlanRow extends DataClass implements Insertable<PlanRow> {
  final int id;
  final int userId;
  final String directionId;
  final String title;
  final double hoursPerWeek;

  /// Учебные дни через запятую: «1,3,5» (1 — понедельник).
  final String studyDays;
  final DateTime startDate;
  final DateTime? deadline;

  /// Темы, исключённые по тесту, через запятую.
  final String knownTopicIds;
  final bool isActive;
  final DateTime createdAt;
  const PlanRow({
    required this.id,
    required this.userId,
    required this.directionId,
    required this.title,
    required this.hoursPerWeek,
    required this.studyDays,
    required this.startDate,
    this.deadline,
    required this.knownTopicIds,
    required this.isActive,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<int>(userId);
    map['direction_id'] = Variable<String>(directionId);
    map['title'] = Variable<String>(title);
    map['hours_per_week'] = Variable<double>(hoursPerWeek);
    map['study_days'] = Variable<String>(studyDays);
    map['start_date'] = Variable<DateTime>(startDate);
    if (!nullToAbsent || deadline != null) {
      map['deadline'] = Variable<DateTime>(deadline);
    }
    map['known_topic_ids'] = Variable<String>(knownTopicIds);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PlansCompanion toCompanion(bool nullToAbsent) {
    return PlansCompanion(
      id: Value(id),
      userId: Value(userId),
      directionId: Value(directionId),
      title: Value(title),
      hoursPerWeek: Value(hoursPerWeek),
      studyDays: Value(studyDays),
      startDate: Value(startDate),
      deadline: deadline == null && nullToAbsent
          ? const Value.absent()
          : Value(deadline),
      knownTopicIds: Value(knownTopicIds),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
    );
  }

  factory PlanRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanRow(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      directionId: serializer.fromJson<String>(json['directionId']),
      title: serializer.fromJson<String>(json['title']),
      hoursPerWeek: serializer.fromJson<double>(json['hoursPerWeek']),
      studyDays: serializer.fromJson<String>(json['studyDays']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      deadline: serializer.fromJson<DateTime?>(json['deadline']),
      knownTopicIds: serializer.fromJson<String>(json['knownTopicIds']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int>(userId),
      'directionId': serializer.toJson<String>(directionId),
      'title': serializer.toJson<String>(title),
      'hoursPerWeek': serializer.toJson<double>(hoursPerWeek),
      'studyDays': serializer.toJson<String>(studyDays),
      'startDate': serializer.toJson<DateTime>(startDate),
      'deadline': serializer.toJson<DateTime?>(deadline),
      'knownTopicIds': serializer.toJson<String>(knownTopicIds),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PlanRow copyWith({
    int? id,
    int? userId,
    String? directionId,
    String? title,
    double? hoursPerWeek,
    String? studyDays,
    DateTime? startDate,
    Value<DateTime?> deadline = const Value.absent(),
    String? knownTopicIds,
    bool? isActive,
    DateTime? createdAt,
  }) => PlanRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    directionId: directionId ?? this.directionId,
    title: title ?? this.title,
    hoursPerWeek: hoursPerWeek ?? this.hoursPerWeek,
    studyDays: studyDays ?? this.studyDays,
    startDate: startDate ?? this.startDate,
    deadline: deadline.present ? deadline.value : this.deadline,
    knownTopicIds: knownTopicIds ?? this.knownTopicIds,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
  );
  PlanRow copyWithCompanion(PlansCompanion data) {
    return PlanRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      directionId: data.directionId.present
          ? data.directionId.value
          : this.directionId,
      title: data.title.present ? data.title.value : this.title,
      hoursPerWeek: data.hoursPerWeek.present
          ? data.hoursPerWeek.value
          : this.hoursPerWeek,
      studyDays: data.studyDays.present ? data.studyDays.value : this.studyDays,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      deadline: data.deadline.present ? data.deadline.value : this.deadline,
      knownTopicIds: data.knownTopicIds.present
          ? data.knownTopicIds.value
          : this.knownTopicIds,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('directionId: $directionId, ')
          ..write('title: $title, ')
          ..write('hoursPerWeek: $hoursPerWeek, ')
          ..write('studyDays: $studyDays, ')
          ..write('startDate: $startDate, ')
          ..write('deadline: $deadline, ')
          ..write('knownTopicIds: $knownTopicIds, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    directionId,
    title,
    hoursPerWeek,
    studyDays,
    startDate,
    deadline,
    knownTopicIds,
    isActive,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.directionId == this.directionId &&
          other.title == this.title &&
          other.hoursPerWeek == this.hoursPerWeek &&
          other.studyDays == this.studyDays &&
          other.startDate == this.startDate &&
          other.deadline == this.deadline &&
          other.knownTopicIds == this.knownTopicIds &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt);
}

class PlansCompanion extends UpdateCompanion<PlanRow> {
  final Value<int> id;
  final Value<int> userId;
  final Value<String> directionId;
  final Value<String> title;
  final Value<double> hoursPerWeek;
  final Value<String> studyDays;
  final Value<DateTime> startDate;
  final Value<DateTime?> deadline;
  final Value<String> knownTopicIds;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  const PlansCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.directionId = const Value.absent(),
    this.title = const Value.absent(),
    this.hoursPerWeek = const Value.absent(),
    this.studyDays = const Value.absent(),
    this.startDate = const Value.absent(),
    this.deadline = const Value.absent(),
    this.knownTopicIds = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PlansCompanion.insert({
    this.id = const Value.absent(),
    required int userId,
    required String directionId,
    required String title,
    required double hoursPerWeek,
    required String studyDays,
    required DateTime startDate,
    this.deadline = const Value.absent(),
    this.knownTopicIds = const Value.absent(),
    this.isActive = const Value.absent(),
    required DateTime createdAt,
  }) : userId = Value(userId),
       directionId = Value(directionId),
       title = Value(title),
       hoursPerWeek = Value(hoursPerWeek),
       studyDays = Value(studyDays),
       startDate = Value(startDate),
       createdAt = Value(createdAt);
  static Insertable<PlanRow> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<String>? directionId,
    Expression<String>? title,
    Expression<double>? hoursPerWeek,
    Expression<String>? studyDays,
    Expression<DateTime>? startDate,
    Expression<DateTime>? deadline,
    Expression<String>? knownTopicIds,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (directionId != null) 'direction_id': directionId,
      if (title != null) 'title': title,
      if (hoursPerWeek != null) 'hours_per_week': hoursPerWeek,
      if (studyDays != null) 'study_days': studyDays,
      if (startDate != null) 'start_date': startDate,
      if (deadline != null) 'deadline': deadline,
      if (knownTopicIds != null) 'known_topic_ids': knownTopicIds,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PlansCompanion copyWith({
    Value<int>? id,
    Value<int>? userId,
    Value<String>? directionId,
    Value<String>? title,
    Value<double>? hoursPerWeek,
    Value<String>? studyDays,
    Value<DateTime>? startDate,
    Value<DateTime?>? deadline,
    Value<String>? knownTopicIds,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
  }) {
    return PlansCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      directionId: directionId ?? this.directionId,
      title: title ?? this.title,
      hoursPerWeek: hoursPerWeek ?? this.hoursPerWeek,
      studyDays: studyDays ?? this.studyDays,
      startDate: startDate ?? this.startDate,
      deadline: deadline ?? this.deadline,
      knownTopicIds: knownTopicIds ?? this.knownTopicIds,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (directionId.present) {
      map['direction_id'] = Variable<String>(directionId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (hoursPerWeek.present) {
      map['hours_per_week'] = Variable<double>(hoursPerWeek.value);
    }
    if (studyDays.present) {
      map['study_days'] = Variable<String>(studyDays.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (deadline.present) {
      map['deadline'] = Variable<DateTime>(deadline.value);
    }
    if (knownTopicIds.present) {
      map['known_topic_ids'] = Variable<String>(knownTopicIds.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlansCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('directionId: $directionId, ')
          ..write('title: $title, ')
          ..write('hoursPerWeek: $hoursPerWeek, ')
          ..write('studyDays: $studyDays, ')
          ..write('startDate: $startDate, ')
          ..write('deadline: $deadline, ')
          ..write('knownTopicIds: $knownTopicIds, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PlanTopicsTable extends PlanTopics
    with TableInfo<$PlanTopicsTable, PlanTopicRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanTopicsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<int> planId = GeneratedColumn<int>(
    'plan_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES plans (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _topicIdMeta = const VerificationMeta(
    'topicId',
  );
  @override
  late final GeneratedColumn<String> topicId = GeneratedColumn<String>(
    'topic_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minutesMeta = const VerificationMeta(
    'minutes',
  );
  @override
  late final GeneratedColumn<int> minutes = GeneratedColumn<int>(
    'minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _prerequisitesMeta = const VerificationMeta(
    'prerequisites',
  );
  @override
  late final GeneratedColumn<String> prerequisites = GeneratedColumn<String>(
    'prerequisites',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    planId,
    topicId,
    title,
    category,
    minutes,
    level,
    prerequisites,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_topics';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlanTopicRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('topic_id')) {
      context.handle(
        _topicIdMeta,
        topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta),
      );
    } else if (isInserting) {
      context.missing(_topicIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('minutes')) {
      context.handle(
        _minutesMeta,
        minutes.isAcceptableOrUnknown(data['minutes']!, _minutesMeta),
      );
    } else if (isInserting) {
      context.missing(_minutesMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('prerequisites')) {
      context.handle(
        _prerequisitesMeta,
        prerequisites.isAcceptableOrUnknown(
          data['prerequisites']!,
          _prerequisitesMeta,
        ),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanTopicRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanTopicRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plan_id'],
      )!,
      topicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      minutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minutes'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      prerequisites: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prerequisites'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $PlanTopicsTable createAlias(String alias) {
    return $PlanTopicsTable(attachedDatabase, alias);
  }
}

class PlanTopicRow extends DataClass implements Insertable<PlanTopicRow> {
  final int id;
  final int planId;
  final String topicId;
  final String title;
  final String category;
  final int minutes;
  final int level;
  final String prerequisites;
  final int position;
  const PlanTopicRow({
    required this.id,
    required this.planId,
    required this.topicId,
    required this.title,
    required this.category,
    required this.minutes,
    required this.level,
    required this.prerequisites,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['plan_id'] = Variable<int>(planId);
    map['topic_id'] = Variable<String>(topicId);
    map['title'] = Variable<String>(title);
    map['category'] = Variable<String>(category);
    map['minutes'] = Variable<int>(minutes);
    map['level'] = Variable<int>(level);
    map['prerequisites'] = Variable<String>(prerequisites);
    map['position'] = Variable<int>(position);
    return map;
  }

  PlanTopicsCompanion toCompanion(bool nullToAbsent) {
    return PlanTopicsCompanion(
      id: Value(id),
      planId: Value(planId),
      topicId: Value(topicId),
      title: Value(title),
      category: Value(category),
      minutes: Value(minutes),
      level: Value(level),
      prerequisites: Value(prerequisites),
      position: Value(position),
    );
  }

  factory PlanTopicRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanTopicRow(
      id: serializer.fromJson<int>(json['id']),
      planId: serializer.fromJson<int>(json['planId']),
      topicId: serializer.fromJson<String>(json['topicId']),
      title: serializer.fromJson<String>(json['title']),
      category: serializer.fromJson<String>(json['category']),
      minutes: serializer.fromJson<int>(json['minutes']),
      level: serializer.fromJson<int>(json['level']),
      prerequisites: serializer.fromJson<String>(json['prerequisites']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'planId': serializer.toJson<int>(planId),
      'topicId': serializer.toJson<String>(topicId),
      'title': serializer.toJson<String>(title),
      'category': serializer.toJson<String>(category),
      'minutes': serializer.toJson<int>(minutes),
      'level': serializer.toJson<int>(level),
      'prerequisites': serializer.toJson<String>(prerequisites),
      'position': serializer.toJson<int>(position),
    };
  }

  PlanTopicRow copyWith({
    int? id,
    int? planId,
    String? topicId,
    String? title,
    String? category,
    int? minutes,
    int? level,
    String? prerequisites,
    int? position,
  }) => PlanTopicRow(
    id: id ?? this.id,
    planId: planId ?? this.planId,
    topicId: topicId ?? this.topicId,
    title: title ?? this.title,
    category: category ?? this.category,
    minutes: minutes ?? this.minutes,
    level: level ?? this.level,
    prerequisites: prerequisites ?? this.prerequisites,
    position: position ?? this.position,
  );
  PlanTopicRow copyWithCompanion(PlanTopicsCompanion data) {
    return PlanTopicRow(
      id: data.id.present ? data.id.value : this.id,
      planId: data.planId.present ? data.planId.value : this.planId,
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
      title: data.title.present ? data.title.value : this.title,
      category: data.category.present ? data.category.value : this.category,
      minutes: data.minutes.present ? data.minutes.value : this.minutes,
      level: data.level.present ? data.level.value : this.level,
      prerequisites: data.prerequisites.present
          ? data.prerequisites.value
          : this.prerequisites,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanTopicRow(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('topicId: $topicId, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('minutes: $minutes, ')
          ..write('level: $level, ')
          ..write('prerequisites: $prerequisites, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    planId,
    topicId,
    title,
    category,
    minutes,
    level,
    prerequisites,
    position,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanTopicRow &&
          other.id == this.id &&
          other.planId == this.planId &&
          other.topicId == this.topicId &&
          other.title == this.title &&
          other.category == this.category &&
          other.minutes == this.minutes &&
          other.level == this.level &&
          other.prerequisites == this.prerequisites &&
          other.position == this.position);
}

class PlanTopicsCompanion extends UpdateCompanion<PlanTopicRow> {
  final Value<int> id;
  final Value<int> planId;
  final Value<String> topicId;
  final Value<String> title;
  final Value<String> category;
  final Value<int> minutes;
  final Value<int> level;
  final Value<String> prerequisites;
  final Value<int> position;
  const PlanTopicsCompanion({
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    this.topicId = const Value.absent(),
    this.title = const Value.absent(),
    this.category = const Value.absent(),
    this.minutes = const Value.absent(),
    this.level = const Value.absent(),
    this.prerequisites = const Value.absent(),
    this.position = const Value.absent(),
  });
  PlanTopicsCompanion.insert({
    this.id = const Value.absent(),
    required int planId,
    required String topicId,
    required String title,
    required String category,
    required int minutes,
    required int level,
    this.prerequisites = const Value.absent(),
    required int position,
  }) : planId = Value(planId),
       topicId = Value(topicId),
       title = Value(title),
       category = Value(category),
       minutes = Value(minutes),
       level = Value(level),
       position = Value(position);
  static Insertable<PlanTopicRow> custom({
    Expression<int>? id,
    Expression<int>? planId,
    Expression<String>? topicId,
    Expression<String>? title,
    Expression<String>? category,
    Expression<int>? minutes,
    Expression<int>? level,
    Expression<String>? prerequisites,
    Expression<int>? position,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planId != null) 'plan_id': planId,
      if (topicId != null) 'topic_id': topicId,
      if (title != null) 'title': title,
      if (category != null) 'category': category,
      if (minutes != null) 'minutes': minutes,
      if (level != null) 'level': level,
      if (prerequisites != null) 'prerequisites': prerequisites,
      if (position != null) 'position': position,
    });
  }

  PlanTopicsCompanion copyWith({
    Value<int>? id,
    Value<int>? planId,
    Value<String>? topicId,
    Value<String>? title,
    Value<String>? category,
    Value<int>? minutes,
    Value<int>? level,
    Value<String>? prerequisites,
    Value<int>? position,
  }) {
    return PlanTopicsCompanion(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      topicId: topicId ?? this.topicId,
      title: title ?? this.title,
      category: category ?? this.category,
      minutes: minutes ?? this.minutes,
      level: level ?? this.level,
      prerequisites: prerequisites ?? this.prerequisites,
      position: position ?? this.position,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<int>(planId.value);
    }
    if (topicId.present) {
      map['topic_id'] = Variable<String>(topicId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (minutes.present) {
      map['minutes'] = Variable<int>(minutes.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (prerequisites.present) {
      map['prerequisites'] = Variable<String>(prerequisites.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanTopicsCompanion(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('topicId: $topicId, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('minutes: $minutes, ')
          ..write('level: $level, ')
          ..write('prerequisites: $prerequisites, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions
    with TableInfo<$SessionsTable, SessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<int> planId = GeneratedColumn<int>(
    'plan_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES plans (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _topicIdMeta = const VerificationMeta(
    'topicId',
  );
  @override
  late final GeneratedColumn<String> topicId = GeneratedColumn<String>(
    'topic_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _topicTitleMeta = const VerificationMeta(
    'topicTitle',
  );
  @override
  late final GeneratedColumn<String> topicTitle = GeneratedColumn<String>(
    'topic_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minutesMeta = const VerificationMeta(
    'minutes',
  );
  @override
  late final GeneratedColumn<int> minutes = GeneratedColumn<int>(
    'minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _partMeta = const VerificationMeta('part');
  @override
  late final GeneratedColumn<int> part = GeneratedColumn<int>(
    'part',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _totalPartsMeta = const VerificationMeta(
    'totalParts',
  );
  @override
  late final GeneratedColumn<int> totalParts = GeneratedColumn<int>(
    'total_parts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isDoneMeta = const VerificationMeta('isDone');
  @override
  late final GeneratedColumn<bool> isDone = GeneratedColumn<bool>(
    'is_done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    planId,
    topicId,
    topicTitle,
    category,
    date,
    minutes,
    kind,
    part,
    totalParts,
    isDone,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('topic_id')) {
      context.handle(
        _topicIdMeta,
        topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta),
      );
    } else if (isInserting) {
      context.missing(_topicIdMeta);
    }
    if (data.containsKey('topic_title')) {
      context.handle(
        _topicTitleMeta,
        topicTitle.isAcceptableOrUnknown(data['topic_title']!, _topicTitleMeta),
      );
    } else if (isInserting) {
      context.missing(_topicTitleMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('minutes')) {
      context.handle(
        _minutesMeta,
        minutes.isAcceptableOrUnknown(data['minutes']!, _minutesMeta),
      );
    } else if (isInserting) {
      context.missing(_minutesMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('part')) {
      context.handle(
        _partMeta,
        part.isAcceptableOrUnknown(data['part']!, _partMeta),
      );
    }
    if (data.containsKey('total_parts')) {
      context.handle(
        _totalPartsMeta,
        totalParts.isAcceptableOrUnknown(data['total_parts']!, _totalPartsMeta),
      );
    }
    if (data.containsKey('is_done')) {
      context.handle(
        _isDoneMeta,
        isDone.isAcceptableOrUnknown(data['is_done']!, _isDoneMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plan_id'],
      )!,
      topicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic_id'],
      )!,
      topicTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic_title'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      minutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minutes'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      part: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}part'],
      )!,
      totalParts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_parts'],
      )!,
      isDone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_done'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class SessionRow extends DataClass implements Insertable<SessionRow> {
  final int id;
  final int planId;
  final String topicId;
  final String topicTitle;
  final String category;
  final DateTime date;
  final int minutes;

  /// «study» или «review».
  final String kind;
  final int part;
  final int totalParts;
  final bool isDone;
  final DateTime? completedAt;
  const SessionRow({
    required this.id,
    required this.planId,
    required this.topicId,
    required this.topicTitle,
    required this.category,
    required this.date,
    required this.minutes,
    required this.kind,
    required this.part,
    required this.totalParts,
    required this.isDone,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['plan_id'] = Variable<int>(planId);
    map['topic_id'] = Variable<String>(topicId);
    map['topic_title'] = Variable<String>(topicTitle);
    map['category'] = Variable<String>(category);
    map['date'] = Variable<DateTime>(date);
    map['minutes'] = Variable<int>(minutes);
    map['kind'] = Variable<String>(kind);
    map['part'] = Variable<int>(part);
    map['total_parts'] = Variable<int>(totalParts);
    map['is_done'] = Variable<bool>(isDone);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      planId: Value(planId),
      topicId: Value(topicId),
      topicTitle: Value(topicTitle),
      category: Value(category),
      date: Value(date),
      minutes: Value(minutes),
      kind: Value(kind),
      part: Value(part),
      totalParts: Value(totalParts),
      isDone: Value(isDone),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory SessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionRow(
      id: serializer.fromJson<int>(json['id']),
      planId: serializer.fromJson<int>(json['planId']),
      topicId: serializer.fromJson<String>(json['topicId']),
      topicTitle: serializer.fromJson<String>(json['topicTitle']),
      category: serializer.fromJson<String>(json['category']),
      date: serializer.fromJson<DateTime>(json['date']),
      minutes: serializer.fromJson<int>(json['minutes']),
      kind: serializer.fromJson<String>(json['kind']),
      part: serializer.fromJson<int>(json['part']),
      totalParts: serializer.fromJson<int>(json['totalParts']),
      isDone: serializer.fromJson<bool>(json['isDone']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'planId': serializer.toJson<int>(planId),
      'topicId': serializer.toJson<String>(topicId),
      'topicTitle': serializer.toJson<String>(topicTitle),
      'category': serializer.toJson<String>(category),
      'date': serializer.toJson<DateTime>(date),
      'minutes': serializer.toJson<int>(minutes),
      'kind': serializer.toJson<String>(kind),
      'part': serializer.toJson<int>(part),
      'totalParts': serializer.toJson<int>(totalParts),
      'isDone': serializer.toJson<bool>(isDone),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  SessionRow copyWith({
    int? id,
    int? planId,
    String? topicId,
    String? topicTitle,
    String? category,
    DateTime? date,
    int? minutes,
    String? kind,
    int? part,
    int? totalParts,
    bool? isDone,
    Value<DateTime?> completedAt = const Value.absent(),
  }) => SessionRow(
    id: id ?? this.id,
    planId: planId ?? this.planId,
    topicId: topicId ?? this.topicId,
    topicTitle: topicTitle ?? this.topicTitle,
    category: category ?? this.category,
    date: date ?? this.date,
    minutes: minutes ?? this.minutes,
    kind: kind ?? this.kind,
    part: part ?? this.part,
    totalParts: totalParts ?? this.totalParts,
    isDone: isDone ?? this.isDone,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  SessionRow copyWithCompanion(SessionsCompanion data) {
    return SessionRow(
      id: data.id.present ? data.id.value : this.id,
      planId: data.planId.present ? data.planId.value : this.planId,
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
      topicTitle: data.topicTitle.present
          ? data.topicTitle.value
          : this.topicTitle,
      category: data.category.present ? data.category.value : this.category,
      date: data.date.present ? data.date.value : this.date,
      minutes: data.minutes.present ? data.minutes.value : this.minutes,
      kind: data.kind.present ? data.kind.value : this.kind,
      part: data.part.present ? data.part.value : this.part,
      totalParts: data.totalParts.present
          ? data.totalParts.value
          : this.totalParts,
      isDone: data.isDone.present ? data.isDone.value : this.isDone,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionRow(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('topicId: $topicId, ')
          ..write('topicTitle: $topicTitle, ')
          ..write('category: $category, ')
          ..write('date: $date, ')
          ..write('minutes: $minutes, ')
          ..write('kind: $kind, ')
          ..write('part: $part, ')
          ..write('totalParts: $totalParts, ')
          ..write('isDone: $isDone, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    planId,
    topicId,
    topicTitle,
    category,
    date,
    minutes,
    kind,
    part,
    totalParts,
    isDone,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionRow &&
          other.id == this.id &&
          other.planId == this.planId &&
          other.topicId == this.topicId &&
          other.topicTitle == this.topicTitle &&
          other.category == this.category &&
          other.date == this.date &&
          other.minutes == this.minutes &&
          other.kind == this.kind &&
          other.part == this.part &&
          other.totalParts == this.totalParts &&
          other.isDone == this.isDone &&
          other.completedAt == this.completedAt);
}

class SessionsCompanion extends UpdateCompanion<SessionRow> {
  final Value<int> id;
  final Value<int> planId;
  final Value<String> topicId;
  final Value<String> topicTitle;
  final Value<String> category;
  final Value<DateTime> date;
  final Value<int> minutes;
  final Value<String> kind;
  final Value<int> part;
  final Value<int> totalParts;
  final Value<bool> isDone;
  final Value<DateTime?> completedAt;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    this.topicId = const Value.absent(),
    this.topicTitle = const Value.absent(),
    this.category = const Value.absent(),
    this.date = const Value.absent(),
    this.minutes = const Value.absent(),
    this.kind = const Value.absent(),
    this.part = const Value.absent(),
    this.totalParts = const Value.absent(),
    this.isDone = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  SessionsCompanion.insert({
    this.id = const Value.absent(),
    required int planId,
    required String topicId,
    required String topicTitle,
    required String category,
    required DateTime date,
    required int minutes,
    required String kind,
    this.part = const Value.absent(),
    this.totalParts = const Value.absent(),
    this.isDone = const Value.absent(),
    this.completedAt = const Value.absent(),
  }) : planId = Value(planId),
       topicId = Value(topicId),
       topicTitle = Value(topicTitle),
       category = Value(category),
       date = Value(date),
       minutes = Value(minutes),
       kind = Value(kind);
  static Insertable<SessionRow> custom({
    Expression<int>? id,
    Expression<int>? planId,
    Expression<String>? topicId,
    Expression<String>? topicTitle,
    Expression<String>? category,
    Expression<DateTime>? date,
    Expression<int>? minutes,
    Expression<String>? kind,
    Expression<int>? part,
    Expression<int>? totalParts,
    Expression<bool>? isDone,
    Expression<DateTime>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planId != null) 'plan_id': planId,
      if (topicId != null) 'topic_id': topicId,
      if (topicTitle != null) 'topic_title': topicTitle,
      if (category != null) 'category': category,
      if (date != null) 'date': date,
      if (minutes != null) 'minutes': minutes,
      if (kind != null) 'kind': kind,
      if (part != null) 'part': part,
      if (totalParts != null) 'total_parts': totalParts,
      if (isDone != null) 'is_done': isDone,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  SessionsCompanion copyWith({
    Value<int>? id,
    Value<int>? planId,
    Value<String>? topicId,
    Value<String>? topicTitle,
    Value<String>? category,
    Value<DateTime>? date,
    Value<int>? minutes,
    Value<String>? kind,
    Value<int>? part,
    Value<int>? totalParts,
    Value<bool>? isDone,
    Value<DateTime?>? completedAt,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      topicId: topicId ?? this.topicId,
      topicTitle: topicTitle ?? this.topicTitle,
      category: category ?? this.category,
      date: date ?? this.date,
      minutes: minutes ?? this.minutes,
      kind: kind ?? this.kind,
      part: part ?? this.part,
      totalParts: totalParts ?? this.totalParts,
      isDone: isDone ?? this.isDone,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<int>(planId.value);
    }
    if (topicId.present) {
      map['topic_id'] = Variable<String>(topicId.value);
    }
    if (topicTitle.present) {
      map['topic_title'] = Variable<String>(topicTitle.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (minutes.present) {
      map['minutes'] = Variable<int>(minutes.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (part.present) {
      map['part'] = Variable<int>(part.value);
    }
    if (totalParts.present) {
      map['total_parts'] = Variable<int>(totalParts.value);
    }
    if (isDone.present) {
      map['is_done'] = Variable<bool>(isDone.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('topicId: $topicId, ')
          ..write('topicTitle: $topicTitle, ')
          ..write('category: $category, ')
          ..write('date: $date, ')
          ..write('minutes: $minutes, ')
          ..write('kind: $kind, ')
          ..write('part: $part, ')
          ..write('totalParts: $totalParts, ')
          ..write('isDone: $isDone, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

class $CustomTopicsTable extends CustomTopics
    with TableInfo<$CustomTopicsTable, CustomTopicRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomTopicsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _directionIdMeta = const VerificationMeta(
    'directionId',
  );
  @override
  late final GeneratedColumn<String> directionId = GeneratedColumn<String>(
    'direction_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _minutesMeta = const VerificationMeta(
    'minutes',
  );
  @override
  late final GeneratedColumn<int> minutes = GeneratedColumn<int>(
    'minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _prerequisitesMeta = const VerificationMeta(
    'prerequisites',
  );
  @override
  late final GeneratedColumn<String> prerequisites = GeneratedColumn<String>(
    'prerequisites',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    directionId,
    title,
    description,
    minutes,
    category,
    prerequisites,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_topics';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomTopicRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('direction_id')) {
      context.handle(
        _directionIdMeta,
        directionId.isAcceptableOrUnknown(
          data['direction_id']!,
          _directionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_directionIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('minutes')) {
      context.handle(
        _minutesMeta,
        minutes.isAcceptableOrUnknown(data['minutes']!, _minutesMeta),
      );
    } else if (isInserting) {
      context.missing(_minutesMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('prerequisites')) {
      context.handle(
        _prerequisitesMeta,
        prerequisites.isAcceptableOrUnknown(
          data['prerequisites']!,
          _prerequisitesMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomTopicRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomTopicRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      directionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      minutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minutes'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      prerequisites: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prerequisites'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CustomTopicsTable createAlias(String alias) {
    return $CustomTopicsTable(attachedDatabase, alias);
  }
}

class CustomTopicRow extends DataClass implements Insertable<CustomTopicRow> {
  final int id;
  final int userId;
  final String directionId;
  final String title;
  final String description;
  final int minutes;
  final String category;
  final String prerequisites;
  final DateTime createdAt;
  const CustomTopicRow({
    required this.id,
    required this.userId,
    required this.directionId,
    required this.title,
    required this.description,
    required this.minutes,
    required this.category,
    required this.prerequisites,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<int>(userId);
    map['direction_id'] = Variable<String>(directionId);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['minutes'] = Variable<int>(minutes);
    map['category'] = Variable<String>(category);
    map['prerequisites'] = Variable<String>(prerequisites);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CustomTopicsCompanion toCompanion(bool nullToAbsent) {
    return CustomTopicsCompanion(
      id: Value(id),
      userId: Value(userId),
      directionId: Value(directionId),
      title: Value(title),
      description: Value(description),
      minutes: Value(minutes),
      category: Value(category),
      prerequisites: Value(prerequisites),
      createdAt: Value(createdAt),
    );
  }

  factory CustomTopicRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomTopicRow(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      directionId: serializer.fromJson<String>(json['directionId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      minutes: serializer.fromJson<int>(json['minutes']),
      category: serializer.fromJson<String>(json['category']),
      prerequisites: serializer.fromJson<String>(json['prerequisites']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int>(userId),
      'directionId': serializer.toJson<String>(directionId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'minutes': serializer.toJson<int>(minutes),
      'category': serializer.toJson<String>(category),
      'prerequisites': serializer.toJson<String>(prerequisites),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CustomTopicRow copyWith({
    int? id,
    int? userId,
    String? directionId,
    String? title,
    String? description,
    int? minutes,
    String? category,
    String? prerequisites,
    DateTime? createdAt,
  }) => CustomTopicRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    directionId: directionId ?? this.directionId,
    title: title ?? this.title,
    description: description ?? this.description,
    minutes: minutes ?? this.minutes,
    category: category ?? this.category,
    prerequisites: prerequisites ?? this.prerequisites,
    createdAt: createdAt ?? this.createdAt,
  );
  CustomTopicRow copyWithCompanion(CustomTopicsCompanion data) {
    return CustomTopicRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      directionId: data.directionId.present
          ? data.directionId.value
          : this.directionId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      minutes: data.minutes.present ? data.minutes.value : this.minutes,
      category: data.category.present ? data.category.value : this.category,
      prerequisites: data.prerequisites.present
          ? data.prerequisites.value
          : this.prerequisites,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomTopicRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('directionId: $directionId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('minutes: $minutes, ')
          ..write('category: $category, ')
          ..write('prerequisites: $prerequisites, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    directionId,
    title,
    description,
    minutes,
    category,
    prerequisites,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomTopicRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.directionId == this.directionId &&
          other.title == this.title &&
          other.description == this.description &&
          other.minutes == this.minutes &&
          other.category == this.category &&
          other.prerequisites == this.prerequisites &&
          other.createdAt == this.createdAt);
}

class CustomTopicsCompanion extends UpdateCompanion<CustomTopicRow> {
  final Value<int> id;
  final Value<int> userId;
  final Value<String> directionId;
  final Value<String> title;
  final Value<String> description;
  final Value<int> minutes;
  final Value<String> category;
  final Value<String> prerequisites;
  final Value<DateTime> createdAt;
  const CustomTopicsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.directionId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.minutes = const Value.absent(),
    this.category = const Value.absent(),
    this.prerequisites = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CustomTopicsCompanion.insert({
    this.id = const Value.absent(),
    required int userId,
    required String directionId,
    required String title,
    this.description = const Value.absent(),
    required int minutes,
    required String category,
    this.prerequisites = const Value.absent(),
    required DateTime createdAt,
  }) : userId = Value(userId),
       directionId = Value(directionId),
       title = Value(title),
       minutes = Value(minutes),
       category = Value(category),
       createdAt = Value(createdAt);
  static Insertable<CustomTopicRow> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<String>? directionId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<int>? minutes,
    Expression<String>? category,
    Expression<String>? prerequisites,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (directionId != null) 'direction_id': directionId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (minutes != null) 'minutes': minutes,
      if (category != null) 'category': category,
      if (prerequisites != null) 'prerequisites': prerequisites,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CustomTopicsCompanion copyWith({
    Value<int>? id,
    Value<int>? userId,
    Value<String>? directionId,
    Value<String>? title,
    Value<String>? description,
    Value<int>? minutes,
    Value<String>? category,
    Value<String>? prerequisites,
    Value<DateTime>? createdAt,
  }) {
    return CustomTopicsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      directionId: directionId ?? this.directionId,
      title: title ?? this.title,
      description: description ?? this.description,
      minutes: minutes ?? this.minutes,
      category: category ?? this.category,
      prerequisites: prerequisites ?? this.prerequisites,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (directionId.present) {
      map['direction_id'] = Variable<String>(directionId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (minutes.present) {
      map['minutes'] = Variable<int>(minutes.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (prerequisites.present) {
      map['prerequisites'] = Variable<String>(prerequisites.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomTopicsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('directionId: $directionId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('minutes: $minutes, ')
          ..write('category: $category, ')
          ..write('prerequisites: $prerequisites, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $NotesTable extends Notes with TableInfo<$NotesTable, NoteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _topicIdMeta = const VerificationMeta(
    'topicId',
  );
  @override
  late final GeneratedColumn<String> topicId = GeneratedColumn<String>(
    'topic_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _topicTitleMeta = const VerificationMeta(
    'topicTitle',
  );
  @override
  late final GeneratedColumn<String> topicTitle = GeneratedColumn<String>(
    'topic_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    title,
    body,
    topicId,
    topicTitle,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<NoteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('topic_id')) {
      context.handle(
        _topicIdMeta,
        topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta),
      );
    }
    if (data.containsKey('topic_title')) {
      context.handle(
        _topicTitleMeta,
        topicTitle.isAcceptableOrUnknown(data['topic_title']!, _topicTitleMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NoteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      topicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic_id'],
      ),
      topicTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic_title'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }
}

class NoteRow extends DataClass implements Insertable<NoteRow> {
  final int id;
  final int userId;
  final String title;
  final String body;
  final String? topicId;
  final String? topicTitle;
  final DateTime createdAt;
  final DateTime updatedAt;
  const NoteRow({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.topicId,
    this.topicTitle,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<int>(userId);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    if (!nullToAbsent || topicId != null) {
      map['topic_id'] = Variable<String>(topicId);
    }
    if (!nullToAbsent || topicTitle != null) {
      map['topic_title'] = Variable<String>(topicTitle);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      id: Value(id),
      userId: Value(userId),
      title: Value(title),
      body: Value(body),
      topicId: topicId == null && nullToAbsent
          ? const Value.absent()
          : Value(topicId),
      topicTitle: topicTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(topicTitle),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory NoteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteRow(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      topicId: serializer.fromJson<String?>(json['topicId']),
      topicTitle: serializer.fromJson<String?>(json['topicTitle']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int>(userId),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'topicId': serializer.toJson<String?>(topicId),
      'topicTitle': serializer.toJson<String?>(topicTitle),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  NoteRow copyWith({
    int? id,
    int? userId,
    String? title,
    String? body,
    Value<String?> topicId = const Value.absent(),
    Value<String?> topicTitle = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => NoteRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    title: title ?? this.title,
    body: body ?? this.body,
    topicId: topicId.present ? topicId.value : this.topicId,
    topicTitle: topicTitle.present ? topicTitle.value : this.topicTitle,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  NoteRow copyWithCompanion(NotesCompanion data) {
    return NoteRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
      topicTitle: data.topicTitle.present
          ? data.topicTitle.value
          : this.topicTitle,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('topicId: $topicId, ')
          ..write('topicTitle: $topicTitle, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    title,
    body,
    topicId,
    topicTitle,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.title == this.title &&
          other.body == this.body &&
          other.topicId == this.topicId &&
          other.topicTitle == this.topicTitle &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class NotesCompanion extends UpdateCompanion<NoteRow> {
  final Value<int> id;
  final Value<int> userId;
  final Value<String> title;
  final Value<String> body;
  final Value<String?> topicId;
  final Value<String?> topicTitle;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.topicId = const Value.absent(),
    this.topicTitle = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  NotesCompanion.insert({
    this.id = const Value.absent(),
    required int userId,
    required String title,
    required String body,
    this.topicId = const Value.absent(),
    this.topicTitle = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : userId = Value(userId),
       title = Value(title),
       body = Value(body),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<NoteRow> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<String>? title,
    Expression<String>? body,
    Expression<String>? topicId,
    Expression<String>? topicTitle,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (topicId != null) 'topic_id': topicId,
      if (topicTitle != null) 'topic_title': topicTitle,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  NotesCompanion copyWith({
    Value<int>? id,
    Value<int>? userId,
    Value<String>? title,
    Value<String>? body,
    Value<String?>? topicId,
    Value<String?>? topicTitle,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return NotesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      topicId: topicId ?? this.topicId,
      topicTitle: topicTitle ?? this.topicTitle,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (topicId.present) {
      map['topic_id'] = Variable<String>(topicId.value);
    }
    if (topicTitle.present) {
      map['topic_title'] = Variable<String>(topicTitle.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('topicId: $topicId, ')
          ..write('topicTitle: $topicTitle, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $FavoritesTable extends Favorites
    with TableInfo<$FavoritesTable, FavoriteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _topicIdMeta = const VerificationMeta(
    'topicId',
  );
  @override
  late final GeneratedColumn<String> topicId = GeneratedColumn<String>(
    'topic_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [userId, topicId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorites';
  @override
  VerificationContext validateIntegrity(
    Insertable<FavoriteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('topic_id')) {
      context.handle(
        _topicIdMeta,
        topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta),
      );
    } else if (isInserting) {
      context.missing(_topicIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, topicId};
  @override
  FavoriteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoriteRow(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      topicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FavoritesTable createAlias(String alias) {
    return $FavoritesTable(attachedDatabase, alias);
  }
}

class FavoriteRow extends DataClass implements Insertable<FavoriteRow> {
  final int userId;
  final String topicId;
  final DateTime createdAt;
  const FavoriteRow({
    required this.userId,
    required this.topicId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<int>(userId);
    map['topic_id'] = Variable<String>(topicId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FavoritesCompanion toCompanion(bool nullToAbsent) {
    return FavoritesCompanion(
      userId: Value(userId),
      topicId: Value(topicId),
      createdAt: Value(createdAt),
    );
  }

  factory FavoriteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoriteRow(
      userId: serializer.fromJson<int>(json['userId']),
      topicId: serializer.fromJson<String>(json['topicId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<int>(userId),
      'topicId': serializer.toJson<String>(topicId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  FavoriteRow copyWith({int? userId, String? topicId, DateTime? createdAt}) =>
      FavoriteRow(
        userId: userId ?? this.userId,
        topicId: topicId ?? this.topicId,
        createdAt: createdAt ?? this.createdAt,
      );
  FavoriteRow copyWithCompanion(FavoritesCompanion data) {
    return FavoriteRow(
      userId: data.userId.present ? data.userId.value : this.userId,
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteRow(')
          ..write('userId: $userId, ')
          ..write('topicId: $topicId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, topicId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoriteRow &&
          other.userId == this.userId &&
          other.topicId == this.topicId &&
          other.createdAt == this.createdAt);
}

class FavoritesCompanion extends UpdateCompanion<FavoriteRow> {
  final Value<int> userId;
  final Value<String> topicId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const FavoritesCompanion({
    this.userId = const Value.absent(),
    this.topicId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FavoritesCompanion.insert({
    required int userId,
    required String topicId,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       topicId = Value(topicId),
       createdAt = Value(createdAt);
  static Insertable<FavoriteRow> custom({
    Expression<int>? userId,
    Expression<String>? topicId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (topicId != null) 'topic_id': topicId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FavoritesCompanion copyWith({
    Value<int>? userId,
    Value<String>? topicId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return FavoritesCompanion(
      userId: userId ?? this.userId,
      topicId: topicId ?? this.topicId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (topicId.present) {
      map['topic_id'] = Variable<String>(topicId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoritesCompanion(')
          ..write('userId: $userId, ')
          ..write('topicId: $topicId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PomodoroLogsTable extends PomodoroLogs
    with TableInfo<$PomodoroLogsTable, PomodoroLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PomodoroLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _minutesMeta = const VerificationMeta(
    'minutes',
  );
  @override
  late final GeneratedColumn<int> minutes = GeneratedColumn<int>(
    'minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _topicTitleMeta = const VerificationMeta(
    'topicTitle',
  );
  @override
  late final GeneratedColumn<String> topicTitle = GeneratedColumn<String>(
    'topic_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    minutes,
    topicTitle,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pomodoro_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<PomodoroLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('minutes')) {
      context.handle(
        _minutesMeta,
        minutes.isAcceptableOrUnknown(data['minutes']!, _minutesMeta),
      );
    } else if (isInserting) {
      context.missing(_minutesMeta);
    }
    if (data.containsKey('topic_title')) {
      context.handle(
        _topicTitleMeta,
        topicTitle.isAcceptableOrUnknown(data['topic_title']!, _topicTitleMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PomodoroLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PomodoroLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      minutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minutes'],
      )!,
      topicTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic_title'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
    );
  }

  @override
  $PomodoroLogsTable createAlias(String alias) {
    return $PomodoroLogsTable(attachedDatabase, alias);
  }
}

class PomodoroLogRow extends DataClass implements Insertable<PomodoroLogRow> {
  final int id;
  final int userId;
  final int minutes;
  final String? topicTitle;
  final DateTime completedAt;
  const PomodoroLogRow({
    required this.id,
    required this.userId,
    required this.minutes,
    this.topicTitle,
    required this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<int>(userId);
    map['minutes'] = Variable<int>(minutes);
    if (!nullToAbsent || topicTitle != null) {
      map['topic_title'] = Variable<String>(topicTitle);
    }
    map['completed_at'] = Variable<DateTime>(completedAt);
    return map;
  }

  PomodoroLogsCompanion toCompanion(bool nullToAbsent) {
    return PomodoroLogsCompanion(
      id: Value(id),
      userId: Value(userId),
      minutes: Value(minutes),
      topicTitle: topicTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(topicTitle),
      completedAt: Value(completedAt),
    );
  }

  factory PomodoroLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PomodoroLogRow(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      minutes: serializer.fromJson<int>(json['minutes']),
      topicTitle: serializer.fromJson<String?>(json['topicTitle']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int>(userId),
      'minutes': serializer.toJson<int>(minutes),
      'topicTitle': serializer.toJson<String?>(topicTitle),
      'completedAt': serializer.toJson<DateTime>(completedAt),
    };
  }

  PomodoroLogRow copyWith({
    int? id,
    int? userId,
    int? minutes,
    Value<String?> topicTitle = const Value.absent(),
    DateTime? completedAt,
  }) => PomodoroLogRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    minutes: minutes ?? this.minutes,
    topicTitle: topicTitle.present ? topicTitle.value : this.topicTitle,
    completedAt: completedAt ?? this.completedAt,
  );
  PomodoroLogRow copyWithCompanion(PomodoroLogsCompanion data) {
    return PomodoroLogRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      minutes: data.minutes.present ? data.minutes.value : this.minutes,
      topicTitle: data.topicTitle.present
          ? data.topicTitle.value
          : this.topicTitle,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PomodoroLogRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('minutes: $minutes, ')
          ..write('topicTitle: $topicTitle, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, minutes, topicTitle, completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PomodoroLogRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.minutes == this.minutes &&
          other.topicTitle == this.topicTitle &&
          other.completedAt == this.completedAt);
}

class PomodoroLogsCompanion extends UpdateCompanion<PomodoroLogRow> {
  final Value<int> id;
  final Value<int> userId;
  final Value<int> minutes;
  final Value<String?> topicTitle;
  final Value<DateTime> completedAt;
  const PomodoroLogsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.minutes = const Value.absent(),
    this.topicTitle = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  PomodoroLogsCompanion.insert({
    this.id = const Value.absent(),
    required int userId,
    required int minutes,
    this.topicTitle = const Value.absent(),
    required DateTime completedAt,
  }) : userId = Value(userId),
       minutes = Value(minutes),
       completedAt = Value(completedAt);
  static Insertable<PomodoroLogRow> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<int>? minutes,
    Expression<String>? topicTitle,
    Expression<DateTime>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (minutes != null) 'minutes': minutes,
      if (topicTitle != null) 'topic_title': topicTitle,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  PomodoroLogsCompanion copyWith({
    Value<int>? id,
    Value<int>? userId,
    Value<int>? minutes,
    Value<String?>? topicTitle,
    Value<DateTime>? completedAt,
  }) {
    return PomodoroLogsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      minutes: minutes ?? this.minutes,
      topicTitle: topicTitle ?? this.topicTitle,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (minutes.present) {
      map['minutes'] = Variable<int>(minutes.value);
    }
    if (topicTitle.present) {
      map['topic_title'] = Variable<String>(topicTitle.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PomodoroLogsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('minutes: $minutes, ')
          ..write('topicTitle: $topicTitle, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $PlansTable plans = $PlansTable(this);
  late final $PlanTopicsTable planTopics = $PlanTopicsTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $CustomTopicsTable customTopics = $CustomTopicsTable(this);
  late final $NotesTable notes = $NotesTable(this);
  late final $FavoritesTable favorites = $FavoritesTable(this);
  late final $PomodoroLogsTable pomodoroLogs = $PomodoroLogsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    users,
    plans,
    planTopics,
    sessions,
    customTopics,
    notes,
    favorites,
    pomodoroLogs,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('plans', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'plans',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('plan_topics', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'plans',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('sessions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('custom_topics', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('notes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('favorites', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('pomodoro_logs', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$UsersTableCreateCompanionBuilder = UsersCompanion Function({
  Value<int> id,
  required String name,
  required String email,
  required String passwordHash,
  required String salt,
  required int avatarColor,
  Value<bool> reminderEnabled,
  Value<int> reminderHour,
  Value<int> reminderMinute,
  required DateTime createdAt,
});
typedef $$UsersTableUpdateCompanionBuilder = UsersCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> email,
  Value<String> passwordHash,
  Value<String> salt,
  Value<int> avatarColor,
  Value<bool> reminderEnabled,
  Value<int> reminderHour,
  Value<int> reminderMinute,
  Value<DateTime> createdAt,
});

final class $$UsersTableReferences
    extends BaseReferences<_$AppDatabase, $UsersTable, UserRow> {
  $$UsersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PlansTable, List<PlanRow>> _plansRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.plans,
    aliasName: 'users__id__plans__user_id',
  );

  $$PlansTableProcessedTableManager get plansRefs {
    final manager = $$PlansTableTableManager(
      $_db,
      $_db.plans,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_plansRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CustomTopicsTable, List<CustomTopicRow>>
  _customTopicsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.customTopics,
    aliasName: 'users__id__custom_topics__user_id',
  );

  $$CustomTopicsTableProcessedTableManager get customTopicsRefs {
    final manager = $$CustomTopicsTableTableManager(
      $_db,
      $_db.customTopics,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_customTopicsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$NotesTable, List<NoteRow>> _notesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.notes,
    aliasName: 'users__id__notes__user_id',
  );

  $$NotesTableProcessedTableManager get notesRefs {
    final manager = $$NotesTableTableManager(
      $_db,
      $_db.notes,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_notesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FavoritesTable, List<FavoriteRow>>
  _favoritesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.favorites,
    aliasName: 'users__id__favorites__user_id',
  );

  $$FavoritesTableProcessedTableManager get favoritesRefs {
    final manager = $$FavoritesTableTableManager(
      $_db,
      $_db.favorites,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_favoritesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PomodoroLogsTable, List<PomodoroLogRow>>
  _pomodoroLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.pomodoroLogs,
    aliasName: 'users__id__pomodoro_logs__user_id',
  );

  $$PomodoroLogsTableProcessedTableManager get pomodoroLogsRefs {
    final manager = $$PomodoroLogsTableTableManager(
      $_db,
      $_db.pomodoroLogs,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_pomodoroLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get salt => $composableBuilder(
    column: $table.salt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get avatarColor => $composableBuilder(
    column: $table.avatarColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get reminderEnabled => $composableBuilder(
    column: $table.reminderEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderHour => $composableBuilder(
    column: $table.reminderHour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderMinute => $composableBuilder(
    column: $table.reminderMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> plansRefs(
    Expression<bool> Function($$PlansTableFilterComposer f) f,
  ) {
    final $$PlansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.plans,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlansTableFilterComposer(
            $db: $db,
            $table: $db.plans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> customTopicsRefs(
    Expression<bool> Function($$CustomTopicsTableFilterComposer f) f,
  ) {
    final $$CustomTopicsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.customTopics,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomTopicsTableFilterComposer(
            $db: $db,
            $table: $db.customTopics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> notesRefs(
    Expression<bool> Function($$NotesTableFilterComposer f) f,
  ) {
    final $$NotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotesTableFilterComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> favoritesRefs(
    Expression<bool> Function($$FavoritesTableFilterComposer f) f,
  ) {
    final $$FavoritesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.favorites,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoritesTableFilterComposer(
            $db: $db,
            $table: $db.favorites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> pomodoroLogsRefs(
    Expression<bool> Function($$PomodoroLogsTableFilterComposer f) f,
  ) {
    final $$PomodoroLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pomodoroLogs,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PomodoroLogsTableFilterComposer(
            $db: $db,
            $table: $db.pomodoroLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get salt => $composableBuilder(
    column: $table.salt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get avatarColor => $composableBuilder(
    column: $table.avatarColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get reminderEnabled => $composableBuilder(
    column: $table.reminderEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderHour => $composableBuilder(
    column: $table.reminderHour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderMinute => $composableBuilder(
    column: $table.reminderMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get salt =>
      $composableBuilder(column: $table.salt, builder: (column) => column);

  GeneratedColumn<int> get avatarColor => $composableBuilder(
    column: $table.avatarColor,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get reminderEnabled => $composableBuilder(
    column: $table.reminderEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderHour => $composableBuilder(
    column: $table.reminderHour,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderMinute => $composableBuilder(
    column: $table.reminderMinute,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> plansRefs<T extends Object>(
    Expression<T> Function($$PlansTableAnnotationComposer a) f,
  ) {
    final $$PlansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.plans,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlansTableAnnotationComposer(
            $db: $db,
            $table: $db.plans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> customTopicsRefs<T extends Object>(
    Expression<T> Function($$CustomTopicsTableAnnotationComposer a) f,
  ) {
    final $$CustomTopicsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.customTopics,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomTopicsTableAnnotationComposer(
            $db: $db,
            $table: $db.customTopics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> notesRefs<T extends Object>(
    Expression<T> Function($$NotesTableAnnotationComposer a) f,
  ) {
    final $$NotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotesTableAnnotationComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> favoritesRefs<T extends Object>(
    Expression<T> Function($$FavoritesTableAnnotationComposer a) f,
  ) {
    final $$FavoritesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.favorites,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoritesTableAnnotationComposer(
            $db: $db,
            $table: $db.favorites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> pomodoroLogsRefs<T extends Object>(
    Expression<T> Function($$PomodoroLogsTableAnnotationComposer a) f,
  ) {
    final $$PomodoroLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pomodoroLogs,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PomodoroLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.pomodoroLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsersTable,
          UserRow,
          $$UsersTableFilterComposer,
          $$UsersTableOrderingComposer,
          $$UsersTableAnnotationComposer,
          $$UsersTableCreateCompanionBuilder,
          $$UsersTableUpdateCompanionBuilder,
          (UserRow, $$UsersTableReferences),
          UserRow,
          PrefetchHooks Function({
            bool plansRefs,
            bool customTopicsRefs,
            bool notesRefs,
            bool favoritesRefs,
            bool pomodoroLogsRefs,
          })
        > {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> passwordHash = const Value.absent(),
                Value<String> salt = const Value.absent(),
                Value<int> avatarColor = const Value.absent(),
                Value<bool> reminderEnabled = const Value.absent(),
                Value<int> reminderHour = const Value.absent(),
                Value<int> reminderMinute = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                name: name,
                email: email,
                passwordHash: passwordHash,
                salt: salt,
                avatarColor: avatarColor,
                reminderEnabled: reminderEnabled,
                reminderHour: reminderHour,
                reminderMinute: reminderMinute,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String email,
                required String passwordHash,
                required String salt,
                required int avatarColor,
                Value<bool> reminderEnabled = const Value.absent(),
                Value<int> reminderHour = const Value.absent(),
                Value<int> reminderMinute = const Value.absent(),
                required DateTime createdAt,
              }) => UsersCompanion.insert(
                id: id,
                name: name,
                email: email,
                passwordHash: passwordHash,
                salt: salt,
                avatarColor: avatarColor,
                reminderEnabled: reminderEnabled,
                reminderHour: reminderHour,
                reminderMinute: reminderMinute,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UsersTable, UserRow>(table),
                  $$UsersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                plansRefs = false,
                customTopicsRefs = false,
                notesRefs = false,
                favoritesRefs = false,
                pomodoroLogsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (plansRefs) db.plans,
                    if (customTopicsRefs) db.customTopics,
                    if (notesRefs) db.notes,
                    if (favoritesRefs) db.favorites,
                    if (pomodoroLogsRefs) db.pomodoroLogs,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (plansRefs)
                        await $_getPrefetchedData<
                          UserRow,
                          $UsersTable,
                          PlanRow
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableReferences
                              ._plansRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableReferences(db, table, p0).plansRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (customTopicsRefs)
                        await $_getPrefetchedData<
                          UserRow,
                          $UsersTable,
                          CustomTopicRow
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableReferences
                              ._customTopicsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableReferences(
                                db,
                                table,
                                p0,
                              ).customTopicsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (notesRefs)
                        await $_getPrefetchedData<
                          UserRow,
                          $UsersTable,
                          NoteRow
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableReferences
                              ._notesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableReferences(db, table, p0).notesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (favoritesRefs)
                        await $_getPrefetchedData<
                          UserRow,
                          $UsersTable,
                          FavoriteRow
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableReferences
                              ._favoritesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableReferences(
                                db,
                                table,
                                p0,
                              ).favoritesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (pomodoroLogsRefs)
                        await $_getPrefetchedData<
                          UserRow,
                          $UsersTable,
                          PomodoroLogRow
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableReferences
                              ._pomodoroLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableReferences(
                                db,
                                table,
                                p0,
                              ).pomodoroLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$UsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsersTable,
      UserRow,
      $$UsersTableFilterComposer,
      $$UsersTableOrderingComposer,
      $$UsersTableAnnotationComposer,
      $$UsersTableCreateCompanionBuilder,
      $$UsersTableUpdateCompanionBuilder,
      (UserRow, $$UsersTableReferences),
      UserRow,
      PrefetchHooks Function({
        bool plansRefs,
        bool customTopicsRefs,
        bool notesRefs,
        bool favoritesRefs,
        bool pomodoroLogsRefs,
      })
    >;
typedef $$PlansTableCreateCompanionBuilder = PlansCompanion Function({
  Value<int> id,
  required int userId,
  required String directionId,
  required String title,
  required double hoursPerWeek,
  required String studyDays,
  required DateTime startDate,
  Value<DateTime?> deadline,
  Value<String> knownTopicIds,
  Value<bool> isActive,
  required DateTime createdAt,
});
typedef $$PlansTableUpdateCompanionBuilder = PlansCompanion Function({
  Value<int> id,
  Value<int> userId,
  Value<String> directionId,
  Value<String> title,
  Value<double> hoursPerWeek,
  Value<String> studyDays,
  Value<DateTime> startDate,
  Value<DateTime?> deadline,
  Value<String> knownTopicIds,
  Value<bool> isActive,
  Value<DateTime> createdAt,
});

final class $$PlansTableReferences
    extends BaseReferences<_$AppDatabase, $PlansTable, PlanRow> {
  $$PlansTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) =>
      db.users.createAlias('plans__user_id__users__id');

  $$UsersTableProcessedTableManager get userId {
    final $_column = $_itemColumn<int>('user_id')!;

    final manager = $$UsersTableTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PlanTopicsTable, List<PlanTopicRow>>
  _planTopicsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.planTopics,
    aliasName: 'plans__id__plan_topics__plan_id',
  );

  $$PlanTopicsTableProcessedTableManager get planTopicsRefs {
    final manager = $$PlanTopicsTableTableManager(
      $_db,
      $_db.planTopics,
    ).filter((f) => f.planId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_planTopicsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SessionsTable, List<SessionRow>>
  _sessionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.sessions,
    aliasName: 'plans__id__sessions__plan_id',
  );

  $$SessionsTableProcessedTableManager get sessionsRefs {
    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.planId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_sessionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlansTableFilterComposer extends Composer<_$AppDatabase, $PlansTable> {
  $$PlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get directionId => $composableBuilder(
    column: $table.directionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get hoursPerWeek => $composableBuilder(
    column: $table.hoursPerWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get studyDays => $composableBuilder(
    column: $table.studyDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deadline => $composableBuilder(
    column: $table.deadline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get knownTopicIds => $composableBuilder(
    column: $table.knownTopicIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> planTopicsRefs(
    Expression<bool> Function($$PlanTopicsTableFilterComposer f) f,
  ) {
    final $$PlanTopicsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.planTopics,
      getReferencedColumn: (t) => t.planId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlanTopicsTableFilterComposer(
            $db: $db,
            $table: $db.planTopics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> sessionsRefs(
    Expression<bool> Function($$SessionsTableFilterComposer f) f,
  ) {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.planId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlansTableOrderingComposer
    extends Composer<_$AppDatabase, $PlansTable> {
  $$PlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get directionId => $composableBuilder(
    column: $table.directionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get hoursPerWeek => $composableBuilder(
    column: $table.hoursPerWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get studyDays => $composableBuilder(
    column: $table.studyDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deadline => $composableBuilder(
    column: $table.deadline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get knownTopicIds => $composableBuilder(
    column: $table.knownTopicIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlansTable> {
  $$PlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get directionId => $composableBuilder(
    column: $table.directionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<double> get hoursPerWeek => $composableBuilder(
    column: $table.hoursPerWeek,
    builder: (column) => column,
  );

  GeneratedColumn<String> get studyDays =>
      $composableBuilder(column: $table.studyDays, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get deadline =>
      $composableBuilder(column: $table.deadline, builder: (column) => column);

  GeneratedColumn<String> get knownTopicIds => $composableBuilder(
    column: $table.knownTopicIds,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> planTopicsRefs<T extends Object>(
    Expression<T> Function($$PlanTopicsTableAnnotationComposer a) f,
  ) {
    final $$PlanTopicsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.planTopics,
      getReferencedColumn: (t) => t.planId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlanTopicsTableAnnotationComposer(
            $db: $db,
            $table: $db.planTopics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> sessionsRefs<T extends Object>(
    Expression<T> Function($$SessionsTableAnnotationComposer a) f,
  ) {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.planId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlansTable,
          PlanRow,
          $$PlansTableFilterComposer,
          $$PlansTableOrderingComposer,
          $$PlansTableAnnotationComposer,
          $$PlansTableCreateCompanionBuilder,
          $$PlansTableUpdateCompanionBuilder,
          (PlanRow, $$PlansTableReferences),
          PlanRow,
          PrefetchHooks Function({
            bool userId,
            bool planTopicsRefs,
            bool sessionsRefs,
          })
        > {
  $$PlansTableTableManager(_$AppDatabase db, $PlansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<String> directionId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<double> hoursPerWeek = const Value.absent(),
                Value<String> studyDays = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<DateTime?> deadline = const Value.absent(),
                Value<String> knownTopicIds = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PlansCompanion(
                id: id,
                userId: userId,
                directionId: directionId,
                title: title,
                hoursPerWeek: hoursPerWeek,
                studyDays: studyDays,
                startDate: startDate,
                deadline: deadline,
                knownTopicIds: knownTopicIds,
                isActive: isActive,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int userId,
                required String directionId,
                required String title,
                required double hoursPerWeek,
                required String studyDays,
                required DateTime startDate,
                Value<DateTime?> deadline = const Value.absent(),
                Value<String> knownTopicIds = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required DateTime createdAt,
              }) => PlansCompanion.insert(
                id: id,
                userId: userId,
                directionId: directionId,
                title: title,
                hoursPerWeek: hoursPerWeek,
                studyDays: studyDays,
                startDate: startDate,
                deadline: deadline,
                knownTopicIds: knownTopicIds,
                isActive: isActive,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlansTable, PlanRow>(table),
                  $$PlansTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({userId = false, planTopicsRefs = false, sessionsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (planTopicsRefs) db.planTopics,
                    if (sessionsRefs) db.sessions,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (userId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.userId,
                            referencedTable: $$PlansTableReferences
                                ._userIdTable(db),
                            referencedColumn: $$PlansTableReferences
                                ._userIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (planTopicsRefs)
                        await $_getPrefetchedData<
                          PlanRow,
                          $PlansTable,
                          PlanTopicRow
                        >(
                          currentTable: table,
                          referencedTable: $$PlansTableReferences
                              ._planTopicsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlansTableReferences(
                                db,
                                table,
                                p0,
                              ).planTopicsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.planId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (sessionsRefs)
                        await $_getPrefetchedData<
                          PlanRow,
                          $PlansTable,
                          SessionRow
                        >(
                          currentTable: table,
                          referencedTable: $$PlansTableReferences
                              ._sessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlansTableReferences(
                                db,
                                table,
                                p0,
                              ).sessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.planId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlansTable,
      PlanRow,
      $$PlansTableFilterComposer,
      $$PlansTableOrderingComposer,
      $$PlansTableAnnotationComposer,
      $$PlansTableCreateCompanionBuilder,
      $$PlansTableUpdateCompanionBuilder,
      (PlanRow, $$PlansTableReferences),
      PlanRow,
      PrefetchHooks Function({
        bool userId,
        bool planTopicsRefs,
        bool sessionsRefs,
      })
    >;
typedef $$PlanTopicsTableCreateCompanionBuilder = PlanTopicsCompanion Function({
  Value<int> id,
  required int planId,
  required String topicId,
  required String title,
  required String category,
  required int minutes,
  required int level,
  Value<String> prerequisites,
  required int position,
});
typedef $$PlanTopicsTableUpdateCompanionBuilder = PlanTopicsCompanion Function({
  Value<int> id,
  Value<int> planId,
  Value<String> topicId,
  Value<String> title,
  Value<String> category,
  Value<int> minutes,
  Value<int> level,
  Value<String> prerequisites,
  Value<int> position,
});

final class $$PlanTopicsTableReferences
    extends BaseReferences<_$AppDatabase, $PlanTopicsTable, PlanTopicRow> {
  $$PlanTopicsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PlansTable _planIdTable(_$AppDatabase db) =>
      db.plans.createAlias('plan_topics__plan_id__plans__id');

  $$PlansTableProcessedTableManager get planId {
    final $_column = $_itemColumn<int>('plan_id')!;

    final manager = $$PlansTableTableManager(
      $_db,
      $_db.plans,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_planIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlanTopicsTableFilterComposer
    extends Composer<_$AppDatabase, $PlanTopicsTable> {
  $$PlanTopicsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minutes => $composableBuilder(
    column: $table.minutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prerequisites => $composableBuilder(
    column: $table.prerequisites,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$PlansTableFilterComposer get planId {
    final $$PlansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planId,
      referencedTable: $db.plans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlansTableFilterComposer(
            $db: $db,
            $table: $db.plans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlanTopicsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlanTopicsTable> {
  $$PlanTopicsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minutes => $composableBuilder(
    column: $table.minutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prerequisites => $composableBuilder(
    column: $table.prerequisites,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlansTableOrderingComposer get planId {
    final $$PlansTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planId,
      referencedTable: $db.plans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlansTableOrderingComposer(
            $db: $db,
            $table: $db.plans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlanTopicsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlanTopicsTable> {
  $$PlanTopicsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get topicId =>
      $composableBuilder(column: $table.topicId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get minutes =>
      $composableBuilder(column: $table.minutes, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<String> get prerequisites => $composableBuilder(
    column: $table.prerequisites,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$PlansTableAnnotationComposer get planId {
    final $$PlansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planId,
      referencedTable: $db.plans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlansTableAnnotationComposer(
            $db: $db,
            $table: $db.plans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlanTopicsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlanTopicsTable,
          PlanTopicRow,
          $$PlanTopicsTableFilterComposer,
          $$PlanTopicsTableOrderingComposer,
          $$PlanTopicsTableAnnotationComposer,
          $$PlanTopicsTableCreateCompanionBuilder,
          $$PlanTopicsTableUpdateCompanionBuilder,
          (PlanTopicRow, $$PlanTopicsTableReferences),
          PlanTopicRow,
          PrefetchHooks Function({bool planId})
        > {
  $$PlanTopicsTableTableManager(_$AppDatabase db, $PlanTopicsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanTopicsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanTopicsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanTopicsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> planId = const Value.absent(),
                Value<String> topicId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> minutes = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<String> prerequisites = const Value.absent(),
                Value<int> position = const Value.absent(),
              }) => PlanTopicsCompanion(
                id: id,
                planId: planId,
                topicId: topicId,
                title: title,
                category: category,
                minutes: minutes,
                level: level,
                prerequisites: prerequisites,
                position: position,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int planId,
                required String topicId,
                required String title,
                required String category,
                required int minutes,
                required int level,
                Value<String> prerequisites = const Value.absent(),
                required int position,
              }) => PlanTopicsCompanion.insert(
                id: id,
                planId: planId,
                topicId: topicId,
                title: title,
                category: category,
                minutes: minutes,
                level: level,
                prerequisites: prerequisites,
                position: position,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlanTopicsTable, PlanTopicRow>(table),
                  $$PlanTopicsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({planId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (planId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.planId,
                        referencedTable: $$PlanTopicsTableReferences
                            ._planIdTable(db),
                        referencedColumn: $$PlanTopicsTableReferences
                            ._planIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PlanTopicsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlanTopicsTable,
      PlanTopicRow,
      $$PlanTopicsTableFilterComposer,
      $$PlanTopicsTableOrderingComposer,
      $$PlanTopicsTableAnnotationComposer,
      $$PlanTopicsTableCreateCompanionBuilder,
      $$PlanTopicsTableUpdateCompanionBuilder,
      (PlanTopicRow, $$PlanTopicsTableReferences),
      PlanTopicRow,
      PrefetchHooks Function({bool planId})
    >;
typedef $$SessionsTableCreateCompanionBuilder = SessionsCompanion Function({
  Value<int> id,
  required int planId,
  required String topicId,
  required String topicTitle,
  required String category,
  required DateTime date,
  required int minutes,
  required String kind,
  Value<int> part,
  Value<int> totalParts,
  Value<bool> isDone,
  Value<DateTime?> completedAt,
});
typedef $$SessionsTableUpdateCompanionBuilder = SessionsCompanion Function({
  Value<int> id,
  Value<int> planId,
  Value<String> topicId,
  Value<String> topicTitle,
  Value<String> category,
  Value<DateTime> date,
  Value<int> minutes,
  Value<String> kind,
  Value<int> part,
  Value<int> totalParts,
  Value<bool> isDone,
  Value<DateTime?> completedAt,
});

final class $$SessionsTableReferences
    extends BaseReferences<_$AppDatabase, $SessionsTable, SessionRow> {
  $$SessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PlansTable _planIdTable(_$AppDatabase db) =>
      db.plans.createAlias('sessions__plan_id__plans__id');

  $$PlansTableProcessedTableManager get planId {
    final $_column = $_itemColumn<int>('plan_id')!;

    final manager = $$PlansTableTableManager(
      $_db,
      $_db.plans,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_planIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topicTitle => $composableBuilder(
    column: $table.topicTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minutes => $composableBuilder(
    column: $table.minutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get part => $composableBuilder(
    column: $table.part,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalParts => $composableBuilder(
    column: $table.totalParts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDone => $composableBuilder(
    column: $table.isDone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PlansTableFilterComposer get planId {
    final $$PlansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planId,
      referencedTable: $db.plans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlansTableFilterComposer(
            $db: $db,
            $table: $db.plans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topicTitle => $composableBuilder(
    column: $table.topicTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minutes => $composableBuilder(
    column: $table.minutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get part => $composableBuilder(
    column: $table.part,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalParts => $composableBuilder(
    column: $table.totalParts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDone => $composableBuilder(
    column: $table.isDone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlansTableOrderingComposer get planId {
    final $$PlansTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planId,
      referencedTable: $db.plans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlansTableOrderingComposer(
            $db: $db,
            $table: $db.plans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get topicId =>
      $composableBuilder(column: $table.topicId, builder: (column) => column);

  GeneratedColumn<String> get topicTitle => $composableBuilder(
    column: $table.topicTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get minutes =>
      $composableBuilder(column: $table.minutes, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get part =>
      $composableBuilder(column: $table.part, builder: (column) => column);

  GeneratedColumn<int> get totalParts => $composableBuilder(
    column: $table.totalParts,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDone =>
      $composableBuilder(column: $table.isDone, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  $$PlansTableAnnotationComposer get planId {
    final $$PlansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planId,
      referencedTable: $db.plans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlansTableAnnotationComposer(
            $db: $db,
            $table: $db.plans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          SessionRow,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (SessionRow, $$SessionsTableReferences),
          SessionRow,
          PrefetchHooks Function({bool planId})
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> planId = const Value.absent(),
                Value<String> topicId = const Value.absent(),
                Value<String> topicTitle = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int> minutes = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> part = const Value.absent(),
                Value<int> totalParts = const Value.absent(),
                Value<bool> isDone = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                planId: planId,
                topicId: topicId,
                topicTitle: topicTitle,
                category: category,
                date: date,
                minutes: minutes,
                kind: kind,
                part: part,
                totalParts: totalParts,
                isDone: isDone,
                completedAt: completedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int planId,
                required String topicId,
                required String topicTitle,
                required String category,
                required DateTime date,
                required int minutes,
                required String kind,
                Value<int> part = const Value.absent(),
                Value<int> totalParts = const Value.absent(),
                Value<bool> isDone = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                planId: planId,
                topicId: topicId,
                topicTitle: topicTitle,
                category: category,
                date: date,
                minutes: minutes,
                kind: kind,
                part: part,
                totalParts: totalParts,
                isDone: isDone,
                completedAt: completedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SessionsTable, SessionRow>(table),
                  $$SessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({planId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (planId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.planId,
                        referencedTable: $$SessionsTableReferences._planIdTable(
                          db,
                        ),
                        referencedColumn: $$SessionsTableReferences
                            ._planIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      SessionRow,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (SessionRow, $$SessionsTableReferences),
      SessionRow,
      PrefetchHooks Function({bool planId})
    >;
typedef $$CustomTopicsTableCreateCompanionBuilder =
    CustomTopicsCompanion Function({
      Value<int> id,
      required int userId,
      required String directionId,
      required String title,
      Value<String> description,
      required int minutes,
      required String category,
      Value<String> prerequisites,
      required DateTime createdAt,
    });
typedef $$CustomTopicsTableUpdateCompanionBuilder =
    CustomTopicsCompanion Function({
      Value<int> id,
      Value<int> userId,
      Value<String> directionId,
      Value<String> title,
      Value<String> description,
      Value<int> minutes,
      Value<String> category,
      Value<String> prerequisites,
      Value<DateTime> createdAt,
    });

final class $$CustomTopicsTableReferences
    extends BaseReferences<_$AppDatabase, $CustomTopicsTable, CustomTopicRow> {
  $$CustomTopicsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) =>
      db.users.createAlias('custom_topics__user_id__users__id');

  $$UsersTableProcessedTableManager get userId {
    final $_column = $_itemColumn<int>('user_id')!;

    final manager = $$UsersTableTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CustomTopicsTableFilterComposer
    extends Composer<_$AppDatabase, $CustomTopicsTable> {
  $$CustomTopicsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get directionId => $composableBuilder(
    column: $table.directionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minutes => $composableBuilder(
    column: $table.minutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prerequisites => $composableBuilder(
    column: $table.prerequisites,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CustomTopicsTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomTopicsTable> {
  $$CustomTopicsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get directionId => $composableBuilder(
    column: $table.directionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minutes => $composableBuilder(
    column: $table.minutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prerequisites => $composableBuilder(
    column: $table.prerequisites,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CustomTopicsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomTopicsTable> {
  $$CustomTopicsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get directionId => $composableBuilder(
    column: $table.directionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get minutes =>
      $composableBuilder(column: $table.minutes, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get prerequisites => $composableBuilder(
    column: $table.prerequisites,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CustomTopicsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomTopicsTable,
          CustomTopicRow,
          $$CustomTopicsTableFilterComposer,
          $$CustomTopicsTableOrderingComposer,
          $$CustomTopicsTableAnnotationComposer,
          $$CustomTopicsTableCreateCompanionBuilder,
          $$CustomTopicsTableUpdateCompanionBuilder,
          (CustomTopicRow, $$CustomTopicsTableReferences),
          CustomTopicRow,
          PrefetchHooks Function({bool userId})
        > {
  $$CustomTopicsTableTableManager(_$AppDatabase db, $CustomTopicsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomTopicsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomTopicsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomTopicsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<String> directionId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> minutes = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> prerequisites = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => CustomTopicsCompanion(
                id: id,
                userId: userId,
                directionId: directionId,
                title: title,
                description: description,
                minutes: minutes,
                category: category,
                prerequisites: prerequisites,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int userId,
                required String directionId,
                required String title,
                Value<String> description = const Value.absent(),
                required int minutes,
                required String category,
                Value<String> prerequisites = const Value.absent(),
                required DateTime createdAt,
              }) => CustomTopicsCompanion.insert(
                id: id,
                userId: userId,
                directionId: directionId,
                title: title,
                description: description,
                minutes: minutes,
                category: category,
                prerequisites: prerequisites,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CustomTopicsTable, CustomTopicRow>(table),
                  $$CustomTopicsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({userId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (userId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.userId,
                        referencedTable: $$CustomTopicsTableReferences
                            ._userIdTable(db),
                        referencedColumn: $$CustomTopicsTableReferences
                            ._userIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CustomTopicsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomTopicsTable,
      CustomTopicRow,
      $$CustomTopicsTableFilterComposer,
      $$CustomTopicsTableOrderingComposer,
      $$CustomTopicsTableAnnotationComposer,
      $$CustomTopicsTableCreateCompanionBuilder,
      $$CustomTopicsTableUpdateCompanionBuilder,
      (CustomTopicRow, $$CustomTopicsTableReferences),
      CustomTopicRow,
      PrefetchHooks Function({bool userId})
    >;
typedef $$NotesTableCreateCompanionBuilder = NotesCompanion Function({
  Value<int> id,
  required int userId,
  required String title,
  required String body,
  Value<String?> topicId,
  Value<String?> topicTitle,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$NotesTableUpdateCompanionBuilder = NotesCompanion Function({
  Value<int> id,
  Value<int> userId,
  Value<String> title,
  Value<String> body,
  Value<String?> topicId,
  Value<String?> topicTitle,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$NotesTableReferences
    extends BaseReferences<_$AppDatabase, $NotesTable, NoteRow> {
  $$NotesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) =>
      db.users.createAlias('notes__user_id__users__id');

  $$UsersTableProcessedTableManager get userId {
    final $_column = $_itemColumn<int>('user_id')!;

    final manager = $$UsersTableTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$NotesTableFilterComposer extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topicTitle => $composableBuilder(
    column: $table.topicTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NotesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topicTitle => $composableBuilder(
    column: $table.topicTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get topicId =>
      $composableBuilder(column: $table.topicId, builder: (column) => column);

  GeneratedColumn<String> get topicTitle => $composableBuilder(
    column: $table.topicTitle,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotesTable,
          NoteRow,
          $$NotesTableFilterComposer,
          $$NotesTableOrderingComposer,
          $$NotesTableAnnotationComposer,
          $$NotesTableCreateCompanionBuilder,
          $$NotesTableUpdateCompanionBuilder,
          (NoteRow, $$NotesTableReferences),
          NoteRow,
          PrefetchHooks Function({bool userId})
        > {
  $$NotesTableTableManager(_$AppDatabase db, $NotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String?> topicId = const Value.absent(),
                Value<String?> topicTitle = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => NotesCompanion(
                id: id,
                userId: userId,
                title: title,
                body: body,
                topicId: topicId,
                topicTitle: topicTitle,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int userId,
                required String title,
                required String body,
                Value<String?> topicId = const Value.absent(),
                Value<String?> topicTitle = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => NotesCompanion.insert(
                id: id,
                userId: userId,
                title: title,
                body: body,
                topicId: topicId,
                topicTitle: topicTitle,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NotesTable, NoteRow>(table),
                  $$NotesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({userId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (userId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.userId,
                        referencedTable: $$NotesTableReferences._userIdTable(
                          db,
                        ),
                        referencedColumn: $$NotesTableReferences
                            ._userIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$NotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotesTable,
      NoteRow,
      $$NotesTableFilterComposer,
      $$NotesTableOrderingComposer,
      $$NotesTableAnnotationComposer,
      $$NotesTableCreateCompanionBuilder,
      $$NotesTableUpdateCompanionBuilder,
      (NoteRow, $$NotesTableReferences),
      NoteRow,
      PrefetchHooks Function({bool userId})
    >;
typedef $$FavoritesTableCreateCompanionBuilder = FavoritesCompanion Function({
  required int userId,
  required String topicId,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$FavoritesTableUpdateCompanionBuilder = FavoritesCompanion Function({
  Value<int> userId,
  Value<String> topicId,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$FavoritesTableReferences
    extends BaseReferences<_$AppDatabase, $FavoritesTable, FavoriteRow> {
  $$FavoritesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) =>
      db.users.createAlias('favorites__user_id__users__id');

  $$UsersTableProcessedTableManager get userId {
    final $_column = $_itemColumn<int>('user_id')!;

    final manager = $$UsersTableTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FavoritesTableFilterComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoritesTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoritesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get topicId =>
      $composableBuilder(column: $table.topicId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoritesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FavoritesTable,
          FavoriteRow,
          $$FavoritesTableFilterComposer,
          $$FavoritesTableOrderingComposer,
          $$FavoritesTableAnnotationComposer,
          $$FavoritesTableCreateCompanionBuilder,
          $$FavoritesTableUpdateCompanionBuilder,
          (FavoriteRow, $$FavoritesTableReferences),
          FavoriteRow,
          PrefetchHooks Function({bool userId})
        > {
  $$FavoritesTableTableManager(_$AppDatabase db, $FavoritesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> userId = const Value.absent(),
                Value<String> topicId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FavoritesCompanion(
                userId: userId,
                topicId: topicId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int userId,
                required String topicId,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => FavoritesCompanion.insert(
                userId: userId,
                topicId: topicId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FavoritesTable, FavoriteRow>(table),
                  $$FavoritesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({userId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (userId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.userId,
                        referencedTable: $$FavoritesTableReferences
                            ._userIdTable(db),
                        referencedColumn: $$FavoritesTableReferences
                            ._userIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FavoritesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FavoritesTable,
      FavoriteRow,
      $$FavoritesTableFilterComposer,
      $$FavoritesTableOrderingComposer,
      $$FavoritesTableAnnotationComposer,
      $$FavoritesTableCreateCompanionBuilder,
      $$FavoritesTableUpdateCompanionBuilder,
      (FavoriteRow, $$FavoritesTableReferences),
      FavoriteRow,
      PrefetchHooks Function({bool userId})
    >;
typedef $$PomodoroLogsTableCreateCompanionBuilder =
    PomodoroLogsCompanion Function({
      Value<int> id,
      required int userId,
      required int minutes,
      Value<String?> topicTitle,
      required DateTime completedAt,
    });
typedef $$PomodoroLogsTableUpdateCompanionBuilder =
    PomodoroLogsCompanion Function({
      Value<int> id,
      Value<int> userId,
      Value<int> minutes,
      Value<String?> topicTitle,
      Value<DateTime> completedAt,
    });

final class $$PomodoroLogsTableReferences
    extends BaseReferences<_$AppDatabase, $PomodoroLogsTable, PomodoroLogRow> {
  $$PomodoroLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) =>
      db.users.createAlias('pomodoro_logs__user_id__users__id');

  $$UsersTableProcessedTableManager get userId {
    final $_column = $_itemColumn<int>('user_id')!;

    final manager = $$UsersTableTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PomodoroLogsTableFilterComposer
    extends Composer<_$AppDatabase, $PomodoroLogsTable> {
  $$PomodoroLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minutes => $composableBuilder(
    column: $table.minutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topicTitle => $composableBuilder(
    column: $table.topicTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PomodoroLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $PomodoroLogsTable> {
  $$PomodoroLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minutes => $composableBuilder(
    column: $table.minutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topicTitle => $composableBuilder(
    column: $table.topicTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PomodoroLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PomodoroLogsTable> {
  $$PomodoroLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get minutes =>
      $composableBuilder(column: $table.minutes, builder: (column) => column);

  GeneratedColumn<String> get topicTitle => $composableBuilder(
    column: $table.topicTitle,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PomodoroLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PomodoroLogsTable,
          PomodoroLogRow,
          $$PomodoroLogsTableFilterComposer,
          $$PomodoroLogsTableOrderingComposer,
          $$PomodoroLogsTableAnnotationComposer,
          $$PomodoroLogsTableCreateCompanionBuilder,
          $$PomodoroLogsTableUpdateCompanionBuilder,
          (PomodoroLogRow, $$PomodoroLogsTableReferences),
          PomodoroLogRow,
          PrefetchHooks Function({bool userId})
        > {
  $$PomodoroLogsTableTableManager(_$AppDatabase db, $PomodoroLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PomodoroLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PomodoroLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PomodoroLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<int> minutes = const Value.absent(),
                Value<String?> topicTitle = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
              }) => PomodoroLogsCompanion(
                id: id,
                userId: userId,
                minutes: minutes,
                topicTitle: topicTitle,
                completedAt: completedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int userId,
                required int minutes,
                Value<String?> topicTitle = const Value.absent(),
                required DateTime completedAt,
              }) => PomodoroLogsCompanion.insert(
                id: id,
                userId: userId,
                minutes: minutes,
                topicTitle: topicTitle,
                completedAt: completedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PomodoroLogsTable, PomodoroLogRow>(table),
                  $$PomodoroLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({userId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (userId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.userId,
                        referencedTable: $$PomodoroLogsTableReferences
                            ._userIdTable(db),
                        referencedColumn: $$PomodoroLogsTableReferences
                            ._userIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PomodoroLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PomodoroLogsTable,
      PomodoroLogRow,
      $$PomodoroLogsTableFilterComposer,
      $$PomodoroLogsTableOrderingComposer,
      $$PomodoroLogsTableAnnotationComposer,
      $$PomodoroLogsTableCreateCompanionBuilder,
      $$PomodoroLogsTableUpdateCompanionBuilder,
      (PomodoroLogRow, $$PomodoroLogsTableReferences),
      PomodoroLogRow,
      PrefetchHooks Function({bool userId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$PlansTableTableManager get plans =>
      $$PlansTableTableManager(_db, _db.plans);
  $$PlanTopicsTableTableManager get planTopics =>
      $$PlanTopicsTableTableManager(_db, _db.planTopics);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$CustomTopicsTableTableManager get customTopics =>
      $$CustomTopicsTableTableManager(_db, _db.customTopics);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
  $$FavoritesTableTableManager get favorites =>
      $$FavoritesTableTableManager(_db, _db.favorites);
  $$PomodoroLogsTableTableManager get pomodoroLogs =>
      $$PomodoroLogsTableTableManager(_db, _db.pomodoroLogs);
}
