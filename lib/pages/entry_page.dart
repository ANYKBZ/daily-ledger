import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../core/app_colors.dart';
import '../core/formatters.dart';
import '../l10n/localization_extensions.dart';
import '../models/ledger_transaction.dart';
import '../state/ledger_controller.dart';

class EntryPage extends StatefulWidget {
  const EntryPage({super.key, required this.controller});

  final LedgerController controller;

  @override
  State<EntryPage> createState() => _EntryPageState();
}

class _EntryPageState extends State<EntryPage> {
  final _noteController = TextEditingController();
  final _imagePicker = ImagePicker();

  TransactionType _type = TransactionType.expense;
  ExpenseCategory _category = ExpenseCategory.food;
  DateTime _date = DateTools.dateOnly(DateTime.now());
  String _amountText = '';

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _pressKey(String key) {
    setState(() {
      if (key == 'backspace') {
        if (_amountText.isNotEmpty) {
          _amountText = _amountText.substring(0, _amountText.length - 1);
        }
        return;
      }

      if (key == '.') {
        if (_amountText.contains('.')) return;
        _amountText = _amountText.isEmpty ? '0.' : '$_amountText.';
        return;
      }

      final decimalIndex = _amountText.indexOf('.');
      if (decimalIndex >= 0 && _amountText.length - decimalIndex - 1 >= 2) {
        return;
      }
      if (_amountText.length >= 10) return;
      if (_amountText == '0') {
        _amountText = key;
      } else {
        _amountText += key;
      }
    });
  }

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTools.dateOnly(DateTime.now()),
    );
    if (selected != null) setState(() => _date = selected);
  }

  Future<void> _openPhotoMenu() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: Text(context.l10n.takePhoto),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: Text(context.l10n.choosePhoto),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 1800,
      );
      if (image == null || !mounted) return;
      await _showPhotoPreview(image);
      if (source == ImageSource.camera) {
        try {
          await File(image.path).delete();
        } on FileSystemException {
          // The picker may already have cleaned its temporary file.
        }
      }
    } on PlatformException {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.cameraUnavailable)));
    }
  }

  Future<void> _showPhotoPreview(XFile image) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.photoPreviewTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: Image.file(File(image.path), fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 16),
            Text(dialogContext.l10n.photoPreviewMessage),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(dialogContext.l10n.close),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(dialogContext.l10n.continueManually),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final cents = MoneyFormatter.parseCents(_amountText);
    if (cents == null || cents <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.invalidAmount)));
      return;
    }

    await widget.controller.add(
      type: _type,
      amountCents: cents,
      category: _category,
      date: _date,
      note: _noteController.text,
    );
    if (!mounted) return;
    setState(() {
      _type = TransactionType.expense;
      _category = ExpenseCategory.food;
      _date = DateTools.dateOnly(DateTime.now());
      _amountText = '';
      _noteController.clear();
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.saved)));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final categories = ExpenseCategory.values
        .where((category) => category != ExpenseCategory.income)
        .toList(growable: false);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.appName,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            SegmentedButton<TransactionType>(
              segments: [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text(context.l10n.expense),
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text(context.l10n.income),
                  icon: const Icon(Icons.arrow_downward_rounded),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (selection) {
                setState(() => _type = selection.first);
              },
              showSelectedIcon: false,
            ),
            const SizedBox(height: 22),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.amount,
                            style: textTheme.labelLarge?.copyWith(
                              color: AppColors.mutedText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              MoneyFormatter.inputDisplay(_amountText),
                              key: const Key('amount-display'),
                              style: textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: _type == TransactionType.income
                                    ? AppColors.primary
                                    : AppColors.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      key: const Key('receipt-photo-button'),
                      tooltip: context.l10n.photoRecord,
                      onPressed: _openPhotoMenu,
                      icon: const Icon(Icons.document_scanner_rounded),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.l10n.category,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            if (_type == TransactionType.income)
              _CategoryChip(
                selected: true,
                icon: ExpenseCategory.income.icon,
                label: ExpenseCategory.income.label(context.l10n),
                onTap: () {},
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in categories)
                    _CategoryChip(
                      selected: _category == category,
                      icon: category.icon,
                      label: category.label(context.l10n),
                      onTap: () => setState(() => _category = category),
                    ),
                ],
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _chooseDate,
                    icon: const Icon(Icons.calendar_today_rounded, size: 18),
                    label: Text(
                      DateFormat.yMMMd(
                        Localizations.localeOf(context).toLanguageTag(),
                      ).format(_date),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLength: 100,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: context.l10n.note,
                prefixIcon: const Icon(Icons.edit_note_rounded),
                counterText: '',
              ),
            ),
            const SizedBox(height: 14),
            _NumberPad(onKey: _pressKey),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('save-transaction'),
              onPressed: _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(context.l10n.saveTransaction),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primarySoft : AppColors.surface,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.divider,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 19, color: AppColors.primary),
              const SizedBox(width: 7),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberPad extends StatelessWidget {
  const _NumberPad({required this.onKey});

  final ValueChanged<String> onKey;

  @override
  Widget build(BuildContext context) {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0'];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 2.2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        for (final keyValue in keys)
          _KeypadButton(
            key: Key('keypad-$keyValue'),
            onPressed: () => onKey(keyValue),
            child: Text(
              keyValue,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        _KeypadButton(
          key: const Key('keypad-backspace'),
          onPressed: () => onKey('backspace'),
          child: const Icon(Icons.backspace_outlined),
        ),
      ],
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: Center(child: child),
      ),
    );
  }
}
