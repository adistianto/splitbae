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
}
