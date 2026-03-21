#[flutter_rust_bridge::frb(sync)]
pub fn greet(name: String) -> String {
    format!("Hello, {name}!")
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

#[flutter_rust_bridge::frb]
#[derive(Clone, Debug)]
pub struct ReceiptItem {
    pub name: String,
    pub price: f64,
    /// ISO 4217 code (e.g. IDR, USD).
    pub currency_code: String,
}

#[flutter_rust_bridge::frb]
#[derive(Clone, Debug)]
pub struct SplitResult {
    pub person_name: String,
    pub total_owed: f64,
    pub currency_code: String,
}

#[flutter_rust_bridge::frb]
#[derive(Clone, Debug)]
pub struct ParticipantRef {
    pub id: String,
    pub display_name: String,
}

#[flutter_rust_bridge::frb]
#[derive(Clone, Debug)]
pub struct AssignedReceiptLine {
    pub item: ReceiptItem,
    /// Empty = all current participants split this line equally.
    pub assignee_ids: Vec<String>,
}

/// Per–line-item assignees: each line is split equally among its assignees (no FX conversion).
/// Rows are produced for every (participant × currency) present in the bill; amounts may be zero.
#[flutter_rust_bridge::frb(sync)]
pub fn calculate_split_assigned(
    lines: Vec<AssignedReceiptLine>,
    participants: Vec<ParticipantRef>,
) -> Vec<SplitResult> {
    use std::collections::{BTreeSet, HashMap, HashSet};

    let mut currencies: BTreeSet<String> = BTreeSet::new();
    for line in &lines {
        currencies.insert(line.item.currency_code.clone());
    }

    let mut totals: HashMap<String, HashMap<String, f64>> = HashMap::new();
    for p in &participants {
        totals.insert(p.id.clone(), HashMap::new());
    }

    let id_set: HashSet<String> = participants.iter().map(|p| p.id.clone()).collect();

    for line in lines {
        let item = line.item;
        let mut assignee_ids: Vec<String> = if line.assignee_ids.is_empty() {
            participants.iter().map(|p| p.id.clone()).collect()
        } else {
            line.assignee_ids
                .into_iter()
                .filter(|id| id_set.contains(id))
                .collect()
        };

        if assignee_ids.is_empty() {
            assignee_ids = participants.iter().map(|p| p.id.clone()).collect();
        }

        let count = assignee_ids.len().max(1);
        let share = item.price / count as f64;
        for pid in assignee_ids {
            *totals
                .entry(pid)
                .or_insert_with(HashMap::new)
                .entry(item.currency_code.clone())
                .or_insert(0.0) += share;
        }
    }

    let currencies: Vec<String> = currencies.into_iter().collect();
    let mut out: Vec<SplitResult> = Vec::new();
    for p in &participants {
        for ccy in &currencies {
            let amt = totals
                .get(&p.id)
                .and_then(|m| m.get(ccy))
                .copied()
                .unwrap_or(0.0);
            out.push(SplitResult {
                person_name: p.display_name.clone(),
                total_owed: amt,
                currency_code: ccy.clone(),
            });
        }
    }

    out.sort_by(|a, b| {
        a.person_name
            .cmp(&b.person_name)
            .then_with(|| a.currency_code.cmp(&b.currency_code))
    });
    out
}

// --- Amount encoding (keep all numeric money rules in Rust; Dart calls FRB only.) ---

/// Maps a decimal UI amount to integer minor units for persistence (e.g. SQLite).
/// IDR/JPY/KRW: 1 minor = 1 unit; others: cents (10^-2).
#[flutter_rust_bridge::frb(sync)]
pub fn amount_to_minor_units(amount: f64, currency_code: String) -> i64 {
    let c = currency_code.to_uppercase();
    if matches!(c.as_str(), "IDR" | "JPY" | "KRW") {
        amount.round() as i64
    } else {
        (amount * 100.0).round() as i64
    }
}

#[flutter_rust_bridge::frb(sync)]
pub fn minor_units_to_amount(minor: i64, currency_code: String) -> f64 {
    let c = currency_code.to_uppercase();
    if matches!(c.as_str(), "IDR" | "JPY" | "KRW") {
        minor as f64
    } else {
        minor as f64 / 100.0
    }
}

/// Plain string for amount text fields (add/edit line).
#[flutter_rust_bridge::frb(sync)]
pub fn amount_to_input_text(amount: f64, currency_code: String) -> String {
    let c = currency_code.to_uppercase();
    if matches!(c.as_str(), "IDR" | "JPY" | "KRW") {
        amount.round().to_string()
    } else {
        format!("{amount:.2}")
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn p(id: &str, name: &str) -> ParticipantRef {
        ParticipantRef {
            id: id.into(),
            display_name: name.into(),
        }
    }

    #[test]
    fn split_assigned_single_item_one_person() {
        let participants = vec![p("a", "Alice"), p("b", "Bob")];
        let lines = vec![AssignedReceiptLine {
            item: ReceiptItem {
                name: "Burger".into(),
                price: 100.0,
                currency_code: "USD".into(),
            },
            assignee_ids: vec!["a".into()],
        }];
        let out = calculate_split_assigned(lines, participants);
        let alice = out.iter().find(|r| r.person_name == "Alice").unwrap();
        let bob = out.iter().find(|r| r.person_name == "Bob").unwrap();
        assert!((alice.total_owed - 100.0).abs() < 1e-9);
        assert!((bob.total_owed - 0.0).abs() < 1e-9);
    }

    #[test]
    fn split_assigned_empty_assignees_means_everyone() {
        let participants = vec![p("a", "Alice"), p("b", "Bob")];
        let lines = vec![AssignedReceiptLine {
            item: ReceiptItem {
                name: "Pizza".into(),
                price: 100.0,
                currency_code: "USD".into(),
            },
            assignee_ids: vec![],
        }];
        let out = calculate_split_assigned(lines, participants);
        let alice = out.iter().find(|r| r.person_name == "Alice").unwrap();
        let bob = out.iter().find(|r| r.person_name == "Bob").unwrap();
        assert!((alice.total_owed - 50.0).abs() < 1e-9);
        assert!((bob.total_owed - 50.0).abs() < 1e-9);
    }

    #[test]
    fn minor_usd_round_trip() {
        let m = amount_to_minor_units(10.50, "USD".into());
        assert_eq!(m, 1050);
        assert!((minor_units_to_amount(m, "USD".into()) - 10.50).abs() < 1e-9);
    }

    #[test]
    fn minor_idr_integer() {
        let m = amount_to_minor_units(45_000.0, "IDR".into());
        assert_eq!(m, 45_000);
        assert!((minor_units_to_amount(m, "IDR".into()) - 45_000.0).abs() < 1e-9);
    }
}
