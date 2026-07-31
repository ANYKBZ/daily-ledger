import 'package:flutter_test/flutter_test.dart';
import 'package:shou_zhi_ben/core/formatters.dart';

void main() {
  group('MoneyFormatter', () {
    test('parses valid dollar inputs into exact cents', () {
      expect(MoneyFormatter.parseCents('12'), 1200);
      expect(MoneyFormatter.parseCents('12.3'), 1230);
      expect(MoneyFormatter.parseCents('12.34'), 1234);
      expect(MoneyFormatter.parseCents('0.01'), 1);
    });

    test('rejects invalid or over-precise inputs', () {
      expect(MoneyFormatter.parseCents(''), isNull);
      expect(MoneyFormatter.parseCents('.50'), isNull);
      expect(MoneyFormatter.parseCents('1.234'), isNull);
      expect(MoneyFormatter.parseCents('-1'), isNull);
      expect(MoneyFormatter.parseCents('money'), isNull);
    });

    test('formats signed dollar values', () {
      expect(MoneyFormatter.currency(1234, signed: true), '+\$12.34');
      expect(MoneyFormatter.currency(-1234, signed: true), '-\$12.34');
    });

    test('converts USD cents to signed CNY', () {
      expect(
        MoneyFormatter.convertedCurrency(900000, rate: 6.7583, signed: true),
        '+¥60,824.70',
      );
      expect(
        MoneyFormatter.convertedCurrency(-1234, rate: 6.7583, signed: true),
        '-¥83.40',
      );
    });
  });

  test('database dates remain local calendar dates', () {
    final date = DateTime(2026, 7, 27, 23, 59);
    expect(DateTools.databaseDate(date), '2026-07-27');
    expect(DateTools.parseDatabaseDate('2026-07-27'), DateTime(2026, 7, 27));
  });
}
