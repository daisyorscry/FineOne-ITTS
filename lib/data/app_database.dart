import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class TransactionEntry {
  TransactionEntry({
    this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.type,
    required this.date,
    this.notes,
    this.method,
    this.pocketId,
  });

  final int? id;
  final String title;
  final String category;
  final int amount;
  final String type; // income | expense
  final DateTime date;
  final String? notes;
  final String? method;
  final int? pocketId;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'type': type,
      'date': date.toIso8601String(),
      'notes': notes,
      'method': method,
      'pocket_id': pocketId,
    };
  }

  static TransactionEntry fromMap(Map<String, Object?> map) {
    return TransactionEntry(
      id: map['id'] as int?,
      title: map['title'] as String,
      category: map['category'] as String,
      amount: map['amount'] as int,
      type: map['type'] as String,
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
      method: map['method'] as String?,
      pocketId: map['pocket_id'] as int?,
    );
  }
}

class ProfileEntry {
  ProfileEntry({
    this.id = 1,
    required this.name,
    required this.goal,
    this.photoPath,
    this.geminiApiKey,
  });

  final int id;
  final String name;
  final String goal;
  final String? photoPath;
  final String? geminiApiKey;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'goal': goal,
      'photo_path': photoPath,
      'gemini_api_key': geminiApiKey,
    };
  }

  static ProfileEntry fromMap(Map<String, Object?> map) {
    return ProfileEntry(
      id: map['id'] as int? ?? 1,
      name: map['name'] as String? ?? '',
      goal: map['goal'] as String? ?? '',
      photoPath: map['photo_path'] as String?,
      geminiApiKey: map['gemini_api_key'] as String?,
    );
  }
}

class PocketEntry {
  PocketEntry({
    this.id,
    required this.name,
    this.colorValue,
    this.tabId,
  });

  final int? id;
  final String name;
  final int? colorValue;
  final int? tabId;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'color': colorValue,
      'tab_id': tabId,
    };
  }

  static PocketEntry fromMap(Map<String, Object?> map) {
    return PocketEntry(
      id: map['id'] as int?,
      name: map['name'] as String,
      colorValue: map['color'] as int?,
      tabId: map['tab_id'] as int?,
    );
  }
}

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final basePath = await getDatabasesPath();
    final dbPath = p.join(basePath, 'finone.db');
    return openDatabase(
      dbPath,
      version: 10,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            category TEXT NOT NULL,
            amount INTEGER NOT NULL,
            type TEXT NOT NULL,
            date TEXT NOT NULL,
            notes TEXT,
            method TEXT,
            pocket_id INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE profile (
            id INTEGER PRIMARY KEY,
            name TEXT,
            goal TEXT,
            photo_path TEXT,
            gemini_api_key TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE pocket_tabs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE pockets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            color INTEGER,
            tab_id INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE insights (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            month TEXT NOT NULL,
            content TEXT NOT NULL,
            created_at TEXT NOT NULL,
            period_start TEXT NOT NULL,
            period_end TEXT NOT NULL
          )
        ''');
        await db.insert('pocket_tabs', {'name': 'My pockets'});
        await db.insert('pocket_tabs', {'name': 'Shared'});
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE transactions ADD COLUMN notes TEXT');
          await db.execute('ALTER TABLE transactions ADD COLUMN method TEXT');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE profile (
              id INTEGER PRIMARY KEY,
              name TEXT,
              goal TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE pockets (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 4) {
          await db.execute(
            'ALTER TABLE transactions ADD COLUMN pocket_id INTEGER',
          );
          final pocketRows = await db.query('pockets', limit: 1);
          int pocketId;
          if (pocketRows.isEmpty) {
            pocketId = await db.insert('pockets', {'name': 'Main'});
          } else {
            pocketId = pocketRows.first['id'] as int;
          }
          await db.update(
            'transactions',
            {'pocket_id': pocketId},
            where: 'pocket_id IS NULL',
          );
        }
        if (oldVersion < 5) {
          await db.execute('ALTER TABLE pockets ADD COLUMN color INTEGER');
          await db.update(
            'pockets',
            {'color': 0xFFBFFFE3},
            where: 'color IS NULL',
          );
        }
        if (oldVersion < 6) {
          await db.execute('''
            CREATE TABLE pocket_tabs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL
            )
          ''');
          await db.execute('ALTER TABLE pockets ADD COLUMN tab_id INTEGER');
          final myTabId =
              await db.insert('pocket_tabs', {'name': 'My pockets'});
          await db.insert('pocket_tabs', {'name': 'Shared'});
          await db.update(
            'pockets',
            {'tab_id': myTabId},
            where: 'tab_id IS NULL',
          );
        }
        if (oldVersion < 7) {
          await db.execute(
            'ALTER TABLE profile ADD COLUMN photo_path TEXT',
          );
        }
        if (oldVersion < 8) {
          await db.execute(
            'ALTER TABLE profile ADD COLUMN gemini_api_key TEXT',
          );
        }
        if (oldVersion < 9) {
          await db.execute('''
            CREATE TABLE insights (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              month TEXT NOT NULL,
              content TEXT NOT NULL,
              created_at TEXT NOT NULL,
              period_start TEXT NOT NULL,
              period_end TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 10) {
          await db.execute(
            'ALTER TABLE insights ADD COLUMN period_start TEXT',
          );
          await db.execute(
            'ALTER TABLE insights ADD COLUMN period_end TEXT',
          );
          final now = DateTime.now().toIso8601String();
          await db.update(
            'insights',
            {'period_start': now, 'period_end': now},
            where: 'period_start IS NULL OR period_end IS NULL',
          );
        }
      },
    );
  }

  Future<int> insertTransaction(TransactionEntry entry) async {
    final db = await database;
    return db.insert('transactions', entry.toMap());
  }

  Future<int> updateTransaction(TransactionEntry entry) async {
    final db = await database;
    if (entry.id == null) {
      return 0;
    }
    return db.update(
      'transactions',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<List<TransactionEntry>> fetchTransactions({
    DateTime? startDate,
    DateTime? endDate,
    int? minAmount,
    int? maxAmount,
    String? category,
    String? type,
    int? pocketId,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <Object?>[];

    if (startDate != null) {
      where.add('date >= ?');
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      where.add('date <= ?');
      args.add(endDate.toIso8601String());
    }
    if (minAmount != null) {
      where.add('amount >= ?');
      args.add(minAmount);
    }
    if (maxAmount != null) {
      where.add('amount <= ?');
      args.add(maxAmount);
    }
    if (category != null && category != 'all') {
      where.add('category = ?');
      args.add(category);
    }
    if (type != null && type != 'all') {
      where.add('type = ?');
      args.add(type);
    }
    if (pocketId != null) {
      where.add('pocket_id = ?');
      args.add(pocketId);
    }

    final rows = await db.query(
      'transactions',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: where.isEmpty ? null : args,
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(TransactionEntry.fromMap).toList();
  }

  Future<int> getBalance({int? pocketId}) async {
    final db = await database;
    final where = pocketId == null ? '' : 'WHERE pocket_id = ?';
    final rows = await db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount END), 0) as income,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount END), 0) as expense
      FROM transactions
      $where
    ''', pocketId == null ? [] : [pocketId]);
    final row = rows.isNotEmpty ? rows.first : <String, Object?>{};
    final income = (row['income'] as num?)?.toInt() ?? 0;
    final expense = (row['expense'] as num?)?.toInt() ?? 0;
    return income - expense;
  }

  Future<ProfileEntry?> fetchProfile() async {
    final db = await database;
    final rows = await db.query('profile', limit: 1);
    if (rows.isEmpty) {
      return null;
    }
    return ProfileEntry.fromMap(rows.first);
  }

  Future<void> saveProfile(ProfileEntry profile) async {
    final db = await database;
    await db.insert(
      'profile',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<PocketEntry>> fetchPockets({int? tabId}) async {
    final db = await database;
    final rows = await db.query(
      'pockets',
      where: tabId == null ? null : 'tab_id = ?',
      whereArgs: tabId == null ? null : [tabId],
      orderBy: 'id DESC',
    );
    return rows.map(PocketEntry.fromMap).toList();
  }

  Future<int> insertPocket(String name, {int? colorValue, int? tabId}) async {
    final db = await database;
    return db.insert(
      'pockets',
      {
        'name': name,
        'color': colorValue,
        'tab_id': tabId,
      },
    );
  }

  Future<int> updatePocket(PocketEntry pocket) async {
    final db = await database;
    if (pocket.id == null) {
      return 0;
    }
    return db.update(
      'pockets',
      {
        'name': pocket.name,
        'color': pocket.colorValue,
        'tab_id': pocket.tabId,
      },
      where: 'id = ?',
      whereArgs: [pocket.id],
    );
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('transactions');
      await txn.delete('pockets');
      await txn.delete('profile');
      await txn.delete('pocket_tabs');
      await txn.delete('insights');
    });
  }

  Future<String?> fetchInsight(String monthKey) async {
    final db = await database;
    final rows = await db.query(
      'insights',
      where: 'month = ?',
      whereArgs: [monthKey],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first['content'] as String?;
  }

  Future<Map<String, Object?>?> fetchInsightRecord(String monthKey) async {
    final db = await database;
    final rows = await db.query(
      'insights',
      where: 'month = ?',
      whereArgs: [monthKey],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first;
  }

  Future<void> saveInsight({
    required String monthKey,
    required String content,
    required String periodStart,
    required String periodEnd,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('insights', where: 'month = ?', whereArgs: [monthKey]);
      await txn.insert('insights', {
        'month': monthKey,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
        'period_start': periodStart,
        'period_end': periodEnd,
      });
    });
  }

  Future<List<Map<String, Object?>>> fetchInsightHistory() async {
    final db = await database;
    return db.query('insights', orderBy: 'created_at DESC');
  }

  Future<void> deletePocket(int id) async {
    final db = await database;
    await db.delete('pockets', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> replacePockets(List<PocketEntry> pockets) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('pockets');
      for (final pocket in pockets) {
        await txn.insert('pockets', {
          'name': pocket.name,
          'color': pocket.colorValue,
          'tab_id': pocket.tabId,
        });
      }
    });
  }

  Future<List<Map<String, Object?>>> fetchTabs() async {
    final db = await database;
    return db.query('pocket_tabs', orderBy: 'id ASC');
  }

  Future<int> insertTab(String name) async {
    final db = await database;
    return db.insert('pocket_tabs', {'name': name});
  }
}
