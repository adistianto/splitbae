import type { LucideIcon } from "lucide-react"
import { cn } from "@/lib/utils"

export type InsightChipVariant = "rose" | "emerald" | "amber" | "orange" | "muted" | "teal" | "violet" | "blue"

const variantStyles: Record<InsightChipVariant, string> = {
  rose: "bg-rose-100 dark:bg-rose-950/50 text-rose-700 dark:text-rose-300",
  emerald: "bg-emerald-100 dark:bg-emerald-950/50 text-emerald-700 dark:text-emerald-300",
  amber: "bg-amber-100 dark:bg-amber-950/50 text-amber-700 dark:text-amber-300",
  orange: "bg-orange-100 dark:bg-orange-950/50 text-orange-700 dark:text-orange-300",
  teal: "bg-teal-100 dark:bg-teal-950/50 text-teal-700 dark:text-teal-300",
  violet: "bg-violet-100 dark:bg-violet-950/50 text-violet-700 dark:text-violet-300",
  blue: "bg-blue-100 dark:bg-blue-950/50 text-blue-700 dark:text-blue-300",
  muted: "bg-muted text-foreground",
}

const iconVariantStyles: Record<InsightChipVariant, string> = {
  rose: "text-rose-600 dark:text-rose-400",
  emerald: "text-emerald-600 dark:text-emerald-400",
  amber: "text-amber-600 dark:text-amber-400",
  orange: "text-orange-600 dark:text-orange-400",
  teal: "text-teal-600 dark:text-teal-400",
  violet: "text-violet-600 dark:text-violet-400",
  blue: "text-blue-600 dark:text-blue-400",
  muted: "text-muted-foreground",
}

interface InsightChipProps {
  icon: LucideIcon
  children: React.ReactNode
  variant?: InsightChipVariant
  iconClassName?: string
  className?: string
}

/**
 * Reusable insight chip component with automatic dark mode support
 * Used for stats, trends, and quick info display
 */
export function InsightChip({
  icon: Icon,
  children,
  variant = "muted",
  iconClassName,
  className,
}: InsightChipProps) {
  return (
    <div
      className={cn(
        "flex items-center gap-2 px-4 py-2.5 rounded-full shrink-0 transition-colors",
        variantStyles[variant],
        className
      )}
    >
      <Icon
        className={cn("w-4 h-4", iconVariantStyles[variant], iconClassName)}
        strokeWidth={2.5}
      />
      <span className="text-sm font-semibold">{children}</span>
    </div>
  )
}

/**
 * Larger insight card for hero sections
 */
interface InsightCardProps {
  icon: LucideIcon
  label: string
  value: string
  variant?: InsightChipVariant
  className?: string
}

const cardVariantStyles: Record<InsightChipVariant, {
  bg: string
  border: string
  iconBg: string
  iconText: string
  labelText: string
  valueText: string
}> = {
  rose: {
    bg: "bg-rose-50 dark:bg-rose-950/50",
    border: "border-rose-100 dark:border-rose-900/50",
    iconBg: "bg-rose-100 dark:bg-rose-900/60",
    iconText: "text-rose-600 dark:text-rose-400",
    labelText: "text-rose-600/80 dark:text-rose-400/80",
    valueText: "text-rose-700 dark:text-rose-300",
  },
  emerald: {
    bg: "bg-emerald-50 dark:bg-emerald-950/50",
    border: "border-emerald-100 dark:border-emerald-900/50",
    iconBg: "bg-emerald-100 dark:bg-emerald-900/60",
    iconText: "text-emerald-600 dark:text-emerald-400",
    labelText: "text-emerald-600/80 dark:text-emerald-400/80",
    valueText: "text-emerald-700 dark:text-emerald-300",
  },
  amber: {
    bg: "bg-amber-50 dark:bg-amber-950/50",
    border: "border-amber-100 dark:border-amber-900/50",
    iconBg: "bg-amber-100 dark:bg-amber-900/60",
    iconText: "text-amber-600 dark:text-amber-400",
    labelText: "text-amber-600/80 dark:text-amber-400/80",
    valueText: "text-amber-700 dark:text-amber-300",
  },
  orange: {
    bg: "bg-orange-50 dark:bg-orange-950/50",
    border: "border-orange-100 dark:border-orange-900/50",
    iconBg: "bg-orange-100 dark:bg-orange-900/60",
    iconText: "text-orange-600 dark:text-orange-400",
    labelText: "text-orange-600/80 dark:text-orange-400/80",
    valueText: "text-orange-700 dark:text-orange-300",
  },
  teal: {
    bg: "bg-teal-50 dark:bg-teal-950/50",
    border: "border-teal-100 dark:border-teal-900/50",
    iconBg: "bg-teal-100 dark:bg-teal-900/60",
    iconText: "text-teal-600 dark:text-teal-400",
    labelText: "text-teal-600/80 dark:text-teal-400/80",
    valueText: "text-teal-700 dark:text-teal-300",
  },
  violet: {
    bg: "bg-violet-50 dark:bg-violet-950/50",
    border: "border-violet-100 dark:border-violet-900/50",
    iconBg: "bg-violet-100 dark:bg-violet-900/60",
    iconText: "text-violet-600 dark:text-violet-400",
    labelText: "text-violet-600/80 dark:text-violet-400/80",
    valueText: "text-violet-700 dark:text-violet-300",
  },
  blue: {
    bg: "bg-blue-50 dark:bg-blue-950/50",
    border: "border-blue-100 dark:border-blue-900/50",
    iconBg: "bg-blue-100 dark:bg-blue-900/60",
    iconText: "text-blue-600 dark:text-blue-400",
    labelText: "text-blue-600/80 dark:text-blue-400/80",
    valueText: "text-blue-700 dark:text-blue-300",
  },
  muted: {
    bg: "bg-muted/50",
    border: "border-border",
    iconBg: "bg-muted",
    iconText: "text-muted-foreground",
    labelText: "text-muted-foreground",
    valueText: "text-foreground",
  },
}

export function InsightCard({
  icon: Icon,
  label,
  value,
  variant = "muted",
  className,
}: InsightCardProps) {
  const styles = cardVariantStyles[variant]
  
  return (
    <div className={cn(
      "flex-1 rounded-[18px] p-3.5 border",
      styles.bg,
      styles.border,
      className
    )}>
      <div className="flex items-center gap-2.5">
        <div className={cn(
          "w-9 h-9 rounded-[12px] flex items-center justify-center",
          styles.iconBg
        )}>
          <Icon className={cn("w-4 h-4", styles.iconText)} strokeWidth={2.5} />
        </div>
        <div className="min-w-0 flex-1">
          <p className={cn("text-[11px] uppercase tracking-wide", styles.labelText)}>
            {label}
          </p>
          <p className={cn("text-sm font-bold truncate", styles.valueText)}>
            {value}
          </p>
        </div>
      </div>
    </div>
  )
}
