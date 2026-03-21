"use client"

import { useState, useMemo } from "react"
import {
  Receipt, Sparkles, TrendingUp, ArrowUpRight,
  Flame, SlidersHorizontal, X
} from "lucide-react"
import { useSplitStore } from "@/lib/store"
import { ExpenseCard } from "@/components/expense-card"
import { AddExpenseSheet } from "@/components/add-expense-sheet"
import { useCurrency } from "@/hooks/use-currency"
import { CATEGORY_OPTIONS } from "@/lib/category-config"
import type { Transaction, Category } from "@/lib/types"

const FILTER_CATEGORIES = CATEGORY_OPTIONS.map(cat => ({ id: cat.id, label: cat.label }))

interface TransactionsTabProps {
  searchQuery?: string
  onFiltersOpenChange?: (open: boolean) => void
}

export function TransactionsTab({ searchQuery = "", onFiltersOpenChange }: TransactionsTabProps) {
  const { transactions, people, calculateBalances } = useSplitStore()
  const { formatAmount } = useCurrency()
  const [showEditSheet, setShowEditSheet] = useState(false)
  const [editingTransaction, setEditingTransaction] = useState<Transaction | null>(null)
  
  // Filter state
  const [showFilters, setShowFilters] = useState(false)

  const toggleFilters = (val: boolean) => {
    setShowFilters(val)
    onFiltersOpenChange?.(val)
  }
  const [selectedCategories, setSelectedCategories] = useState<Category[]>([])
  const [selectedParticipants, setSelectedParticipants] = useState<string[]>([])
  
  // Check if any filters are active
  const hasActiveFilters = selectedCategories.length > 0 || selectedParticipants.length > 0
  const activeFilterCount = selectedCategories.length + selectedParticipants.length

  // Filter by search query, category, and participants
  const filteredTransactions = transactions.filter(t => {
    // Text search filter
    if (searchQuery.trim()) {
      const query = searchQuery.toLowerCase()
      const matchesText = (
        t.description.toLowerCase().includes(query) ||
        t.items.some(item => item.name.toLowerCase().includes(query)) ||
        t.category.toLowerCase().includes(query)
      )
      if (!matchesText) return false
    }
    
    // Category filter
    if (selectedCategories.length > 0 && !selectedCategories.includes(t.category)) {
      return false
    }
    
    // Participants filter - transaction must include at least one selected participant
    if (selectedParticipants.length > 0) {
      const hasParticipant = t.participants.some(p => selectedParticipants.includes(p))
      if (!hasParticipant) return false
    }
    
    return true
  })
  
  // Clear all filters — keeps the filter panel open
  const clearFilters = () => {
    setSelectedCategories([])
    setSelectedParticipants([])
  }
  
  // Toggle category filter
  const toggleCategory = (cat: Category) => {
    setSelectedCategories(prev => 
      prev.includes(cat) ? prev.filter(c => c !== cat) : [...prev, cat]
    )
  }
  
  // Toggle participant filter
  const toggleParticipant = (personId: string) => {
    setSelectedParticipants(prev =>
      prev.includes(personId) ? prev.filter(p => p !== personId) : [...prev, personId]
    )
  }

  // Sort by date, most recent first
  const sortedTransactions = [...filteredTransactions].sort(
    (a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
  )

  // Group by Month Year for display (e.g. "MARCH 2026")
  const groupedByDate = sortedTransactions.reduce((acc, transaction) => {
    const date = new Date(transaction.createdAt).toLocaleDateString("en-US", {
      month: "long",
      year: "numeric",
    }).toUpperCase()
    if (!acc[date]) {
      acc[date] = []
    }
    acc[date].push(transaction)
    return acc
  }, {} as Record<string, Transaction[]>)

  // Calculate insights - focused on spending trends (unique to this view)
  const insights = useMemo(() => {
    const totalExpenses = transactions.reduce((sum, t) => sum + t.totalAmount, 0)
    
    // This week's expenses
    const weekAgo = new Date()
    weekAgo.setDate(weekAgo.getDate() - 7)
    const thisWeekExpenses = transactions
      .filter(t => new Date(t.createdAt) >= weekAgo)
      .reduce((sum, t) => sum + t.totalAmount, 0)
    
    // Last week's expenses (for comparison)
    const twoWeeksAgo = new Date()
    twoWeeksAgo.setDate(twoWeeksAgo.getDate() - 14)
    const lastWeekExpenses = transactions
      .filter(t => {
        const date = new Date(t.createdAt)
        return date >= twoWeeksAgo && date < weekAgo
      })
      .reduce((sum, t) => sum + t.totalAmount, 0)
    
    // Week-over-week trend
    const weekTrend = lastWeekExpenses > 0 
      ? ((thisWeekExpenses - lastWeekExpenses) / lastWeekExpenses) * 100 
      : thisWeekExpenses > 0 ? 100 : 0
    
    // Average per transaction
    const avgPerTransaction = transactions.length > 0 
      ? totalExpenses / transactions.length 
      : 0
    
    // Biggest single expense
    const biggestExpense = transactions.length > 0
      ? Math.max(...transactions.map(t => t.totalAmount))
      : 0
    
    // Active streak (consecutive days with transactions, capped at recent activity)
    const sortedDates = [...new Set(
      transactions.map(t => new Date(t.createdAt).toDateString())
    )].sort((a, b) => new Date(b).getTime() - new Date(a).getTime())
    
    let streak = 0
    const today = new Date().toDateString()
    const yesterday = new Date(Date.now() - 86400000).toDateString()
    
    if (sortedDates[0] === today || sortedDates[0] === yesterday) {
      streak = 1
      for (let i = 1; i < sortedDates.length; i++) {
        const curr = new Date(sortedDates[i - 1])
        const prev = new Date(sortedDates[i])
        const diffDays = Math.floor((curr.getTime() - prev.getTime()) / 86400000)
        if (diffDays === 1) {
          streak++
        } else {
          break
        }
      }
    }
    
    // Active splits - non-settlement transactions (unresolved expenses)
    const unsettledCount = transactions.filter(t => t.category !== 'settlement').length
    
    // Active settlements - settlement transactions
    const activeSettlementsCount = transactions.filter(t => t.category === 'settlement').length
    
    return {
      totalExpenses,
      thisWeekExpenses,
      lastWeekExpenses,
      weekTrend,
      avgPerTransaction,
      biggestExpense,
      streak,
      unsettledCount,
      activeSettlementsCount,
    }
  }, [transactions])

  const handleEdit = (transaction: Transaction) => {
    setEditingTransaction(transaction)
    setShowEditSheet(true)
  }

  const handleCloseSheet = () => {
    setShowEditSheet(false)
    setEditingTransaction(null)
  }



  const categoryLabels: Record<string, string> = {
    food: "Food",
    transport: "Transport",
    accommodation: "Stay",
    entertainment: "Fun",
    shopping: "Shop",
    utilities: "Bills",
    other: "Other",
  }

  return (
    <div className="flex-1 flex flex-col min-w-0">

      {/* ── Hero Section ─────────────────────────────────── */}
      {!hasActiveFilters && (
        <div className="px-5 pt-6 pb-5 shrink-0">
          {/* Header */}
          <div className="flex items-start justify-between mb-5">
            <div>
              <h1 className="text-display text-3xl text-foreground">SplitBae</h1>
              <p className="text-sm text-muted-foreground mt-0.5">Split bills with friends</p>
            </div>
            <div className="w-24 shrink-0" />
          </div>

          {/* Primary card */}
          <div className="relative overflow-hidden bg-gradient-to-br from-primary via-primary to-primary/80 rounded-[28px] p-5 elevation-2 mb-4">
            <div className="absolute -top-12 -right-12 w-40 h-40 bg-white/10 rounded-full blur-2xl" />
            <div className="absolute -bottom-8 -left-8 w-32 h-32 bg-white/5 rounded-full blur-xl" />
            <div className="relative">
              <div className="flex items-center gap-2 mb-1">
                <Sparkles className="w-4 h-4 text-primary-foreground/70" />
                <p className="text-xs font-medium text-primary-foreground/70 uppercase tracking-wide">Total Expenses</p>
              </div>
              <p className="text-display text-3xl text-primary-foreground mb-4">
                {formatAmount(insights.totalExpenses)}
              </p>
              <div className="flex gap-2">
                <div className="flex-1 bg-white/15 backdrop-blur-sm rounded-[14px] px-3 py-2.5">
                  <p className="text-[10px] text-primary-foreground/70 uppercase tracking-wide">This Week</p>
                  <p className="text-sm font-bold text-primary-foreground">{formatAmount(insights.thisWeekExpenses)}</p>
                </div>
                <div className="flex-1 bg-white/15 backdrop-blur-sm rounded-[14px] px-3 py-2.5">
                  <p className="text-[10px] text-primary-foreground/70 uppercase tracking-wide">Average</p>
                  <p className="text-sm font-bold text-primary-foreground">{formatAmount(insights.avgPerTransaction)}</p>
                </div>
              </div>
            </div>
          </div>

          {/* Insight chips */}
          <div className="flex gap-2 overflow-x-auto pb-1 -mx-5 px-5 scrollbar-hide">
            <div className={`flex items-center gap-2 px-4 py-2.5 rounded-full shrink-0 transition-colors ${insights.weekTrend > 0 ? "bg-rose-100 dark:bg-rose-950/50" : insights.weekTrend < 0 ? "bg-emerald-100 dark:bg-emerald-950/50" : "bg-muted"}`}>
              <ArrowUpRight className={`w-4 h-4 ${insights.weekTrend > 0 ? "text-rose-600 dark:text-rose-400" : insights.weekTrend < 0 ? "text-emerald-600 dark:text-emerald-400 rotate-180" : "text-muted-foreground"}`} strokeWidth={2.5} />
              <span className={`text-sm font-semibold ${insights.weekTrend > 0 ? "text-rose-700 dark:text-rose-300" : insights.weekTrend < 0 ? "text-emerald-700 dark:text-emerald-300" : "text-foreground"}`}>
                {insights.weekTrend > 0 ? "+" : ""}{Math.round(insights.weekTrend)}% vs last week
              </span>
            </div>
            <div className="flex items-center gap-2 px-4 py-2.5 bg-amber-100 dark:bg-amber-950/50 rounded-full shrink-0">
              <TrendingUp className="w-4 h-4 text-amber-600 dark:text-amber-400" strokeWidth={2.5} />
              <span className="text-sm font-semibold text-amber-700 dark:text-amber-300">Top: {formatAmount(insights.biggestExpense)}</span>
            </div>
            {insights.streak > 0 && (
              <div className="flex items-center gap-2 px-4 py-2.5 bg-orange-100 dark:bg-orange-950/50 rounded-full shrink-0">
                <Flame className="w-4 h-4 text-orange-600 dark:text-orange-400" strokeWidth={2.5} />
                <span className="text-sm font-semibold text-orange-700 dark:text-orange-300">{insights.streak} day streak</span>
              </div>
            )}
            <div className="flex items-center gap-2 px-4 py-2.5 bg-muted rounded-full shrink-0">
              <Receipt className="w-4 h-4 text-muted-foreground" strokeWidth={2.5} />
              <span className="text-sm font-semibold text-foreground">{transactions.length} bills</span>
            </div>
            {insights.unsettledCount > 0 && (
              <div className="flex items-center gap-2 px-4 py-2.5 bg-violet-100 dark:bg-violet-950/50 rounded-full shrink-0">
                <Sparkles className="w-4 h-4 text-violet-600 dark:text-violet-400" strokeWidth={2.5} />
                <span className="text-sm font-semibold text-violet-700 dark:text-violet-300">{insights.unsettledCount} active splits</span>
              </div>
            )}
            {insights.activeSettlementsCount > 0 && (
              <div className="flex items-center gap-2 px-4 py-2.5 bg-teal-100 dark:bg-teal-950/50 rounded-full shrink-0">
                <TrendingUp className="w-4 h-4 text-teal-600 dark:text-teal-400" strokeWidth={2.5} />
                <span className="text-sm font-semibold text-teal-700 dark:text-teal-300">{insights.activeSettlementsCount} settlements</span>
              </div>
            )}
          </div>
        </div>
      )}

      {/* ── Transactions List ─────────────────────────────── */}
      <div className="flex-1 overflow-y-auto px-4 pb-8 min-w-0">
        {filteredTransactions.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-16 text-center">
            <div className="w-20 h-20 rounded-[24px] bg-secondary flex items-center justify-center mb-5 elevation-1">
              <Receipt className="w-9 h-9 text-secondary-foreground" />
            </div>
            <h3 className="text-headline text-xl text-foreground mb-2">
              {hasActiveFilters ? "No matching bills" : "No transactions yet"}
            </h3>
            <p className="text-sm text-muted-foreground max-w-[260px] leading-relaxed">
              {hasActiveFilters
                ? "Try adjusting your filters to see more results"
                : "Tap the + button to add your first transaction and start splitting bills"}
            </p>
            {hasActiveFilters && (
              <button
                onClick={clearFilters}
                className="mt-4 px-4 py-2 bg-primary text-primary-foreground rounded-[12px] text-sm font-semibold"
              >
                Clear filters
              </button>
            )}
          </div>
        ) : (
          <div className="space-y-6">
            {Object.entries(groupedByDate).map(([date, dateTransactions], groupIndex) => (
              <section key={date}>
                {/* Month header + filter toggle */}
                <div className="flex items-center justify-between mb-3">
                  <h2 className="text-xs font-semibold text-muted-foreground tracking-wide">{date}</h2>
                  {groupIndex === 0 && (
                    <button
                      onClick={() => toggleFilters(!showFilters)}
                      aria-label="Toggle filters"
                      aria-expanded={showFilters}
                      className={`w-8 h-8 rounded-[8px] flex items-center justify-center transition-all
                                 touch-manipulation active:scale-[0.95]
                                 ${hasActiveFilters ? "bg-primary text-primary-foreground" : "bg-muted/60 text-muted-foreground hover:bg-muted"}`}
                    >
                      <SlidersHorizontal className="w-3.5 h-3.5" strokeWidth={2.5} />
                    </button>
                  )}
                </div>

                {/* Filter panel (first group only, when open) */}
                {groupIndex === 0 && showFilters && (
                  <div className="mb-3 rounded-[14px] border border-border/40 bg-muted/20 overflow-hidden">
                    <div className="flex items-center justify-between px-3 pt-2.5 pb-2.5">
                      <button onClick={() => toggleFilters(false)} className="w-9 h-9 rounded-full bg-card/90 flex items-center justify-center" aria-label="Close filters">
                        <svg className="w-4 h-4 text-foreground" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M15 19l-7-7 7-7" />
                        </svg>
                      </button>
                      <span className="text-xs font-semibold text-muted-foreground uppercase">Filters</span>
                      <button onClick={clearFilters} className="text-xs text-primary font-medium">Clear all</button>
                    </div>
                    <div className="h-px bg-border/30 mx-3" />
                    <div className="px-3 py-2">
                      <p className="text-[10px] font-semibold text-muted-foreground uppercase mb-1.5">Category</p>
                      <div className="flex gap-1.5 overflow-x-auto -mx-3 px-3 pb-1 scrollbar-hide">
                        {FILTER_CATEGORIES.map(cat => (
                          <button key={cat.id} onClick={() => toggleCategory(cat.id)} className={`px-3 py-1 rounded-full text-xs font-medium shrink-0 ${selectedCategories.includes(cat.id) ? "bg-primary text-primary-foreground" : "bg-background dark:bg-background/60 text-foreground border border-border/50"}`}>
                            {cat.label}
                          </button>
                        ))}
                      </div>
                    </div>
                    {people.length > 0 && (
                      <>
                        <div className="h-px bg-border/30 mx-3" />
                        <div className="px-3 py-2">
                          <p className="text-[10px] font-semibold text-muted-foreground uppercase mb-1.5">People</p>
                          <div className="flex gap-1.5 overflow-x-auto -mx-3 px-3 pb-1 scrollbar-hide">
                            {people.map(person => (
                              <button key={person.id} onClick={() => toggleParticipant(person.id)} className={`h-7 pl-1 pr-2.5 rounded-full text-xs font-medium flex items-center gap-1.5 shrink-0 ${selectedParticipants.includes(person.id) ? "bg-primary text-primary-foreground" : "bg-background dark:bg-background/60 text-foreground border border-border/50"}`}>
                                <span className={`w-5 h-5 rounded-full text-[10px] flex items-center justify-center font-semibold shrink-0 ${selectedParticipants.includes(person.id) ? "bg-white/25 text-primary-foreground" : "bg-primary/20 text-primary"}`}>
                                  {person.avatar}
                                </span>
                                {person.name.split(" ")[0]}
                              </button>
                            ))}
                          </div>
                        </div>
                      </>
                    )}
                  </div>
                )}

                {/* Active filter pills — shown when filters are collapsed but active */}
                {groupIndex === 0 && hasActiveFilters && !showFilters && (
                  <div className="mb-3 overflow-x-auto -mx-5 px-5 pb-1 scrollbar-hide">
                    <div className="flex items-center gap-2">
                      {selectedCategories.map(cat => {
                        const label = FILTER_CATEGORIES.find(c => c.id === cat)?.label
                        return (
                          <button
                            key={`cat-${cat}`}
                            onClick={() => toggleCategory(cat)}
                            className="flex items-center gap-1 px-2.5 py-1.5 bg-primary/10 dark:bg-primary/20 text-primary rounded-full text-xs font-medium touch-manipulation active:scale-[0.95] shrink-0"
                          >
                            {label}
                            <X className="w-3 h-3" strokeWidth={2.5} />
                          </button>
                        )
                      })}
                      {selectedParticipants.map(personId => {
                        const person = people.find(p => p.id === personId)
                        if (!person) return null
                        return (
                          <button
                            key={`person-${personId}`}
                            onClick={() => toggleParticipant(personId)}
                            className="h-7 pl-1.5 pr-2.5 rounded-full bg-primary/10 dark:bg-primary/20 text-primary flex items-center gap-1.5 text-xs font-medium touch-manipulation active:scale-[0.95] shrink-0"
                          >
                            <span className="w-4 h-4 rounded-full bg-primary/20 text-[9px] flex items-center justify-center font-semibold shrink-0">
                              {person.avatar}
                            </span>
                            {person.name.split(" ")[0]}
                            <X className="w-3 h-3" strokeWidth={2.5} />
                          </button>
                        )
                      })}
                      <button
                        onClick={clearFilters}
                        className="text-xs font-medium text-muted-foreground hover:text-foreground touch-manipulation active:scale-[0.95] shrink-0"
                      >
                        Clear all
                      </button>
                    </div>
                  </div>
                )}

                {/* Bills */}
                <div className="space-y-3">
                  {dateTransactions.map(transaction => (
                    <ExpenseCard
                      key={transaction.id}
                      transaction={transaction}
                      onEdit={() => handleEdit(transaction)}
                    />
                  ))}
                </div>
              </section>
            ))}
          </div>
        )}
      </div>

      <AddExpenseSheet
        open={showEditSheet}
        onOpenChange={handleCloseSheet}
        editingTransaction={editingTransaction}
      />
    </div>
  );
}
