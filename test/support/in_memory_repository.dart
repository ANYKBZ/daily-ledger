import 'package:shou_zhi_ben/data/ledger_repository.dart';
import 'package:shou_zhi_ben/models/ledger_transaction.dart';

class InMemoryLedgerRepository implements LedgerRepository {
  final List<LedgerTransaction> items = [];
  int _nextId = 1;

  @override
  Future<List<LedgerTransaction>> transactionsForMonth(DateTime month) async {
    final result = items.where(
      (item) => item.date.year == month.year && item.date.month == month.month,
    );
    return result.toList()..sort((a, b) {
      final dateOrder = b.date.compareTo(a.date);
      return dateOrder != 0 ? dateOrder : b.createdAt.compareTo(a.createdAt);
    });
  }

  @override
  Future<LedgerTransaction> insert(LedgerTransaction transaction) async {
    final saved = transaction.copyWith(id: transaction.id ?? _nextId++);
    items.add(saved);
    return saved;
  }

  @override
  Future<void> update(LedgerTransaction transaction) async {
    final index = items.indexWhere((item) => item.id == transaction.id);
    if (index >= 0) items[index] = transaction;
  }

  @override
  Future<void> delete(int id) async {
    items.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> restore(LedgerTransaction transaction) async {
    items.removeWhere((item) => item.id == transaction.id);
    items.add(transaction);
  }

  @override
  Future<void> close() async {}
}
