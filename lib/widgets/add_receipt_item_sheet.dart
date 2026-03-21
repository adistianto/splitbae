import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitbae/app_settings.dart';
import 'package:splitbae/core/data/amount_minor.dart';
import 'package:splitbae/core/domain/ledger_line_item.dart';
import 'package:splitbae/currency_catalog.dart';
import 'package:splitbae/providers.dart';

/// iOS: glass-style modal. Android: M3 bottom sheet.
/// Pass [existingLine] to edit; omit to add a new line.
Future<void> showAddReceiptItemSheet(
  BuildContext context,
  WidgetRef ref, {
  LedgerLineItem? existingLine,
}) {
  final platform = Theme.of(context).platform;
  if (platform == TargetPlatform.iOS) {
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
      final glassTint = isDark
          ? const Color(0xFF2C2C2E).withValues(alpha: 0.72)
          : CupertinoColors.systemBackground.resolveFrom(ctx).withValues(alpha: 0.82);

      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 16 + bottomInset,
        ),
        child: SafeArea(
          top: false,
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(22)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: glassTint,
                  borderRadius: const BorderRadius.all(Radius.circular(22)),
                  border: Border.all(
                    color: CupertinoColors.separator
                        .resolveFrom(ctx)
                        .withValues(alpha: 0.35),
                  ),
                  boxShadow: [
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
              ),
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
    final title =
        widget.existingLine != null ? l10n.editItemTitle : l10n.addItemTitle;

    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: CupertinoTheme.of(context)
                .textTheme
                .navLargeTitleTextStyle
                .copyWith(fontSize: 22),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.addItemSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
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
                      style: TextStyle(
                        color: CupertinoColors.secondaryLabel.resolveFrom(context),
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Text(
                    _currencyCode,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
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
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: TextStyle(
                color: CupertinoColors.destructiveRed.resolveFrom(context),
                fontSize: 13,
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
        borderSide:
            BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title =
        widget.existingLine != null ? l10n.editItemTitle : l10n.addItemTitle;

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
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.addItemSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
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
              decoration: _fieldDecoration(
                context,
                label: l10n.currencyLabel,
              ),
              items: [
                for (final code in kSupportedCurrencyCodes)
                  DropdownMenuItem(
                    value: code,
                    child: Text(code),
                  ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _currencyCode = v);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
