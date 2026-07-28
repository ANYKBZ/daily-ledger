import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_theme.dart';
import 'data/ledger_repository.dart';
import 'l10n/generated/app_localizations.dart';
import 'pages/home_shell.dart';
import 'state/ledger_controller.dart';

class DailyLedgerApp extends StatefulWidget {
  const DailyLedgerApp({super.key, required this.repository, this.locale});

  final LedgerRepository repository;
  final Locale? locale;

  @override
  State<DailyLedgerApp> createState() => _DailyLedgerAppState();
}

class _DailyLedgerAppState extends State<DailyLedgerApp> {
  late final LedgerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LedgerController(widget.repository)..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: widget.locale,
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      theme: AppTheme.light,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomeShell(controller: _controller),
    );
  }
}
