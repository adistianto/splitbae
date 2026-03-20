/// ISO 4217 codes supported for line items (extend as needed).
const List<String> kSupportedCurrencyCodes = [
  'IDR',
  'USD',
  'EUR',
  'GBP',
  'SGD',
  'MYR',
  'THB',
  'JPY',
  'AUD',
  'CNY',
];

String currencyMenuLabel(String code) {
  switch (code) {
    case 'IDR':
      return 'IDR — Indonesian Rupiah';
    case 'USD':
      return 'USD — US Dollar';
    case 'EUR':
      return 'EUR — Euro';
    case 'GBP':
      return 'GBP — British Pound';
    case 'SGD':
      return 'SGD — Singapore Dollar';
    case 'MYR':
      return 'MYR — Malaysian Ringgit';
    case 'THB':
      return 'THB — Thai Baht';
    case 'JPY':
      return 'JPY — Japanese Yen';
    case 'AUD':
      return 'AUD — Australian Dollar';
    case 'CNY':
      return 'CNY — Chinese Yuan';
    default:
      return code;
  }
}
