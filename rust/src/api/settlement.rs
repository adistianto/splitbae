//! Minimal multi-currency **debt netting**: turn per-participant net balances into a
//! small set of pairwise transfers that clear everyone.
//!
//! - **Accuracy**: All arithmetic in `i64` minor units; sums validated with `i128`.
//! - **Transfers count**: Greedy “largest remaining debtor → largest remaining creditor”
//!   uses at most `k − 1` transfers per currency for `k` non-zero parties (standard for
//!   single-currency settlement; same class of solution as Splitwise-style simplify).
//! - **Determinism**: When amounts tie, `(participant_id)` lexicographic order breaks ties.

use std::collections::HashMap;

#[flutter_rust_bridge::frb]
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct NetBalance {
    pub participant_id: String,
    /// Net **creditor** position: positive = should receive, negative = should pay.
    pub amount_minor: i64,
    pub currency_code: String,
}

#[flutter_rust_bridge::frb]
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct SettlementEdge {
    pub from_participant_id: String,
    pub to_participant_id: String,
    pub amount_minor: i64,
    pub currency_code: String,
}

/// Merge duplicate `(participant, currency)` rows, then run greedy netting per currency.
///
/// Returns `Err` if any currency bucket does not sum to zero (after merge).
#[flutter_rust_bridge::frb(sync)]
pub fn calculate_minimal_settlement_edges(
    balances: Vec<NetBalance>,
) -> Result<Vec<SettlementEdge>, String> {
    if balances.is_empty() {
        return Ok(Vec::new());
    }

    // (currency_upper, participant_id) -> net minor
    let mut merged: HashMap<(String, String), i64> = HashMap::new();
    for b in balances {
        let ccy = b.currency_code.trim().to_uppercase();
        if ccy.is_empty() {
            return Err("Empty currency_code in net balance".to_string());
        }
        let key = (ccy, b.participant_id);
        let slot = merged.entry(key).or_insert(0);
        *slot = slot
            .checked_add(b.amount_minor)
            .ok_or("amount_minor overflow when merging balances")?;
    }

    let mut by_currency: HashMap<String, HashMap<String, i64>> = HashMap::new();
    for ((ccy, pid), net) in merged {
        if net == 0 {
            continue;
        }
        by_currency.entry(ccy).or_default().insert(pid, net);
    }

    let mut out: Vec<SettlementEdge> = Vec::new();
    let mut currencies: Vec<String> = by_currency.keys().cloned().collect();
    currencies.sort();

    for ccy in currencies {
        let bucket = by_currency.get(&ccy).cloned().unwrap_or_default();
        let mut edges = settle_one_currency(&ccy, bucket)?;
        out.append(&mut edges);
    }

    Ok(out)
}

fn settle_one_currency(
    currency_code: &str,
    balances: HashMap<String, i64>,
) -> Result<Vec<SettlementEdge>, String> {
    let sum: i128 = balances.values().map(|&x| x as i128).sum();
    if sum != 0 {
        return Err(format!(
            "Net balances for {} do not sum to zero (sum_minor={})",
            currency_code, sum
        ));
    }

    let mut debtors: Vec<(String, i64)> = Vec::new();
    let mut creditors: Vec<(String, i64)> = Vec::new();

    for (id, net) in balances {
        if net < 0 {
            let owe = net.checked_neg().ok_or("debt amount overflow")?;
            if owe > 0 {
                debtors.push((id, owe));
            }
        } else if net > 0 {
            creditors.push((id, net));
        }
    }

    // Largest obligations first; tie-break by id for stable, deterministic output.
    debtors.sort_by(|a, b| b.1.cmp(&a.1).then_with(|| a.0.cmp(&b.0)));
    creditors.sort_by(|a, b| b.1.cmp(&a.1).then_with(|| a.0.cmp(&b.0)));

    let mut i = 0usize;
    let mut j = 0usize;
    let mut edges = Vec::new();

    while i < debtors.len() && j < creditors.len() {
        let take = debtors[i].1.min(creditors[j].1);
        if take > 0 {
            edges.push(SettlementEdge {
                from_participant_id: debtors[i].0.clone(),
                to_participant_id: creditors[j].0.clone(),
                amount_minor: take,
                currency_code: currency_code.to_string(),
            });
        }

        debtors[i].1 -= take;
        creditors[j].1 -= take;

        if debtors[i].1 == 0 {
            i += 1;
        }
        if creditors[j].1 == 0 {
            j += 1;
        }
    }

    debug_assert!(
        debtors.iter().all(|(_, a)| *a == 0) && creditors.iter().all(|(_, a)| *a == 0),
        "settlement greedy left non-zero remainder"
    );

    Ok(edges)
}

// --- Posted-bill obligation graph: proportional split per transaction, pairwise net ---

#[flutter_rust_bridge::frb]
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct SplitObligationRow {
    pub transaction_id: String,
    /// Participant who owes their share toward this bill (split obligation row).
    pub ower_id: String,
    pub amount_minor: i64,
    pub currency_code: String,
}

#[flutter_rust_bridge::frb]
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct SplitPaymentRow {
    pub transaction_id: String,
    /// Participant who paid toward this bill (may be multiple per currency).
    pub payer_id: String,
    pub amount_minor: i64,
    pub currency_code: String,
}

/// Build directed “debtor owes creditor” edges from posted split rows, apply recorded
/// peer settlements, then **bilateral** cancellation (A↔B) per currency.
///
/// All arithmetic uses `i64` minor units; proportional allocation uses integer floor with
/// remainder on the last payer (payers sorted by id) so sums stay exact.
///
/// Returns non-zero [`SettlementEdge`]s: `from` owes `to` `amount_minor` in `currency_code`.
#[flutter_rust_bridge::frb(sync)]
pub fn calculate_net_balances(
    obligations: Vec<SplitObligationRow>,
    payments: Vec<SplitPaymentRow>,
    recorded_settlements: Vec<SettlementEdge>,
) -> Result<Vec<SettlementEdge>, String> {
    #[derive(Clone, Debug, Eq, PartialEq, Hash)]
    struct BucketKey {
        tx: String,
        ccy: String,
    }

    let mut pay_map: HashMap<BucketKey, HashMap<String, i64>> = HashMap::new();
    for p in payments {
        let ccy = p.currency_code.trim().to_uppercase();
        if ccy.is_empty() {
            return Err("Empty currency_code in payment row".to_string());
        }
        if p.amount_minor < 0 {
            return Err("Negative payment amount_minor".to_string());
        }
        let key = BucketKey {
            tx: p.transaction_id,
            ccy,
        };
        let slot = pay_map.entry(key).or_default();
        let e = slot.entry(p.payer_id).or_insert(0);
        *e = e
            .checked_add(p.amount_minor)
            .ok_or("payment merge overflow")?;
    }

    // owed[debtor][creditor][ccy] = amount debtor owes creditor
    let mut owed: HashMap<(String, String, String), i64> = HashMap::new();

    for o in obligations {
        let ccy = o.currency_code.trim().to_uppercase();
        if ccy.is_empty() {
            return Err("Empty currency_code in obligation row".to_string());
        }
        if o.amount_minor < 0 {
            return Err("Negative obligation amount_minor".to_string());
        }
        let key = BucketKey {
            tx: o.transaction_id.clone(),
            ccy: ccy.clone(),
        };
        let payer_sums = pay_map.get(&key).cloned().ok_or_else(|| {
            format!(
                "No payments for transaction {} currency {}",
                o.transaction_id, ccy
            )
        })?;
        let mut payers: Vec<(String, i64)> = payer_sums.into_iter().collect();
        payers.sort_by(|a, b| a.0.cmp(&b.0));
        let total_p: i128 = payers.iter().map(|(_, a)| *a as i128).sum();
        if total_p == 0 {
            return Err(format!(
                "Zero total payments for transaction {} currency {}",
                o.transaction_id, ccy
            ));
        }
        let shares = allocate_minor_proportional(o.amount_minor, &payers)?;
        for (payer_id, share) in shares {
            if share == 0 {
                continue;
            }
            add_owed_edge(&mut owed, &o.ower_id, &payer_id, &ccy, share)?;
        }
    }

    for s in recorded_settlements {
        let ccy = s.currency_code.trim().to_uppercase();
        if ccy.is_empty() {
            return Err("Empty currency_code in settlement".to_string());
        }
        if s.amount_minor < 0 {
            return Err("Negative settlement amount_minor".to_string());
        }
        apply_settlement_payment(
            &mut owed,
            &s.from_participant_id,
            &s.to_participant_id,
            &ccy,
            s.amount_minor,
        )?;
    }

    pairwise_net_edges(&owed)
}

fn add_owed_edge(
    owed: &mut HashMap<(String, String, String), i64>,
    debtor: &str,
    creditor: &str,
    ccy: &str,
    amount: i64,
) -> Result<(), String> {
    if amount == 0 {
        return Ok(());
    }
    let key = (debtor.to_string(), creditor.to_string(), ccy.to_string());
    let slot = owed.entry(key).or_insert(0);
    *slot = slot
        .checked_add(amount)
        .ok_or("owed edge overflow")?;
    Ok(())
}

/// `from` paid `to` — reduces what `from` owes `to`; surplus becomes debt the other way.
fn apply_settlement_payment(
    owed: &mut HashMap<(String, String, String), i64>,
    from: &str,
    to: &str,
    ccy: &str,
    amount: i64,
) -> Result<(), String> {
    if amount == 0 {
        return Ok(());
    }
    let key_fwd = (from.to_string(), to.to_string(), ccy.to_string());
    let cur = *owed.get(&key_fwd).unwrap_or(&0);
    if cur >= amount {
        let new = cur - amount;
        if new == 0 {
            owed.remove(&key_fwd);
        } else {
            owed.insert(key_fwd, new);
        }
        return Ok(());
    }
    let remaining = amount - cur;
    if cur > 0 {
        owed.remove(&key_fwd);
    }
    let key_rev = (to.to_string(), from.to_string(), ccy.to_string());
    let rev = owed.entry(key_rev).or_insert(0);
    *rev = rev
        .checked_add(remaining)
        .ok_or("settlement reverse overflow")?;
    Ok(())
}

fn allocate_minor_proportional(
    amount: i64,
    payers: &[(String, i64)],
) -> Result<Vec<(String, i64)>, String> {
    if payers.is_empty() {
        return Err("allocate_minor_proportional: empty payers".to_string());
    }
    if amount == 0 {
        return Ok(payers
            .iter()
            .map(|(id, _)| (id.clone(), 0i64))
            .collect());
    }
    let total_w: i128 = payers.iter().map(|(_, w)| *w as i128).sum();
    if total_w == 0 {
        return Err("allocate_minor_proportional: zero total weight".to_string());
    }
    let n = payers.len();
    let mut out: Vec<(String, i64)> = Vec::with_capacity(n);
    let mut assigned: i128 = 0;
    for (i, (id, w)) in payers.iter().enumerate() {
        if i == n - 1 {
            let last = (amount as i128) - assigned;
            out.push((id.clone(), last as i64));
        } else {
            let share = ((amount as i128) * (*w as i128) / total_w) as i64;
            assigned += share as i128;
            out.push((id.clone(), share));
        }
    }
    Ok(out)
}

fn pairwise_net_edges(
    owed: &HashMap<(String, String, String), i64>,
) -> Result<Vec<SettlementEdge>, String> {
    let mut participants_by_ccy: HashMap<String, Vec<String>> = HashMap::new();
    for ((a, b, ccy), _) in owed.iter() {
        participants_by_ccy.entry(ccy.clone()).or_default();
        let v = participants_by_ccy.get_mut(ccy).unwrap();
        if !v.contains(a) {
            v.push(a.clone());
        }
        if !v.contains(b) {
            v.push(b.clone());
        }
    }
    for v in participants_by_ccy.values_mut() {
        v.sort();
        v.dedup();
    }

    let mut edges: Vec<SettlementEdge> = Vec::new();

    for (ccy, ids) in participants_by_ccy {
        let n = ids.len();
        for i in 0..n {
            for j in (i + 1)..n {
                let a = &ids[i];
                let b = &ids[j];
                let ab = *owed.get(&(a.clone(), b.clone(), ccy.clone())).unwrap_or(&0);
                let ba = *owed.get(&(b.clone(), a.clone(), ccy.clone())).unwrap_or(&0);
                let net = ab
                    .checked_sub(ba)
                    .ok_or("pairwise net underflow")?;
                if net == 0 {
                    continue;
                }
                if net > 0 {
                    edges.push(SettlementEdge {
                        from_participant_id: a.clone(),
                        to_participant_id: b.clone(),
                        amount_minor: net,
                        currency_code: ccy.clone(),
                    });
                } else {
                    let owe = net.checked_neg().ok_or("pairwise net neg overflow")?;
                    edges.push(SettlementEdge {
                        from_participant_id: b.clone(),
                        to_participant_id: a.clone(),
                        amount_minor: owe,
                        currency_code: ccy.clone(),
                    });
                }
            }
        }
    }

    edges.sort_by(|x, y| {
        x.currency_code
            .cmp(&y.currency_code)
            .then_with(|| x.from_participant_id.cmp(&y.from_participant_id))
            .then_with(|| x.to_participant_id.cmp(&y.to_participant_id))
            .then_with(|| x.amount_minor.cmp(&y.amount_minor))
    });

    Ok(edges)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn nb(id: &str, amount: i64, ccy: &str) -> NetBalance {
        NetBalance {
            participant_id: id.to_string(),
            amount_minor: amount,
            currency_code: ccy.to_string(),
        }
    }

    #[test]
    fn empty_ok() {
        assert!(calculate_minimal_settlement_edges(vec![]).unwrap().is_empty());
    }

    #[test]
    fn two_party_idr() {
        let out = calculate_minimal_settlement_edges(vec![
            nb("a", -50_000, "IDR"),
            nb("b", 50_000, "IDR"),
        ])
        .unwrap();
        assert_eq!(out.len(), 1);
        assert_eq!(out[0].from_participant_id, "a");
        assert_eq!(out[0].to_participant_id, "b");
        assert_eq!(out[0].amount_minor, 50_000);
        assert_eq!(out[0].currency_code, "IDR");
    }

    #[test]
    fn three_way() {
        let out = calculate_minimal_settlement_edges(vec![
            nb("a", -30, "USD"),
            nb("b", -20, "USD"),
            nb("c", 50, "USD"),
        ])
        .unwrap();
        assert_eq!(out.len(), 2);
        let total: i64 = out.iter().map(|e| e.amount_minor).sum();
        assert_eq!(total, 50);
    }

    #[test]
    fn rejects_nonzero_sum() {
        let err = calculate_minimal_settlement_edges(vec![
            nb("a", -10, "USD"),
            nb("b", 5, "USD"),
        ])
        .unwrap_err();
        assert!(err.contains("do not sum to zero"));
    }

    #[test]
    fn merges_duplicate_rows() {
        let out = calculate_minimal_settlement_edges(vec![
            nb("a", -5, "USD"),
            nb("a", 5, "USD"),
            nb("b", 0, "USD"),
        ])
        .unwrap();
        assert!(out.is_empty());
    }

    #[test]
    fn two_currencies_independent() {
        let out = calculate_minimal_settlement_edges(vec![
            nb("a", -100, "IDR"),
            nb("b", 100, "IDR"),
            nb("x", -2, "USD"),
            nb("y", 2, "USD"),
        ])
        .unwrap();
        assert_eq!(out.len(), 2);
        assert!(out.iter().any(|e| e.currency_code == "IDR"));
        assert!(out.iter().any(|e| e.currency_code == "USD"));
    }

    #[test]
    fn deterministic_tie() {
        let out = calculate_minimal_settlement_edges(vec![
            nb("bob", -10, "USD"),
            nb("amy", -10, "USD"),
            nb("cam", 10, "USD"),
            nb("dan", 10, "USD"),
        ])
        .unwrap();
        assert_eq!(out.len(), 2);
        // With stable sort, first debtor is "bob" vs "amy" — both 10; order by id: amy, bob
        // Actually sort is descending by amount then id: amount both 10, then amy before bob.
        assert_eq!(out[0].from_participant_id, "amy");
    }

    #[test]
    fn net_balances_single_payer_one_ower() {
        let out = calculate_net_balances(
            vec![SplitObligationRow {
                transaction_id: "tx1".to_string(),
                ower_id: "a".to_string(),
                amount_minor: 100,
                currency_code: "IDR".to_string(),
            }],
            vec![SplitPaymentRow {
                transaction_id: "tx1".to_string(),
                payer_id: "b".to_string(),
                amount_minor: 100,
                currency_code: "IDR".to_string(),
            }],
            vec![],
        )
        .unwrap();
        assert_eq!(out.len(), 1);
        assert_eq!(out[0].from_participant_id, "a");
        assert_eq!(out[0].to_participant_id, "b");
        assert_eq!(out[0].amount_minor, 100);
    }

    #[test]
    fn net_balances_bilateral_cancel() {
        let out = calculate_net_balances(
            vec![
                SplitObligationRow {
                    transaction_id: "t1".to_string(),
                    ower_id: "a".to_string(),
                    amount_minor: 10,
                    currency_code: "USD".to_string(),
                },
                SplitObligationRow {
                    transaction_id: "t2".to_string(),
                    ower_id: "b".to_string(),
                    amount_minor: 3,
                    currency_code: "USD".to_string(),
                },
            ],
            vec![
                SplitPaymentRow {
                    transaction_id: "t1".to_string(),
                    payer_id: "b".to_string(),
                    amount_minor: 10,
                    currency_code: "USD".to_string(),
                },
                SplitPaymentRow {
                    transaction_id: "t2".to_string(),
                    payer_id: "a".to_string(),
                    amount_minor: 3,
                    currency_code: "USD".to_string(),
                },
            ],
            vec![],
        )
        .unwrap();
        assert_eq!(out.len(), 1);
        assert_eq!(out[0].from_participant_id, "a");
        assert_eq!(out[0].to_participant_id, "b");
        assert_eq!(out[0].amount_minor, 7);
    }

    #[test]
    fn net_balances_empty() {
        assert!(calculate_net_balances(vec![], vec![], vec![])
            .unwrap()
            .is_empty());
    }
}
