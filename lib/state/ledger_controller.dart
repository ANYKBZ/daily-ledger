import 'package:flutter/foundation.dart';

import '../core/formatters.dart';
import '../data/ledger_repository.dart';
import '../models/ledger_transaction.dart';
import '../models/monthly_summary.dart';

class LedgerController extends ChangeNotifier {
  LedgerController(this.repository)
    : _selectedMonth = DateTools.monthOnly(DateTime.now());

  final LedgerRepository repository;

  DateTime _selectedMonth;
  DateTime get selectedMonth => _selectedMonth;

  List<LedgerTransaction> _transactions = const [];
  List<LedgerTransaction> get transactions => _transactions;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  MonthlySummary get summary => MonthlySummary.fromTransactions(_transactions);

  Map<DateTime, List<LedgerTransaction>> get groupedTransactions {
    final grouped = <DateTime, List<LedgerTransaction>>{};
    for (final transaction in _transactions) {
      final date = DateTools.dateOnly(transaction.date);
      grouped.putIfAbsent(date, () => []).add(transaction);
    }
    return grouped;
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    _transactions = await repository.transactionsForMonth(_selectedMonth);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> selectMonth(DateTime month) async {
    _selectedMonth = DateTools.monthOnly(month);
    await load();
  }

  Future<void> previousMonth() =>
      selectMonth(DateTime(_selectedMonth.year, _selectedMonth.month - 1));

  Future<void> nextMonth() =>
      selectMonth(DateTime(_selectedMonth.year, _selectedMonth.month + 1));

  Future<void> add({
    required TransactionType type,
    required int amountCents,
    required ExpenseCategory category,
    required DateTime date,
    String? note,
    TransactionSource source = TransactionSource.manual,
  }) async {
    final now = DateTime.now();
    final transaction = LedgerTransaction(
      type: type,
      amountCents: amountCents,
      category: type == TransactionType.income
          ? ExpenseCategory.income
          : category,
      date: DateTools.dateOnly(date),
      note: _cleanNote(note),
      source: source,
      createdAt: now,
      updatedAt: now,
    );
    await repository.insert(transaction);
    _selectedMonth = DateTools.monthOnly(date);
    await load();
  }

  Future<void> updateTransaction(LedgerTransaction transaction) async {
    await repository.update(
      LedgerTransaction(
        id: transaction.id,
        type: transaction.type,
        amountCents: transaction.amountCents,
        category: transaction.type == TransactionType.income
            ? ExpenseCategory.income
            : transaction.category,
        date: DateTools.dateOnly(transaction.date),
        note: _cleanNote(transaction.note),
        source: transaction.source,
        createdAt: transaction.createdAt,
        updatedAt: DateTime.now(),
      ),
    );
    await load();
  }

  Future<LedgerTransaction> deleteTransaction(
    LedgerTransaction transaction,
  ) async {
    final id = transaction.id;
    if (id == null) {
      throw ArgumentError('Cannot delete a transaction without id');
    }
    _transactions = _transactions.where((item) => item.id != id).toList();
    notifyListeners();
    await repository.delete(id);
    return transaction;
  }

  Future<void> restoreTransaction(LedgerTransaction transaction) async {
    await repository.restore(transaction);
    await load();
  }

  static String? _cleanNote(String? note) {
    final value = note?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  @override
  void dispose() {
    repository.close();
    super.dispose();
  }
}
