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
