import 'package:flutter/material.dart';

import '../models/ledger_transaction.dart';
import 'generated/app_localizations.dart';

extension LocalizationContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension ExpenseCategoryPresentation on ExpenseCategory {
  String label(AppLocalizations l10n) {
    return switch (this) {
      ExpenseCategory.food => l10n.food,
      ExpenseCategory.transport => l10n.transport,
      ExpenseCategory.shopping => l10n.shopping,
      ExpenseCategory.housing => l10n.housing,
      ExpenseCategory.other => l10n.other,
      ExpenseCategory.income => l10n.incomeCategory,
    };
  }

  IconData get icon {
    return switch (this) {
      ExpenseCategory.food => Icons.restaurant_rounded,
      ExpenseCategory.transport => Icons.directions_car_filled_rounded,
      ExpenseCategory.shopping => Icons.shopping_bag_rounded,
      ExpenseCategory.housing => Icons.home_rounded,
      ExpenseCategory.other => Icons.more_horiz_rounded,
      ExpenseCategory.income => Icons.savings_rounded,
    };
  }
}
