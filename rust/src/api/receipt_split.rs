//! Receipt split: line shares in minor units, then tax + tip allocated by pre-tax weights.

use std::collections::{BTreeSet, HashMap};

use super::money::{validate_currency_amount, CurrencyAmount};

/// One purchased line: **equal split** among unique assignees (empty = everyone on the receipt).
#[flutter_rust_bridge::frb]
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct ReceiptItem {
    pub name: String,
    pub cost: CurrencyAmount,
    /// Participant IDs. Empty means “split among everyone” (union of IDs that appear on any line).
    pub assignee_ids: Vec<String>,
}

#[flutter_rust_bridge::frb]
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Receipt {
    pub items: Vec<ReceiptItem>,
    pub tax: CurrencyAmount,
    pub tip: CurrencyAmount,
}

/// Per-user total owed (items + share of tax + share of tip), minor units.
#[flutter_rust_bridge::frb]
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct UserOwedMinor {
    pub user_id: String,
    pub amount_minor: i64,
    pub currency_code: String,
    pub scale: u8,
}

/// Split receipt lines, then allocate **tax** and **tip** separately by each user’s pre-tax subtotal.
///
/// - Line costs: divided equally among **unique** assignees; indivisible remainder goes to the first
///   `r` assignees in lexicographic ID order (`+1` minor each).
/// - Tax / tip: proportional floor by pre-tax weights; **all** rounding slack goes to the
///   lexicographically smallest user ID with positive weight (per product rule: “first user” gets the odd cents).
#[flutter_rust_bridge::frb(sync)]
pub fn calculate_split(receipt: Receipt) -> Result<Vec<UserOwedMinor>, String> {
    let ccy_tax = validate_currency_amount(&receipt.tax)?;
    let ccy_tip = validate_currency_amount(&receipt.tip)?;
    if ccy_tax != ccy_tip {
        return Err(format!(
            "tax currency {ccy_tax} != tip currency {ccy_tip}"
        ));
    }
    let bill_ccy = ccy_tax;

    if receipt.items.is_empty() {
        if receipt.tax.amount_minor == 0 && receipt.tip.amount_minor == 0 {
            return Ok(Vec::new());
        }
        return Err("Receipt has no items but non-zero tax or tip".to_string());
    }

    let mut subtotal: i128 = 0;
    for item in &receipt.items {
        let c = validate_currency_amount(&item.cost)?;
        if c != bill_ccy {
            return Err(format!(
                "Item {:?} currency {c} does not match bill currency {bill_ccy}",
                item.name
            ));
        }
        subtotal += item.cost.amount_minor as i128;
    }

    let universe = build_universe(&receipt.items)?;
    if universe.is_empty() {
        return Err(
            "No assignees: add participant IDs on items or use empty assignee lists with at least one ID elsewhere"
                .to_string(),
        );
    }

    let mut pre_tax: HashMap<String, i128> = HashMap::new();
    for u in &universe {
        pre_tax.insert(u.clone(), 0);
    }

    for item in &receipt.items {
        let assignees = resolve_assignees(item, &universe)?;
        let split = split_equal_with_remainder_spread(
            item.cost.amount_minor,
            &assignees,
        )?;
        for (uid, amt) in split {
            let slot = pre_tax.entry(uid).or_insert(0);
            *slot = slot
                .checked_add(amt as i128)
                .ok_or("pre-tax share overflow")?;
        }
    }

    let pre_tax_sum: i128 = pre_tax.values().sum();
    if pre_tax_sum != subtotal {
        return Err(format!(
            "internal: pre-tax shares {} != subtotal {}",
            pre_tax_sum, subtotal
        ));
    }

    let tax_part = allocate_proportional_first_user_slack(
        receipt.tax.amount_minor,
        &pre_tax,
        &universe,
    )?;
    let tip_part = allocate_proportional_first_user_slack(
        receipt.tip.amount_minor,
        &pre_tax,
        &universe,
    )?;

    let scale = receipt.tax.scale;
    let mut out: Vec<UserOwedMinor> = Vec::new();
    for uid in &universe {
        let base = *pre_tax.get(uid).ok_or("internal: missing user")?;
        let t = *tax_part.get(uid).unwrap_or(&0) as i128;
        let p = *tip_part.get(uid).unwrap_or(&0) as i128;
        let total = base
            .checked_add(t)
            .and_then(|x| x.checked_add(p))
            .ok_or("total owed overflow")?;
        let total_i64: i64 = total
            .try_into()
            .map_err(|_| "total owed does not fit i64")?;
        out.push(UserOwedMinor {
            user_id: uid.clone(),
            amount_minor: total_i64,
            currency_code: bill_ccy.clone(),
            scale,
        });
    }

    let expected_total = subtotal
        .checked_add(receipt.tax.amount_minor as i128)
        .and_then(|x| x.checked_add(receipt.tip.amount_minor as i128))
        .ok_or("receipt total overflow")?;
    let got: i128 = out.iter().map(|r| r.amount_minor as i128).sum();
    if got != expected_total {
        return Err(format!(
            "internal: sum owed {} != receipt total {}",
            got, expected_total
        ));
    }

    Ok(out)
}

fn build_universe(items: &[ReceiptItem]) -> Result<Vec<String>, String> {
    let mut u = BTreeSet::new();
    for item in items {
        for id in &item.assignee_ids {
            let t = id.trim();
            if !t.is_empty() {
                u.insert(t.to_string());
            }
        }
    }
    Ok(u.into_iter().collect())
}

fn resolve_assignees(item: &ReceiptItem, universe: &[String]) -> Result<Vec<String>, String> {
    let unique: BTreeSet<String> = item
        .assignee_ids
        .iter()
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
        .collect();
    if unique.is_empty() {
        if universe.is_empty() {
            return Err("Empty assignee list with empty universe".to_string());
        }
        return Ok(universe.to_vec());
    }
    Ok(unique.into_iter().collect())
}

/// `assignees` must be non-empty, sorted lexicographically for deterministic remainder spread.
fn split_equal_with_remainder_spread(
    cost_minor: i64,
    assignees: &[String],
) -> Result<HashMap<String, i64>, String> {
    if assignees.is_empty() {
        return Err("split_equal: empty assignees".to_string());
    }
    if cost_minor < 0 {
        return Err("Negative line cost".to_string());
    }
    let n = assignees.len() as i64;
    let base = cost_minor / n;
    let rem = (cost_minor % n) as usize;
    let mut map = HashMap::new();
    for (i, uid) in assignees.iter().enumerate() {
        let mut v = base;
        if i < rem {
            v = v.checked_add(1).ok_or("line split overflow")?;
        }
        map.insert(uid.clone(), v);
    }
    Ok(map)
}

/// Floor allocation; entire `(pool - sum_floors)` goes to the lexicographically smallest ID with weight > 0.
fn allocate_proportional_first_user_slack(
    pool_minor: i64,
    weights: &HashMap<String, i128>,
    universe_sorted: &[String],
) -> Result<HashMap<String, i64>, String> {
    if pool_minor < 0 {
        return Err("Negative tax or tip pool".to_string());
    }
    if pool_minor == 0 {
        return Ok(HashMap::new());
    }

    let total_w: i128 = weights.values().sum();
    if total_w == 0 {
        // No pre-tax allocation: split pool equally (first users get +1 remainder).
        return Ok(split_equal_with_remainder_spread(pool_minor, universe_sorted)?);
    }

    let pool = pool_minor as i128;
    let mut out: HashMap<String, i64> = HashMap::new();
    let mut allocated: i128 = 0;

    for uid in universe_sorted {
        let w = *weights.get(uid).unwrap_or(&0);
        let share = if w > 0 {
            (pool * w) / total_w
        } else {
            0
        };
        let s_i64: i64 = share
            .try_into()
            .map_err(|_| "tax/tip share does not fit i64")?;
        out.insert(uid.clone(), s_i64);
        allocated = allocated
            .checked_add(share)
            .ok_or("tax/tip allocation overflow")?;
    }

    let slack = pool
        .checked_sub(allocated)
        .ok_or("internal: negative slack")?;
    if slack > 0 {
        let first = universe_sorted
            .iter()
            .find(|u| *weights.get(*u).unwrap_or(&0) > 0)
            .ok_or("internal: no positive weight for slack")?;
        let slot = out.entry(first.clone()).or_insert(0);
        *slot = slot
            .checked_add(
                slack
                    .try_into()
                    .map_err(|_| "slack does not fit i64")?,
            )
            .ok_or("slack add overflow")?;
    }

    Ok(out)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::api::money::CurrencyAmount;

    fn usd(minor: i64) -> CurrencyAmount {
        CurrencyAmount {
            amount_minor: minor,
            currency_code: "USD".into(),
            scale: 2,
        }
    }

    fn item(name: &str, minor: i64, assignees: Vec<&str>) -> ReceiptItem {
        ReceiptItem {
            name: name.into(),
            cost: usd(minor),
            assignee_ids: assignees.into_iter().map(String::from).collect(),
        }
    }

    #[test]
    fn two_items_tax_tip_proportional() {
        // Alice 100, Bob 300 pre-tax → 25% / 75% of tax+tip
        let receipt = Receipt {
            items: vec![
                item("a", 100, vec!["alice"]),
                item("b", 300, vec!["bob"]),
            ],
            tax: usd(40),
            tip: usd(20),
        };
        let out = calculate_split(receipt).unwrap();
        let m: HashMap<_, _> = out.iter().map(|r| (r.user_id.as_str(), r.amount_minor)).collect();
        assert_eq!(m["alice"], 100 + 10 + 5); // 115
        assert_eq!(m["bob"], 300 + 30 + 15); // 345
        assert_eq!(m["alice"] + m["bob"], 400 + 40 + 20);
    }

    #[test]
    fn empty_assignees_splits_universe() {
        let receipt = Receipt {
            items: vec![
                item("only_alice", 100, vec!["alice"]),
                item("everyone", 100, vec![]),
            ],
            tax: usd(0),
            tip: usd(0),
        };
        let out = calculate_split(receipt).unwrap();
        let m: HashMap<_, _> = out.iter().map(|r| (r.user_id.as_str(), r.amount_minor)).collect();
        assert_eq!(m["alice"], 200);
    }

    #[test]
    fn line_remainder_spreads_to_first_ids() {
        // 100 / 3 → 34 + 33 + 33 (assignees sorted lexicographically: a, b, c)
        let receipt = Receipt {
            items: vec![item("x", 100, vec!["c", "b", "a"])],
            tax: usd(0),
            tip: usd(0),
        };
        let out = calculate_split(receipt).unwrap();
        let m: HashMap<_, _> = out.iter().map(|r| (r.user_id.as_str(), r.amount_minor)).collect();
        assert_eq!(m["a"], 34);
        assert_eq!(m["b"], 33);
        assert_eq!(m["c"], 33);
    }

    #[test]
    fn tax_slack_to_smallest_id_with_weight() {
        // Pre-tax equal 50/50; tax=3 → floor 1+1, slack 1 → "alice" < "bob"
        let receipt = Receipt {
            items: vec![
                item("a", 50, vec!["bob"]),
                item("b", 50, vec!["alice"]),
            ],
            tax: usd(3),
            tip: usd(0),
        };
        let out = calculate_split(receipt).unwrap();
        let m: HashMap<_, _> = out.iter().map(|r| (r.user_id.as_str(), r.amount_minor)).collect();
        assert_eq!(m["alice"], 50 + 2);
        assert_eq!(m["bob"], 50 + 1);
    }
}
