// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'SplitBae';

  @override
  String get addItemTooltip => 'Tambah item';

  @override
  String get addPerson => 'Tambah orang';

  @override
  String get settings => 'Pengaturan';

  @override
  String get settingsLanguage => 'Bahasa';

  @override
  String get settingsLanguageSubtitle =>
      'Mengikuti bahasa perangkat sampai Anda memilih di sini.';

  @override
  String get languageDevice => 'Ikuti bahasa perangkat';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageIndonesian => 'Bahasa Indonesia';

  @override
  String get settingsDefaultCurrency => 'Mata uang default untuk item baru';

  @override
  String get settingsDefaultCurrencySubtitle =>
      'Anda tetap bisa pilih mata uang lain per item.';

  @override
  String get addItemTitle => 'Tambah item';

  @override
  String get addItemSubtitle =>
      'Nominal memakai mata uang yang Anda pilih di bawah.';

  @override
  String get itemNameLabel => 'Nama item';

  @override
  String get itemNameHint => 'mis. Nasi goreng';

  @override
  String get priceLabel => 'Jumlah';

  @override
  String get priceHint => '15000';

  @override
  String get currencyLabel => 'Mata uang';

  @override
  String get cancel => 'Batal';

  @override
  String get save => 'Simpan';

  @override
  String get errorNameRequired => 'Nama item wajib diisi.';

  @override
  String get errorPriceRequired => 'Jumlah wajib diisi.';

  @override
  String get errorPriceInvalid => 'Masukkan nominal yang valid (positif).';

  @override
  String get splitSubtitle => 'Per orang, per mata uang (tanpa konversi kurs).';

  @override
  String get settingsDataPrivacy => 'Data & privasi';

  @override
  String get settingsEncryptDatabase => 'Enkripsi basis data lokal';

  @override
  String get settingsEncryptDatabaseSubtitle =>
      'Sangat disarankan jika ponsel bisa hilang atau dicuri—melindungi nama dan nominal saat disimpan. Default: mati.';

  @override
  String get settingsEncryptChangeTitle => 'Ubah enkripsi basis data?';

  @override
  String get settingsEncryptChangeBody =>
      'Untuk menerapkan ini, data tagihan lokal akan dihapus dan diganti basis data baru yang kosong. Tidak bisa dibatalkan.';

  @override
  String get settingsEncryptChangeConfirm => 'Hapus dan lanjutkan';

  @override
  String get settingsEncryptChangeError =>
      'Basis data tidak bisa diperbarui. Coba lagi atau mulai ulang aplikasi.';
}
