import 'package:intl/intl.dart';

abstract final class MoneyFormatter {
  static int? parseCents(String value) {
    final normalized = value.trim();
    if (!RegExp(r'^\d+(\.\d{0,2})?$').hasMatch(normalized)) {
      return null;
    }
    final parts = normalized.split('.');
    final dollars = int.tryParse(parts.first);
    if (dollars == null) return null;
    final centsText = parts.length == 1 ? '00' : parts[1].padRight(2, '0');
    final cents = int.tryParse(centsText);
    if (cents == null) return null;
    return dollars * 100 + cents;
  }

  static String inputDisplay(String value) {
    if (value.isEmpty) return '\$0';
    return '\$$value';
  }

  static String currency(int cents, {bool signed = false}) {
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$',
      decimalDigits: 2,
    );
    final value = formatter.format(cents.abs() / 100);
    if (!signed || cents == 0) return value;
    return cents > 0 ? '+$value' : '-$value';
  }

  static String convertedCurrency(
    int usdCents, {
    required double rate,
    bool signed = false,
  }) {
    final formatter = NumberFormat.currency(
      locale: 'zh_CN',
      symbol: '¥',
      decimalDigits: 2,
    );
    final value = formatter.format(usdCents.abs() / 100 * rate);
    if (!signed || usdCents == 0) return value;
    return usdCents > 0 ? '+$value' : '-$value';
  }
}

abstract final class DateTools {
  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static DateTime monthOnly(DateTime value) =>
      DateTime(value.year, value.month);

  static String databaseDate(DateTime value) =>
      DateFormat('yyyy-MM-dd').format(value);

  static DateTime parseDatabaseDate(String value) => DateTime.parse(value);

  static String monthLabel(DateTime value, String locale) =>
      DateFormat.yMMMM(locale).format(value);

  static String dayLabel(DateTime value, String locale) =>
      DateFormat.MMMEd(locale).format(value);
}
