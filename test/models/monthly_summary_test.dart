import 'package:flutter_test/flutter_test.dart';
import 'package:shou_zhi_ben/models/ledger_transaction.dart';
import 'package:shou_zhi_ben/models/monthly_summary.dart';

void main() {
  test('aggregates income, expenses, balance, and categories', () {
    final now = DateTime(2026, 7, 27);
    final transactions = [
      LedgerTransaction(
        type: TransactionType.income,
        amountCents: 500000,
        category: ExpenseCategory.income,
        date: now,
        createdAt: now,
        updatedAt: now,
      ),
      LedgerTransaction(
        type: TransactionType.expense,
        amountCents: 1250,
        category: ExpenseCategory.food,
        date: now,
        createdAt: now,
        updatedAt: now,
      ),
      LedgerTransaction(
        type: TransactionType.expense,
        amountCents: 3000,
        category: ExpenseCategory.transport,
        date: now,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final summary = MonthlySummary.fromTransactions(transactions);

    expect(summary.incomeCents, 500000);
    expect(summary.expenseCents, 4250);
    expect(summary.balanceCents, 495750);
    expect(summary.expensesByCategory[ExpenseCategory.food], 1250);
    expect(summary.expensesByCategory[ExpenseCategory.transport], 3000);
    expect(summary.expensesByCategory[ExpenseCategory.shopping], 0);
  });
}
