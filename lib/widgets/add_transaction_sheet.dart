import 'dart:async' show unawaited;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:splitbae/core/data/amount_minor.dart';
import 'package:splitbae/core/data/draft_bill_inclusion_repository.dart';
import 'package:splitbae/core/domain/ledger_ids.dart';
import 'package:splitbae/core/domain/posted_bill_summary.dart';
import 'package:splitbae/core/domain/ledger_line_item.dart';
import 'package:splitbae/core/domain/participant_entry.dart';
import 'package:splitbae/core/providers/database_providers.dart';
import 'package:splitbae/core/suggest/category_from_description.dart';
import 'package:splitbae/core/theme/splitbae_semantic_colors.dart';
import 'package:splitbae/core/theme/splitbae_v0_theme.dart';
import 'package:splitbae/core/ui/category_icons.dart';
import 'package:splitbae/app_settings.dart';
import 'package:splitbae/core/widgets/adaptive_app_bar.dart';
import 'package:splitbae/features/split/application/draft_split_provider.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:splitbae/money_format.dart';
import 'package:splitbae/providers.dart';
import 'package:splitbae/screens/draft_split_screen.dart';
import 'package:splitbae/src/rust/api/receipt_split.dart' show calculateSplit;
import 'package:splitbae/widgets/add_receipt_item_sheet.dart';
import 'package:splitbae/widgets/item_assignee_chips.dart';
import 'package:splitbae/widgets/draft_paid_by_compact.dart';
import 'package:splitbae/widgets/who_paid_sheet.dart';

Future<void> showAddTransactionSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AddTransactionSheetBody(hostContext: context),
  );
}

/// v0 [add-expense-sheet] “Frequent / Also” row: co-occurrence from posted bills.
List<ParticipantEntry> recommendedSplitPartnersForAddTransaction({
  required List<PostedBillSummary> bills,
  required List<ParticipantEntry> allPeople,
  required Set<String> selectedIds,
}) {
  if (allPeople.length <= 1) return [];
  final unselected =
      allPeople.where((p) => !selectedIds.contains(p.id)).toList();
  if (unselected.isEmpty) return [];
  final scores = <String, int>{};
  for (final s in bills) {
    final ids = s.participantIds.toSet();
    if (selectedIds.isEmpty) {
      for (final id in ids) {
        scores[id] = (scores[id] ?? 0) + 1;
      }
    } else {
      if (!selectedIds.any(ids.contains)) continue;
      for (final id in ids) {
        if (selectedIds.contains(id)) continue;
        scores[id] = (scores[id] ?? 0) + 1;
      }
    }
  }
  unselected.sort((a, b) {
    final d = (scores[b.id] ?? 0).compareTo(scores[a.id] ?? 0);
    if (d != 0) return d;
    return a.displayName.compareTo(b.displayName);
  });
  return unselected.take(3).toList();
}

class _AddTransactionSheetBody extends ConsumerStatefulWidget {
  const _AddTransactionSheetBody({required this.hostContext});

  final BuildContext hostContext;

  @override
  ConsumerState<_AddTransactionSheetBody> createState() =>
      _AddTransactionSheetBodyState();
}

class _AddTransactionSheetBodyState
    extends ConsumerState<_AddTransactionSheetBody> {
  final _desc = TextEditingController();
  final _tax = TextEditingController();
  DateTime _when = DateTime.now();
  String _category = 'food';
  String? _receiptPath;
  String? _suggestedCategory;
  final _peopleSearchCtrl = TextEditingController();
  final _peopleSearchFocus = FocusNode();
  bool _peopleMenuOpen = false;

  static const _categories = <String>[
    'food',
    'transport',
    'accommodation',
    'entertainment',
    'shopping',
    'utilities',
    'other',
    'settlement',
  ];

  @override
  void initState() {
    super.initState();
    _peopleSearchFocus.addListener(() {
      setState(() => _peopleMenuOpen = _peopleSearchFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _desc.dispose();
    _tax.dispose();
    _peopleSearchCtrl.dispose();
    _peopleSearchFocus.dispose();
    super.dispose();
  }

  String _primaryCurrency(List<LedgerLineItem> items) {
    if (items.isEmpty) return ref.read(defaultCurrencyProvider);
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
        case 'no_one_on_bill':
          return l10n.postBillErrorNoParticipants;
        case 'split_incomplete':
          return l10n.postBillErrorSplitIncomplete;
        default:
          break;
      }
    }
    return e.toString();
  }

  bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  bool _isYesterday(DateTime d) {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return d.year == y.year && d.month == y.month && d.day == y.day;
  }

  void _setToday() {
    setState(() => _when = DateTime.now());
  }

  void _setYesterday() {
    final n = DateTime.now();
    final y = DateTime(n.year, n.month, n.day)
        .subtract(const Duration(days: 1));
    final t = TimeOfDay.fromDateTime(_when);
    setState(() {
      _when = DateTime(y.year, y.month, y.day, t.hour, t.minute);
    });
  }

  Future<void> _onToggleSplittingPerson(
    WidgetRef ref,
    ParticipantEntry p,
    List<ParticipantEntry> active,
    List<ParticipantEntry> allPeople,
  ) async {
    if (allPeople.length <= 1) return;
    final messenger = ScaffoldMessenger.of(widget.hostContext);
    final l10n = AppLocalizations.of(context)!;
    final effectiveIds = active.map((e) => e.id).toSet();
    final next = Set<String>.from(effectiveIds);
    if (next.contains(p.id)) {
      if (next.length <= 1) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.postBillErrorNoParticipants)),
        );
        return;
      }
      next.remove(p.id);
    } else {
      next.add(p.id);
    }
    try {
      await DraftBillInclusionRepository(ref.read(appDatabaseProvider))
          .setIncludedParticipants(kDefaultLedgerId, next);
      ref.read(draftBillInclusionRevisionProvider.notifier).state++;
      await ref.read(itemsProvider.notifier).reloadFromDatabase();
      ref.read(draftPaymentsDbRevisionProvider.notifier).state++;
    } catch (e) {
      if (e is StateError && e.message == 'no_one_on_bill') {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.postBillErrorNoParticipants)),
        );
      }
    }
  }

  Future<void> _pickDateTime() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_when),
    );
    if (t == null || !mounted) return;
    setState(() {
      _when = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
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

  Future<void> _addPersonFromSearch() async {
    final name = _peopleSearchCtrl.text.trim();
    if (name.isEmpty) return;
    final before = ref.read(participantsProvider).map((e) => e.id).toSet();
    await ref.read(participantsProvider.notifier).addParticipant(name);
    if (!mounted) return;
    final after = ref.read(participantsProvider);
    final newIds = after.map((e) => e.id).toSet().difference(before);
    if (newIds.isEmpty) return;
    final newId = newIds.first;
    final active = await ref.read(draftBillActiveParticipantsProvider.future);
    final activeIds = active.map((e) => e.id).toSet();
    if (!activeIds.contains(newId)) {
      await DraftBillInclusionRepository(ref.read(appDatabaseProvider))
          .setIncludedParticipants(kDefaultLedgerId, {...activeIds, newId});
      ref.read(draftBillInclusionRevisionProvider.notifier).state++;
      await ref.read(itemsProvider.notifier).reloadFromDatabase();
      ref.read(draftPaymentsDbRevisionProvider.notifier).state++;
    }
    if (!mounted) return;
    _peopleSearchCtrl.clear();
    FocusScope.of(context).unfocus();
    setState(() {});
    HapticFeedback.selectionClick();
  }

  Future<void> _selectCategory(String id) async {
    setState(() {
      _category = id;
      _suggestedCategory = null;
    });
    if (id != 'settlement') return;
    final active = await ref.read(draftBillActiveParticipantsProvider.future);
    if (!mounted) return;
    if (active.length >= 2) {
      final a = active[0].displayName.split(RegExp(r'\s+')).first;
      final b = active[1].displayName.split(RegExp(r'\s+')).first;
      _desc.text = 'Settlement: $a → $b';
    } else {
      _desc.text = 'Settlement';
    }
  }

  Future<void> _post(AppLocalizations l10n) async {
    final messenger = ScaffoldMessenger.of(widget.hostContext);
    final items = ref.read(itemsProvider);
    final ccy = _primaryCurrency(items);
    var description = _desc.text.trim();
    if (description.isEmpty && items.isNotEmpty) {
      description = items.first.receiptItem.name;
    }
    try {
      final active = await ref.read(draftBillActiveParticipantsProvider.future);
      final taxMinor = _taxMinor(ccy);
      final split = calculateSplit(
        receipt: receiptForRustSplit(
          items: items,
          activeParticipants: active,
          currencyCode: ccy,
          taxAmountMinor: taxMinor,
          tipAmountMinor: 0,
        ),
      );
      await ref.read(itemsProvider.notifier).postDraftBill(
            description,
            splitOwedMinor: split,
            taxAmountMinor: taxMinor,
            tipAmountMinor: 0,
            category: _category,
            createdAtMs: _when.millisecondsSinceEpoch,
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

  String _categoryLabel(String id, AppLocalizations l10n) {
    switch (id) {
      case 'food':
        return l10n.categoryFood;
      case 'transport':
        return l10n.categoryTransport;
      case 'accommodation':
        return l10n.categoryAccommodation;
      case 'entertainment':
        return l10n.categoryEntertainment;
      case 'shopping':
        return l10n.categoryShopping;
      case 'utilities':
        return l10n.categoryUtilities;
      case 'settlement':
        return l10n.categorySettlement;
      default:
        return l10n.categoryOther;
    }
  }

  Widget _buildPeopleSplittingSection({
    required BuildContext context,
    required AppLocalizations l10n,
    required ColorScheme scheme,
    required List<PostedBillSummary> bills,
    required List<ParticipantEntry> allPeople,
    required List<ParticipantEntry> active,
  }) {
    final effectiveIds = active.map((e) => e.id).toSet();
    final recommended = recommendedSplitPartnersForAddTransaction(
      bills: bills,
      allPeople: allPeople,
      selectedIds: effectiveIds,
    );
    final q = _peopleSearchCtrl.text.trim().toLowerCase();
    final filtered = q.isEmpty
        ? allPeople
        : allPeople
            .where((p) => p.displayName.toLowerCase().contains(q))
            .toList();
    final exactNameMatch = q.isNotEmpty &&
        allPeople.any((p) => p.displayName.toLowerCase() == q);
    final showAddTile = q.isNotEmpty && !exactNameMatch;
    final unselectedCount =
        filtered.where((p) => !effectiveIds.contains(p.id)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${l10n.addTransactionWhosSplitting} (${effectiveIds.length})',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.addTransactionEveryoneIncludedHint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 10),
        if (allPeople.isEmpty)
          Text(
            l10n.itemAssigneesNeedPeople,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          )
        else ...[
          if (active.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in active)
                  InputChip(
                    label: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 140),
                      child: Text(
                        p.displayName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    avatar: CircleAvatar(
                      radius: 12,
                      backgroundColor: scheme.primaryContainer,
                      child: Text(
                        splitBaeInitialGrapheme(p.displayName),
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    onDeleted: allPeople.length <= 1
                        ? null
                        : () => unawaited(
                              _onToggleSplittingPerson(
                                ref,
                                p,
                                active,
                                allPeople,
                              ),
                            ),
                  ),
              ],
            ),
          if (recommended.isNotEmpty) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text(
                    effectiveIds.isEmpty
                        ? l10n.addTransactionFrequentPartners
                        : l10n.addTransactionAlsoPartners,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(width: 8),
                  for (final p in recommended)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        avatar: CircleAvatar(
                          radius: 12,
                          backgroundColor: scheme.primary.withValues(alpha: 0.22),
                          child: Text(
                            splitBaeInitialGrapheme(p.displayName),
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                        label: Text(
                          p.displayName.split(RegExp(r'\s+')).first,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: allPeople.length <= 1
                            ? null
                            : () => unawaited(
                                  _onToggleSplittingPerson(
                                    ref,
                                    p,
                                    active,
                                    allPeople,
                                  ),
                                ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: _peopleSearchCtrl,
            focusNode: _peopleSearchFocus,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, size: 22),
              hintText: l10n.addTransactionSearchPeopleHint,
              filled: true,
              fillColor: scheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_peopleMenuOpen &&
              (unselectedCount > 0 || showAddTile)) ...[
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final p in filtered)
                      if (!effectiveIds.contains(p.id))
                        ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            child: Text(
                              splitBaeInitialGrapheme(p.displayName),
                            ),
                          ),
                          title: Text(p.displayName),
                          onTap: () {
                            unawaited(
                              _onToggleSplittingPerson(
                                ref,
                                p,
                                active,
                                allPeople,
                              ),
                            );
                            _peopleSearchCtrl.clear();
                            FocusScope.of(context).unfocus();
                          },
                        ),
                    if (showAddTile)
                      ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.person_add_alt_1,
                          color: scheme.primary,
                        ),
                        title: Text(
                          l10n.addTransactionAddPersonNamed(
                            _peopleSearchCtrl.text.trim(),
                          ),
                        ),
                        onTap: () => unawaited(_addPersonFromSearch()),
                      ),
                    if (unselectedCount == 0 &&
                        !showAddTile &&
                        q.isEmpty &&
                        allPeople.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          l10n.addTransactionAllPeopleAdded,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final items = ref.watch(itemsProvider);
    final allPeople = ref.watch(participantsProvider);
    final billsAsync = ref.watch(postedBillSummariesProvider);
    final activeAsync = ref.watch(draftBillActiveParticipantsProvider);
    final ccy = _primaryCurrency(items);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final h = MediaQuery.sizeOf(context).height;
    final scheme = splitBaeV0DarkColorScheme();

    var subtotal = 0.0;
    for (final line in items) {
      subtotal += line.receiptItem.price;
    }
    final taxVal = double.tryParse(_tax.text.trim().replaceAll(',', '.')) ?? 0.0;
    final grand = subtotal + (taxVal < 0 ? 0 : taxVal);
    final activeList = activeAsync.valueOrNull ?? [];

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: scheme,
        brightness: Brightness.dark,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SizedBox(
          height: (h * 0.92).clamp(400.0, h),
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.addTransactionSheetTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      tooltip: MaterialLocalizations.of(context)
                          .closeButtonTooltip,
                    ),
                  ],
                ),
                Text(
                  l10n.addTransactionSheetSubtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionLabel(context, l10n.addTransactionReceiptLabel),
                        const SizedBox(height: 8),
                        if (_receiptPath == null)
                          FilledButton.tonal(
                            onPressed: _pickReceipt,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.photo_camera_outlined,
                                    color: scheme.primary),
                                const SizedBox(width: 10),
                                Text(l10n.addTransactionReceiptPick),
                              ],
                            ),
                          )
                        else
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: Image.file(
                                    File(_receiptPath!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Material(
                                  color: Colors.black54,
                                  shape: const CircleBorder(),
                                  child: IconButton(
                                    onPressed: () =>
                                        setState(() => _receiptPath = null),
                                    icon: const Icon(Icons.close,
                                        color: Colors.white, size: 20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _sectionLabel(
                                  context, l10n.addTransactionDescriptionSection),
                            ),
                            Text(
                              l10n.addTransactionDescriptionAutoHint,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _desc,
                          onChanged: (v) {
                            final s = suggestCategoryFromDescription(v);
                            setState(() {
                              _suggestedCategory =
                                  (s != null && s != _category) ? s : null;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: l10n.postBillDescriptionHint,
                            filled: true,
                            fillColor: scheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        if (_suggestedCategory != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                l10n.addTransactionSuggestedCategory,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                        color: scheme.onSurfaceVariant),
                              ),
                              const SizedBox(width: 8),
                              ActionChip(
                                label: Text(
                                  _categoryLabel(
                                      _suggestedCategory!, l10n),
                                ),
                                onPressed: () => unawaited(
                                  _selectCategory(_suggestedCategory!),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 20),
                        _sectionLabel(
                            context, l10n.addTransactionCategoryLabel),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 48,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _categories.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemBuilder: (ctx, i) {
                              final id = _categories[i];
                              final selected = _category == id;
                              final (bg, fg) = context
                                  .splitBaeSemantic
                                  .categoryIconColors(id);
                              final icon = splitBaeCategoryIcon(id);
                              return FilterChip(
                                showCheckmark: false,
                                selected: selected,
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(icon, size: 18, color: selected ? scheme.onPrimary : fg),
                                    const SizedBox(width: 6),
                                    Text(_categoryLabel(id, l10n)),
                                  ],
                                ),
                                selectedColor: scheme.primary,
                                backgroundColor: bg,
                                onSelected: (_) => unawaited(_selectCategory(id)),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        _sectionLabel(
                            context, l10n.addTransactionDateTimeSection),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            FilledButton.tonal(
                              onPressed: _setToday,
                              style: FilledButton.styleFrom(
                                backgroundColor: _isToday(_when)
                                    ? scheme.primary
                                    : scheme.surfaceContainerHighest,
                                foregroundColor: _isToday(_when)
                                    ? scheme.onPrimary
                                    : scheme.onSurface,
                              ),
                              child: Text(l10n.addTransactionToday),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.tonal(
                              onPressed: _setYesterday,
                              style: FilledButton.styleFrom(
                                backgroundColor: _isYesterday(_when)
                                    ? scheme.primary
                                    : scheme.surfaceContainerHighest,
                                foregroundColor: _isYesterday(_when)
                                    ? scheme.onPrimary
                                    : scheme.onSurface,
                              ),
                              child: Text(l10n.addTransactionYesterday),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          tileColor: scheme.surfaceContainerHighest,
                          leading: Icon(Icons.calendar_today_outlined,
                              color: scheme.primary),
                          title: Text(
                            DateFormat.yMMMd(locale.toString())
                                .add_jm()
                                .format(_when),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          onTap: _pickDateTime,
                        ),
                        const SizedBox(height: 20),
                        billsAsync.when(
                          data: (bills) => activeAsync.when(
                            data: (active) => _buildPeopleSplittingSection(
                              context: context,
                              l10n: l10n,
                              scheme: scheme,
                              bills: bills,
                              allPeople: allPeople,
                              active: active,
                            ),
                            loading: () => const SizedBox(height: 8),
                            error: (_, _) => const SizedBox.shrink(),
                          ),
                          loading: () => const SizedBox(height: 8),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _sectionLabel(
                                  context,
                                  l10n.addTransactionItemsSection(
                                      items.length)),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                showAddReceiptItemSheet(context, ref);
                              },
                              icon: const Icon(Icons.add, size: 20),
                              label: Text(l10n.addTransactionAddLineItem),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              l10n.emptyBillHint,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          )
                        else
                          for (final line in items)
                            _DraftLinePreviewCard(
                              line: line,
                              locale: locale,
                              scheme: scheme,
                              activeParticipants: activeList,
                              onTap: () {
                                showAddReceiptItemSheet(
                                  context,
                                  ref,
                                  existingLine: line,
                                );
                              },
                            ),
                        const SizedBox(height: 16),
                        _sectionLabel(context, l10n.addTransactionTaxLabel),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _tax,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            prefixIcon:
                                Icon(Icons.receipt_long, color: scheme.primary),
                            prefixText: '$ccy ',
                            prefixStyle: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                            filled: true,
                            fillColor: scheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 4),
                          child: Text(
                            l10n.addTransactionTaxSplitHint,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest
                                .withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: scheme.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _totalRow(
                                  context,
                                  l10n.addTransactionSubtotalLine(
                                    items.where((e) =>
                                        e.receiptItem.price > 0).length),
                                  formatCurrencyAmount(
                                    amount: subtotal,
                                    currencyCode: ccy,
                                    locale: locale,
                                  ),
                                  emphasize: false,
                                ),
                                const SizedBox(height: 10),
                                _totalRow(
                                  context,
                                  l10n.addTransactionTaxSummaryLine,
                                  formatCurrencyAmount(
                                    amount: taxVal < 0 ? 0 : taxVal,
                                    currencyCode: ccy,
                                    locale: locale,
                                  ),
                                  emphasize: false,
                                ),
                                Divider(
                                  height: 24,
                                  color: scheme.outlineVariant
                                      .withValues(alpha: 0.6),
                                ),
                                _totalRow(
                                  context,
                                  l10n.addTransactionGrandTotal,
                                  formatCurrencyAmount(
                                    amount: grand,
                                    currencyCode: ccy,
                                    locale: locale,
                                  ),
                                  emphasize: true,
                                  valueColor: scheme.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.addTransactionDraftSummary(
                            items.length,
                            activeAsync.valueOrNull?.length ??
                                allPeople.length,
                          ),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 12),
                        const DraftPaidByCompact(),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              showWhoPaidSheet(context, ref);
                            },
                            child: Text(l10n.paidByFullEditor),
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
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _post(l10n);
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline),
                      const SizedBox(width: 8),
                      Text(l10n.addTransactionPostAction),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
    );
  }

  Widget _totalRow(
    BuildContext context,
    String label,
    String value, {
    required bool emphasize,
    Color? valueColor,
  }) {
    final t = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: emphasize
                ? t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)
                : t.textTheme.bodyMedium?.copyWith(
                    color: t.colorScheme.onSurfaceVariant,
                  ),
          ),
        ),
        Text(
          value,
          style: (emphasize ? t.textTheme.titleLarge : t.textTheme.titleSmall)
              ?.copyWith(
            fontWeight: emphasize ? FontWeight.w900 : FontWeight.w600,
            color: valueColor ?? t.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _DraftLinePreviewCard extends ConsumerWidget {
  const _DraftLinePreviewCard({
    required this.line,
    required this.locale,
    required this.scheme,
    required this.activeParticipants,
    required this.onTap,
  });

  final LedgerLineItem line;
  final Locale locale;
  final ColorScheme scheme;
  final List<ParticipantEntry> activeParticipants;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final lineStr = formatCurrencyAmount(
      amount: line.receiptItem.price,
      currencyCode: line.receiptItem.currencyCode,
      locale: locale,
    );
    final unitStr = formatCurrencyAmount(
      amount: line.unitPrice,
      currencyCode: line.receiptItem.currencyCode,
      locale: locale,
    );
    final assignee = line.assignedParticipantIds.toSet();
    final caption = assignee.isEmpty
        ? l10n.addTransactionLineSharedByAll
        : l10n.addTransactionLineAssignedToCount(assignee.length);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      line.receiptItem.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _lineMini(
                          context,
                          l10n.itemQuantityLabel,
                          '${line.quantity}',
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _lineMini(
                            context,
                            l10n.draftBillLineUnitColumn,
                            unitStr,
                          ),
                        ),
                        _lineMini(
                          context,
                          l10n.draftBillLineLineTotalColumn,
                          lineStr,
                          strong: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (activeParticipants.length > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: ItemAssigneeChips(
                  participants: activeParticipants,
                  assigneeIds: assignee,
                  dense: true,
                  avatarOnly: true,
                  showMainLabel: false,
                  caption: caption,
                  onAssigneesChanged: (ids) {
                    unawaited(
                      ref.read(itemsProvider.notifier).setLineAssignments(
                            lineId: line.id,
                            selectedParticipantIds: ids,
                          ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _lineMini(
    BuildContext context,
    String label,
    String value, {
    bool strong = false,
  }) {
    final t = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: t.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: strong
              ? t.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                )
              : t.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
