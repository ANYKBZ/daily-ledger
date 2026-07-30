// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Daily Ledger';

  @override
  String get mambaTagline => 'Focus daily. Own every dollar.';

  @override
  String get recordTab => 'Record';

  @override
  String get transactionsTab => 'Transactions';

  @override
  String get statisticsTab => 'Statistics';

  @override
  String get expense => 'Expense';

  @override
  String get income => 'Income';

  @override
  String get amount => 'Amount';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get choosePhoto => 'Choose from library';

  @override
  String get photoRecord => 'Receipt photo';

  @override
  String get photoPreviewTitle => 'Receipt selected';

  @override
  String get photoPreviewMessage =>
      'Automatic receipt recognition is coming next. You can enter this transaction manually now.';

  @override
  String get continueManually => 'Enter manually';

  @override
  String get close => 'Close';

  @override
  String get cameraUnavailable => 'Camera or photo library is unavailable.';

  @override
  String get category => 'Category';

  @override
  String get food => 'Food';

  @override
  String get transport => 'Transport';

  @override
  String get shopping => 'Shopping';

  @override
  String get housing => 'Housing';

  @override
  String get other => 'Other';

  @override
  String get incomeCategory => 'Income';

  @override
  String get date => 'Date';

  @override
  String get note => 'Note (optional)';

  @override
  String get saveTransaction => 'Save transaction';

  @override
  String get invalidAmount => 'Enter an amount greater than \$0.';

  @override
  String get saved => 'Transaction saved';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String dailyIncome(String amount) {
    return 'Income $amount';
  }

  @override
  String dailyExpense(String amount) {
    return 'Expense $amount';
  }

  @override
  String dailyBalance(String amount) {
    return 'Net $amount';
  }

  @override
  String get noTransactions => 'No transactions this month';

  @override
  String get noTransactionsHint =>
      'Record your first transaction to see it here.';

  @override
  String get recordOne => 'Record one';

  @override
  String get delete => 'Delete';

  @override
  String get deleted => 'Transaction deleted';

  @override
  String get undo => 'Undo';

  @override
  String get editTransaction => 'Edit transaction';

  @override
  String get cancel => 'Cancel';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get monthlyOverview => 'Monthly overview';

  @override
  String get totalIncome => 'Income';

  @override
  String get totalExpense => 'Expense';

  @override
  String get balance => 'Balance';

  @override
  String get expenseBreakdown => 'Expense breakdown';

  @override
  String get noExpenses => 'No expenses this month';

  @override
  String get noExpensesHint =>
      'Expense categories will appear here after you record spending.';

  @override
  String chartSummary(String summary) {
    return 'Expense breakdown: $summary';
  }

  @override
  String percentage(String value) {
    return '$value%';
  }

  @override
  String get loading => 'Loading…';
}
