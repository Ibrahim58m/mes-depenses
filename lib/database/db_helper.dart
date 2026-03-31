import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart';
import '../models/transaction.dart';
import '../models/category.dart';

class DbHelper {
  static final DbHelper _instance = DbHelper._internal();
  factory DbHelper() => _instance;
  DbHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'expense_tracker.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        raw_sms TEXT NOT NULL,
        source INTEGER NOT NULL,
        type INTEGER NOT NULL,
        amount REAL NOT NULL,
        balance REAL,
        beneficiary_name TEXT,
        beneficiary_phone TEXT,
        merchant_name TEXT,
        reference TEXT,
        date INTEGER NOT NULL,
        category_id INTEGER,
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color INTEGER NOT NULL
      )
    ''');

    // Insérer les catégories par défaut
    for (final cat in Category.defaults) {
      await db.insert('categories', {
        'id': cat.id,
        'name': cat.name,
        'icon': cat.icon,
        'color': cat.color,
      });
    }
  }

  // ──────────────── TRANSACTIONS ────────────────

  Future<int> insertTransaction(Transaction tx) async {
    final db = await database;
    return db.insert('transactions', tx.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<bool> transactionExists(String rawSms) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'raw_sms = ?',
      whereArgs: [rawSms],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<List<Transaction>> getAllTransactions({
    DateTime? from,
    DateTime? to,
    int? categoryId,
    TransactionSource? source,
  }) async {
    final db = await database;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (from != null) {
      conditions.add('date >= ?');
      args.add(from.millisecondsSinceEpoch);
    }
    if (to != null) {
      conditions.add('date <= ?');
      args.add(to.millisecondsSinceEpoch);
    }
    if (categoryId != null) {
      conditions.add('category_id = ?');
      args.add(categoryId);
    }
    if (source != null) {
      conditions.add('source = ?');
      args.add(source.index);
    }

    final where = conditions.isEmpty ? null : conditions.join(' AND ');
    final maps = await db.query(
      'transactions',
      where: where,
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'date DESC',
    );
    return maps.map(Transaction.fromMap).toList();
  }

  Future<void> updateTransactionCategory(int txId, int categoryId) async {
    final db = await database;
    await db.update(
      'transactions',
      {'category_id': categoryId},
      where: 'id = ?',
      whereArgs: [txId],
    );
  }

  Future<double> getTotalExpenses({DateTime? from, DateTime? to}) async {
    final transactions = await getAllTransactions(from: from, to: to);
    double total = 0.0;
    for (final t in transactions) {
      if (t.type == TransactionType.debit ||
          t.type == TransactionType.transfer ||
          t.type == TransactionType.phoneCredit) {
        total += t.amount;
      }
    }
    return total;
  }

  /// Dépenses par catégorie sur une période
  Future<Map<int, double>> getExpensesByCategory({
    DateTime? from,
    DateTime? to,
  }) async {
    final transactions = await getAllTransactions(from: from, to: to);
    final result = <int, double>{};
    for (final tx in transactions) {
      if (tx.type == TransactionType.debit ||
          tx.type == TransactionType.transfer ||
          tx.type == TransactionType.phoneCredit) {
        final catId = tx.categoryId ?? 8; // 8 = Autre
        result[catId] = (result[catId] ?? 0) + tx.amount;
      }
    }
    return result;
  }

  /// Dépenses par bénéficiaire
  Future<Map<String, double>> getExpensesByBeneficiary({
    DateTime? from,
    DateTime? to,
  }) async {
    final transactions = await getAllTransactions(from: from, to: to);
    final result = <String, double>{};
    for (final tx in transactions) {
      if (tx.type == TransactionType.transfer) {
        final name = tx.beneficiaryName ?? 'Inconnu';
        result[name] = (result[name] ?? 0) + tx.amount;
      }
    }
    return result;
  }

  /// Dépenses par jour sur les 30 derniers jours
  Future<Map<DateTime, double>> getDailyExpenses({int days = 30}) async {
    final from = DateTime.now().subtract(Duration(days: days));
    final transactions =
        await getAllTransactions(from: from, to: DateTime.now());
    final result = <DateTime, double>{};
    for (final tx in transactions) {
      if (tx.type == TransactionType.debit ||
          tx.type == TransactionType.transfer ||
          tx.type == TransactionType.phoneCredit) {
        final day =
            DateTime(tx.date.year, tx.date.month, tx.date.day);
        result[day] = (result[day] ?? 0) + tx.amount;
      }
    }
    return result;
  }

  // ──────────────── CATEGORIES ────────────────

  Future<List<Category>> getCategories() async {
    final db = await database;
    final maps = await db.query('categories', orderBy: 'id');
    return maps.map(Category.fromMap).toList();
  }
}
