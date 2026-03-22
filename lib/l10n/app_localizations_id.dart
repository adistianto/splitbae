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
  String get settingsV0ManagePreferences => 'Kelola preferensi Anda';

  @override
  String get settingsV0ActivityTitle => 'Aktivitas Anda';

  @override
  String get settingsV0TotalSpent => 'Total belanja';

  @override
  String get settingsV0ThisMonth => 'Bulan ini';

  @override
  String get settingsV0StatTransactions => 'Transaksi';

  @override
  String get settingsV0StatFriends => 'Teman';

  @override
  String get settingsV0StatAvgPerTxn => 'Rata/transaksi';

  @override
  String get settingsV0TopCategories => 'Kategori teratas';

  @override
  String get settingsV0TopPartner => 'Partner paling sering';

  @override
  String settingsV0PartnerTxCount(int count) {
    return '$count tagihan bersama';
  }

  @override
  String get settingsLanguage => 'Bahasa';

  @override
  String get settingsLanguageSubtitle =>
      'Mengikuti bahasa perangkat sampai Anda memilih di sini.';

  @override
  String get settingsAppearance => 'Tampilan';

  @override
  String get settingsAppearanceSubtitle =>
      'Terang, Gelap, atau ikuti perangkat (Default sistem di Android; Otomatis di iPhone dan Mac).';

  @override
  String get settingsThemeFollowDeviceMaterial => 'Default sistem';

  @override
  String get settingsThemeFollowDeviceMaterialShort => 'Sistem';

  @override
  String get settingsThemeFollowDeviceApple => 'Otomatis';

  @override
  String get settingsThemeLight => 'Terang';

  @override
  String get settingsThemeDark => 'Gelap';

  @override
  String get settingsMaterialYou => 'Warna dinamis Material You';

  @override
  String get settingsMaterialYouSubtitle =>
      'Memakai palet wallpaper untuk tema aplikasi di perangkat yang mendukung. Default mati; aktifkan untuk Material You, atau biarkan mati untuk tampilan teal default SplitBae.';

  @override
  String get languageDevice => 'Ikuti bahasa perangkat';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageIndonesian => 'Bahasa Indonesia';

  @override
  String get settingsDefaultCurrency => 'Mata uang default untuk tagihan baru';

  @override
  String get settingsDefaultCurrencySubtitle =>
      'Dipakai saat memulai tagihan baru tanpa baris.';

  @override
  String get settingsDefaultCurrencyRecordingNote =>
      'Transaksi yang sudah diposting tetap memakai mata uang saat disimpan. Mengubah ini hanya memengaruhi baris baru dan draf kosong.';

  @override
  String get addItemTitle => 'Tambah item';

  @override
  String get addItemSubtitle =>
      'Nominal memakai mata uang tagihan ini (default saat draf kosong; ubah default di Pengaturan).';

  @override
  String get billCurrencyLabel => 'Mata uang tagihan';

  @override
  String get scanReceiptButton => 'Pindai struk';

  @override
  String get scanReceiptScreenTitle => 'Pindai struk';

  @override
  String get scanReceiptScreenSubtitle =>
      'Ambil gambar untuk menambah pengeluaran dengan cepat';

  @override
  String get scanReceiptHeroQuickAdd => 'Tambah cepat';

  @override
  String get scanReceiptHeroPointCamera => 'Arahkan kamera ke struk';

  @override
  String scanReceiptHeroItemsDetected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count item terdeteksi',
      one: '1 item terdeteksi',
    );
    return '$_temp0';
  }

  @override
  String get scanReceiptTakePhotoSubtitle => 'Foto struk Anda';

  @override
  String get scanReceiptExtractingTitle => 'Mengekstrak item…';

  @override
  String get scanReceiptExtractingSubtitle => 'Ini bisa memakan waktu sebentar';

  @override
  String get scanReceiptContinueToSplit => 'Lanjut ke bagi tagihan';

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
  String get scanReceiptPermissionCameraDenied =>
      'Akses kamera diperlukan untuk memotret struk.';

  @override
  String get scanReceiptPermissionPhotosDenied =>
      'Akses galeri diperlukan untuk memilih gambar struk.';

  @override
  String get scanReceiptPermissionCameraBlockedTitle =>
      'Akses kamera dimatikan';

  @override
  String get scanReceiptPermissionCameraBlockedBody =>
      'Izinkan SplitBae menggunakan kamera di Pengaturan agar Anda bisa memindai struk.';

  @override
  String get scanReceiptPermissionPhotosBlockedTitle => 'Akses foto dimatikan';

  @override
  String get scanReceiptPermissionPhotosBlockedBody =>
      'Izinkan SplitBae mengakses galeri di Pengaturan agar Anda bisa memilih gambar struk.';

  @override
  String get scanReceiptPermissionOpenSettings => 'Buka Pengaturan';

  @override
  String get scanReceiptTimeout =>
      'Pindaian terlalu lama. Coba foto lain atau isi item manual di bawah.';

  @override
  String get scanReceiptDegradedBody =>
      'Pengenalan teks di perangkat tidak bisa dipastikan. Anda tetap bisa coba pindai, atau ketik nama item dan jumlah di bawah.';

  @override
  String get scanReceiptPickLine => 'Pilih baris yang dipakai';

  @override
  String scanReceiptLineQtyUnitPrice(int quantity, String unitPrice) {
    return '×$quantity · $unitPrice per item';
  }

  @override
  String scanReceiptOcrLineDetail(
    int quantity,
    String unitPrice,
    String lineTotal,
  ) {
    return 'Qty $quantity · $unitPrice per item · baris $lineTotal';
  }

  @override
  String scanReceiptAddAllLines(int count) {
    return 'Tambah semua $count baris';
  }

  @override
  String scanReceiptBatchAdded(int count) {
    return 'Menambahkan $count baris dari struk.';
  }

  @override
  String get scanReceiptNoLines =>
      'Tidak ada baris dengan nominal. Coba foto lebih jelas atau isi manual.';

  @override
  String get scanReceiptUnavailable =>
      'Pindaian struk membutuhkan OCR di perangkat (Android, iOS, macOS, atau Windows di aplikasi ini).';

  @override
  String get scanReceiptChooseImageFile => 'Pilih file gambar';

  @override
  String get scanReceiptNonMobileScanHint =>
      'OCR di perangkat tidak tersedia di web atau Linux dalam build ini. Anda tetap bisa memilih foto atau mengisi manual.';

  @override
  String get scanReceiptNoNativeOcr =>
      'OCR struk di perangkat tidak tersedia di platform ini. Isi baris secara manual.';

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
  String get itemQuantityLabel => 'Jml';

  @override
  String get itemQuantityHint => '1';

  @override
  String get errorQuantityInvalid => 'Gunakan bilangan bulat minimal 1.';

  @override
  String get draftBillLineQtyColumn => 'Jml';

  @override
  String get draftBillLineUnitColumn => 'Satuan';

  @override
  String get draftBillLineLineTotalColumn => 'Baris';

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
  String get draftSplitPinnedSummaryTitle => 'Jumlah terutang';

  @override
  String get draftSplitTaxFieldLabel => 'Pajak';

  @override
  String get draftSplitTipFieldLabel => 'Tip';

  @override
  String get draftSplitCalculateError => 'Tidak bisa memperbarui pembagian.';

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
  String get balancesScreenSubtitle => 'Lihat siapa berhutang kepada siapa';

  @override
  String get balancesHeroToSettle => 'Yang harus dilunasi';

  @override
  String get balancesHeroStatus => 'Status';

  @override
  String get balancesHeroAllSettledTitle => 'Semua lunas!';

  @override
  String get balancesHeroEveryoneEven =>
      'Semua sudah impas — tidak perlu transfer';

  @override
  String balancesHeroPaymentsNeeded(int count) {
    return '$count pembayaran diperlukan';
  }

  @override
  String get balancesTotalSpentLabel => 'Total pengeluaran';

  @override
  String get balancesAvgPerPersonLabel => 'Rata-rata / orang';

  @override
  String get balancesSectionIndividual => 'Saldo per orang';

  @override
  String get balancesInsightOwesMost => 'Paling banyak berhutang';

  @override
  String get balancesInsightOwedMost => 'Paling banyak ditagih';

  @override
  String get balancesNetGetsBack => 'Menerima kembali';

  @override
  String get balancesNetOwes => 'Berhutang';

  @override
  String get balancesNetSettled => 'Sudah impas';

  @override
  String balancesShowMore(int count) {
    return 'Tampilkan $count lagi';
  }

  @override
  String get balancesShowLess => 'Lebih sedikit';

  @override
  String get balancesShareSummary => 'Bagikan ringkasan';

  @override
  String get balancesEmptyTitle => 'Belum ada transaksi';

  @override
  String get balancesEmptySubtitle =>
      'Tambah tagihan untuk melihat saldo dan siapa berhutang';

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
  String get paidByModeSingle => 'Satu orang';

  @override
  String get paidByModeSplit => 'Bagi';

  @override
  String get paidByMultiCurrencyHint =>
      'Draf ini memakai lebih dari satu mata uang. Pakai editor lengkap untuk siapa bayar tiap mata uang.';

  @override
  String get paidByBalanced => 'Pas';

  @override
  String get paidByRemainingLabel => 'Sisa';

  @override
  String get paidByFullEditor => 'Editor lengkap';

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

  @override
  String get appTagline => 'Bagi tagihan bareng teman';

  @override
  String get billsTotalExpenses => 'Total pengeluaran';

  @override
  String get billsThisWeek => 'Minggu ini';

  @override
  String get billsAverage => 'Rata-rata';

  @override
  String billsInsightVsLastWeek(String value) {
    return '$value% vs minggu lalu';
  }

  @override
  String billsInsightTop(String amount) {
    return 'Tertinggi: $amount';
  }

  @override
  String billsInsightStreak(int days) {
    return 'Streak $days hari';
  }

  @override
  String billsCountLabel(int count) {
    return '$count tagihan';
  }

  @override
  String get billsSearchHint => 'Cari tagihan, item…';

  @override
  String get balancesSearchPeopleHint => 'Cari orang…';

  @override
  String get v0UserMenuTitle => 'Pengaturan';

  @override
  String get v0UserMenuSubtitle => 'Kelola preferensi Anda';

  @override
  String get v0UserMenuJourney => 'Perjalanan Anda';

  @override
  String v0UserMenuMemberSince(String monthYear) {
    return 'Anggota sejak $monthYear';
  }

  @override
  String get v0UserMenuMemberSinceNew => 'Tambah tagihan pertama untuk memulai';

  @override
  String get v0UserMenuStatBills => 'Tagihan';

  @override
  String get v0UserMenuStatFriends => 'Teman';

  @override
  String get v0UserMenuOpenFullSettings => 'Buka pengaturan lengkap';

  @override
  String get billsSearchEmpty => 'Tidak ada tagihan yang cocok';

  @override
  String get billsSearchPeopleHint => 'Cari orang…';

  @override
  String get billsEmptyHeroTitle => 'Belum ada transaksi';

  @override
  String get billsEmptyHeroSubtitle => 'Ketuk + untuk menambah tagihan.';

  @override
  String get billsFiltersTitle => 'Filter';

  @override
  String get billsFiltersCategorySection => 'Kategori';

  @override
  String get billsFiltersPeopleSection => 'Orang';

  @override
  String get billsFiltersClearAll => 'Hapus semua';

  @override
  String get billsFiltersAdjustHint => 'Coba ubah filter atau pencarian.';

  @override
  String get fabNewBill => 'Tagihan baru';

  @override
  String get fabScanBill => 'Pindai struk';

  @override
  String get fabCreateReport => 'Buat laporan';

  @override
  String get addTransactionSheetTitle => 'Tambah transaksi';

  @override
  String get addTransactionSheetSubtitle =>
      'Struk, orang, item, pajak — lalu posting.';

  @override
  String get addTransactionDescriptionSection => 'Deskripsi';

  @override
  String get addTransactionDescriptionAutoHint =>
      'Otomatis dari item pertama jika kosong';

  @override
  String get addTransactionSuggestedCategory => 'Saran';

  @override
  String get addTransactionApplySuggestion => 'Terapkan';

  @override
  String get addTransactionToday => 'Hari ini';

  @override
  String get addTransactionYesterday => 'Kemarin';

  @override
  String get addTransactionDateTimeSection => 'Tanggal';

  @override
  String get addTransactionWhosSplitting => 'Siapa yang patungan?';

  @override
  String get addTransactionEveryoneIncludedHint =>
      'Cari atau ketuk nama; saran dari tagihan yang diposting.';

  @override
  String get addTransactionSearchPeopleHint => 'Cari atau tambah orang…';

  @override
  String addTransactionAddPersonNamed(String name) {
    return 'Tambah \"$name\"';
  }

  @override
  String get addTransactionFrequentPartners => 'Sering';

  @override
  String get addTransactionAlsoPartners => 'Juga';

  @override
  String get addTransactionLineSharedByAll => 'Dibagi semua';

  @override
  String addTransactionLineAssignedToCount(int count) {
    return 'Ditugaskan ke $count';
  }

  @override
  String get addTransactionAllPeopleAdded =>
      'Semua orang sudah ada di tagihan ini.';

  @override
  String addTransactionItemsSection(int count) {
    return 'Item ($count)';
  }

  @override
  String get addTransactionAddLineItem => 'Tambah item';

  @override
  String get addTransactionTaxSplitHint => 'Dibagi proporsional ke peserta';

  @override
  String addTransactionSubtotalLine(int count) {
    return 'Subtotal ($count item)';
  }

  @override
  String get addTransactionTaxSummaryLine => 'Pajak & layanan';

  @override
  String get addTransactionGrandTotal => 'Total';

  @override
  String get addTransactionWhoPaidShortcut => 'Siapa yang bayar';

  @override
  String get categoryEntertainment => 'Hiburan';

  @override
  String get categoryShopping => 'Belanja';

  @override
  String get categoryUtilities => 'Tagihan';

  @override
  String get categorySettlement => 'Pelunasan';

  @override
  String get addTransactionCategoryLabel => 'Kategori';

  @override
  String get categoryFood => 'Makanan';

  @override
  String get categoryTransport => 'Transport';

  @override
  String get categoryAccommodation => 'Akomodasi';

  @override
  String get categoryOther => 'Lainnya';

  @override
  String get addTransactionDateLabel => 'Tanggal';

  @override
  String get addTransactionTaxLabel => 'Pajak & layanan';

  @override
  String get addTransactionReceiptLabel => 'Foto struk';

  @override
  String get addTransactionReceiptPick => 'Lampirkan foto';

  @override
  String get addTransactionReceiptRemove => 'Hapus';

  @override
  String addTransactionDraftSummary(int itemCount, int peopleCount) {
    return '$itemCount item · $peopleCount orang';
  }

  @override
  String get addTransactionOpenDraft => 'Baris & bagi';

  @override
  String get addTransactionPostAction => 'Tambah transaksi';

  @override
  String get billCardShare => 'Bagikan';

  @override
  String get billCardEdit => 'Detail';

  @override
  String get billCardDelete => 'Hapus';

  @override
  String get billCardAdjustDraft => 'Sesuaikan di draf';

  @override
  String get draftReplaceFromPostedTitle => 'Ganti draf yang sedang berjalan?';

  @override
  String get draftReplaceFromPostedBody =>
      'Draf saat ini akan diganti salinan tagihan ini.';

  @override
  String get draftReplaceFromPostedAction => 'Ganti';

  @override
  String get billCopyToDraftFailed => 'Tidak bisa menyalin tagihan ke draf.';

  @override
  String get billDeleteConfirmTitle => 'Hapus tagihan ini?';

  @override
  String get billDeleteConfirmBody =>
      'Tagihan dan barisnya akan dihapus di perangkat ini.';

  @override
  String get billSwipeDeleteHint => 'Geser kiri untuk hapus';

  @override
  String semanticsDraftBillLine(String itemName, String formattedAmount) {
    return '$itemName, $formattedAmount';
  }

  @override
  String get semanticsDraftLineHint => 'Ketuk dua kali untuk mengubah.';

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
    return '$fromName membayar $toName, $formattedAmount';
  }

  @override
  String semanticsRecordedSettlement(
    String fromName,
    String toName,
    String formattedAmount,
  ) {
    return '$fromName ke $toName, $formattedAmount';
  }

  @override
  String get shellPlaceholderTransactionRow => 'Contoh tagihan';

  @override
  String get shellPlaceholderSubtitle => 'Kerangka UI — data menyusul';

  @override
  String get shellPlaceholderChipBills => '0 tagihan';

  @override
  String get shellPlaceholderChipTrend => 'Tren';

  @override
  String get shellPlaceholderBalancesSubtitle =>
      'Pratinjau pelunasan — hanya kerangka';

  @override
  String get shellPlaceholderPerson => 'Alex';

  @override
  String get shellPlaceholderBalance => 'Saldo —';

  @override
  String get shellPlaceholderSettingsRow => 'Preferensi';
}
