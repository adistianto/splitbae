/// Thrown when stored draft payments do not match per-currency line totals.
class BillPaymentsMismatchException implements Exception {
  BillPaymentsMismatchException(this.message);

  final String message;

  @override
  String toString() => message;
}
