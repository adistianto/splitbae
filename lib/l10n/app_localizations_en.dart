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
}
