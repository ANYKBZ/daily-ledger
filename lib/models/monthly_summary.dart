import 'ledger_transaction.dart';

class MonthlySummary {
  const MonthlySummary({
    required this.incomeCents,
    required this.expenseCents,
    required this.expensesByCategory,
  });

  factory MonthlySummary.fromTransactions(
    Iterable<LedgerTransaction> transactions,
  ) {
    var income = 0;
    var expense = 0;
    final categories = <ExpenseCategory, int>{
      for (final category in ExpenseCategory.values)
        if (category != ExpenseCategory.income) category: 0,
    };

    for (final transaction in transactions) {
      if (transaction.type == TransactionType.income) {
        income += transaction.amountCents;
      } else {
        expense += transaction.amountCents;
        categories.update(
          transaction.category,
          (value) => value + transaction.amountCents,
          ifAbsent: () => transaction.amountCents,
        );
      }
    }

    return MonthlySummary(
      incomeCents: income,
      expenseCents: expense,
      expensesByCategory: categories,
    );
  }

  final int incomeCents;
  final int expenseCents;
  final Map<ExpenseCategory, int> expensesByCategory;

  int get balanceCents => incomeCents - expenseCents;
}
