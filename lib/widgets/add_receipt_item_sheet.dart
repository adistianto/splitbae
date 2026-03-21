import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitbae/app_settings.dart';
import 'package:splitbae/core/data/amount_minor.dart';
import 'package:splitbae/core/domain/ledger_line_item.dart';
import 'package:splitbae/core/platform/host_platform.dart';
import 'package:splitbae/currency_catalog.dart';
import 'package:splitbae/core/ocr/receipt_ocr_probe_provider.dart';
import 'package:splitbae/providers.dart';
import 'package:splitbae/widgets/item_assignee_chips.dart';
import 'package:splitbae/widgets/receipt_scan_flow.dart';

Widget receiptOcrProbeBanner(
  BuildContext context,
  WidgetRef ref,
  AppLocalizations l10n, {
  required bool material,
}) {
  final probe = ref.watch(receiptOcrProbeProvider);
  Widget card(String text) {
    if (material) {
      final scheme = Theme.of(context).colorScheme;
      return Card(
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.9),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: scheme.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemFill.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              CupertinoIcons.info,
              size: 20,
              color: CupertinoColors.systemOrange.resolveFrom(context),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  return probe.when(
    data: (p) {
      if (p.ready) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: card(l10n.scanReceiptDegradedBody),
      );
    },
    loading: () => const SizedBox.shrink(),
    error: (_, _) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: card(l10n.scanReceiptDegradedBody),
    ),
  );
}

/// iOS: glass-style modal. Android: M3 bottom sheet.
/// Pass [existingLine] to edit; omit to add a new line.
Future<void> showAddReceiptItemSheet(
  BuildContext context,
  WidgetRef ref, {
  LedgerLineItem? existingLine,
}) {
  if (hostPlatformIsApple()) {
    return _showCupertinoGlassSheet(context, ref, existingLine: existingLine);
  }
  return _showMaterialExpressiveSheet(context, ref, existingLine: existingLine);
}

Future<void> _openCurrencyPicker({
  required BuildContext context,
  required String selected,
  required ValueChanged<String> onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: ListView(
          children: [
            for (final code in kSupportedCurrencyCodes)
              ListTile(
                title: Text(currencyMenuLabel(code)),
                trailing: code == selected
                    ? Icon(
                        Icons.check,
                        color: Theme.of(ctx).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  onSelected(code);
                  Navigator.of(ctx).pop();
                },
              ),
          ],
        ),
      );
    },
  );
}

Future<void> _showCupertinoGlassSheet(
  BuildContext context,
  WidgetRef ref, {
  LedgerLineItem? existingLine,
}) {
  return showCupertinoModalPopup<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (ctx) {
      final bottomInset = MediaQuery.viewInsetsOf(ctx).bottom;
      final brightness = MediaQuery.platformBrightnessOf(ctx);
      final isDark = brightness == Brightness.dark;
      final reduceMotion = MediaQuery.disableAnimationsOf(ctx);
      final glassTint = isDark
          ? const Color(0xFF2C2C2E).withValues(alpha: 0.72)
          : CupertinoColors.systemBackground
                .resolveFrom(ctx)
                .withValues(alpha: 0.82);

      final sheetBody = DecoratedBox(
        decoration: BoxDecoration(
          color: glassTint,
          borderRadius: const BorderRadius.all(Radius.circular(22)),
          border: Border.all(
            color: CupertinoColors.separator
                .resolveFrom(ctx)
                .withValues(alpha: 0.35),
          ),
          boxShadow: reduceMotion
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
        ),
        child: CupertinoTheme(
          data: CupertinoTheme.of(ctx).copyWith(
            brightness: brightness,
            primaryColor: CupertinoColors.activeBlue.resolveFrom(ctx),
          ),
          child: _AddItemFormCupertino(existingLine: existingLine),
        ),
      );

      return Padding(
        padding: EdgeInsets.only(left: 16, right: 16, bottom: 16 + bottomInset),
        child: SafeArea(
          top: false,
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(22)),
            child: reduceMotion
                ? sheetBody
                : BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                    child: sheetBody,
                  ),
          ),
        ),
      );
    },
  );
}

class _AddItemFormCupertino extends ConsumerStatefulWidget {
  const _AddItemFormCupertino({this.existingLine});

  final LedgerLineItem? existingLine;

  @override
  ConsumerState<_AddItemFormCupertino> createState() =>
      _AddItemFormCupertinoState();
}

class _AddItemFormCupertinoState extends ConsumerState<_AddItemFormCupertino> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late String _currencyCode;
  late Set<String> _assigneeIds;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingLine;
    final item = existing?.receiptItem;
    _nameCtrl = TextEditingController(text: item?.name ?? '');
    _priceCtrl = TextEditingController(
      text: item != null
          ? amountToInputText(item.price, item.currencyCode)
          : '',
    );
    _currencyCode = item?.currencyCode ?? ref.read(defaultCurrencyProvider);
    _assigneeIds = Set.from(existing?.assignedParticipantIds ?? const []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context, AppLocalizations l10n) async {
    setState(() => _error = null);
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = l10n.errorNameRequired);
      return;
    }
    final raw = _priceCtrl.text.trim().replaceAll(RegExp(r'[^\d.]'), '');
    final price = double.tryParse(raw);
    if (price == null || price <= 0) {
      setState(() => _error = l10n.errorPriceInvalid);
      return;
    }
    final notifier = ref.read(itemsProvider.notifier);
    if (widget.existingLine != null) {
      await notifier.updateItem(
        id: widget.existingLine!.id,
        name: name,
        price: price,
        currencyCode: _currencyCode,
      );
    } else {
      await notifier.addItem(name, price, _currencyCode);
    }
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final padding = const EdgeInsets.fromLTRB(20, 20, 20, 16);
    final title = widget.existingLine != null
        ? l10n.editItemTitle
        : l10n.addItemTitle;

    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.addItemSubtitle,
            textAlign: TextAlign.center,
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 12),
          receiptOcrProbeBanner(context, ref, l10n, material: false),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 8),
            onPressed: () => runReceiptScanFlow(
              context: context,
              nameController: _nameCtrl,
              priceController: _priceCtrl,
              currencyCode: _currencyCode,
              onApplied: () => setState(() {}),
              l10n: l10n,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.doc_text_viewfinder,
                  size: 22,
                  color: CupertinoColors.activeBlue.resolveFrom(context),
                ),
                const SizedBox(width: 8),
                Text(l10n.scanReceiptButton),
              ],
            ),
          ),
          const SizedBox(height: 18),
          CupertinoTextField(
            controller: _nameCtrl,
            placeholder: l10n.itemNameHint,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: CupertinoColors.secondarySystemFill.resolveFrom(context),
              borderRadius: BorderRadius.circular(12),
            ),
            textCapitalization: TextCapitalization.sentences,
            autofocus: true,
          ),
          const SizedBox(height: 12),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _openCurrencyPicker(
              context: context,
              selected: _currencyCode,
              onSelected: (c) => setState(() => _currencyCode = c),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: CupertinoColors.secondarySystemFill.resolveFrom(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.currencyLabel,
                      style: CupertinoTheme.of(context).textTheme.textStyle
                          .copyWith(
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                          ),
                    ),
                  ),
                  Text(
                    _currencyCode,
                    style: CupertinoTheme.of(
                      context,
                    ).textTheme.textStyle.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    CupertinoIcons.chevron_down,
                    size: 18,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          CupertinoTextField(
            controller: _priceCtrl,
            placeholder: l10n.priceHint,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: CupertinoColors.secondarySystemFill.resolveFrom(context),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),
          Material(
            color: Colors.transparent,
            child: ItemAssigneeChips(
              participants: ref.watch(participantsProvider),
              assigneeIds: _assigneeIds,
              dense: true,
              onAssigneesChanged: (ids) => setState(() => _assigneeIds = ids),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                color: CupertinoColors.destructiveRed.resolveFrom(context),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: CupertinoButton.filled(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  borderRadius: BorderRadius.circular(14),
                  onPressed: () => _submit(context, l10n),
                  child: Text(l10n.save),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _showMaterialExpressiveSheet(
  BuildContext context,
  WidgetRef ref, {
  LedgerLineItem? existingLine,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: SingleChildScrollView(
          child: _AddItemFormMaterial(existingLine: existingLine),
        ),
      );
    },
  );
}

class _AddItemFormMaterial extends ConsumerStatefulWidget {
  const _AddItemFormMaterial({this.existingLine});

  final LedgerLineItem? existingLine;

  @override
  ConsumerState<_AddItemFormMaterial> createState() =>
      _AddItemFormMaterialState();
}

class _AddItemFormMaterialState extends ConsumerState<_AddItemFormMaterial> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late String _currencyCode;
  late Set<String> _assigneeIds;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final existing = widget.existingLine;
    final item = existing?.receiptItem;
    _nameCtrl = TextEditingController(text: item?.name ?? '');
    _priceCtrl = TextEditingController(
      text: item != null
          ? amountToInputText(item.price, item.currencyCode)
          : '',
    );
    _currencyCode = item?.currencyCode ?? ref.read(defaultCurrencyProvider);
    _assigneeIds = Set.from(existing?.assignedParticipantIds ?? const []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String label,
    String? hint,
    Widget? prefix,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefix: prefix,
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    );
  }

  Future<void> _submit(BuildContext context, AppLocalizations l10n) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final name = _nameCtrl.text.trim();
    final raw = _priceCtrl.text.trim().replaceAll(RegExp(r'[^\d.]'), '');
    final price = double.parse(raw);
    final notifier = ref.read(itemsProvider.notifier);
    if (widget.existingLine != null) {
      final id = widget.existingLine!.id;
      await notifier.updateItem(
        id: id,
        name: name,
        price: price,
        currencyCode: _currencyCode,
      );
      await notifier.setLineAssignments(
        lineId: id,
        selectedParticipantIds: _assigneeIds,
      );
    } else {
      final id = await notifier.addItem(name, price, _currencyCode);
      await notifier.setLineAssignments(
        lineId: id,
        selectedParticipantIds: _assigneeIds,
      );
    }
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = widget.existingLine != null
        ? l10n.editItemTitle
        : l10n.addItemTitle;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.addItemSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            receiptOcrProbeBanner(context, ref, l10n, material: true),
            OutlinedButton.icon(
              onPressed: () => runReceiptScanFlow(
                context: context,
                nameController: _nameCtrl,
                priceController: _priceCtrl,
                currencyCode: _currencyCode,
                onApplied: () => setState(() {}),
                l10n: l10n,
              ),
              icon: const Icon(Icons.document_scanner_outlined),
              label: Text(l10n.scanReceiptButton),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: _fieldDecoration(
                context,
                label: l10n.itemNameLabel,
                hint: l10n.itemNameHint,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return l10n.errorNameRequired;
                }
                return null;
              },
              onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              // Controlled selection; `value` remains the correct API until a stable replacement.
              // ignore: deprecated_member_use
              value: _currencyCode,
              decoration: _fieldDecoration(context, label: l10n.currencyLabel),
              items: [
                for (final code in kSupportedCurrencyCodes)
                  DropdownMenuItem(value: code, child: Text(code)),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _currencyCode = v);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _fieldDecoration(
                context,
                label: l10n.priceLabel,
                hint: l10n.priceHint,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return l10n.errorPriceRequired;
                }
                final raw = v.trim().replaceAll(RegExp(r'[^\d.]'), '');
                final n = double.tryParse(raw);
                if (n == null || n <= 0) {
                  return l10n.errorPriceInvalid;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ItemAssigneeChips(
              participants: ref.watch(participantsProvider),
              assigneeIds: _assigneeIds,
              dense: true,
              onAssigneesChanged: (ids) => setState(() => _assigneeIds = ids),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      side: BorderSide(
                        color: scheme.outline.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () => _submit(context, l10n),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(l10n.save),
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
