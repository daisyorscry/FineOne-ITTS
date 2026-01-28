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
  });

  final int? id;
  final String title;
  final String category;
  final int amount;
  final String type; // income | expense
  final DateTime date;
  final String? notes;
  final String? method;

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
      version: 2,
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
            method TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE transactions ADD COLUMN notes TEXT');
          await db.execute('ALTER TABLE transactions ADD COLUMN method TEXT');
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

    final rows = await db.query(
      'transactions',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: where.isEmpty ? null : args,
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(TransactionEntry.fromMap).toList();
  }

  Future<int> getBalance() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount END), 0) as income,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount END), 0) as expense
      FROM transactions
    ''');
    final row = rows.isNotEmpty ? rows.first : <String, Object?>{};
    final income = (row['income'] as num?)?.toInt() ?? 0;
    final expense = (row['expense'] as num?)?.toInt() ?? 0;
    return income - expense;
  }
}
