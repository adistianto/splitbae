import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// App name shown in the title bar. Keep short; do not translate the brand if policy says so.
  ///
  /// In en, this message translates to:
  /// **'SplitBae'**
  String get appTitle;

  /// Navigation rail / primary destination: bill split home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHomeLabel;

  /// Tooltip for the app bar button that opens the add-receipt-line flow.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItemTooltip;

  /// Label on the FAB that adds another participant to the split.
  ///
  /// In en, this message translates to:
  /// **'Add person'**
  String get addPerson;

  /// Title for the settings screen and its entry in navigation.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Section header for language / locale preferences.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Explains that the app follows the OS locale until the user overrides.
  ///
  /// In en, this message translates to:
  /// **'Uses your phone language until you pick one here.'**
  String get settingsLanguageSubtitle;

  /// Option to follow the system locale instead of a fixed app language.
  ///
  /// In en, this message translates to:
  /// **'Use device language'**
  String get languageDevice;

  /// Fixed language option: English.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Fixed language option: Indonesian (use the autonym in target locale).
  ///
  /// In en, this message translates to:
  /// **'Bahasa Indonesia'**
  String get languageIndonesian;

  /// Settings row: default ISO currency for new line items.
  ///
  /// In en, this message translates to:
  /// **'Default currency for new items'**
  String get settingsDefaultCurrency;

  /// Clarifies that per-line currency can differ from the default.
  ///
  /// In en, this message translates to:
  /// **'You can still pick another currency per item.'**
  String get settingsDefaultCurrencySubtitle;

  /// Title of the modal or sheet for creating a receipt line.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItemTitle;

  /// Explains that the amount uses the selected currency.
  ///
  /// In en, this message translates to:
  /// **'Amount is in the currency you select below.'**
  String get addItemSubtitle;

  /// Starts camera/gallery OCR to fill item name and amount.
  ///
  /// In en, this message translates to:
  /// **'Scan receipt'**
  String get scanReceiptButton;

  /// Image source option for receipt scan.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get scanReceiptCamera;

  /// Image source option for receipt scan.
  ///
  /// In en, this message translates to:
  /// **'Choose from library'**
  String get scanReceiptGallery;

  /// Dismiss scan source sheet and type item fields instead.
  ///
  /// In en, this message translates to:
  /// **'Enter manually'**
  String get scanReceiptEnterManually;

  /// Explains manual path when OCR is skipped.
  ///
  /// In en, this message translates to:
  /// **'Use the name and amount fields below'**
  String get scanReceiptEnterManuallySubtitle;

  /// When native OCR exceeds the time limit.
  ///
  /// In en, this message translates to:
  /// **'Scanning took too long. Try another photo or enter the item manually below.'**
  String get scanReceiptTimeout;

  /// Info when OCR probe fails; manual entry remains available.
  ///
  /// In en, this message translates to:
  /// **'On-device text recognition could not be verified. You can still try scanning, or type the item name and amount below.'**
  String get scanReceiptDegradedBody;

  /// Header when OCR found multiple price lines.
  ///
  /// In en, this message translates to:
  /// **'Pick a line to use'**
  String get scanReceiptPickLine;

  /// Snack bar when OCR text had no parseable lines.
  ///
  /// In en, this message translates to:
  /// **'No lines with an amount were found. Try a clearer photo or enter the item manually.'**
  String get scanReceiptNoLines;

  /// When OCR is not supported (e.g. web/desktop).
  ///
  /// In en, this message translates to:
  /// **'Receipt scanning is only available in the Android and iOS apps.'**
  String get scanReceiptUnavailable;

  /// Generic OCR failure snack bar.
  ///
  /// In en, this message translates to:
  /// **'Could not read text from the image.'**
  String get scanReceiptErrorGeneric;

  /// OCR failure with native error message.
  ///
  /// In en, this message translates to:
  /// **'Could not read the receipt: {message}'**
  String scanReceiptErrorDetail(String message);

  /// Form label for the line description (e.g. food name).
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get itemNameLabel;

  /// Placeholder example for the item name field.
  ///
  /// In en, this message translates to:
  /// **'e.g. Fried rice'**
  String get itemNameHint;

  /// Form label for the monetary amount (not the word Price if Amount fits better).
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get priceLabel;

  /// Numeric placeholder example without currency symbol (locale formats it).
  ///
  /// In en, this message translates to:
  /// **'15000'**
  String get priceHint;

  /// Label for ISO currency selector (IDR, USD, …).
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyLabel;

  /// Generic dismiss action on dialogs.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Generic confirm action to persist the form.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Validation: user left the item name empty.
  ///
  /// In en, this message translates to:
  /// **'Item name is required.'**
  String get errorNameRequired;

  /// Validation: user left the amount empty.
  ///
  /// In en, this message translates to:
  /// **'Amount is required.'**
  String get errorPriceRequired;

  /// Validation: amount is not a positive number.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid positive amount.'**
  String get errorPriceInvalid;

  /// Explains the split list: one row per person per currency; no exchange rates.
  ///
  /// In en, this message translates to:
  /// **'Totals follow who is assigned to each line; one row per person per currency (no FX conversion).'**
  String get splitSubtitle;

  /// Label for chips selecting which people share a line item.
  ///
  /// In en, this message translates to:
  /// **'Split with'**
  String get itemAssigneesLabel;

  /// Shown when there are no participants yet.
  ///
  /// In en, this message translates to:
  /// **'Add people to the split to assign shares.'**
  String get itemAssigneesNeedPeople;

  /// Section header above the split totals list.
  ///
  /// In en, this message translates to:
  /// **'Per person'**
  String get perPersonTitle;

  /// Section header for storage and encryption preferences.
  ///
  /// In en, this message translates to:
  /// **'Data & privacy'**
  String get settingsDataPrivacy;

  /// Toggle label: SQLCipher-style encryption for the on-device database when implemented.
  ///
  /// In en, this message translates to:
  /// **'Encrypt local database'**
  String get settingsEncryptDatabase;

  /// Explains why enabling encryption matters; note default is off.
  ///
  /// In en, this message translates to:
  /// **'Strongly recommended if your phone could be lost or stolen—it protects names and amounts at rest. Off by default.'**
  String get settingsEncryptDatabaseSubtitle;

  /// Dialog title when toggling SQLCipher on or off.
  ///
  /// In en, this message translates to:
  /// **'Change database encryption?'**
  String get settingsEncryptChangeTitle;

  /// Explains in-place migration when toggling SQLCipher; no server upload.
  ///
  /// In en, this message translates to:
  /// **'Your ledgers, people, and line items will be copied into the new encrypted or plain database on this device. Nothing is uploaded. If something goes wrong, we restore your previous data and leave encryption as it was.'**
  String get settingsEncryptChangeBody;

  /// Confirm encryption migration (data preserved on device).
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get settingsEncryptChangeConfirm;

  /// Snack bar when migration failed but snapshot restore succeeded.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t switch encryption; your data is unchanged.'**
  String get settingsEncryptMigrationRolledBack;

  /// Snack bar when DB recreate fails after encryption toggle.
  ///
  /// In en, this message translates to:
  /// **'Could not update the database. Try again or restart the app.'**
  String get settingsEncryptChangeError;

  /// Section header for manual backup export/import.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get settingsBackup;

  /// List tile title: opens export/import backup flow.
  ///
  /// In en, this message translates to:
  /// **'Manual backup'**
  String get settingsBackupManualTitle;

  /// Subtitle on Settings row that opens the manual backup screen.
  ///
  /// In en, this message translates to:
  /// **'Export or restore a .sb_backup file on this device.'**
  String get settingsBackupEntrySubtitle;

  /// List tile: write .sb_backup and open share sheet.
  ///
  /// In en, this message translates to:
  /// **'Export backup file'**
  String get settingsBackupExport;

  /// Security disclaimer for unencrypted backup.
  ///
  /// In en, this message translates to:
  /// **'Plain JSON (.sb_backup). Anyone with the file can read names and amounts—only store or send it where you trust.'**
  String get settingsBackupExportSubtitle;

  /// List tile: pick .sb_backup and replace local DB.
  ///
  /// In en, this message translates to:
  /// **'Import backup file'**
  String get settingsBackupImport;

  /// Warns import is destructive locally.
  ///
  /// In en, this message translates to:
  /// **'Replaces all ledgers, people, and line items on this device.'**
  String get settingsBackupImportSubtitle;

  /// Dialog title before importing a backup over current DB.
  ///
  /// In en, this message translates to:
  /// **'Replace all local data?'**
  String get backupImportConfirmTitle;

  /// Explains destructive import.
  ///
  /// In en, this message translates to:
  /// **'Your current bill data will be removed and replaced by the backup. This cannot be undone.'**
  String get backupImportConfirmBody;

  /// Confirm button on import dialog.
  ///
  /// In en, this message translates to:
  /// **'Replace and import'**
  String get backupImportConfirmAction;

  /// Snack bar after export file written and share opened.
  ///
  /// In en, this message translates to:
  /// **'Backup file ready.'**
  String get backupExportSuccess;

  /// Snack bar after successful import.
  ///
  /// In en, this message translates to:
  /// **'Backup restored.'**
  String get backupImportSuccess;

  /// Parse or format error for .sb_backup.
  ///
  /// In en, this message translates to:
  /// **'That file is not a valid SplitBae backup.'**
  String get backupErrorInvalid;

  /// IO or share failure on export.
  ///
  /// In en, this message translates to:
  /// **'Could not create the backup file.'**
  String get backupErrorExport;

  /// Title when editing an existing receipt line.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get editItemTitle;

  /// Section header above the list of receipt lines.
  ///
  /// In en, this message translates to:
  /// **'Bill items'**
  String get billItemsTitle;

  /// Alert title before deleting a receipt line.
  ///
  /// In en, this message translates to:
  /// **'Remove item?'**
  String get deleteItemTitle;

  /// Alert body for deleting a receipt line.
  ///
  /// In en, this message translates to:
  /// **'This line will be removed from the bill.'**
  String get deleteItemBody;

  /// Destructive confirm button label.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// App bar: open participant list.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get peopleTooltip;

  /// Bottom sheet title for renaming/removing participants.
  ///
  /// In en, this message translates to:
  /// **'People in this split'**
  String get managePeopleTitle;

  /// Button to rename a participant.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameParticipantAction;

  /// Dialog title for participant rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameParticipantTitle;

  /// Label for participant name field.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get participantDisplayNameLabel;

  /// Alert before removing a participant.
  ///
  /// In en, this message translates to:
  /// **'Remove person?'**
  String get removeParticipantTitle;

  /// Alert body; {name} is the participant display name.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from this split?'**
  String removeParticipantBody(String name);

  /// Title of the bottom sheet for adding a participant by name.
  ///
  /// In en, this message translates to:
  /// **'Add someone to the split'**
  String get addPersonSheetTitle;

  /// Placeholder example for the new participant name field.
  ///
  /// In en, this message translates to:
  /// **'e.g. Adistianto'**
  String get addPersonNameHint;

  /// Validation when the user tries to add a participant without a name.
  ///
  /// In en, this message translates to:
  /// **'Enter a name.'**
  String get participantNameRequired;

  /// Shown when there are no participants yet.
  ///
  /// In en, this message translates to:
  /// **'Add people to see how the bill splits.'**
  String get emptyParticipantsHint;

  /// Shown when the bill has no line items.
  ///
  /// In en, this message translates to:
  /// **'No receipt lines yet. Add an item to start.'**
  String get emptyBillHint;

  /// Title for the balances / settlement screen.
  ///
  /// In en, this message translates to:
  /// **'Balances'**
  String get balancesTitle;

  /// Toolbar or navigation tooltip for opening balances.
  ///
  /// In en, this message translates to:
  /// **'Balances and settlements'**
  String get balancesTooltip;

  /// Section header for Rust-computed minimal settlement edges.
  ///
  /// In en, this message translates to:
  /// **'Suggested transfers'**
  String get suggestedSettlementsTitle;

  /// Section header for settlement rows saved in the local database.
  ///
  /// In en, this message translates to:
  /// **'Recorded transfers'**
  String get recordedSettlementsTitle;

  /// Shown when there are no suggested settlement edges.
  ///
  /// In en, this message translates to:
  /// **'Everyone is settled for this ledger.'**
  String get allSettledUp;

  /// Button to persist one suggested settlement as a completed transfer.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get recordSettlementAction;

  /// Confirmation dialog title when recording a settlement.
  ///
  /// In en, this message translates to:
  /// **'Record this transfer?'**
  String get recordSettlementConfirmTitle;

  /// Confirmation dialog body; amount is already localized.
  ///
  /// In en, this message translates to:
  /// **'{fromName} pays {toName} {amount}.'**
  String recordSettlementConfirmBody(
    String fromName,
    String toName,
    String amount,
  );

  /// Explains that per-currency payments drive settlement nets.
  ///
  /// In en, this message translates to:
  /// **'Who paid is stored per currency on the draft bill. Use Who paid on the home screen to edit; totals must match receipt lines.'**
  String get settlementPayerModelHint;

  /// Toolbar: open editor for per-person payments toward the bill.
  ///
  /// In en, this message translates to:
  /// **'Who paid'**
  String get whoPaidTooltip;

  /// Bottom sheet title for splitting payments by participant and currency.
  ///
  /// In en, this message translates to:
  /// **'Who paid'**
  String get whoPaidTitle;

  /// Explains validation against line totals.
  ///
  /// In en, this message translates to:
  /// **'Amounts must add up to each currency’s line total (same as the receipt).'**
  String get whoPaidSubtitle;

  /// Commits who-paid amounts to the local database.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get whoPaidSave;

  /// Resets payments so the first participant pays each currency total.
  ///
  /// In en, this message translates to:
  /// **'First person pays all'**
  String get whoPaidReset;

  /// Shown when opening who-paid with no bill lines.
  ///
  /// In en, this message translates to:
  /// **'Add receipt lines first, then split who paid.'**
  String get whoPaidEmptyBill;

  /// Label before the required total for a currency in who-paid.
  ///
  /// In en, this message translates to:
  /// **'Bill total'**
  String get whoPaidBillTotalLabel;

  /// Bottom sheet title when saving the draft bill to history.
  ///
  /// In en, this message translates to:
  /// **'Post bill'**
  String get postBillTitle;

  /// Explains posting the draft bill.
  ///
  /// In en, this message translates to:
  /// **'This locks the current lines and payments into your history. You can start a new bill afterward.'**
  String get postBillSubtitle;

  /// Label for the posted expense title field.
  ///
  /// In en, this message translates to:
  /// **'Title (optional)'**
  String get postBillDescriptionLabel;

  /// Placeholder for the posted bill title.
  ///
  /// In en, this message translates to:
  /// **'e.g. Team dinner'**
  String get postBillDescriptionHint;

  /// Primary button to commit the draft bill.
  ///
  /// In en, this message translates to:
  /// **'Post bill'**
  String get postBillAction;

  /// Snackbar after a successful post.
  ///
  /// In en, this message translates to:
  /// **'Bill posted.'**
  String get postBillSuccess;

  /// Error when posting with no receipt lines.
  ///
  /// In en, this message translates to:
  /// **'Add at least one line before posting.'**
  String get postBillErrorEmpty;

  /// Error when posting with no participants.
  ///
  /// In en, this message translates to:
  /// **'Add people before posting.'**
  String get postBillErrorNoParticipants;

  /// Section header for posted (non-draft) transactions.
  ///
  /// In en, this message translates to:
  /// **'Recent bills'**
  String get postedBillsTitle;

  /// Shown when a posted bill has no title.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get postBillUntitled;

  /// Bottom navigation: posted bills feed.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get navBillsTab;

  /// Bottom navigation: draft bill workspace.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get navSplitTab;

  /// App bar title for the draft split workspace.
  ///
  /// In en, this message translates to:
  /// **'Split bill'**
  String get navSplitTitle;

  /// App bar title for the posted bills list.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get billsScreenTitle;

  /// Empty state when there are no posted transactions.
  ///
  /// In en, this message translates to:
  /// **'No bills yet. Add lines on Split, then post a bill.'**
  String get billsEmptyState;

  /// Tab on posted bill detail: line items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get transactionDetailTabItems;

  /// Tab on posted bill detail: per-person totals owed.
  ///
  /// In en, this message translates to:
  /// **'Persons'**
  String get transactionDetailTabPersons;

  /// Tab on posted bill detail: who paid.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get transactionDetailTabPayments;

  /// Error when transaction id is missing from the database.
  ///
  /// In en, this message translates to:
  /// **'This bill could not be loaded.'**
  String get transactionDetailMissing;

  /// Empty state on Payments tab.
  ///
  /// In en, this message translates to:
  /// **'No payments recorded for this bill.'**
  String get transactionDetailNoPayments;

  /// When a line has zero assigned shares.
  ///
  /// In en, this message translates to:
  /// **'No split for this line.'**
  String get transactionDetailNoShares;

  /// Persons tab when all per-person amounts are zero.
  ///
  /// In en, this message translates to:
  /// **'Nothing owed on this bill.'**
  String get transactionDetailPersonsEmpty;

  /// Section header above suggested settlement transfers.
  ///
  /// In en, this message translates to:
  /// **'Settle up'**
  String get settleUpSectionTitle;

  /// Label under payer name on settlement card.
  ///
  /// In en, this message translates to:
  /// **'Pays'**
  String get settlementPayerPays;

  /// Label under payee name on settlement card.
  ///
  /// In en, this message translates to:
  /// **'Receives'**
  String get settlementPayeeReceives;

  /// Primary action on a suggested settlement card.
  ///
  /// In en, this message translates to:
  /// **'Mark as paid'**
  String get markAsPaid;

  /// Label beside the settlement amount on an expanded card.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get settleUpAmountLabel;

  /// Confirm recording the full suggested transfer.
  ///
  /// In en, this message translates to:
  /// **'Pay full'**
  String get settleUpPayFull;

  /// Switch to entering a partial settlement amount.
  ///
  /// In en, this message translates to:
  /// **'Partial payment'**
  String get settleUpPartialPayment;

  /// Fills the partial payment field with the full owed amount.
  ///
  /// In en, this message translates to:
  /// **'Use full amount'**
  String get settleUpUseFullAmount;

  /// Reference to the total owed, shown beside Use full amount.
  ///
  /// In en, this message translates to:
  /// **'of {amount}'**
  String settleUpAmountOfTotal(String amount);

  /// Submit a partial settlement after entering an amount.
  ///
  /// In en, this message translates to:
  /// **'Pay Partial'**
  String get settleUpPayPartial;

  /// Hint for the partial payment text field.
  ///
  /// In en, this message translates to:
  /// **'Amount to record'**
  String get settleUpPartialHint;

  /// Validation when partial amount is empty or out of range.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount greater than zero and not more than owed.'**
  String get settleUpPartialInvalid;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
