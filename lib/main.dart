import 'package:flutter/material.dart';

import 'app.dart';
import 'data/ledger_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(DailyLedgerApp(repository: SqfliteLedgerRepository()));
}
