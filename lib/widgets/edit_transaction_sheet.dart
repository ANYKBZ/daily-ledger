import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../core/formatters.dart';
import '../l10n/localization_extensions.dart';
import '../models/ledger_transaction.dart';
import '../state/ledger_controller.dart';

class EditTransactionSheet extends StatefulWidget {
  const EditTransactionSheet({
    super.key,
    required this.transaction,
    required this.controller,
  });

  final LedgerTransaction transaction;
  final LedgerController controller;

  @override
  State<EditTransactionSheet> createState() => _EditTransactionSheetState();
}

class _EditTransactionSheetState extends State<EditTransactionSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late TransactionType _type;
  late ExpenseCategory _category;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: (widget.transaction.amountCents / 100).toStringAsFixed(2),
    );
    _noteController = TextEditingController(text: widget.transaction.note);
    _type = widget.transaction.type;
    _category = widget.transaction.category == ExpenseCategory.income
        ? ExpenseCategory.food
        : widget.transaction.category;
    _date = widget.transaction.date;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTools.dateOnly(DateTime.now()),
    );
    if (selected != null) setState(() => _date = selected);
  }

  Future<void> _save() async {
    final cents = MoneyFormatter.parseCents(_amountController.text);
    if (cents == null || cents <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.invalidAmount)));
      return;
    }
    final note = _noteController.text.trim();
    final updated = LedgerTransaction(
      id: widget.transaction.id,
      type: _type,
      amountCents: cents,
      category: _type == TransactionType.income
          ? ExpenseCategory.income
          : _category,
      date: DateTools.dateOnly(_date),
      note: note.isEmpty ? null : note,
      source: widget.transaction.source,
      createdAt: widget.transaction.createdAt,
      updatedAt: DateTime.now(),
    );
    await widget.controller.updateTransaction(updated);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final categories = ExpenseCategory.values
        .where((category) => category != ExpenseCategory.income)
        .toList(growable: false);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.editTransaction,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            SegmentedButton<TransactionType>(
              segments: [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text(context.l10n.expense),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text(context.l10n.income),
                ),
              ],
              selected: {_type},
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                setState(() => _type = selection.first);
              },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: context.l10n.amount,
                prefixText: '\$ ',
              ),
            ),
            const SizedBox(height: 14),
            if (_type == TransactionType.expense)
              DropdownButtonFormField<ExpenseCategory>(
                initialValue: _category,
                decoration: InputDecoration(labelText: context.l10n.category),
                items: [
                  for (final category in categories)
                    DropdownMenuItem(
                      value: category,
                      child: Row(
                        children: [
                          Icon(category.icon, size: 20),
                          const SizedBox(width: 10),
                          Text(category.label(context.l10n)),
                        ],
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
            if (_type == TransactionType.expense) const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _selectDate,
              icon: const Icon(Icons.calendar_today_rounded, size: 18),
              label: Text(DateFormat.yMMMd(locale).format(_date)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _noteController,
              maxLength: 100,
              decoration: InputDecoration(
                labelText: context.l10n.note,
                counterText: '',
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(context.l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: Text(context.l10n.saveChanges),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
