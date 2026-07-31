import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shou_zhi_ben/services/exchange_rate_service.dart';

void main() {
  test('loads and caches a validated USD to CNY quote', () async {
    var requestCount = 0;
    final client = MockClient((request) async {
      requestCount += 1;
      expect(request.url.host, 'api.frankfurter.dev');
      expect(request.url.path, '/v2/rate/USD/CNY');
      return http.Response(
        '{"date":"2026-07-31","base":"USD",'
        '"quote":"CNY","rate":6.7583}',
        200,
      );
    });
    final service = FrankfurterExchangeRateService(client: client);

    final first = await service.latest(baseCode: 'USD', quoteCode: 'CNY');
    final second = await service.latest(baseCode: 'USD', quoteCode: 'CNY');

    expect(first.rate, 6.7583);
    expect(first.convert(100), closeTo(675.83, 0.000001));
    expect(first.rateDate, DateTime(2026, 7, 31));
    expect(first.isCached, isFalse);
    expect(second.isCached, isTrue);
    expect(requestCount, 1);
  });

  test('rejects malformed exchange-rate data', () async {
    final client = MockClient(
      (_) async => http.Response(
        '{"date":"2026-07-31","base":"CNY","quote":"USD","rate":0}',
        200,
      ),
    );
    final service = FrankfurterExchangeRateService(client: client);

    expect(
      service.latest(baseCode: 'CNY', quoteCode: 'USD'),
      throwsA(isA<ExchangeRateException>()),
    );
  });
}
