import { Utensils, Car, Home, Music, ShoppingBag, Zap, MoreHorizontal, CheckCircle } from "lucide-react"
import type { Category } from "./types"

/**
 * Centralized category configuration - single source of truth
 * All components should import from here instead of defining their own
 */
export const CATEGORY_CONFIG: Record<Category, {
  label: string
  shortLabel: string
  icon: typeof Utensils
  // Light mode
  bg: string
  text: string
  activeBg: string
  // Dark mode
  darkBg: string
  darkText: string
  darkActiveBg: string
  // Icon background (for cards)
  iconBg: string
  darkIconBg: string
}> = {
  food: {
    label: "Food & Drinks",
    shortLabel: "Food",
    icon: Utensils,
    bg: "bg-orange-100",
    text: "text-orange-600",
    activeBg: "bg-orange-500",
    darkBg: "dark:bg-orange-950/50",
    darkText: "dark:text-orange-400",
    darkActiveBg: "dark:bg-orange-600",
    iconBg: "bg-orange-100",
    darkIconBg: "dark:bg-orange-900/60",
  },
  transport: {
    label: "Transport",
    shortLabel: "Transport",
    icon: Car,
    bg: "bg-blue-100",
    text: "text-blue-600",
    activeBg: "bg-blue-500",
    darkBg: "dark:bg-blue-950/50",
    darkText: "dark:text-blue-400",
    darkActiveBg: "dark:bg-blue-600",
    iconBg: "bg-blue-100",
    darkIconBg: "dark:bg-blue-900/60",
  },
  accommodation: {
    label: "Accommodation",
    shortLabel: "Stay",
    icon: Home,
    bg: "bg-violet-100",
    text: "text-violet-600",
    activeBg: "bg-violet-500",
    darkBg: "dark:bg-violet-950/50",
    darkText: "dark:text-violet-400",
    darkActiveBg: "dark:bg-violet-600",
    iconBg: "bg-violet-100",
    darkIconBg: "dark:bg-violet-900/60",
  },
  entertainment: {
    label: "Entertainment",
    shortLabel: "Fun",
    icon: Music,
    bg: "bg-pink-100",
    text: "text-pink-600",
    activeBg: "bg-pink-500",
    darkBg: "dark:bg-pink-950/50",
    darkText: "dark:text-pink-400",
    darkActiveBg: "dark:bg-pink-600",
    iconBg: "bg-pink-100",
    darkIconBg: "dark:bg-pink-900/60",
  },
  shopping: {
    label: "Shopping",
    shortLabel: "Shop",
    icon: ShoppingBag,
    bg: "bg-emerald-100",
    text: "text-emerald-600",
    activeBg: "bg-emerald-500",
    darkBg: "dark:bg-emerald-950/50",
    darkText: "dark:text-emerald-400",
    darkActiveBg: "dark:bg-emerald-600",
    iconBg: "bg-emerald-100",
    darkIconBg: "dark:bg-emerald-900/60",
  },
  utilities: {
    label: "Utilities",
    shortLabel: "Bills",
    icon: Zap,
    bg: "bg-amber-100",
    text: "text-amber-600",
    activeBg: "bg-amber-500",
    darkBg: "dark:bg-amber-950/50",
    darkText: "dark:text-amber-400",
    darkActiveBg: "dark:bg-amber-600",
    iconBg: "bg-amber-100",
    darkIconBg: "dark:bg-amber-900/60",
  },
  other: {
    label: "Other",
    shortLabel: "Other",
    icon: MoreHorizontal,
    bg: "bg-slate-100",
    text: "text-slate-600",
    activeBg: "bg-slate-500",
    darkBg: "dark:bg-slate-800/50",
    darkText: "dark:text-slate-400",
    darkActiveBg: "dark:bg-slate-600",
    iconBg: "bg-slate-100",
    darkIconBg: "dark:bg-slate-800/60",
  },
  settlement: {
    label: "Settlement",
    shortLabel: "Settlement",
    icon: CheckCircle,
    bg: "bg-teal-100",
    text: "text-teal-600",
    activeBg: "bg-teal-500",
    darkBg: "dark:bg-teal-950/50",
    darkText: "dark:text-teal-400",
    darkActiveBg: "dark:bg-teal-600",
    iconBg: "bg-teal-100",
    darkIconBg: "dark:bg-teal-900/60",
  },
}

/**
 * Get combined classes for category styling
 * @param category - The category to style
 * @param variant - "default" for background, "active" for selected state, "icon" for icon backgrounds
 */
export function getCategoryClasses(category: Category, variant: "default" | "active" | "icon" = "default"): string {
  const config = CATEGORY_CONFIG[category]
  
  switch (variant) {
    case "active":
      return `${config.activeBg} ${config.darkActiveBg} text-white`
    case "icon":
      return `${config.iconBg} ${config.darkIconBg} ${config.text} ${config.darkText}`
    default:
      return `${config.bg} ${config.darkBg} ${config.text} ${config.darkText}`
  }
}

/**
 * Get category array for dropdowns/pickers
 */
export const CATEGORY_OPTIONS = Object.entries(CATEGORY_CONFIG).map(([id, config]) => ({
  id: id as Category,
  label: config.shortLabel,
  fullLabel: config.label,
  icon: config.icon,
}))

/**
 * Filter categories (excludes settlement for user-facing filters)
 */
export const FILTER_CATEGORIES = CATEGORY_OPTIONS.filter(cat => cat.id !== "settlement")
