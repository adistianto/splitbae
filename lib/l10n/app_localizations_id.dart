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
  String get perPersonTitle => 'Per orang';

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
      'Buku besar, orang, dan baris item akan disalin ke basis data terenkripsi atau biasa yang baru di perangkat ini. Tidak ada unggahan. Jika terjadi masalah, data Anda dikembalikan dan pengaturan enkripsi tetap seperti semula.';

  @override
  String get settingsEncryptChangeConfirm => 'Lanjutkan';

  @override
  String get settingsEncryptMigrationRolledBack =>
      'Enkripsi tidak bisa diubah; data Anda tidak berubah.';

  @override
  String get settingsEncryptChangeError =>
      'Basis data tidak bisa diperbarui. Coba lagi atau mulai ulang aplikasi.';

  @override
  String get settingsBackup => 'Cadangan';

  @override
  String get settingsBackupExport => 'Ekspor file cadangan';

  @override
  String get settingsBackupExportSubtitle =>
      'JSON biasa (.sb_backup). Siapa pun yang punya file bisa membaca nama dan nominal—simpan atau kirim hanya ke tempat yang Anda percaya.';

  @override
  String get settingsBackupImport => 'Impor file cadangan';

  @override
  String get settingsBackupImportSubtitle =>
      'Mengganti semua buku besar, orang, dan baris item di perangkat ini.';

  @override
  String get backupImportConfirmTitle => 'Ganti semua data lokal?';

  @override
  String get backupImportConfirmBody =>
      'Data tagihan saat ini akan dihapus dan diganti cadangan. Tidak bisa dibatalkan.';

  @override
  String get backupImportConfirmAction => 'Ganti dan impor';

  @override
  String get backupExportSuccess => 'File cadangan siap.';

  @override
  String get backupImportSuccess => 'Cadangan dipulihkan.';

  @override
  String get backupErrorInvalid =>
      'File itu bukan cadangan SplitBae yang valid.';

  @override
  String get backupErrorExport => 'Tidak bisa membuat file cadangan.';

  @override
  String get editItemTitle => 'Edit item';

  @override
  String get billItemsTitle => 'Item tagihan';

  @override
  String get deleteItemTitle => 'Hapus item?';

  @override
  String get deleteItemBody => 'Baris ini akan dihapus dari tagihan.';

  @override
  String get deleteAction => 'Hapus';

  @override
  String get peopleTooltip => 'Orang';

  @override
  String get managePeopleTitle => 'Orang dalam pembagian ini';

  @override
  String get renameParticipantAction => 'Ganti nama';

  @override
  String get renameParticipantTitle => 'Ganti nama';

  @override
  String get participantDisplayNameLabel => 'Nama';

  @override
  String get removeParticipantTitle => 'Hapus orang?';

  @override
  String removeParticipantBody(String name) {
    return 'Hapus $name dari pembagian ini?';
  }
}
