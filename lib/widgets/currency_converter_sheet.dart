import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../core/app_colors.dart';
import '../l10n/localization_extensions.dart';
import '../models/exchange_rate_quote.dart';
import '../services/exchange_rate_service.dart';

enum _Currency {
  cny(code: 'CNY', symbol: '¥'),
  usd(code: 'USD', symbol: r'$');

  const _Currency({required this.code, required this.symbol});

  final String code;
  final String symbol;
}

class CurrencyConverterSheet extends StatefulWidget {
  const CurrencyConverterSheet({super.key, required this.provider});

  final ExchangeRateProvider provider;

  @override
  State<CurrencyConverterSheet> createState() => _CurrencyConverterSheetState();
}

class _CurrencyConverterSheetState extends State<CurrencyConverterSheet> {
  final _amountController = TextEditingController(text: '100');

  _Currency _from = _Currency.cny;
  _Currency _to = _Currency.usd;
  ExchangeRateQuote? _quote;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_loadRate());
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadRate({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final quote = await widget.provider.latest(
        baseCode: _from.code,
        quoteCode: _to.code,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() => _quote = quote);
    } on ExchangeRateException {
      if (!mounted) return;
      setState(() => _error = context.l10n.rateError);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = context.l10n.rateError);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _swapCurrencies() {
    setState(() {
      final previousFrom = _from;
      _from = _to;
      _to = previousFrom;
      _quote = _quote?.reversed();
      _error = null;
    });
    unawaited(_loadRate());
  }

  double? get _amount {
    final normalized = _amountController.text.replaceAll(',', '').trim();
    final amount = double.tryParse(normalized);
    if (amount == null || amount < 0) return null;
    return amount;
  }

  String _currencyName(BuildContext context, _Currency currency) {
    return currency == _Currency.cny
        ? context.l10n.chineseYuan
        : context.l10n.usDollar;
  }

  String _formatCurrency(
    BuildContext context,
    _Currency currency,
    double amount,
  ) {
    return NumberFormat.currency(
      locale: Localizations.localeOf(context).toLanguageTag(),
      symbol: currency.symbol,
      decimalDigits: 2,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final quote = _quote;
    final amount = _amount;
    final converted = quote == null || amount == null
        ? null
        : quote.convert(amount);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.currency_exchange_rounded,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.l10n.currencyConverter,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.close,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _CurrencyTile(
                    code: _from.code,
                    name: _currencyName(context, _from),
                    label: context.l10n.fromCurrency,
                    highlighted: true,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: IconButton.filled(
                    key: const Key('swap-currencies'),
                    tooltip: context.l10n.switchCurrencies,
                    onPressed: _swapCurrencies,
                    style: IconButton.styleFrom(
                      minimumSize: const Size(52, 52),
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.primaryDark,
                    ),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 28),
                  ),
                ),
                Expanded(
                  child: _CurrencyTile(
                    code: _to.code,
                    name: _currencyName(context, _to),
                    label: context.l10n.toCurrency,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              key: const Key('currency-amount-input'),
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d{0,9}([.]\d{0,2})?'),
                ),
              ],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: context.l10n.amountToConvert,
                prefixText: '${_from.symbol} ',
                suffixText: _from.code,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.convertedResult,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 7),
                  if (_isLoading && quote == null)
                    const SizedBox(
                      height: 38,
                      width: 38,
                      child: CircularProgressIndicator(
                        color: AppColors.gold,
                        strokeWidth: 3,
                      ),
                    )
                  else
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        converted == null
                            ? '—'
                            : _formatCurrency(context, _to, converted),
                        key: const Key('converted-amount'),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                  if (converted != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${_to.code} · ${_currencyName(context, _to)}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (_error != null)
              _RateError(
                message: _error!,
                onRetry: () => unawaited(_loadRate(forceRefresh: true)),
              )
            else if (quote != null)
              _RateDetails(
                quote: quote,
                onRefresh: () => unawaited(_loadRate(forceRefresh: true)),
                isLoading: _isLoading,
              ),
            const SizedBox(height: 12),
            Text(
              context.l10n.currencyDisclaimer,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.exchangeRateSource,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mutedText, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyTile extends StatelessWidget {
  const _CurrencyTile({
    required this.code,
    required this.name,
    required this.label,
    this.highlighted = false,
  });

  final String code;
  final String name;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.goldSoft : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted ? AppColors.gold : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.mutedText, fontSize: 11),
          ),
          const SizedBox(height: 5),
          Text(
            code,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _RateDetails extends StatelessWidget {
  const _RateDetails({
    required this.quote,
    required this.onRefresh,
    required this.isLoading,
  });

  final ExchangeRateQuote quote;
  final VoidCallback onRefresh;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final rateDigits = quote.rate < 1 ? 5 : 4;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.public_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '1 ${quote.baseCode} = '
                  '${quote.rate.toStringAsFixed(rateDigits)} ${quote.quoteCode}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  context.l10n.rateDate(
                    DateFormat.yMMMd(locale).format(quote.rateDate),
                  ),
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: context.l10n.refreshRate,
            onPressed: isLoading ? null : onRefresh,
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}

class _RateError extends StatelessWidget {
  const _RateError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.expense),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: Text(context.l10n.retry)),
        ],
      ),
    );
  }
}
