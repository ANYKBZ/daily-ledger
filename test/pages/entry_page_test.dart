import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shou_zhi_ben/app.dart';

import '../support/in_memory_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'keeps add action visible, shows a top success animation, and syncs pages',
    (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = InMemoryLedgerRepository();

      await tester.pumpWidget(
        DailyLedgerApp(repository: repository, locale: const Locale('zh')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('save-transaction')).hitTestable(),
        findsOneWidget,
      );
      expect(
        tester
            .widget<AnimatedOpacity>(find.byKey(const Key('saved-banner')))
            .opacity,
        0,
      );

      final oneKey = find.byKey(const Key('keypad-1'));
      await tester.ensureVisible(oneKey);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: oneKey, matching: find.byType(InkWell)),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('save-transaction')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 180));

      expect(repository.items, hasLength(1));
      expect(find.byType(SnackBar), findsNothing);
      expect(
        tester
            .widget<AnimatedSlide>(find.byKey(const Key('saved-banner-slide')))
            .offset,
        Offset.zero,
      );
      expect(
        tester
            .widget<AnimatedOpacity>(find.byKey(const Key('saved-banner')))
            .opacity,
        1,
      );

      await tester.pump(const Duration(milliseconds: 319));
      expect(
        tester
            .widget<AnimatedOpacity>(find.byKey(const Key('saved-banner')))
            .opacity,
        1,
      );
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 180));
      expect(
        tester
            .widget<AnimatedSlide>(find.byKey(const Key('saved-banner-slide')))
            .offset,
        const Offset(0, -1.5),
      );
      expect(
        tester
            .widget<AnimatedOpacity>(find.byKey(const Key('saved-banner')))
            .opacity,
        0,
      );

      await tester.tap(find.text('明细'));
      await tester.pumpAndSettle();
      expect(find.text('-\$1.00'), findsOneWidget);

      await tester.tap(find.text('统计'));
      await tester.pumpAndSettle();
      expect(find.text('\$1.00'), findsWidgets);
      expect(find.text('餐饮'), findsOneWidget);
    },
  );
}
