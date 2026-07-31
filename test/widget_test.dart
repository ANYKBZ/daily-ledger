import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shou_zhi_ben/app.dart';
import 'package:shou_zhi_ben/models/exchange_rate_quote.dart';
import 'package:shou_zhi_ben/models/ledger_transaction.dart';
import 'package:shou_zhi_ben/services/exchange_rate_service.dart';

import 'support/in_memory_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('records a transaction and updates all three separate pages', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = InMemoryLedgerRepository();

    await tester.pumpWidget(
      DailyLedgerApp(repository: repository, locale: const Locale('zh')),
    );
    await tester.pumpAndSettle();

    expect(find.text('收支本'), findsOneWidget);
    expect(find.text('MAMBA MODE'), findsOneWidget);
    expect(find.text('8  •  24'), findsOneWidget);
    expect(find.text('记账'), findsOneWidget);
    expect(find.text('明细'), findsOneWidget);
    expect(find.text('统计'), findsOneWidget);

    for (final key in ['1', '2', '.', '3', '4']) {
      final keyFinder = find.byKey(Key('keypad-$key'));
      await tester.ensureVisible(keyFinder);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: keyFinder, matching: find.byType(InkWell)),
      );
      await tester.pump();
    }
    expect(
      tester.widget<Text>(find.byKey(const Key('amount-display'))).data,
      '\$12.34',
    );

    await tester.ensureVisible(find.byKey(const Key('save-transaction')));
    await tester.tap(find.byKey(const Key('save-transaction')));
    await tester.pumpAndSettle();

    expect(repository.items, hasLength(1));
    expect(repository.items.single.amountCents, 1234);
    expect(
      tester.widget<Text>(find.byKey(const Key('amount-display'))).data,
      '\$0',
    );
    expect(find.text('保存成功'), findsOneWidget);

    await tester.tap(find.text('明细'));
    await tester.pumpAndSettle();
    expect(find.text('-\$12.34'), findsOneWidget);

    await tester.tap(find.text('统计'));
    await tester.pumpAndSettle();
    expect(find.text('\$12.34'), findsWidgets);
    expect(find.text('餐饮'), findsOneWidget);
  });

  testWidgets('receipt button exposes camera and photo library choices', (
    tester,
  ) async {
    await tester.pumpWidget(
      DailyLedgerApp(
        repository: InMemoryLedgerRepository(),
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('receipt-photo-button')));
    await tester.pumpAndSettle();

    expect(find.text('Take photo'), findsOneWidget);
    expect(find.text('Choose from library'), findsOneWidget);
  });

  testWidgets('toggles transaction amounts between USD and CNY in place', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.now();
    final repository = InMemoryLedgerRepository()
      ..items.add(
        LedgerTransaction(
          id: 1,
          type: TransactionType.income,
          amountCents: 900000,
          category: ExpenseCategory.income,
          date: now,
          createdAt: now,
          updatedAt: now,
        ),
      );

    await tester.pumpWidget(
      DailyLedgerApp(
        repository: repository,
        locale: const Locale('zh'),
        exchangeRateProvider: _FakeExchangeRateProvider(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('明细'));
    await tester.pumpAndSettle();
    expect(find.text(r'+$9,000.00'), findsOneWidget);

    await tester.tap(find.byKey(const Key('currency-converter-button')));
    await tester.pumpAndSettle();

    expect(find.text('+¥60,824.70'), findsOneWidget);
    expect(find.text('货币转换'), findsNothing);

    await tester.tap(find.byKey(const Key('currency-converter-button')));
    await tester.pumpAndSettle();

    expect(find.text(r'+$9,000.00'), findsOneWidget);
  });
}

class _FakeExchangeRateProvider implements ExchangeRateProvider {
  @override
  Future<ExchangeRateQuote> latest({
    required String baseCode,
    required String quoteCode,
    bool forceRefresh = false,
  }) async {
    return ExchangeRateQuote(
      baseCode: baseCode,
      quoteCode: quoteCode,
      rate: 6.7583,
      rateDate: DateTime(2026, 7, 31),
      fetchedAt: DateTime(2026, 7, 31, 8),
    );
  }
}
