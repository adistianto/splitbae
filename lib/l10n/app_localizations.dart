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
  /// **'Per person, grouped by currency (no FX conversion).'**
  String get splitSubtitle;

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
