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
  String get navHomeLabel => 'Beranda';

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
  String get scanReceiptButton => 'Pindai struk';

  @override
  String get scanReceiptCamera => 'Ambil foto';

  @override
  String get scanReceiptGallery => 'Pilih dari galeri';

  @override
  String get scanReceiptEnterManually => 'Isi manual';

  @override
  String get scanReceiptEnterManuallySubtitle =>
      'Pakai kolom nama dan jumlah di bawah';

  @override
  String get scanReceiptTimeout =>
      'Pindaian terlalu lama. Coba foto lain atau isi item manual di bawah.';

  @override
  String get scanReceiptDegradedBody =>
      'Pengenalan teks di perangkat tidak bisa dipastikan. Anda tetap bisa coba pindai, atau ketik nama item dan jumlah di bawah.';

  @override
  String get scanReceiptPickLine => 'Pilih baris yang dipakai';

  @override
  String get scanReceiptNoLines =>
      'Tidak ada baris dengan nominal. Coba foto lebih jelas atau isi manual.';

  @override
  String get scanReceiptUnavailable =>
      'Pindaian struk hanya di aplikasi Android dan iOS.';

  @override
  String get scanReceiptErrorGeneric => 'Tidak bisa membaca teks dari gambar.';

  @override
  String scanReceiptErrorDetail(String message) {
    return 'Tidak bisa membaca struk: $message';
  }

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
  String get splitSubtitle =>
      'Total mengikuti siapa yang ditugaskan ke tiap baris; per orang, per mata uang (tanpa konversi kurs).';

  @override
  String get itemAssigneesLabel => 'Bagi dengan';

  @override
  String get itemAssigneesNeedPeople =>
      'Tambah orang dulu untuk membagi bagian.';

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
  String get settingsBackupManualTitle => 'Cadangan manual';

  @override
  String get settingsBackupEntrySubtitle =>
      'Ekspor atau pulihkan file .sb_backup di perangkat ini.';

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

  @override
  String get addPersonSheetTitle => 'Tambah orang ke pembagian';

  @override
  String get addPersonNameHint => 'mis. Adistianto';

  @override
  String get participantNameRequired => 'Isi nama dulu.';

  @override
  String get emptyParticipantsHint =>
      'Tambah orang untuk melihat pembagian tagihan.';

  @override
  String get emptyBillHint => 'Belum ada item. Tambah baris struk untuk mulai.';

  @override
  String get balancesTitle => 'Saldo';

  @override
  String get balancesTooltip => 'Saldo dan pelunasan';

  @override
  String get suggestedSettlementsTitle => 'Transfer yang disarankan';

  @override
  String get recordedSettlementsTitle => 'Transfer tercatat';

  @override
  String get allSettledUp => 'Semua sudah selesai untuk buku besar ini.';

  @override
  String get recordSettlementAction => 'Catat';

  @override
  String get recordSettlementConfirmTitle => 'Catat transfer ini?';

  @override
  String recordSettlementConfirmBody(
    String fromName,
    String toName,
    String amount,
  ) {
    return '$fromName membayar $toName $amount.';
  }

  @override
  String get settlementPayerModelHint =>
      'Siapa membayar disimpan per mata uang pada draf tagihan. Gunakan Siapa bayar di layar utama untuk mengubah; total harus sama dengan baris struk.';

  @override
  String get whoPaidTooltip => 'Siapa bayar';

  @override
  String get whoPaidTitle => 'Siapa bayar';

  @override
  String get whoPaidSubtitle =>
      'Jumlah harus berjumlah sama dengan total tiap mata uang (sama dengan struk).';

  @override
  String get whoPaidSave => 'Simpan';

  @override
  String get whoPaidReset => 'Orang pertama bayar semua';

  @override
  String get whoPaidEmptyBill =>
      'Tambah baris struk dulu, lalu bagi siapa yang bayar.';

  @override
  String get whoPaidBillTotalLabel => 'Total tagihan';

  @override
  String get postBillTitle => 'Posting tagihan';

  @override
  String get postBillSubtitle =>
      'Baris dan pembayaran saat ini disimpan ke riwayat. Setelah itu Anda bisa mulai tagihan baru.';

  @override
  String get postBillDescriptionLabel => 'Judul (opsional)';

  @override
  String get postBillDescriptionHint => 'mis. Makan tim';

  @override
  String get postBillAction => 'Posting';

  @override
  String get postBillSuccess => 'Tagihan tersimpan.';

  @override
  String get postBillErrorEmpty => 'Tambah minimal satu baris sebelum posting.';

  @override
  String get postBillErrorNoParticipants =>
      'Tambah orang dulu sebelum posting.';

  @override
  String get postedBillsTitle => 'Tagihan terbaru';

  @override
  String get postBillUntitled => 'Tanpa judul';

  @override
  String get navBillsTab => 'Tagihan';

  @override
  String get navSplitTab => 'Bagi';

  @override
  String get navSplitTitle => 'Bagi tagihan';

  @override
  String get billsScreenTitle => 'Tagihan';

  @override
  String get billsEmptyState =>
      'Belum ada tagihan. Tambah baris di Bagi, lalu posting.';

  @override
  String get transactionDetailTabItems => 'Item';

  @override
  String get transactionDetailTabPersons => 'Orang';

  @override
  String get transactionDetailTabPayments => 'Bayar';

  @override
  String get transactionDetailMissing => 'Tagihan ini tidak bisa dimuat.';

  @override
  String get transactionDetailNoPayments =>
      'Tidak ada pembayaran tercatat untuk tagihan ini.';

  @override
  String get transactionDetailNoShares =>
      'Tidak ada pembagian untuk baris ini.';

  @override
  String get transactionDetailPersonsEmpty =>
      'Tidak ada yang harus dibayar pada tagihan ini.';

  @override
  String get settleUpSectionTitle => 'Lunasi';

  @override
  String get settlementPayerPays => 'Membayar';

  @override
  String get settlementPayeeReceives => 'Menerima';

  @override
  String get markAsPaid => 'Tandai lunas';

  @override
  String get settleUpAmountLabel => 'Jumlah';

  @override
  String get settleUpPayFull => 'Bayar penuh';

  @override
  String get settleUpPartialPayment => 'Bayar sebagian';

  @override
  String get settleUpUseFullAmount => 'Pakai jumlah penuh';

  @override
  String settleUpAmountOfTotal(String amount) {
    return 'dari $amount';
  }

  @override
  String get settleUpPayPartial => 'Bayar sebagian';

  @override
  String get settleUpPartialHint => 'Jumlah yang dicatat';

  @override
  String get settleUpPartialInvalid =>
      'Masukkan jumlah lebih dari nol dan tidak melebihi yang terutang.';
}
