import 'package:flutter/material.dart';

import '../l10n/localization_extensions.dart';
import '../state/ledger_controller.dart';
import 'entry_page.dart';
import 'statistics_page.dart';
import 'transactions_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller});

  final LedgerController controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      EntryPage(controller: widget.controller),
      TransactionsPage(
        controller: widget.controller,
        onRecordRequested: () => setState(() => _selectedIndex = 0),
      ),
      StatisticsPage(controller: widget.controller),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.add_circle_outline_rounded),
            selectedIcon: const Icon(Icons.add_circle_rounded),
            label: context.l10n.recordTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long_rounded),
            label: context.l10n.transactionsTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.donut_large_outlined),
            selectedIcon: const Icon(Icons.donut_large_rounded),
            label: context.l10n.statisticsTab,
          ),
        ],
      ),
    );
  }
}
