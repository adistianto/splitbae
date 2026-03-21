import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:splitbae/core/data/amount_minor.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:splitbae/providers.dart';
import 'package:splitbae/screens/draft_split_screen.dart';

Future<void> showAddTransactionSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => _AddTransactionSheetBody(hostContext: context),
  );
}

class _AddTransactionSheetBody extends ConsumerStatefulWidget {
  const _AddTransactionSheetBody({required this.hostContext});

  final BuildContext hostContext;

  @override
  ConsumerState<_AddTransactionSheetBody> createState() =>
      _AddTransactionSheetBodyState();
}

class _AddTransactionSheetBodyState extends ConsumerState<_AddTransactionSheetBody> {
  final _desc = TextEditingController();
  final _tax = TextEditingController();
  DateTime _date = DateTime.now();
  String _category = 'other';
  String? _receiptPath;

  @override
  void dispose() {
    _desc.dispose();
    _tax.dispose();
    super.dispose();
  }

  String _primaryCurrency() {
    final items = ref.read(itemsProvider);
    if (items.isEmpty) return 'IDR';
    return items.first.receiptItem.currencyCode;
  }

  int _taxMinor(String currencyCode) {
    final raw = _tax.text.trim();
    if (raw.isEmpty) return 0;
    final v = double.tryParse(raw.replaceAll(',', '.'));
    if (v == null || v < 0) return 0;
    return amountToMinorUnits(v, currencyCode);
  }

  String _errorMessage(Object e, AppLocalizations l10n) {
    if (e is StateError) {
      switch (e.message) {
        case 'empty_bill':
          return l10n.postBillErrorEmpty;
        case 'empty_participants':
          return l10n.postBillErrorNoParticipants;
        default:
          break;
      }
    }
    return e.toString();
  }

  Future<void> _pickReceipt() async {
    HapticFeedback.selectionClick();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(AppLocalizations.of(ctx)!.scanReceiptGallery),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(AppLocalizations.of(ctx)!.scanReceiptCamera),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 85);
    if (file == null || !mounted) return;
    setState(() => _receiptPath = file.path);
  }

  Future<void> _post(AppLocalizations l10n) async {
    final messenger = ScaffoldMessenger.of(widget.hostContext);
    final ccy = _primaryCurrency();
    try {
      final at = DateTime(_date.year, _date.month, _date.day);
      await ref.read(itemsProvider.notifier).postDraftBill(
            _desc.text.trim(),
            category: _category,
            createdAtMs: at.millisecondsSinceEpoch,
            taxAmountMinor: _taxMinor(ccy),
            receiptSourcePath: _receiptPath,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.postBillSuccess)));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(_errorMessage(e, l10n))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final items = ref.watch(itemsProvider);
    final people = ref.watch(participantsProvider);
    final ccy = items.isEmpty ? 'IDR' : items.first.receiptItem.currencyCode;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final h = MediaQuery.sizeOf(context).height;

    return SizedBox(
      height: (h * 0.92).clamp(400.0, h),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 16 + bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.addTransactionSheetTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.addTransactionSheetSubtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _desc,
                      decoration: InputDecoration(
                        labelText: l10n.postBillDescriptionLabel,
                        hintText: l10n.postBillDescriptionHint,
                        border: const OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.addTransactionCategoryLabel,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final c in _categories)
                          ChoiceChip(
                            label: Text(_categoryLabel(c, l10n)),
                            selected: _category == c,
                            onSelected: (_) => setState(() => _category = c),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.addTransactionDateLabel),
                      subtitle: Text(
                        DateFormat.yMMMd(locale.toString()).format(_date),
                      ),
                      trailing: const Icon(Icons.calendar_today_outlined),
                      onTap: () async {
                        HapticFeedback.selectionClick();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => _date = picked);
                        }
                      },
                    ),
                    TextField(
                      controller: _tax,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: '${l10n.addTransactionTaxLabel} ($ccy)',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.addTransactionReceiptLabel,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        FilledButton.tonal(
                          onPressed: _pickReceipt,
                          child: Text(l10n.addTransactionReceiptPick),
                        ),
                        if (_receiptPath != null) ...[
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => setState(() => _receiptPath = null),
                            child: Text(l10n.addTransactionReceiptRemove),
                          ),
                        ],
                      ],
                    ),
                    if (_receiptPath != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.file(
                            File(_receiptPath!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      l10n.addTransactionDraftSummary(
                        items.length,
                        people.length,
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pop();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  openDraftSplitScreen(widget.hostContext, ref);
                });
              },
              icon: const Icon(Icons.edit_note_outlined),
              label: Text(l10n.addTransactionOpenDraft),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _post(l10n);
              },
              child: Text(l10n.addTransactionPostAction),
            ),
          ],
        ),
      ),
    );
  }

  static const _categories = [
    'food',
    'transport',
    'accommodation',
    'other',
  ];

  String _categoryLabel(String id, AppLocalizations l10n) {
    switch (id) {
      case 'food':
        return l10n.categoryFood;
      case 'transport':
        return l10n.categoryTransport;
      case 'accommodation':
        return l10n.categoryAccommodation;
      default:
        return l10n.categoryOther;
    }
  }
}
