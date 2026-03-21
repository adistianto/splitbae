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
  String get languageDevice => 'Use device language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageIndonesian => 'Bahasa Indonesia';

  @override
  String get settingsDefaultCurrency => 'Default currency for new items';

  @override
  String get settingsDefaultCurrencySubtitle =>
      'You can still pick another currency per item.';

  @override
  String get addItemTitle => 'Add item';

  @override
  String get addItemSubtitle => 'Amount is in the currency you select below.';

  @override
  String get scanReceiptButton => 'Scan receipt';

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
  String get scanReceiptTimeout =>
      'Scanning took too long. Try another photo or enter the item manually below.';

  @override
  String get scanReceiptDegradedBody =>
      'On-device text recognition could not be verified. You can still try scanning, or type the item name and amount below.';

  @override
  String get scanReceiptPickLine => 'Pick a line to use';

  @override
  String get scanReceiptNoLines =>
      'No lines with an amount were found. Try a clearer photo or enter the item manually.';

  @override
  String get scanReceiptUnavailable =>
      'Receipt scanning is only available in the Android and iOS apps.';

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
  String get fabNewBill => 'New Bill';

  @override
  String get fabScanBill => 'Scan Bill';

  @override
  String get fabCreateReport => 'Create Report';
}
