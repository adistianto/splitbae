"use client"

import { create } from "zustand"
import { persist } from "zustand/middleware"

export type CurrencyCode = "IDR" | "USD" | "AUD" | "EUR" | "GBP" | "SGD" | "MYR"

interface CurrencyConfig {
  code: CurrencyCode
  symbol: string
  name: string
  locale: string
  decimals: number
}

export const CURRENCIES: Record<CurrencyCode, CurrencyConfig> = {
  IDR: { code: "IDR", symbol: "Rp", name: "Indonesian Rupiah", locale: "id-ID", decimals: 0 },
  USD: { code: "USD", symbol: "$", name: "US Dollar", locale: "en-US", decimals: 2 },
  AUD: { code: "AUD", symbol: "$", name: "Australian Dollar", locale: "en-AU", decimals: 2 },
  EUR: { code: "EUR", symbol: "€", name: "Euro", locale: "de-DE", decimals: 2 },
  GBP: { code: "GBP", symbol: "£", name: "British Pound", locale: "en-GB", decimals: 2 },
  SGD: { code: "SGD", symbol: "$", name: "Singapore Dollar", locale: "en-SG", decimals: 2 },
  MYR: { code: "MYR", symbol: "RM", name: "Malaysian Ringgit", locale: "ms-MY", decimals: 2 },
}

interface CurrencyState {
  currency: CurrencyCode
  showFractional: boolean
  setCurrency: (currency: CurrencyCode) => void
  setShowFractional: (show: boolean) => void
}

export const useCurrencyStore = create<CurrencyState>()(
  persist(
    (set) => ({
      currency: "IDR",
      showFractional: false,
      setCurrency: (currency) => set({ currency }),
      setShowFractional: (showFractional) => set({ showFractional }),
    }),
    { name: "splitbae-currency" }
  )
)

/**
 * Hook to format currency values consistently throughout the app.
 * Uses the persisted currency preference.
 */
export function useCurrency() {
  const { currency, showFractional } = useCurrencyStore()
  const config = CURRENCIES[currency]

  const formatAmount = (value: number): string => {
    const decimals = showFractional ? config.decimals : 0
    return new Intl.NumberFormat(config.locale, {
      style: "currency",
      currency: config.code,
      minimumFractionDigits: decimals,
      maximumFractionDigits: decimals,
    }).format(value)
  }

  const formatCompact = (value: number): string => {
    // For large numbers, use compact notation
    if (Math.abs(value) >= 1000000) {
      return new Intl.NumberFormat(config.locale, {
        style: "currency",
        currency: config.code,
        notation: "compact",
        maximumFractionDigits: 1,
      }).format(value)
    }
    return formatAmount(value)
  }

  return {
    currency,
    config,
    formatAmount,
    formatCompact,
    symbol: config.symbol,
  }
}
