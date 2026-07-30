import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shou_zhi_ben/app.dart';

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
    expect(find.text('\$12.34'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('save-transaction')));
    await tester.tap(find.byKey(const Key('save-transaction')));
    await tester.pumpAndSettle();

    expect(repository.items, hasLength(1));
    expect(repository.items.single.amountCents, 1234);
    expect(find.text('\$0'), findsOneWidget);
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
}
