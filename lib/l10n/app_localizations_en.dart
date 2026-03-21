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
      'Per person, grouped by currency (no FX conversion).';

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
      'To apply this, your local bill data will be erased and replaced with a fresh empty database. This cannot be undone.';

  @override
  String get settingsEncryptChangeConfirm => 'Erase and continue';

  @override
  String get settingsEncryptChangeError =>
      'Could not update the database. Try again or restart the app.';
}
