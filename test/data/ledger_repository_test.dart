import 'package:flutter_test/flutter_test.dart';
import 'package:shou_zhi_ben/data/ledger_repository.dart';
import 'package:shou_zhi_ben/models/ledger_transaction.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late SqfliteLedgerRepository repository;

  setUp(() {
    sqfliteFfiInit();
    repository = SqfliteLedgerRepository(
      databaseFactoryOverride: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
  });

  tearDown(() => repository.close());

  test('persists, updates, deletes, and restores a transaction', () async {
    final now = DateTime(2026, 7, 27, 12);
    final saved = await repository.insert(
      LedgerTransaction(
        type: TransactionType.expense,
        amountCents: 1299,
        category: ExpenseCategory.food,
        date: now,
        note: 'Lunch',
        createdAt: now,
        updatedAt: now,
      ),
    );

    expect(saved.id, isNotNull);
    var month = await repository.transactionsForMonth(now);
    expect(month, hasLength(1));
    expect(month.single.amountCents, 1299);

    final updated = saved.copyWith(
      amountCents: 1500,
      category: ExpenseCategory.shopping,
    );
    await repository.update(updated);
    month = await repository.transactionsForMonth(now);
    expect(month.single.amountCents, 1500);
    expect(month.single.category, ExpenseCategory.shopping);

    await repository.delete(saved.id!);
    expect(await repository.transactionsForMonth(now), isEmpty);

    await repository.restore(updated);
    month = await repository.transactionsForMonth(now);
    expect(month.single.id, saved.id);
  });

  test('filters transactions by selected month', () async {
    final createdAt = DateTime(2026, 7, 1);
    for (final date in [DateTime(2026, 7, 31), DateTime(2026, 8, 1)]) {
      await repository.insert(
        LedgerTransaction(
          type: TransactionType.expense,
          amountCents: 100,
          category: ExpenseCategory.other,
          date: date,
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      );
    }

    expect(
      await repository.transactionsForMonth(DateTime(2026, 7)),
      hasLength(1),
    );
    expect(
      await repository.transactionsForMonth(DateTime(2026, 8)),
      hasLength(1),
    );
  });
}
