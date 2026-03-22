//! Money domain: persisted and computed amounts use **minor units** only (`i64`).

/// Canonical amount for storage and Rust-side math. **No `f64` in business logic.**
#[flutter_rust_bridge::frb]
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct CurrencyAmount {
    /// Value in minor units (e.g. USD cents, whole IDR).
    pub amount_minor: i64,
    /// ISO 4217 alphabetic code (e.g. `USD`, `IDR`).
    pub currency_code: String,
    /// ISO 4217 minor-unit exponent: USD/EUR = 2, IDR/JPY/KRW = 0.
    /// Documents how `amount_minor` maps to major units; arithmetic uses minor units only.
    pub scale: u8,
}

pub(crate) fn normalize_currency_code(raw: &str) -> String {
    raw.trim().to_uppercase()
}

/// Matches [`super::simple::amount_to_minor_units`] / display helpers (MVP currencies).
pub(crate) fn expected_minor_scale(currency_upper: &str) -> u8 {
    match currency_upper {
        "IDR" | "JPY" | "KRW" => 0,
        _ => 2,
    }
}

pub(crate) fn validate_currency_amount(a: &CurrencyAmount) -> Result<String, String> {
    let ccy = normalize_currency_code(&a.currency_code);
    if ccy.is_empty() {
        return Err("Empty currency_code on CurrencyAmount".to_string());
    }
    if a.amount_minor < 0 {
        return Err(format!("Negative amount_minor for {ccy}"));
    }
    let exp = expected_minor_scale(&ccy);
    if a.scale != exp {
        return Err(format!(
            "CurrencyAmount scale {} does not match expected ISO minor exponent {} for {}",
            a.scale, exp, ccy
        ));
    }
    Ok(ccy)
}
