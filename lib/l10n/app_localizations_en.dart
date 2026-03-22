// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SplitBae';

  @override
  String get navHomeLabel => 'Home';

  @override
  String get addItemTooltip => 'Add item';

  @override
  String get addPerson => 'Add person';

  @override
  String get settings => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSubtitle =>
      'Uses your phone language until you pick one here.';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsAppearanceSubtitle =>
      'Light, Dark, or follow your device (System default on Android; Automatic on iPhone and Mac).';

  @override
  String get settingsThemeFollowDeviceMaterial => 'System default';

  @override
  String get settingsThemeFollowDeviceMaterialShort => 'System';

  @override
  String get settingsThemeFollowDeviceApple => 'Automatic';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsMaterialYou => 'Material You dynamic color';

  @override
  String get settingsMaterialYouSubtitle =>
      'Uses your wallpaper palette for the app theme on supported devices. Off by default; turn on for Material You colors, or leave off for SplitBae’s default teal look.';

  @override
  String get languageDevice => 'Use device language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageIndonesian => 'Bahasa Indonesia';

  @override
  String get settingsDefaultCurrency => 'Default currency for new bills';

  @override
  String get settingsDefaultCurrencySubtitle =>
      'Used when you start a new bill with no lines yet.';

  @override
  String get settingsDefaultCurrencyRecordingNote =>
      'Posted transactions keep the currency they were saved in. Changing this only affects new lines and the empty draft.';

  @override
  String get addItemTitle => 'Add item';

  @override
  String get addItemSubtitle =>
      'Amounts use this bill’s currency (set by default for an empty bill; change default in Settings).';

  @override
  String get billCurrencyLabel => 'Bill currency';

  @override
  String get scanReceiptButton => 'Scan receipt';

  @override
  String get scanReceiptScreenTitle => 'Scan receipt';

  @override
  String get scanReceiptScreenSubtitle => 'Capture to add expenses quickly';

  @override
  String get scanReceiptHeroQuickAdd => 'Quick add';

  @override
  String get scanReceiptHeroPointCamera => 'Point camera at receipt';

  @override
  String scanReceiptHeroItemsDetected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items detected',
      one: '1 item detected',
    );
    return '$_temp0';
  }

  @override
  String get scanReceiptTakePhotoSubtitle => 'Snap a picture of your receipt';

  @override
  String get scanReceiptExtractingTitle => 'Extracting items…';

  @override
  String get scanReceiptExtractingSubtitle => 'This may take a moment';

  @override
  String get scanReceiptContinueToSplit => 'Continue to Split';

  @override
  String get scanReceiptCamera => 'Take photo';

  @override
  String get scanReceiptGallery => 'Choose from library';

  @override
  String get scanReceiptEnterManually => 'Enter manually';

  @override
  String get scanReceiptEnterManuallySubtitle =>
      'Use the name and amount fields below';

  @override
  String get scanReceiptPermissionCameraDenied =>
      'Camera access is required to take a receipt photo.';

  @override
  String get scanReceiptPermissionPhotosDenied =>
      'Photo library access is required to choose a receipt image.';

  @override
  String get scanReceiptPermissionCameraBlockedTitle => 'Camera access is off';

  @override
  String get scanReceiptPermissionCameraBlockedBody =>
      'Allow SplitBae to use the camera in Settings so you can scan receipts.';

  @override
  String get scanReceiptPermissionPhotosBlockedTitle => 'Photo access is off';

  @override
  String get scanReceiptPermissionPhotosBlockedBody =>
      'Allow SplitBae to access your photo library in Settings so you can choose receipt images.';

  @override
  String get scanReceiptPermissionOpenSettings => 'Open Settings';

  @override
  String get scanReceiptTimeout =>
      'Scanning took too long. Try another photo or enter the item manually below.';

  @override
  String get scanReceiptDegradedBody =>
      'On-device text recognition could not be verified. You can still try scanning, or type the item name and amount below.';

  @override
  String get scanReceiptPickLine => 'Pick a line to use';

  @override
  String scanReceiptLineQtyUnitPrice(int quantity, String unitPrice) {
    return '×$quantity · $unitPrice each';
  }

  @override
  String scanReceiptOcrLineDetail(
    int quantity,
    String unitPrice,
    String lineTotal,
  ) {
    return 'Qty $quantity · $unitPrice each · line $lineTotal';
  }

  @override
  String scanReceiptAddAllLines(int count) {
    return 'Add all $count lines';
  }

  @override
  String scanReceiptBatchAdded(int count) {
    return 'Added $count lines from the receipt.';
  }

  @override
  String get scanReceiptNoLines =>
      'No lines with an amount were found. Try a clearer photo or enter the item manually.';

  @override
  String get scanReceiptUnavailable =>
      'Receipt scanning needs on-device OCR (Android, iOS, macOS, or Windows in this app).';

  @override
  String get scanReceiptChooseImageFile => 'Choose image file';

  @override
  String get scanReceiptNonMobileScanHint =>
      'On-device OCR isn’t available on web or Linux in this build. You can still pick a photo or enter lines manually.';

  @override
  String get scanReceiptNoNativeOcr =>
      'On-device receipt OCR isn’t available on this platform. Enter the line manually.';

  @override
  String get scanReceiptErrorGeneric => 'Could not read text from the image.';

  @override
  String scanReceiptErrorDetail(String message) {
    return 'Could not read the receipt: $message';
  }

  @override
  String get itemNameLabel => 'Item name';

  @override
  String get itemNameHint => 'e.g. Fried rice';

  @override
  String get priceLabel => 'Amount';

  @override
  String get priceHint => '15000';

  @override
  String get itemQuantityLabel => 'Qty';

  @override
  String get itemQuantityHint => '1';

  @override
  String get errorQuantityInvalid => 'Use a whole number of at least 1.';

  @override
  String get draftBillLineQtyColumn => 'Qty';

  @override
  String get draftBillLineUnitColumn => 'Unit';

  @override
  String get draftBillLineLineTotalColumn => 'Line';

  @override
  String get currencyLabel => 'Currency';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get errorNameRequired => 'Item name is required.';

  @override
  String get errorPriceRequired => 'Amount is required.';

  @override
  String get errorPriceInvalid => 'Enter a valid positive amount.';

  @override
  String get splitSubtitle =>
      'Totals follow who is assigned to each line; one row per person per currency (no FX conversion).';

  @override
  String get itemAssigneesLabel => 'Split with';

  @override
  String get itemAssigneesNeedPeople =>
      'Add people to the split to assign shares.';

  @override
  String get perPersonTitle => 'Per person';

  @override
  String get settingsDataPrivacy => 'Data & privacy';

  @override
  String get settingsEncryptDatabase => 'Encrypt local database';

  @override
  String get settingsEncryptDatabaseSubtitle =>
      'Strongly recommended if your phone could be lost or stolen—it protects names and amounts at rest. Off by default.';

  @override
  String get settingsEncryptChangeTitle => 'Change database encryption?';

  @override
  String get settingsEncryptChangeBody =>
      'Your ledgers, people, and line items will be copied into the new encrypted or plain database on this device. Nothing is uploaded. If something goes wrong, we restore your previous data and leave encryption as it was.';

  @override
  String get settingsEncryptChangeConfirm => 'Continue';

  @override
  String get settingsEncryptMigrationRolledBack =>
      'Couldn’t switch encryption; your data is unchanged.';

  @override
  String get settingsEncryptChangeError =>
      'Could not update the database. Try again or restart the app.';

  @override
  String get settingsBackup => 'Backup';

  @override
  String get settingsBackupManualTitle => 'Manual backup';

  @override
  String get settingsBackupEntrySubtitle =>
      'Export or restore a .sb_backup file on this device.';

  @override
  String get settingsBackupExport => 'Export backup file';

  @override
  String get settingsBackupExportSubtitle =>
      'Plain JSON (.sb_backup). Anyone with the file can read names and amounts—only store or send it where you trust.';

  @override
  String get settingsBackupImport => 'Import backup file';

  @override
  String get settingsBackupImportSubtitle =>
      'Replaces all ledgers, people, and line items on this device.';

  @override
  String get backupImportConfirmTitle => 'Replace all local data?';

  @override
  String get backupImportConfirmBody =>
      'Your current bill data will be removed and replaced by the backup. This cannot be undone.';

  @override
  String get backupImportConfirmAction => 'Replace and import';

  @override
  String get backupExportSuccess => 'Backup file ready.';

  @override
  String get backupImportSuccess => 'Backup restored.';

  @override
  String get backupErrorInvalid => 'That file is not a valid SplitBae backup.';

  @override
  String get backupErrorExport => 'Could not create the backup file.';

  @override
  String get editItemTitle => 'Edit item';

  @override
  String get billItemsTitle => 'Bill items';

  @override
  String get deleteItemTitle => 'Remove item?';

  @override
  String get deleteItemBody => 'This line will be removed from the bill.';

  @override
  String get deleteAction => 'Delete';

  @override
  String get peopleTooltip => 'People';

  @override
  String get managePeopleTitle => 'People in this split';

  @override
  String get renameParticipantAction => 'Rename';

  @override
  String get renameParticipantTitle => 'Rename';

  @override
  String get participantDisplayNameLabel => 'Name';

  @override
  String get removeParticipantTitle => 'Remove person?';

  @override
  String removeParticipantBody(String name) {
    return 'Remove $name from this split?';
  }

  @override
  String get addPersonSheetTitle => 'Add someone to the split';

  @override
  String get addPersonNameHint => 'e.g. Adistianto';

  @override
  String get participantNameRequired => 'Enter a name.';

  @override
  String get emptyParticipantsHint => 'Add people to see how the bill splits.';

  @override
  String get emptyBillHint => 'No receipt lines yet. Add an item to start.';

  @override
  String get balancesTitle => 'Balances';

  @override
  String get balancesTooltip => 'Balances and settlements';

  @override
  String get suggestedSettlementsTitle => 'Suggested transfers';

  @override
  String get recordedSettlementsTitle => 'Recorded transfers';

  @override
  String get allSettledUp => 'Everyone is settled for this ledger.';

  @override
  String get recordSettlementAction => 'Record';

  @override
  String get recordSettlementConfirmTitle => 'Record this transfer?';

  @override
  String recordSettlementConfirmBody(
    String fromName,
    String toName,
    String amount,
  ) {
    return '$fromName pays $toName $amount.';
  }

  @override
  String get settlementPayerModelHint =>
      'Who paid is stored per currency on the draft bill. Use Who paid on the home screen to edit; totals must match receipt lines.';

  @override
  String get whoPaidTooltip => 'Who paid';

  @override
  String get whoPaidTitle => 'Who paid';

  @override
  String get whoPaidSubtitle =>
      'Amounts must add up to each currency’s line total (same as the receipt).';

  @override
  String get whoPaidSave => 'Save';

  @override
  String get whoPaidReset => 'First person pays all';

  @override
  String get whoPaidEmptyBill =>
      'Add receipt lines first, then split who paid.';

  @override
  String get whoPaidBillTotalLabel => 'Bill total';

  @override
  String get paidByModeSingle => 'One person';

  @override
  String get paidByModeSplit => 'Split';

  @override
  String get paidByMultiCurrencyHint =>
      'This draft uses more than one currency. Use the full editor to enter who paid each currency.';

  @override
  String get paidByBalanced => 'Balanced';

  @override
  String get paidByRemainingLabel => 'Remaining';

  @override
  String get paidByFullEditor => 'Full editor';

  @override
  String get postBillTitle => 'Post bill';

  @override
  String get postBillSubtitle =>
      'This locks the current lines and payments into your history. You can start a new bill afterward.';

  @override
  String get postBillDescriptionLabel => 'Title (optional)';

  @override
  String get postBillDescriptionHint => 'e.g. Team dinner';

  @override
  String get postBillAction => 'Post bill';

  @override
  String get postBillSuccess => 'Bill posted.';

  @override
  String get postBillErrorEmpty => 'Add at least one line before posting.';

  @override
  String get postBillErrorNoParticipants => 'Add people before posting.';

  @override
  String get postedBillsTitle => 'Recent bills';

  @override
  String get postBillUntitled => 'Untitled';

  @override
  String get navBillsTab => 'Bills';

  @override
  String get navSplitTab => 'Split';

  @override
  String get navSplitTitle => 'Split bill';

  @override
  String get billsScreenTitle => 'Bills';

  @override
  String get billsEmptyState =>
      'No bills yet. Add lines on Split, then post a bill.';

  @override
  String get transactionDetailTabItems => 'Items';

  @override
  String get transactionDetailTabPersons => 'Persons';

  @override
  String get transactionDetailTabPayments => 'Payments';

  @override
  String get transactionDetailMissing => 'This bill could not be loaded.';

  @override
  String get transactionDetailNoPayments =>
      'No payments recorded for this bill.';

  @override
  String get transactionDetailNoShares => 'No split for this line.';

  @override
  String get transactionDetailPersonsEmpty => 'Nothing owed on this bill.';

  @override
  String get settleUpSectionTitle => 'Settle up';

  @override
  String get settlementPayerPays => 'Pays';

  @override
  String get settlementPayeeReceives => 'Receives';

  @override
  String get markAsPaid => 'Mark as paid';

  @override
  String get settleUpAmountLabel => 'Amount';

  @override
  String get settleUpPayFull => 'Pay full';

  @override
  String get settleUpPartialPayment => 'Partial payment';

  @override
  String get settleUpUseFullAmount => 'Use full amount';

  @override
  String settleUpAmountOfTotal(String amount) {
    return 'of $amount';
  }

  @override
  String get settleUpPayPartial => 'Pay Partial';

  @override
  String get settleUpPartialHint => 'Amount to record';

  @override
  String get settleUpPartialInvalid =>
      'Enter a valid amount greater than zero and not more than owed.';

  @override
  String get appTagline => 'Split bills with friends';

  @override
  String get billsTotalExpenses => 'Total expenses';

  @override
  String get billsThisWeek => 'This week';

  @override
  String get billsAverage => 'Average';

  @override
  String billsInsightVsLastWeek(String value) {
    return '$value% vs last week';
  }

  @override
  String billsInsightTop(String amount) {
    return 'Top: $amount';
  }

  @override
  String billsInsightStreak(int days) {
    return '$days day streak';
  }

  @override
  String billsCountLabel(int count) {
    return '$count bills';
  }

  @override
  String get billsSearchHint => 'Search bills, items…';

  @override
  String get billsSearchEmpty => 'No matching bills';

  @override
  String get billsSearchPeopleHint => 'Search people…';

  @override
  String get billsEmptyHeroTitle => 'No transactions yet';

  @override
  String get billsEmptyHeroSubtitle =>
      'Tap + to add a bill and start splitting.';

  @override
  String get billsFiltersTitle => 'Filters';

  @override
  String get billsFiltersCategorySection => 'Category';

  @override
  String get billsFiltersPeopleSection => 'People';

  @override
  String get billsFiltersClearAll => 'Clear all';

  @override
  String get billsFiltersAdjustHint => 'Try adjusting filters or search.';

  @override
  String get fabNewBill => 'New Bill';

  @override
  String get fabScanBill => 'Scan Bill';

  @override
  String get fabCreateReport => 'Create Report';

  @override
  String get addTransactionSheetTitle => 'Add Transaction';

  @override
  String get addTransactionSheetSubtitle =>
      'Receipt, people, items, tax — then post.';

  @override
  String get addTransactionDescriptionSection => 'Description';

  @override
  String get addTransactionDescriptionAutoHint =>
      'Auto-fills from first item if empty';

  @override
  String get addTransactionSuggestedCategory => 'Suggested';

  @override
  String get addTransactionApplySuggestion => 'Apply';

  @override
  String get addTransactionToday => 'Today';

  @override
  String get addTransactionYesterday => 'Yesterday';

  @override
  String get addTransactionDateTimeSection => 'Date';

  @override
  String get addTransactionWhosSplitting => 'Who\'s splitting?';

  @override
  String get addTransactionEveryoneIncludedHint =>
      'Tap to include or exclude someone from this bill. Add or remove trip members from the draft split screen.';

  @override
  String addTransactionItemsSection(int count) {
    return 'Items ($count)';
  }

  @override
  String get addTransactionAddLineItem => 'Add item';

  @override
  String get addTransactionTaxSplitHint =>
      'Split proportionally among participants';

  @override
  String addTransactionSubtotalLine(int count) {
    return 'Subtotal ($count items)';
  }

  @override
  String get addTransactionTaxSummaryLine => 'Tax & service';

  @override
  String get addTransactionGrandTotal => 'Grand total';

  @override
  String get addTransactionWhoPaidShortcut => 'Who paid';

  @override
  String get categoryEntertainment => 'Fun';

  @override
  String get categoryShopping => 'Shop';

  @override
  String get categoryUtilities => 'Bills';

  @override
  String get categorySettlement => 'Settlement';

  @override
  String get addTransactionCategoryLabel => 'Category';

  @override
  String get categoryFood => 'Food';

  @override
  String get categoryTransport => 'Transport';

  @override
  String get categoryAccommodation => 'Accommodation';

  @override
  String get categoryOther => 'Other';

  @override
  String get addTransactionDateLabel => 'Date';

  @override
  String get addTransactionTaxLabel => 'Tax & service';

  @override
  String get addTransactionReceiptLabel => 'Receipt photo';

  @override
  String get addTransactionReceiptPick => 'Attach photo';

  @override
  String get addTransactionReceiptRemove => 'Remove';

  @override
  String addTransactionDraftSummary(int itemCount, int peopleCount) {
    return '$itemCount items · $peopleCount people';
  }

  @override
  String get addTransactionOpenDraft => 'Line items & split';

  @override
  String get addTransactionPostAction => 'Add Transaction';

  @override
  String get billCardShare => 'Share';

  @override
  String get billCardEdit => 'Details';

  @override
  String get billCardDelete => 'Delete';

  @override
  String get billDeleteConfirmTitle => 'Delete this bill?';

  @override
  String get billDeleteConfirmBody =>
      'This removes the bill and its lines from this device.';

  @override
  String get billSwipeDeleteHint => 'Swipe left to delete';

  @override
  String semanticsDraftBillLine(String itemName, String formattedAmount) {
    return '$itemName, $formattedAmount';
  }

  @override
  String get semanticsDraftLineHint => 'Double tap to edit.';

  @override
  String semanticsSplitPersonRow(String personName, String formattedAmount) {
    return '$personName, $formattedAmount';
  }

  @override
  String semanticsSettlementEdge(
    String fromName,
    String toName,
    String formattedAmount,
  ) {
    return '$fromName pays $toName, $formattedAmount';
  }

  @override
  String semanticsRecordedSettlement(
    String fromName,
    String toName,
    String formattedAmount,
  ) {
    return '$fromName to $toName, $formattedAmount';
  }
}
