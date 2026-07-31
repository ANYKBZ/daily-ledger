import 'dart:async';
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
import '../widgets/mamba_page_header.dart';

class EntryPage extends StatefulWidget {
  const EntryPage({super.key, required this.controller});

  final LedgerController controller;

  @override
  State<EntryPage> createState() => _EntryPageState();
}

class _EntryPageState extends State<EntryPage> {
  final _noteController = TextEditingController();
  final _imagePicker = ImagePicker();
  Timer? _successTimer;

  TransactionType _type = TransactionType.expense;
  ExpenseCategory _category = ExpenseCategory.food;
  DateTime _date = DateTools.dateOnly(DateTime.now());
  String _amountText = '';
  bool _showSuccessBanner = false;

  @override
  void dispose() {
    _successTimer?.cancel();
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
      _showSuccessBanner = true;
    });
    _successTimer?.cancel();
    _successTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _showSuccessBanner = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final categories = ExpenseCategory.values
        .where((category) => category != ExpenseCategory.income)
        .toList(growable: false);

    final accent = _type == TransactionType.expense
        ? AppColors.expense
        : AppColors.income;

    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MambaPageHeader(
                        title: context.l10n.appName,
                        subtitle: context.l10n.mambaTagline,
                      ),
                      const SizedBox(height: 16),
                      _TransactionTypeSelector(
                        type: _type,
                        onChanged: (type) => setState(() => _type = type),
                      ),
                      const SizedBox(height: 14),
                      _AmountPanel(
                        amountText: _amountText,
                        type: _type,
                        accent: accent,
                        onPhotoPressed: _openPhotoMenu,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        context.l10n.category,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _CategorySelector(
                        type: _type,
                        categories: categories,
                        selected: _category,
                        onSelected: (category) =>
                            setState(() => _category = category),
                      ),
                      const SizedBox(height: 16),
                      _EntryDetailsCard(
                        date: _date,
                        noteController: _noteController,
                        onChooseDate: _chooseDate,
                      ),
                      const SizedBox(height: 14),
                      _NumberPad(onKey: _pressKey),
                    ],
                  ),
                ),
              ),
              _SaveBar(accent: accent, onSave: _save),
            ],
          ),
          Positioned(
            top: 10,
            left: 20,
            right: 20,
            child: _SavedBanner(visible: _showSuccessBanner),
          ),
        ],
      ),
    );
  }
}

class _TransactionTypeSelector extends StatelessWidget {
  const _TransactionTypeSelector({required this.type, required this.onChanged});

  final TransactionType type;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TypeButton(
              key: const Key('expense-type'),
              selected: type == TransactionType.expense,
              label: context.l10n.expense,
              icon: Icons.arrow_upward_rounded,
              color: AppColors.expense,
              onTap: () => onChanged(TransactionType.expense),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _TypeButton(
              key: const Key('income-type'),
              selected: type == TransactionType.income,
              label: context.l10n.income,
              icon: Icons.arrow_downward_rounded,
              color: AppColors.income,
              onTap: () => onChanged(TransactionType.income),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    super.key,
    required this.selected,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? Colors.white : AppColors.mutedText,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountPanel extends StatelessWidget {
  const _AmountPanel({
    required this.amountText,
    required this.type,
    required this.accent,
    required this.onPhotoPressed,
  });

  final String amountText;
  final TransactionType type;
  final Color accent;
  final VoidCallback onPhotoPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 18),
      decoration: BoxDecoration(
        color: Color.alphaBlend(accent.withAlpha(22), AppColors.surface),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withAlpha(70)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: accent.withAlpha(28),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  type == TransactionType.expense
                      ? context.l10n.expense
                      : context.l10n.income,
                  style: TextStyle(color: accent, fontWeight: FontWeight.w800),
                ),
              ),
              const Spacer(),
              IconButton.filled(
                key: const Key('receipt-photo-button'),
                tooltip: context.l10n.photoRecord,
                onPressed: onPhotoPressed,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.primary,
                ),
                icon: const Icon(Icons.document_scanner_rounded),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              MoneyFormatter.inputDisplay(amountText),
              key: const Key('amount-display'),
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.5,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            context.l10n.amount,
            style: const TextStyle(
              color: AppColors.mutedText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    required this.type,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final TransactionType type;
  final List<ExpenseCategory> categories;
  final ExpenseCategory selected;
  final ValueChanged<ExpenseCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    if (type == TransactionType.income) {
      return Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 72,
          child: _CategoryTile(
            selected: true,
            category: ExpenseCategory.income,
            color: AppColors.income,
            onTap: () {},
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < categories.length; index++) ...[
          if (index > 0) const SizedBox(width: 4),
          Expanded(
            child: _CategoryTile(
              selected: selected == categories[index],
              category: categories[index],
              color: AppColors.categoryColors[index],
              onTap: () => onSelected(categories[index]),
            ),
          ),
        ],
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.selected,
    required this.category,
    required this.color,
    required this.onTap,
  });

  final bool selected;
  final ExpenseCategory category;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: selected ? color : AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: selected ? color : AppColors.divider),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: color.withAlpha(45),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                category.icon,
                size: 21,
                color: selected ? Colors.white : AppColors.primary,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              category.label(context.l10n),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? AppColors.text : AppColors.mutedText,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryDetailsCard extends StatelessWidget {
  const _EntryDetailsCard({
    required this.date,
    required this.noteController,
    required this.onChooseDate,
  });

  final DateTime date;
  final TextEditingController noteController;
  final VoidCallback onChooseDate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          InkWell(
            onTap: onChooseDate,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    context.l10n.date,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat.yMMMd(
                      Localizations.localeOf(context).toLanguageTag(),
                    ).format(date),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.mutedText,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          TextField(
            controller: noteController,
            maxLength: 100,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: context.l10n.note,
              prefixIcon: const Icon(Icons.edit_note_rounded),
              counterText: '',
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.accent, required this.onSave});

  final Color accent;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('save-action-bar'),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: FilledButton.icon(
        key: const Key('save-transaction'),
        onPressed: onSave,
        icon: const Icon(Icons.add_rounded),
        label: Text(context.l10n.saveTransaction),
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _SavedBanner extends StatelessWidget {
  const _SavedBanner({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedSlide(
        key: const Key('saved-banner-slide'),
        offset: visible ? Offset.zero : const Offset(0, -1.5),
        duration: const Duration(milliseconds: 180),
        curve: visible ? Curves.easeOutCubic : Curves.easeInCubic,
        child: AnimatedOpacity(
          key: const Key('saved-banner'),
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 140),
          child: Material(
            color: AppColors.income,
            elevation: 8,
            shadowColor: AppColors.primaryDark.withAlpha(65),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  const SizedBox(width: 9),
                  Text(
                    context.l10n.saved,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        _KeypadButton(
          key: const Key('keypad-backspace'),
          onPressed: () => onKey('backspace'),
          child: const Icon(Icons.backspace_outlined, color: AppColors.primary),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Center(child: child),
      ),
    );
  }
}
