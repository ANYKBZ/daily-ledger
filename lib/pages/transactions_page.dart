import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/formatters.dart';
import '../l10n/localization_extensions.dart';
import '../models/ledger_transaction.dart';
import '../services/exchange_rate_service.dart';
import '../state/ledger_controller.dart';
import '../widgets/currency_converter_sheet.dart';
import '../widgets/edit_transaction_sheet.dart';
import '../widgets/mamba_page_header.dart';
import '../widgets/month_switcher.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({
    super.key,
    required this.controller,
    required this.exchangeRateProvider,
    required this.onRecordRequested,
  });

  final LedgerController controller;
  final ExchangeRateProvider exchangeRateProvider;
  final VoidCallback onRecordRequested;

  Future<void> _openCurrencyConverter(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) =>
          CurrencyConverterSheet(provider: exchangeRateProvider),
    );
  }

  Future<void> _edit(
    BuildContext context,
    LedgerTransaction transaction,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => EditTransactionSheet(
        transaction: transaction,
        controller: controller,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: MambaPageHeader(
                  title: context.l10n.transactionsTab,
                  subtitle: context.l10n.mambaTagline,
                  action: IconButton.filled(
                    key: const Key('currency-converter-button'),
                    tooltip: context.l10n.currencyConverterTooltip,
                    onPressed: () => _openCurrencyConverter(context),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.primaryDark,
                    ),
                    icon: const Icon(Icons.currency_exchange_rounded),
                  ),
                ),
              ),
              MonthSwitcher(
                month: controller.selectedMonth,
                onPrevious: () => unawaited(controller.previousMonth()),
                onNext: () => unawaited(controller.nextMonth()),
              ),
              const SizedBox(height: 6),
              Expanded(child: _body(context)),
            ],
          );
        },
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (controller.isLoading) {
      return Center(
        child: Semantics(
          label: context.l10n.loading,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (controller.transactions.isEmpty) {
      return _EmptyTransactions(onRecordRequested: onRecordRequested);
    }

    final groups = controller.groupedTransactions.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final entry = groups[index];
        return _DayGroup(
          date: entry.key,
          transactions: entry.value,
          controller: controller,
          onEdit: (transaction) => _edit(context, transaction),
        );
      },
    );
  }
}

class _DayGroup extends StatelessWidget {
  const _DayGroup({
    required this.date,
    required this.transactions,
    required this.controller,
    required this.onEdit,
  });

  final DateTime date;
  final List<LedgerTransaction> transactions;
  final LedgerController controller;
  final ValueChanged<LedgerTransaction> onEdit;

  @override
  Widget build(BuildContext context) {
    final income = transactions
        .where((item) => item.type == TransactionType.income)
        .fold<int>(0, (sum, item) => sum + item.amountCents);
    final expense = transactions
        .where((item) => item.type == TransactionType.expense)
        .fold<int>(0, (sum, item) => sum + item.amountCents);
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 4,
              children: [
                Text(
                  DateTools.dayLabel(date, locale),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  context.l10n.dailyBalance(
                    MoneyFormatter.currency(income - expense, signed: true),
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: AppColors.mutedText),
                ),
              ],
            ),
          ),
          Card(
            child: Column(
              children: [
                for (var index = 0; index < transactions.length; index++) ...[
                  _TransactionRow(
                    transaction: transactions[index],
                    controller: controller,
                    onTap: () => onEdit(transactions[index]),
                  ),
                  if (index < transactions.length - 1)
                    const Divider(height: 1, indent: 68),
                ],
              ],
            ),
          ),
          const SizedBox(height: 7),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  context.l10n.dailyIncome(MoneyFormatter.currency(income)),
                  style: const TextStyle(
                    color: AppColors.income,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  context.l10n.dailyExpense(MoneyFormatter.currency(expense)),
                  style: const TextStyle(
                    color: AppColors.expense,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.transaction,
    required this.controller,
    required this.onTap,
  });

  final LedgerTransaction transaction;
  final LedgerController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final amountColor = transaction.type == TransactionType.income
        ? AppColors.income
        : AppColors.expense;
    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppColors.expense,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_rounded, color: Colors.white),
            Text(
              context.l10n.delete,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
      onDismissed: (_) {
        unawaited(
          controller.deleteTransaction(transaction).then((deleted) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.deleted),
                action: SnackBarAction(
                  label: context.l10n.undo,
                  onPressed: () =>
                      unawaited(controller.restoreTransaction(deleted)),
                ),
              ),
            );
          }),
        );
      },
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: AppColors.goldSoft,
          foregroundColor: AppColors.primary,
          child: Icon(transaction.category.icon),
        ),
        title: Text(
          transaction.category.label(context.l10n),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: transaction.note == null
            ? null
            : Text(
                transaction.note!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        trailing: Text(
          MoneyFormatter.currency(transaction.signedCents, signed: true),
          style: TextStyle(color: amountColor, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions({required this.onRecordRequested});

  final VoidCallback onRecordRequested;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_rounded,
              size: 56,
              color: AppColors.mutedText,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.noTransactions,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.noTransactionsHint,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mutedText),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRecordRequested,
              icon: const Icon(Icons.add_rounded),
              label: Text(context.l10n.recordOne),
            ),
          ],
        ),
      ),
    );
  }
}
