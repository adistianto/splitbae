"use client"

import { useState, useEffect, useCallback } from "react"

const STORAGE_KEY = "splitbae-theme"

export function useTheme() {
  const [isDark, setIsDark] = useState(false)

  // On mount, read persisted preference (or system default)
  useEffect(() => {
    const stored = localStorage.getItem(STORAGE_KEY)
    const prefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches
    const shouldBeDark = stored !== null ? stored === "dark" : prefersDark
    setIsDark(shouldBeDark)
    document.documentElement.classList.toggle("dark", shouldBeDark)
  }, [])

  const toggle = useCallback(() => {
    setIsDark((prev) => {
      const next = !prev
      document.documentElement.classList.toggle("dark", next)
      localStorage.setItem(STORAGE_KEY, next ? "dark" : "light")
      return next
    })
  }, [])

  const set = useCallback((dark: boolean) => {
    setIsDark(dark)
    document.documentElement.classList.toggle("dark", dark)
    localStorage.setItem(STORAGE_KEY, dark ? "dark" : "light")
  }, [])

  return { isDark, toggle, set }
}
