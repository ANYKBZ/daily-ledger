import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/formatters.dart';
import '../l10n/localization_extensions.dart';
import '../models/ledger_transaction.dart';
import '../state/ledger_controller.dart';
import '../widgets/mamba_page_header.dart';
import '../widgets/month_switcher.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key, required this.controller});

  final LedgerController controller;

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
                  title: context.l10n.statisticsTab,
                  subtitle: context.l10n.mambaTagline,
                ),
              ),
              MonthSwitcher(
                month: controller.selectedMonth,
                onPrevious: () => unawaited(controller.previousMonth()),
                onNext: () => unawaited(controller.nextMonth()),
              ),
              Expanded(
                child: controller.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _StatisticsContent(controller: controller),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatisticsContent extends StatelessWidget {
  const _StatisticsContent({required this.controller});

  final LedgerController controller;

  @override
  Widget build(BuildContext context) {
    final summary = controller.summary;
    final nonZeroCategories = summary.expensesByCategory.entries
        .where((entry) => entry.value > 0)
        .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Text(
          context.l10n.monthlyOverview,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: context.l10n.totalIncome,
                amount: MoneyFormatter.currency(summary.incomeCents),
                color: AppColors.income,
                icon: Icons.south_west_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                label: context.l10n.totalExpense,
                amount: MoneyFormatter.currency(summary.expenseCents),
                color: AppColors.expense,
                icon: Icons.north_east_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _BalanceCard(balanceCents: summary.balanceCents),
        const SizedBox(height: 24),
        Text(
          context.l10n.expenseBreakdown,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        if (nonZeroCategories.isEmpty)
          const _NoExpenses()
        else
          _BreakdownChart(
            categories: nonZeroCategories,
            totalCents: summary.expenseCents,
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  final String label;
  final String amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(color: AppColors.mutedText)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                amount,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balanceCents});

  final int balanceCents;

  @override
  Widget build(BuildContext context) {
    final amountColor = balanceCents < 0
        ? const Color(0xFFFFA0AA)
        : AppColors.gold;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                context.l10n.balance,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              MoneyFormatter.currency(balanceCents, signed: true),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: amountColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownChart extends StatelessWidget {
  const _BreakdownChart({required this.categories, required this.totalCents});

  final List<MapEntry<ExpenseCategory, int>> categories;
  final int totalCents;

  @override
  Widget build(BuildContext context) {
    final summaryText = categories
        .map(
          (entry) =>
              '${entry.key.label(context.l10n)} '
              '${(entry.value / totalCents * 100).toStringAsFixed(0)}%',
        )
        .join(', ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Semantics(
          label: context.l10n.chartSummary(summaryText),
          child: Column(
            children: [
              SizedBox(
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        centerSpaceRadius: 58,
                        sectionsSpace: 3,
                        startDegreeOffset: -90,
                        sections: [
                          for (final entry in categories)
                            PieChartSectionData(
                              value: entry.value.toDouble(),
                              color: AppColors.categoryColors[entry.key.index],
                              radius: 38,
                              showTitle: false,
                            ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.l10n.totalExpense,
                          style: const TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          MoneyFormatter.currency(totalCents),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              for (final entry in categories)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.categoryColors[entry.key.index],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(entry.key.icon, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(entry.key.label(context.l10n))),
                      Text(
                        MoneyFormatter.currency(entry.value),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 38,
                        child: Text(
                          context.l10n.percentage(
                            (entry.value / totalCents * 100).toStringAsFixed(0),
                          ),
                          textAlign: TextAlign.end,
                          style: const TextStyle(color: AppColors.mutedText),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoExpenses extends StatelessWidget {
  const _NoExpenses();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
        child: Column(
          children: [
            const Icon(
              Icons.donut_large_rounded,
              size: 50,
              color: AppColors.mutedText,
            ),
            const SizedBox(height: 14),
            Text(
              context.l10n.noExpenses,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.noExpensesHint,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mutedText),
            ),
          ],
        ),
      ),
    );
  }
}
