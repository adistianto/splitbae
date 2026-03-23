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

  /// Subtitle under Settings title (v0 settings-tab parity).
  ///
  /// In en, this message translates to:
  /// **'Manage your preferences'**
  String get settingsV0ManagePreferences;

  /// Heading for the insights card on Settings (posted bills summary).
  ///
  /// In en, this message translates to:
  /// **'Your activity'**
  String get settingsV0ActivityTitle;

  /// No description provided for @settingsV0TotalSpent.
  ///
  /// In en, this message translates to:
  /// **'Total spent'**
  String get settingsV0TotalSpent;

  /// No description provided for @settingsV0ThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get settingsV0ThisMonth;

  /// No description provided for @settingsV0StatTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get settingsV0StatTransactions;

  /// No description provided for @settingsV0StatFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get settingsV0StatFriends;

  /// No description provided for @settingsV0StatAvgPerTxn.
  ///
  /// In en, this message translates to:
  /// **'Avg/txn'**
  String get settingsV0StatAvgPerTxn;

  /// No description provided for @settingsV0TopCategories.
  ///
  /// In en, this message translates to:
  /// **'Top categories'**
  String get settingsV0TopCategories;

  /// No description provided for @settingsV0TopPartner.
  ///
  /// In en, this message translates to:
  /// **'Most frequent partner'**
  String get settingsV0TopPartner;

  /// Partner insight: how many posted bills included this person.
  ///
  /// In en, this message translates to:
  /// **'{count} bills together'**
  String settingsV0PartnerTxCount(int count);

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

  /// Section header for theme (light/dark) and related display options.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// Explains light/dark vs follow device; references OS naming.
  ///
  /// In en, this message translates to:
  /// **'Light, Dark, or follow your device (System default on Android; Automatic on iPhone and Mac).'**
  String get settingsAppearanceSubtitle;

  /// Material Design: follow OS light/dark (Android, Windows, Linux, web).
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsThemeFollowDeviceMaterial;

  /// Short label for segmented control (Material platforms).
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeFollowDeviceMaterialShort;

  /// Apple HIG: follow system appearance (iOS, macOS), same term as system Settings.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get settingsThemeFollowDeviceApple;

  /// Always use light theme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// Always use dark theme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// Settings toggle: Material 3 dynamic color from wallpaper (Material You).
  ///
  /// In en, this message translates to:
  /// **'Material You dynamic color'**
  String get settingsMaterialYou;

  /// Explains M3 dynamic color toggle; default off.
  ///
  /// In en, this message translates to:
  /// **'Uses your wallpaper palette for the app theme on supported devices. Off by default; turn on for Material You colors, or leave off for SplitBae’s default teal look.'**
  String get settingsMaterialYouSubtitle;

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

  /// Settings row: default ISO currency for new draft bills (empty draft).
  ///
  /// In en, this message translates to:
  /// **'Default currency for new bills'**
  String get settingsDefaultCurrency;

  /// Clarifies when the default applies.
  ///
  /// In en, this message translates to:
  /// **'Used when you start a new bill with no lines yet.'**
  String get settingsDefaultCurrencySubtitle;

  /// Explains that historical bills do not change when the default currency setting changes.
  ///
  /// In en, this message translates to:
  /// **'Posted transactions keep the currency they were saved in. Changing this only affects new lines and the empty draft.'**
  String get settingsDefaultCurrencyRecordingNote;

  /// Title of the modal or sheet for creating a receipt line.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItemTitle;

  /// Explains bill-level currency for line amounts.
  ///
  /// In en, this message translates to:
  /// **'Amounts use this bill’s currency (set by default for an empty bill; change default in Settings).'**
  String get addItemSubtitle;

  /// Read-only label for the ISO currency of the current draft or posted bill.
  ///
  /// In en, this message translates to:
  /// **'Bill currency'**
  String get billCurrencyLabel;

  /// Starts camera/gallery OCR to fill item name and amount.
  ///
  /// In en, this message translates to:
  /// **'Scan receipt'**
  String get scanReceiptButton;

  /// Full-screen scan flow title (v0 parity).
  ///
  /// In en, this message translates to:
  /// **'Scan receipt'**
  String get scanReceiptScreenTitle;

  /// Subtitle under the scan screen title.
  ///
  /// In en, this message translates to:
  /// **'Capture to add expenses quickly'**
  String get scanReceiptScreenSubtitle;

  /// Small label on the gradient hero card during scan.
  ///
  /// In en, this message translates to:
  /// **'Quick add'**
  String get scanReceiptHeroQuickAdd;

  /// Hero card line before any OCR result.
  ///
  /// In en, this message translates to:
  /// **'Point camera at receipt'**
  String get scanReceiptHeroPointCamera;

  /// Hero card line after OCR found line items.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item detected} other{{count} items detected}}'**
  String scanReceiptHeroItemsDetected(int count);

  /// Helper under the large Take photo control.
  ///
  /// In en, this message translates to:
  /// **'Snap a picture of your receipt'**
  String get scanReceiptTakePhotoSubtitle;

  /// Shown while OCR runs on the captured image.
  ///
  /// In en, this message translates to:
  /// **'Extracting items…'**
  String get scanReceiptExtractingTitle;

  /// Secondary line under extracting title.
  ///
  /// In en, this message translates to:
  /// **'This may take a moment'**
  String get scanReceiptExtractingSubtitle;

  /// Primary action after OCR when opening the draft split flow (FAB).
  ///
  /// In en, this message translates to:
  /// **'Continue to Split'**
  String get scanReceiptContinueToSplit;

  /// Shown above editable OCR chips after multi-line scan.
  ///
  /// In en, this message translates to:
  /// **'Tap a line to fix the price, then confirm.'**
  String get scanReceiptOcrReviewHint;

  /// Placeholder label when OCR found a price but the item name was unreadable; user can rename.
  ///
  /// In en, this message translates to:
  /// **'Unknown item'**
  String get scanReceiptUnknownOcrItemName;

  /// Dialog title when correcting a parsed receipt line amount.
  ///
  /// In en, this message translates to:
  /// **'Edit amount'**
  String get scanReceiptEditOcrLineTitle;

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

  /// Snack bar when the user denies the camera permission prompt.
  ///
  /// In en, this message translates to:
  /// **'Camera access is required to take a receipt photo.'**
  String get scanReceiptPermissionCameraDenied;

  /// Snack bar when the user denies photo library access (iOS).
  ///
  /// In en, this message translates to:
  /// **'Photo library access is required to choose a receipt image.'**
  String get scanReceiptPermissionPhotosDenied;

  /// Dialog title when camera is blocked in system settings.
  ///
  /// In en, this message translates to:
  /// **'Camera access is off'**
  String get scanReceiptPermissionCameraBlockedTitle;

  /// Dialog body prompting the user to open system settings for camera.
  ///
  /// In en, this message translates to:
  /// **'Allow SplitBae to use the camera in Settings so you can scan receipts.'**
  String get scanReceiptPermissionCameraBlockedBody;

  /// Dialog title when photo library access is blocked in system settings.
  ///
  /// In en, this message translates to:
  /// **'Photo access is off'**
  String get scanReceiptPermissionPhotosBlockedTitle;

  /// Dialog body prompting the user to open system settings for photos.
  ///
  /// In en, this message translates to:
  /// **'Allow SplitBae to access your photo library in Settings so you can choose receipt images.'**
  String get scanReceiptPermissionPhotosBlockedBody;

  /// Opens the app’s page in system Settings (permissions).
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get scanReceiptPermissionOpenSettings;

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

  /// Line picker subtitle when quantity and line total were parsed.
  ///
  /// In en, this message translates to:
  /// **'×{quantity} · {unitPrice} each'**
  String scanReceiptLineQtyUnitPrice(int quantity, String unitPrice);

  /// OCR line picker: quantity, unit price, and line total when a qty column was parsed.
  ///
  /// In en, this message translates to:
  /// **'Qty {quantity} · {unitPrice} each · line {lineTotal}'**
  String scanReceiptOcrLineDetail(
    int quantity,
    String unitPrice,
    String lineTotal,
  );

  /// Primary action to import every parsed OCR line into the draft bill.
  ///
  /// In en, this message translates to:
  /// **'Add all {count} lines'**
  String scanReceiptAddAllLines(int count);

  /// Snack bar after batch-importing OCR lines to the draft.
  ///
  /// In en, this message translates to:
  /// **'Added {count} lines from the receipt.'**
  String scanReceiptBatchAdded(int count);

  /// Snack bar when OCR text had no parseable lines.
  ///
  /// In en, this message translates to:
  /// **'No lines with an amount were found. Try a clearer photo or enter the item manually.'**
  String get scanReceiptNoLines;

  /// Legacy banner when scan is unavailable on the current platform.
  ///
  /// In en, this message translates to:
  /// **'Receipt scanning needs on-device OCR (Android, iOS, macOS, or Windows in this app).'**
  String get scanReceiptUnavailable;

  /// Desktop/web: open a file dialog to pick a receipt image.
  ///
  /// In en, this message translates to:
  /// **'Choose image file'**
  String get scanReceiptChooseImageFile;

  /// Hint when native OCR is unavailable (e.g. web, Linux); camera/file/manual still offered.
  ///
  /// In en, this message translates to:
  /// **'On-device OCR isn’t available on web or Linux in this build. You can still pick a photo or enter lines manually.'**
  String get scanReceiptNonMobileScanHint;

  /// Snack bar when OCR can’t run (e.g. web with no file path, or Linux).
  ///
  /// In en, this message translates to:
  /// **'On-device receipt OCR isn’t available on this platform. Enter the line manually.'**
  String get scanReceiptNoNativeOcr;

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

  /// Inline help when OCR returned no parseable lines; offers retake or manual entry.
  ///
  /// In en, this message translates to:
  /// **'No line items found. Retake the photo or enter amounts manually.'**
  String get scanReceiptRecoveryNoLinesMessage;

  /// Inline help when native OCR hit the time limit.
  ///
  /// In en, this message translates to:
  /// **'Scan took too long. Retake or enter the item manually.'**
  String get scanReceiptRecoveryTimeoutMessage;

  /// Inline help when OCR failed with an error or generic failure.
  ///
  /// In en, this message translates to:
  /// **'Could not read this photo. Retake or enter the item manually.'**
  String get scanReceiptRecoveryErrorMessage;

  /// Clears the preview so the user can capture or pick another receipt image.
  ///
  /// In en, this message translates to:
  /// **'Retake photo'**
  String get scanReceiptRetakePhoto;

  /// Optional short tip under the take-photo control to improve OCR (no new sensors).
  ///
  /// In en, this message translates to:
  /// **'Use good light, hold steady, and keep the receipt in frame.'**
  String get scanReceiptPhotoQualityHint;

  /// Recovery action: crop the receipt to improve OCR for line items.
  ///
  /// In en, this message translates to:
  /// **'Focus on line items'**
  String get scanReceiptCropFocusButton;

  /// Inline hint shown with the crop action after OCR finds no parseable lines.
  ///
  /// In en, this message translates to:
  /// **'Cropping can improve OCR accuracy for line items (not guaranteed).'**
  String get scanReceiptCropFocusHint;

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

  /// Short label for line quantity on add-item and split bill cards.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get itemQuantityLabel;

  /// Placeholder for quantity field (integer).
  ///
  /// In en, this message translates to:
  /// **'1'**
  String get itemQuantityHint;

  /// Validation when quantity is missing or below 1.
  ///
  /// In en, this message translates to:
  /// **'Use a whole number of at least 1.'**
  String get errorQuantityInvalid;

  /// Column header for quantity on draft split line cards.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get draftBillLineQtyColumn;

  /// Column header for unit price (line total ÷ qty).
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get draftBillLineUnitColumn;

  /// Column header for line total amount.
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get draftBillLineLineTotalColumn;

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

  /// Title on the pinned bottom bar showing per-person split totals from calculateSplit.
  ///
  /// In en, this message translates to:
  /// **'Amount owed'**
  String get draftSplitPinnedSummaryTitle;

  /// Label for tax amount (minor units) in the draft receipt split.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get draftSplitTaxFieldLabel;

  /// Label for tip amount (minor units) in the draft receipt split.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get draftSplitTipFieldLabel;

  /// Shown when calculateSplit fails (e.g. invalid receipt).
  ///
  /// In en, this message translates to:
  /// **'Could not update split.'**
  String get draftSplitCalculateError;

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

  /// Subtitle under Balances title (v0 parity).
  ///
  /// In en, this message translates to:
  /// **'See who owes what'**
  String get balancesScreenSubtitle;

  /// No description provided for @balancesHeroToSettle.
  ///
  /// In en, this message translates to:
  /// **'To settle'**
  String get balancesHeroToSettle;

  /// No description provided for @balancesHeroStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get balancesHeroStatus;

  /// No description provided for @balancesHeroAllSettledTitle.
  ///
  /// In en, this message translates to:
  /// **'All settled!'**
  String get balancesHeroAllSettledTitle;

  /// No description provided for @balancesHeroEveryoneEven.
  ///
  /// In en, this message translates to:
  /// **'Everyone is even — no payments needed'**
  String get balancesHeroEveryoneEven;

  /// No description provided for @balancesHeroPaymentsNeeded.
  ///
  /// In en, this message translates to:
  /// **'{count} payments needed'**
  String balancesHeroPaymentsNeeded(int count);

  /// No description provided for @balancesTotalSpentLabel.
  ///
  /// In en, this message translates to:
  /// **'Total spent'**
  String get balancesTotalSpentLabel;

  /// No description provided for @balancesAvgPerPersonLabel.
  ///
  /// In en, this message translates to:
  /// **'Avg / person'**
  String get balancesAvgPerPersonLabel;

  /// No description provided for @balancesSectionIndividual.
  ///
  /// In en, this message translates to:
  /// **'Individual balances'**
  String get balancesSectionIndividual;

  /// No description provided for @balancesInsightOwesMost.
  ///
  /// In en, this message translates to:
  /// **'Owes most'**
  String get balancesInsightOwesMost;

  /// No description provided for @balancesInsightOwedMost.
  ///
  /// In en, this message translates to:
  /// **'Owed most'**
  String get balancesInsightOwedMost;

  /// No description provided for @balancesNetGetsBack.
  ///
  /// In en, this message translates to:
  /// **'Gets back'**
  String get balancesNetGetsBack;

  /// No description provided for @balancesNetOwes.
  ///
  /// In en, this message translates to:
  /// **'Owes'**
  String get balancesNetOwes;

  /// No description provided for @balancesNetSettled.
  ///
  /// In en, this message translates to:
  /// **'Settled up'**
  String get balancesNetSettled;

  /// No description provided for @balancesShowMore.
  ///
  /// In en, this message translates to:
  /// **'Show {count} more'**
  String balancesShowMore(int count);

  /// No description provided for @balancesShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get balancesShowLess;

  /// No description provided for @balancesShareSummary.
  ///
  /// In en, this message translates to:
  /// **'Share summary'**
  String get balancesShareSummary;

  /// No description provided for @balancesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get balancesEmptyTitle;

  /// No description provided for @balancesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a bill to see balances and who owes whom'**
  String get balancesEmptySubtitle;

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

  /// Segment: single payer for the bill.
  ///
  /// In en, this message translates to:
  /// **'One person'**
  String get paidByModeSingle;

  /// Segment: multiple people paid parts of the bill.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get paidByModeSplit;

  /// Shown when compact paid-by UI cannot cover multi-currency drafts.
  ///
  /// In en, this message translates to:
  /// **'This draft uses more than one currency. Use the full editor to enter who paid each currency.'**
  String get paidByMultiCurrencyHint;

  /// Split payments add up to the bill total.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get paidByBalanced;

  /// Difference between bill total and entered payments.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get paidByRemainingLabel;

  /// Opens the full who-paid sheet (all currencies).
  ///
  /// In en, this message translates to:
  /// **'Full editor'**
  String get paidByFullEditor;

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

  /// Snackbar after saving edits to an existing posted bill.
  ///
  /// In en, this message translates to:
  /// **'Bill updated.'**
  String get postBillSuccessUpdated;

  /// Bottom sheet title when updating a posted bill from the draft editor.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get postBillTitleEdit;

  /// Explains updating an existing posted bill.
  ///
  /// In en, this message translates to:
  /// **'This replaces the saved bill with your current lines, split, and payments.'**
  String get postBillSubtitleEdit;

  /// Primary button to commit edits to an existing posted bill.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get postBillActionSaveChanges;

  /// FAB on transaction detail to open the draft split editor with this bill loaded.
  ///
  /// In en, this message translates to:
  /// **'Edit bill'**
  String get editPostedBillAction;

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

  /// Error when Rust split output is missing or invalid at post time.
  ///
  /// In en, this message translates to:
  /// **'The split could not be saved. Check items, people, and tax/tip, then try again.'**
  String get postBillErrorSplitIncomplete;

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

  /// Subtitle under the SplitBae wordmark on the Bills dashboard.
  ///
  /// In en, this message translates to:
  /// **'Split bills with friends'**
  String get appTagline;

  /// Label on the teal hero card on the Bills tab.
  ///
  /// In en, this message translates to:
  /// **'Total expenses'**
  String get billsTotalExpenses;

  /// Sub-stat on the Bills hero card.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get billsThisWeek;

  /// Sub-stat on the Bills hero card (per bill).
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get billsAverage;

  /// Trend chip; value includes sign e.g. +100 or -12.
  ///
  /// In en, this message translates to:
  /// **'{value}% vs last week'**
  String billsInsightVsLastWeek(String value);

  /// Chip showing largest single bill amount.
  ///
  /// In en, this message translates to:
  /// **'Top: {amount}'**
  String billsInsightTop(String amount);

  /// Chip for consecutive days with activity.
  ///
  /// In en, this message translates to:
  /// **'{days} day streak'**
  String billsInsightStreak(int days);

  /// Chip with total bill count.
  ///
  /// In en, this message translates to:
  /// **'{count} bills'**
  String billsCountLabel(int count);

  /// Placeholder in the Bills search field.
  ///
  /// In en, this message translates to:
  /// **'Search bills, items…'**
  String get billsSearchHint;

  /// Placeholder in the shell search field when Balances tab is active (v0).
  ///
  /// In en, this message translates to:
  /// **'Search people…'**
  String get balancesSearchPeopleHint;

  /// No description provided for @v0UserMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get v0UserMenuTitle;

  /// No description provided for @v0UserMenuSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your preferences'**
  String get v0UserMenuSubtitle;

  /// No description provided for @v0UserMenuJourney.
  ///
  /// In en, this message translates to:
  /// **'Your journey'**
  String get v0UserMenuJourney;

  /// No description provided for @v0UserMenuMemberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since {monthYear}'**
  String v0UserMenuMemberSince(String monthYear);

  /// No description provided for @v0UserMenuMemberSinceNew.
  ///
  /// In en, this message translates to:
  /// **'Add your first bill to get started'**
  String get v0UserMenuMemberSinceNew;

  /// No description provided for @v0UserMenuStatBills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get v0UserMenuStatBills;

  /// No description provided for @v0UserMenuStatFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get v0UserMenuStatFriends;

  /// No description provided for @v0UserMenuOpenFullSettings.
  ///
  /// In en, this message translates to:
  /// **'Open full settings'**
  String get v0UserMenuOpenFullSettings;

  /// When search/filter returns nothing but bills exist.
  ///
  /// In en, this message translates to:
  /// **'No matching bills'**
  String get billsSearchEmpty;

  /// Placeholder when searching on Balances (reserved).
  ///
  /// In en, this message translates to:
  /// **'Search people…'**
  String get billsSearchPeopleHint;

  /// Empty state title on Bills feed.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get billsEmptyHeroTitle;

  /// Empty state subtitle on Bills feed.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add a bill and start splitting.'**
  String get billsEmptyHeroSubtitle;

  /// Title for Bills category/people filter sheet (v0 parity).
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get billsFiltersTitle;

  /// Section label in Bills filter sheet.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get billsFiltersCategorySection;

  /// Section label in Bills filter sheet.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get billsFiltersPeopleSection;

  /// Reset category and people filters on Bills.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get billsFiltersClearAll;

  /// Empty state when filters or search exclude all bills.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting filters or search.'**
  String get billsFiltersAdjustHint;

  /// Bills dashboard when the local database stream fails.
  ///
  /// In en, this message translates to:
  /// **'Could not load your bills.'**
  String get billsFeedLoadError;

  /// Retry loading the bills feed after an error.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get billsFeedRetry;

  /// FAB speed dial: open compose flow.
  ///
  /// In en, this message translates to:
  /// **'New Bill'**
  String get fabNewBill;

  /// FAB speed dial: scan receipt into a bill.
  ///
  /// In en, this message translates to:
  /// **'Scan Bill'**
  String get fabScanBill;

  /// FAB speed dial: jump to balances / settlements view.
  ///
  /// In en, this message translates to:
  /// **'Create Report'**
  String get fabCreateReport;

  /// Title for the full-screen add-transaction sheet from Bills.
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get addTransactionSheetTitle;

  /// Explains the flow before posting.
  ///
  /// In en, this message translates to:
  /// **'Receipt, people, items, tax — then post.'**
  String get addTransactionSheetSubtitle;

  /// Section label for bill title / memo.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get addTransactionDescriptionSection;

  /// Hint that description can be left blank; OCR may suggest a store name.
  ///
  /// In en, this message translates to:
  /// **'Auto-fills from receipt scan or first item if empty'**
  String get addTransactionDescriptionAutoHint;

  /// Prefix before apply-suggestion chip.
  ///
  /// In en, this message translates to:
  /// **'Suggested'**
  String get addTransactionSuggestedCategory;

  /// Apply suggested category chip.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get addTransactionApplySuggestion;

  /// Quick date chip for today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get addTransactionToday;

  /// Quick date chip for yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get addTransactionYesterday;

  /// Section label for date and time.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get addTransactionDateTimeSection;

  /// Section for participants on this bill.
  ///
  /// In en, this message translates to:
  /// **'Who\'s splitting?'**
  String get addTransactionWhosSplitting;

  /// Short hint under Who's splitting (v0 add-expense-sheet parity).
  ///
  /// In en, this message translates to:
  /// **'Search or tap a name; suggestions come from your posted bills.'**
  String get addTransactionEveryoneIncludedHint;

  /// People picker search field in add-transaction sheet.
  ///
  /// In en, this message translates to:
  /// **'Search or add person…'**
  String get addTransactionSearchPeopleHint;

  /// List tile to create a new person from search query.
  ///
  /// In en, this message translates to:
  /// **'Add \"{name}\"'**
  String addTransactionAddPersonNamed(String name);

  /// No description provided for @addTransactionFrequentPartners.
  ///
  /// In en, this message translates to:
  /// **'Frequent'**
  String get addTransactionFrequentPartners;

  /// No description provided for @addTransactionAlsoPartners.
  ///
  /// In en, this message translates to:
  /// **'Also'**
  String get addTransactionAlsoPartners;

  /// No description provided for @addTransactionLineSharedByAll.
  ///
  /// In en, this message translates to:
  /// **'Shared by all'**
  String get addTransactionLineSharedByAll;

  /// No description provided for @addTransactionLineAssignedToCount.
  ///
  /// In en, this message translates to:
  /// **'Assigned to {count}'**
  String addTransactionLineAssignedToCount(int count);

  /// People picker: no unselected participants left.
  ///
  /// In en, this message translates to:
  /// **'Everyone is already on this bill.'**
  String get addTransactionAllPeopleAdded;

  /// Section header for line items with count.
  ///
  /// In en, this message translates to:
  /// **'Items ({count})'**
  String addTransactionItemsSection(int count);

  /// Adds a receipt line to the draft.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addTransactionAddLineItem;

  /// Helper under tax field (v0 parity).
  ///
  /// In en, this message translates to:
  /// **'Split proportionally among participants'**
  String get addTransactionTaxSplitHint;

  /// Summary row before tax.
  ///
  /// In en, this message translates to:
  /// **'Subtotal ({count} items)'**
  String addTransactionSubtotalLine(int count);

  /// Tax row in totals card.
  ///
  /// In en, this message translates to:
  /// **'Tax & service'**
  String get addTransactionTaxSummaryLine;

  /// Final total label.
  ///
  /// In en, this message translates to:
  /// **'Grand total'**
  String get addTransactionGrandTotal;

  /// Opens draft payment sheet.
  ///
  /// In en, this message translates to:
  /// **'Who paid'**
  String get addTransactionWhoPaidShortcut;

  /// Bill category: entertainment (v0 Fun).
  ///
  /// In en, this message translates to:
  /// **'Fun'**
  String get categoryEntertainment;

  /// Bill category: shopping.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get categoryShopping;

  /// Bill category: utilities / subscriptions.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get categoryUtilities;

  /// Bill category: peer settlement.
  ///
  /// In en, this message translates to:
  /// **'Settlement'**
  String get categorySettlement;

  /// Label for bill category selector.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get addTransactionCategoryLabel;

  /// Bill category: food and dining.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get categoryFood;

  /// Bill category: transport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get categoryTransport;

  /// Bill category: lodging.
  ///
  /// In en, this message translates to:
  /// **'Accommodation'**
  String get categoryAccommodation;

  /// Bill category: uncategorized.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// Label for bill date picker.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get addTransactionDateLabel;

  /// Optional tax and service charge in the bill currency.
  ///
  /// In en, this message translates to:
  /// **'Tax & service'**
  String get addTransactionTaxLabel;

  /// Optional receipt image attachment.
  ///
  /// In en, this message translates to:
  /// **'Receipt photo'**
  String get addTransactionReceiptLabel;

  /// Button to pick a receipt image.
  ///
  /// In en, this message translates to:
  /// **'Attach photo'**
  String get addTransactionReceiptPick;

  /// Clear selected receipt image.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get addTransactionReceiptRemove;

  /// Summary of current draft line items and participants.
  ///
  /// In en, this message translates to:
  /// **'{itemCount} items · {peopleCount} people'**
  String addTransactionDraftSummary(int itemCount, int peopleCount);

  /// Opens the draft split workspace to edit lines and payments.
  ///
  /// In en, this message translates to:
  /// **'Line items & split'**
  String get addTransactionOpenDraft;

  /// Primary action to post the draft bill with entered metadata.
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get addTransactionPostAction;

  /// Share bill summary action on a posted bill card.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get billCardShare;

  /// Open full transaction detail from a bill card.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get billCardEdit;

  /// Delete a posted bill from history.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get billCardDelete;

  /// Copy a posted bill into the in-progress draft for editing.
  ///
  /// In en, this message translates to:
  /// **'Adjust in draft'**
  String get billCardAdjustDraft;

  /// Title when copying a posted bill would overwrite the current draft.
  ///
  /// In en, this message translates to:
  /// **'Replace in-progress bill?'**
  String get draftReplaceFromPostedTitle;

  /// Body for replace-draft confirmation.
  ///
  /// In en, this message translates to:
  /// **'Your current draft will be replaced with a copy of this bill.'**
  String get draftReplaceFromPostedBody;

  /// Confirm replacing the draft with a copy of a posted bill.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get draftReplaceFromPostedAction;

  /// Shown when copying a posted bill to the draft fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t copy this bill into draft.'**
  String get billCopyToDraftFailed;

  /// Title for delete confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete this bill?'**
  String get billDeleteConfirmTitle;

  /// Body for delete confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'This removes the bill and its lines from this device.'**
  String get billDeleteConfirmBody;

  /// Accessibility hint when bill row can be dismissed.
  ///
  /// In en, this message translates to:
  /// **'Swipe left to delete'**
  String get billSwipeDeleteHint;

  /// Screen reader label for a draft receipt line (item + formatted amount).
  ///
  /// In en, this message translates to:
  /// **'{itemName}, {formattedAmount}'**
  String semanticsDraftBillLine(String itemName, String formattedAmount);

  /// Accessibility hint for draft line row (opens editor).
  ///
  /// In en, this message translates to:
  /// **'Double tap to edit.'**
  String get semanticsDraftLineHint;

  /// Screen reader label for per-person split owed row.
  ///
  /// In en, this message translates to:
  /// **'{personName}, {formattedAmount}'**
  String semanticsSplitPersonRow(String personName, String formattedAmount);

  /// Screen reader label for suggested settlement edge row.
  ///
  /// In en, this message translates to:
  /// **'{fromName} pays {toName}, {formattedAmount}'**
  String semanticsSettlementEdge(
    String fromName,
    String toName,
    String formattedAmount,
  );

  /// Screen reader label for a recorded settlement transfer row.
  ///
  /// In en, this message translates to:
  /// **'{fromName} to {toName}, {formattedAmount}'**
  String semanticsRecordedSettlement(
    String fromName,
    String toName,
    String formattedAmount,
  );

  /// Placeholder row title on shell-only Bills preview (no business data).
  ///
  /// In en, this message translates to:
  /// **'Sample bill'**
  String get shellPlaceholderTransactionRow;

  /// Subtitle on shell placeholder cards.
  ///
  /// In en, this message translates to:
  /// **'UI shell — connect data later'**
  String get shellPlaceholderSubtitle;

  /// Insight chip on shell Bills placeholder.
  ///
  /// In en, this message translates to:
  /// **'0 bills'**
  String get shellPlaceholderChipBills;

  /// Second insight chip label on shell Bills placeholder.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get shellPlaceholderChipTrend;

  /// Subtitle on shell Balances placeholder.
  ///
  /// In en, this message translates to:
  /// **'Settlement preview — shell only'**
  String get shellPlaceholderBalancesSubtitle;

  /// Fake person name on shell Balances placeholder.
  ///
  /// In en, this message translates to:
  /// **'Alex'**
  String get shellPlaceholderPerson;

  /// Fake balance line on shell Balances placeholder.
  ///
  /// In en, this message translates to:
  /// **'Balance —'**
  String get shellPlaceholderBalance;

  /// First settings row on shell Settings placeholder.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get shellPlaceholderSettingsRow;
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
