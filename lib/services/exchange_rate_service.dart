import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/exchange_rate_quote.dart';

abstract interface class ExchangeRateProvider {
  Future<ExchangeRateQuote> latest({
    required String baseCode,
    required String quoteCode,
    bool forceRefresh = false,
  });
}

class ExchangeRateException implements Exception {
  const ExchangeRateException(this.message);

  final String message;

  @override
  String toString() => 'ExchangeRateException: $message';
}

class FrankfurterExchangeRateService implements ExchangeRateProvider {
  FrankfurterExchangeRateService({
    http.Client? client,
    this.cacheDuration = const Duration(minutes: 5),
    this.requestTimeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;
  final Duration cacheDuration;
  final Duration requestTimeout;
  final Map<String, ExchangeRateQuote> _cache = {};

  @override
  Future<ExchangeRateQuote> latest({
    required String baseCode,
    required String quoteCode,
    bool forceRefresh = false,
  }) async {
    final base = baseCode.toUpperCase();
    final quote = quoteCode.toUpperCase();
    if (base == quote) {
      throw const ExchangeRateException('Currencies must be different.');
    }

    final cacheKey = '$base-$quote';
    final cached = _cache[cacheKey];
    final now = DateTime.now();
    if (!forceRefresh &&
        cached != null &&
        now.difference(cached.fetchedAt) < cacheDuration) {
      return cached.asCached();
    }

    final uri = Uri.https('api.frankfurter.dev', '/v2/rate/$base/$quote');

    try {
      final response = await _client.get(uri).timeout(requestTimeout);
      if (response.statusCode != 200) {
        throw ExchangeRateException(
          'Unexpected response status ${response.statusCode}.',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const ExchangeRateException('Malformed response.');
      }

      final responseBase = decoded['base'];
      final responseQuote = decoded['quote'];
      final responseRate = decoded['rate'];
      final responseDate = decoded['date'];
      if (responseBase != base ||
          responseQuote != quote ||
          responseRate is! num ||
          responseRate <= 0 ||
          responseDate is! String) {
        throw const ExchangeRateException('Invalid rate data.');
      }

      final quoteResult = ExchangeRateQuote(
        baseCode: base,
        quoteCode: quote,
        rate: responseRate.toDouble(),
        rateDate: DateTime.parse(responseDate),
        fetchedAt: now,
      );
      _cache[cacheKey] = quoteResult;
      return quoteResult;
    } on TimeoutException catch (_) {
      if (cached != null) return cached.asCached();
      throw const ExchangeRateException('Request timed out.');
    } on FormatException catch (_) {
      if (cached != null) return cached.asCached();
      throw const ExchangeRateException('Invalid response format.');
    } on http.ClientException catch (_) {
      if (cached != null) return cached.asCached();
      throw const ExchangeRateException('Network request failed.');
    } on ExchangeRateException {
      if (cached != null) return cached.asCached();
      rethrow;
    }
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}
