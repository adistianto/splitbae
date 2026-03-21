/// Stable id for the seeded default ledger (schema v1).
const String kDefaultLedgerId = '00000000-0000-4000-8000-000000000001';

/// One **draft** transaction per ledger holds in-progress lines until the bill is
/// posted to history (v0-style workflow). Id is deterministic so migrations and
/// tests stay stable.
String draftTransactionIdForLedger(String ledgerId) => 'draft_tx_$ledgerId';
