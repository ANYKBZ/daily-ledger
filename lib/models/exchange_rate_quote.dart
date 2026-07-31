class ExchangeRateQuote {
  const ExchangeRateQuote({
    required this.baseCode,
    required this.quoteCode,
    required this.rate,
    required this.rateDate,
    required this.fetchedAt,
    this.isCached = false,
  });

  final String baseCode;
  final String quoteCode;
  final double rate;
  final DateTime rateDate;
  final DateTime fetchedAt;
  final bool isCached;

  double convert(double amount) => amount * rate;

  ExchangeRateQuote asCached() {
    return ExchangeRateQuote(
      baseCode: baseCode,
      quoteCode: quoteCode,
      rate: rate,
      rateDate: rateDate,
      fetchedAt: fetchedAt,
      isCached: true,
    );
  }

  ExchangeRateQuote reversed() {
    return ExchangeRateQuote(
      baseCode: quoteCode,
      quoteCode: baseCode,
      rate: 1 / rate,
      rateDate: rateDate,
      fetchedAt: fetchedAt,
      isCached: isCached,
    );
  }
}
