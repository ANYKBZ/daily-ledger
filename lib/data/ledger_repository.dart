import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../core/formatters.dart';
import '../models/ledger_transaction.dart';

abstract interface class LedgerRepository {
  Future<List<LedgerTransaction>> transactionsForMonth(DateTime month);

  Future<LedgerTransaction> insert(LedgerTransaction transaction);

  Future<void> update(LedgerTransaction transaction);

  Future<void> delete(int id);

  Future<void> restore(LedgerTransaction transaction);

  Future<void> close();
}

class SqfliteLedgerRepository implements LedgerRepository {
  SqfliteLedgerRepository({
    DatabaseFactory? databaseFactoryOverride,
    this.databasePath,
  }) : _databaseFactory = databaseFactoryOverride ?? databaseFactory;

  final DatabaseFactory _databaseFactory;
  final String? databasePath;
  Database? _database;

  Future<Database> get _db async {
    final existing = _database;
    if (existing != null) return existing;

    final path =
        databasePath ??
        p.join(await _databaseFactory.getDatabasesPath(), 'daily_ledger.db');
    final database = await _databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE ledger_transactions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
              amount_cents INTEGER NOT NULL CHECK (amount_cents > 0),
              category TEXT NOT NULL,
              transaction_date TEXT NOT NULL,
              note TEXT,
              source TEXT NOT NULL CHECK (source IN ('manual', 'receipt')),
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE INDEX ledger_transactions_date_idx
            ON ledger_transactions(transaction_date DESC)
          ''');
        },
      ),
    );
    _database = database;
    return database;
  }

  @override
  Future<List<LedgerTransaction>> transactionsForMonth(DateTime month) async {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    final rows = await (await _db).query(
      'ledger_transactions',
      where: 'transaction_date >= ? AND transaction_date < ?',
      whereArgs: [DateTools.databaseDate(start), DateTools.databaseDate(end)],
      orderBy: 'transaction_date DESC, created_at DESC',
    );
    return rows.map(LedgerTransaction.fromMap).toList(growable: false);
  }

  @override
  Future<LedgerTransaction> insert(LedgerTransaction transaction) async {
    final id = await (await _db).insert(
      'ledger_transactions',
      transaction.toMap(includeId: false),
    );
    return transaction.copyWith(id: id);
  }

  @override
  Future<void> update(LedgerTransaction transaction) async {
    final id = transaction.id;
    if (id == null) {
      throw ArgumentError('Cannot update a transaction without id');
    }
    await (await _db).update(
      'ledger_transactions',
      transaction.toMap(includeId: false),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> delete(int id) async {
    await (await _db).delete(
      'ledger_transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> restore(LedgerTransaction transaction) async {
    await (await _db).insert(
      'ledger_transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
