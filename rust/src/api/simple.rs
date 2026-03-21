use std::collections::HashMap;

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

/// Equal split per currency bucket (no FX conversion).
#[flutter_rust_bridge::frb(sync)]
pub fn calculate_split(items: Vec<ReceiptItem>, participants: Vec<String>) -> Vec<SplitResult> {
    let n = participants.len();
    let mut totals_by_ccy: HashMap<String, f64> = HashMap::new();
    for item in items {
        *totals_by_ccy
            .entry(item.currency_code)
            .or_insert(0.0) += item.price;
    }

    let mut out: Vec<SplitResult> = Vec::new();
    for (currency_code, total) in totals_by_ccy {
        let share = if n == 0 { 0.0 } else { total / n as f64 };
        for person_name in &participants {
            out.push(SplitResult {
                person_name: person_name.clone(),
                total_owed: share,
                currency_code: currency_code.clone(),
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
