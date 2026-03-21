"use client"

import { useMemo, useState } from "react"
import { ArrowRight, TrendingUp, TrendingDown, Check, Wallet, CircleDollarSign, Zap, Share2, ChevronDown, ChevronUp, Pencil } from "lucide-react"
import { useSplitStore } from "@/lib/store"
import { useCurrency } from "@/hooks/use-currency"
import { useCounterAnimation } from "@/hooks/use-counter-animation"

interface BalancesTabProps {
  searchQuery?: string
}

export function BalancesTab({ searchQuery = "" }: BalancesTabProps) {
  const { people, transactions, calculateBalances, calculateSettlements, recordSettlement } = useSplitStore()
  const { formatAmount, symbol } = useCurrency()
  const [showAllBalances, setShowAllBalances] = useState(false)
  const [settlingKey, setSettlingKey] = useState<string | null>(null)
  const [customAmount, setCustomAmount] = useState<string>("")
  const [showCustomAmount, setShowCustomAmount] = useState(false)

  const balances = calculateBalances()
  const settlements = calculateSettlements()
  
  // Animate total expenses counter
  const insights = useMemo(() => {
    const totalExpenses = transactions.reduce((sum, t) => sum + t.totalAmount, 0)
    const allSettled = settlements.length === 0 && transactions.length > 0
    const totalToSettle = settlements.reduce((sum, s) => sum + s.amount, 0)
    const avgPerPerson = people.length > 0 ? totalExpenses / people.length : 0
    return { totalExpenses, totalToSettle, allSettled, avgPerPerson, settlementCount: settlements.length }
  }, [transactions, settlements, people])
  
  const animatedTotalExpenses = useCounterAnimation(insights.totalExpenses, { duration: 800 })
  const animatedTotalToSettle = useCounterAnimation(insights.totalToSettle, { duration: 800 })
  const animatedAvgPerPerson = useCounterAnimation(insights.avgPerPerson, { duration: 800 })
    
  // Wrap formatAmount to handle absolute values
  const formatRupiah = (value: number): string => formatAmount(Math.abs(value))

  const getPersonById = (id: string) => people.find(p => p.id === id)

  // Calculate detailed insights
  const fullInsights = useMemo(() => {
    // Who owes the most
    const balancesArray = Array.from(balances.entries())
    const sortedByDebt = balancesArray
      .filter(([_, balance]) => balance < -0.01)
      .sort((a, b) => a[1] - b[1])
    const biggestDebtor = sortedByDebt[0] ? { 
      person: getPersonById(sortedByDebt[0][0]), 
      amount: Math.abs(sortedByDebt[0][1]) 
    } : null
    
    // Who is owed the most
    const sortedByCredit = balancesArray
      .filter(([_, balance]) => balance > 0.01)
      .sort((a, b) => b[1] - a[1])
    const biggestCreditor = sortedByCredit[0] ? { 
      person: getPersonById(sortedByCredit[0][0]), 
      amount: sortedByCredit[0][1] 
    } : null
    
    return {
      biggestDebtor,
      biggestCreditor,
      settlementCount: settlements.length,
      peopleInvolved: balancesArray.filter(([_, b]) => Math.abs(b) > 0.01).length,
    }
  }, [transactions, settlements, balances, people, getPersonById])
  
  const balancesArray = Array.from(balances.entries())
  const sortedBalances = balancesArray
    .map(([personId, balance]) => ({ personId, balance, person: getPersonById(personId) }))
    .filter(item => {
      if (!item.person) return false
      if (!searchQuery.trim()) return true
      return item.person.name.toLowerCase().includes(searchQuery.toLowerCase())
    })
    .sort((a, b) => {
      // Define balance status
      const aIsSettled = Math.abs(a.balance) < 0.01
      const bIsSettled = Math.abs(b.balance) < 0.01
      const aIsCreditor = a.balance > 0.01  // Gets money back
      const bIsCreditor = b.balance > 0.01
      const aIsDebtor = a.balance < -0.01   // Owes money
      const bIsDebtor = b.balance < -0.01
      
      // 1. Settled people go to bottom
      if (aIsSettled && !bIsSettled) return 1
      if (!aIsSettled && bIsSettled) return -1
      if (aIsSettled && bIsSettled) return 0
      
      // 2. Creditors (getting money back) come before debtors
      if (aIsCreditor && bIsDebtor) return -1
      if (aIsDebtor && bIsCreditor) return 1
      
      // 3. Among creditors: highest amount first (most likely to get back)
      if (aIsCreditor && bIsCreditor) return b.balance - a.balance
      
      // 4. Among debtors: highest debt first (owes the most)
      if (aIsDebtor && bIsDebtor) return a.balance - b.balance  // More negative = owes more
      
      return 0
    })
  
  // Sort settlements by amount (highest payments first for efficient resolution)
  const sortedSettlements = [...settlements].sort((a, b) => b.amount - a.amount)

  // Generate shareable settlement text
  const generateShareText = () => {
    if (insights.allSettled) {
      return "All settled up! No payments needed."
    }
    
    let text = "Settlement Summary\n"
    text += "==================\n\n"
    text += `Total Spent: ${formatRupiah(insights.totalExpenses)}\n`
    text += `Amount to Settle: ${formatRupiah(insights.totalToSettle)}\n\n`
    text += "Who Owes Whom:\n"
    text += "-----------------\n"
    
    settlements.forEach((settlement) => {
      const from = getPersonById(settlement.from)
      const to = getPersonById(settlement.to)
      if (from && to) {
        text += `${from.name} → ${to.name}: ${formatRupiah(settlement.amount)}\n`
      }
    })
    
    text += "\nGenerated by SplitBae"
    return text
  }

  const handleShare = async () => {
    const text = generateShareText()
    
    if (navigator.share) {
      try {
        await navigator.share({
          title: "Settlement Summary",
          text: text,
        })
      } catch {
        // User cancelled or share failed, fallback to clipboard
        await navigator.clipboard.writeText(text)
        alert("Settlement summary copied to clipboard!")
      }
    } else {
      // Fallback: copy to clipboard
      await navigator.clipboard.writeText(text)
      alert("Settlement summary copied to clipboard!")
    }
  }

  if (transactions.length === 0) {
    return (
      <div className="flex-1 flex flex-col px-5">
        {/* App Title */}
        <div className="pt-6 mb-5 flex items-start justify-between">
          <div>
            <h1 className="text-display text-3xl text-foreground">Balances</h1>
            <p className="text-sm text-muted-foreground mt-0.5">See who owes what</p>
          </div>
          <div className="w-24 shrink-0" />
        </div>
        
        <div className="flex-1 flex flex-col items-center justify-center py-10">
          <div className="w-20 h-20 rounded-[24px] bg-secondary flex items-center justify-center mb-5 elevation-1">
            <Wallet className="w-9 h-9 text-secondary-foreground" />
          </div>
          <h3 className="text-headline text-xl text-foreground mb-2">No transactions yet</h3>
          <p className="text-sm text-muted-foreground text-center max-w-[260px] leading-relaxed">
            Add transactions to see balances and who owes whom
          </p>
        </div>
      </div>
    )
  }

  return (
    <div className="flex-1 overflow-y-auto px-5 pb-28">
      {/* App Title — right padding reserves space for fixed header buttons */}
      <div className="pt-6 mb-5 flex items-start justify-between">
        <div>
          <h1 className="text-display text-3xl text-foreground">Balances</h1>
          <p className="text-sm text-muted-foreground mt-0.5">See who owes what</p>
        </div>
        <div className="w-24 shrink-0" />
      </div>
      
      {/* Hero Summary - Settlement Status */}
      <div className="pb-5">
        <div className={`relative overflow-hidden rounded-[28px] p-5 elevation-2
          ${insights.allSettled 
            ? "bg-gradient-to-br from-emerald-500 via-emerald-500 to-emerald-600" 
            : "bg-gradient-to-br from-amber-500 via-amber-500 to-orange-500"}`}>
          <div className="absolute -top-12 -right-12 w-40 h-40 bg-white/10 rounded-full blur-2xl" />
          <div className="absolute -bottom-8 -left-8 w-32 h-32 bg-white/5 rounded-full blur-xl" />
          
          <div className="relative">
            <div className="flex items-center gap-2 mb-1">
              {insights.allSettled ? (
                <Check className="w-4 h-4 text-white/80" strokeWidth={2.5} />
              ) : (
                <CircleDollarSign className="w-4 h-4 text-white/80" strokeWidth={2} />
              )}
              <p className="text-xs font-medium text-white/80 uppercase tracking-wide">
                {insights.allSettled ? "Status" : "To Settle"}
              </p>
            </div>
            <p className="text-display text-3xl text-white mb-1">
              {insights.allSettled ? "All Settled!" : formatRupiah(animatedTotalToSettle)}
            </p>
            <p className="text-sm text-white/70 mb-4">
              {insights.allSettled 
                ? "Everyone is even - no payments needed" 
                : `${fullInsights.settlementCount} payment${fullInsights.settlementCount !== 1 ? "s" : ""} needed`}
            </p>
            
            {/* Quick Stats Row */}
            <div className="flex gap-2">
              <div className="flex-1 bg-white/15 backdrop-blur-sm rounded-[14px] px-3 py-2.5">
                <p className="text-[10px] text-white/70 uppercase tracking-wide">Total Spent</p>
                <p className="text-sm font-bold text-white">{formatRupiah(animatedTotalExpenses)}</p>
              </div>
              <div className="flex-1 bg-white/15 backdrop-blur-sm rounded-[14px] px-3 py-2.5">
                <p className="text-[10px] text-white/70 uppercase tracking-wide">Avg/Person</p>
                <p className="text-sm font-bold text-white">{formatRupiah(animatedAvgPerPerson)}</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Quick Insight Cards */}
      {(fullInsights.biggestDebtor || fullInsights.biggestCreditor) && !insights.allSettled && (
        <div className="flex gap-2 mb-6">
          {fullInsights.biggestDebtor && (
            <div className="flex-1 bg-rose-50 dark:bg-rose-950/50 rounded-[18px] p-3.5 border border-rose-100 dark:border-rose-900/50">
              <div className="flex items-center gap-2.5">
                <div className="w-9 h-9 rounded-[12px] bg-rose-100 dark:bg-rose-900/60 flex items-center justify-center">
                  <TrendingDown className="w-4 h-4 text-rose-600 dark:text-rose-400" strokeWidth={2.5} />
                </div>
                <div className="min-w-0 flex-1">
                  <p className="text-[11px] text-rose-600/80 dark:text-rose-400/80 uppercase tracking-wide">Owes Most</p>
                  <p className="text-sm font-bold text-rose-700 dark:text-rose-300 truncate">{fullInsights.biggestDebtor.person?.name.split(" ")[0]}</p>
                </div>
              </div>
            </div>
          )}
          {fullInsights.biggestCreditor && (
            <div className="flex-1 bg-emerald-50 dark:bg-emerald-950/50 rounded-[18px] p-3.5 border border-emerald-100 dark:border-emerald-900/50">
              <div className="flex items-center gap-2.5">
                <div className="w-9 h-9 rounded-[12px] bg-emerald-100 dark:bg-emerald-900/60 flex items-center justify-center">
                  <TrendingUp className="w-4 h-4 text-emerald-600 dark:text-emerald-400" strokeWidth={2.5} />
                </div>
                <div className="min-w-0 flex-1">
                  <p className="text-[11px] text-emerald-600/80 dark:text-emerald-400/80 uppercase tracking-wide">Owed Most</p>
                  <p className="text-sm font-bold text-emerald-700 dark:text-emerald-300 truncate">{fullInsights.biggestCreditor.person?.name.split(" ")[0]}</p>
                </div>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Individual Balances - Collapsible when > 4 people */}
      <section className="mb-8">
        <div className="flex items-center justify-between mb-3 px-1">
          <h2 className="text-label text-muted-foreground">Individual Balances</h2>
          <span className="text-xs text-muted-foreground">{sortedBalances.length} people</span>
        </div>
        <div className="bg-card rounded-[24px] border border-border/40 overflow-hidden elevation-1">
          {sortedBalances.slice(0, showAllBalances ? sortedBalances.length : 4).map(({ personId, balance, person }, index, arr) => {
            if (!person) return null
            const isPositive = balance > 0.01
            const isNegative = balance < -0.01
            const isSettled = Math.abs(balance) < 0.01
            const isLast = index === arr.length - 1 && (showAllBalances || sortedBalances.length <= 4)

            return (
              <div 
                key={personId} 
                className={`p-4 flex items-center gap-4 ${!isLast ? "border-b border-border/40" : ""}`}
              >
                <div className={`w-11 h-11 rounded-[14px] flex items-center justify-center shrink-0
                  ${isPositive ? "bg-emerald-100 dark:bg-emerald-900/40" : isNegative ? "bg-rose-100 dark:bg-rose-900/40" : "bg-muted"}`}>
                  <span className={`text-sm font-bold ${isPositive ? "text-emerald-600 dark:text-emerald-400" : isNegative ? "text-rose-600 dark:text-rose-400" : "text-muted-foreground"}`}>
                    {person.avatar}
                  </span>
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-[15px] font-semibold text-foreground truncate">{person.name}</p>
                  <p className={`text-xs font-medium ${isPositive ? "text-emerald-600 dark:text-emerald-400" : isNegative ? "text-rose-600 dark:text-rose-400" : "text-muted-foreground"}`}>
                    {isPositive ? "Gets back" : isNegative ? "Owes" : "Settled up"}
                  </p>
                </div>
                <div className="flex items-center gap-2 shrink-0">
                  <span className={`text-base font-bold ${isPositive ? "text-emerald-600 dark:text-emerald-400" : isNegative ? "text-rose-600 dark:text-rose-400" : "text-muted-foreground"}`}>
                    {isSettled ? "Rp 0" : formatRupiah(balance)}
                  </span>
                </div>
              </div>
            )
          })}
          
          {/* Show More / Show Less toggle */}
          {sortedBalances.length > 4 && (
            <button
              onClick={() => setShowAllBalances(!showAllBalances)}
              className="w-full p-3.5 flex items-center justify-center gap-2 
                         border-t border-border/40 text-sm font-medium text-primary
                         hover:bg-muted/30 transition-colors touch-manipulation active:opacity-70"
            >
              {showAllBalances ? (
                <>
                  <ChevronUp className="w-4 h-4" />
                  Show Less
                </>
              ) : (
                <>
                  <ChevronDown className="w-4 h-4" />
                  Show {sortedBalances.length - 4} More
                </>
              )}
            </button>
          )}
        </div>
      </section>

      {/* Settlements */}
      {!insights.allSettled && settlements.length > 0 && (
        <section id="settle-section">
          <div className="flex items-center justify-between mb-3 px-1">
            <h2 className="text-label text-muted-foreground">Settle Up</h2>
            <div className="flex items-center gap-3">
              <div className="flex items-center gap-1.5 text-xs text-primary">
                <Zap className="w-3.5 h-3.5" strokeWidth={2.5} />
                <span className="font-medium">Optimized</span>
              </div>
            </div>
          </div>
          
          <div className="space-y-3">
            {sortedSettlements.map((settlement) => {
              const from = getPersonById(settlement.from)
              const to = getPersonById(settlement.to)
              if (!from || !to) return null
              
              // Create a unique key for this settlement
              const settlementKey = `${settlement.from}-${settlement.to}-${settlement.amount}`

              return (
                <div 
                  key={settlementKey}
                  className="bg-card rounded-[24px] border border-border/40 p-4 elevation-1"
                >
                  <div className="flex items-center gap-3">
                    {/* From */}
                    <div className="flex items-center gap-2.5 flex-1 min-w-0">
                      <div className="w-10 h-10 rounded-[12px] bg-rose-100 dark:bg-rose-900/60 flex items-center justify-center shrink-0">
                        <span className="text-sm font-bold text-rose-600 dark:text-rose-400">{from.avatar}</span>
                      </div>
                      <div className="min-w-0">
                        <p className="text-sm font-semibold text-foreground truncate">{from.name}</p>
                        <p className="text-[11px] text-rose-500 font-medium">pays</p>
                      </div>
                    </div>

                    {/* Arrow */}
                    <div className="w-9 h-9 rounded-full bg-muted flex items-center justify-center shrink-0">
                      <ArrowRight className="w-4 h-4 text-muted-foreground" strokeWidth={2.5} />
                    </div>

                    {/* To */}
                    <div className="flex items-center gap-2.5 flex-1 min-w-0 justify-end">
                      <div className="min-w-0 text-right">
                        <p className="text-sm font-semibold text-foreground truncate">{to.name}</p>
                        <p className="text-[11px] text-emerald-500 font-medium">receives</p>
                      </div>
                      <div className="w-10 h-10 rounded-[12px] bg-emerald-100 dark:bg-emerald-900/60 flex items-center justify-center shrink-0">
                        <span className="text-sm font-bold text-emerald-600 dark:text-emerald-400">{to.avatar}</span>
                      </div>
                    </div>
                  </div>

                  {/* Amount and Mark as Paid */}
                  <div className="mt-3 pt-3 border-t border-border/40">
                    <div className="flex items-center justify-between mb-3">
                      <span className="text-sm text-muted-foreground">Amount</span>
                      <span className="text-lg font-bold text-primary">
                        {formatRupiah(settlement.amount)}
                      </span>
                    </div>
                    
                    {/* Mark as Paid / Custom Amount */}
                    {settlingKey === settlementKey ? (
                      <div className="space-y-3">
                        {/* Custom Amount Toggle */}
                        <div className="flex items-center justify-between">
                          <button
                            onClick={() => {
                              setShowCustomAmount(!showCustomAmount)
                              if (!showCustomAmount) {
                                setCustomAmount(settlement.amount.toString())
                              }
                            }}
                            className="flex items-center gap-1.5 text-xs font-medium text-primary"
                          >
                            <Pencil className="w-3 h-3" />
                            {showCustomAmount ? "Use full amount" : "Partial payment"}
                          </button>
                          {showCustomAmount && (
                            <span className="text-xs text-muted-foreground">
                              of {formatRupiah(settlement.amount)}
                            </span>
                          )}
                        </div>
                        
                        {/* Custom Amount Input */}
                        {showCustomAmount && (
                          <div className="relative">
                            <span className="absolute left-3.5 top-1/2 -translate-y-1/2 text-sm text-muted-foreground">
                              {symbol}
                            </span>
                            <input
                              type="number"
                              value={customAmount}
                              onChange={(e) => setCustomAmount(e.target.value)}
                              placeholder="Enter amount"
                              min="0"
                              max={settlement.amount}
                              step="0.01"
                              className="w-full h-11 pl-10 pr-3 bg-input rounded-[14px] text-sm text-foreground
                                         border border-border focus:outline-none focus:ring-2 focus:ring-primary/30"
                            />
                          </div>
                        )}
                        
                        {/* Action Buttons */}
                        <div className="flex gap-2">
                          <button
                            onClick={() => {
                              setSettlingKey(null)
                              setShowCustomAmount(false)
                              setCustomAmount("")
                            }}
                            className="flex-1 h-11 rounded-[14px] bg-muted text-muted-foreground
                                       text-sm font-semibold touch-manipulation active:scale-[0.98] transition-all"
                          >
                            Cancel
                          </button>
                          <button
                            onClick={() => {
                              const amount = showCustomAmount 
                                ? Math.min(parseFloat(customAmount) || 0, settlement.amount)
                                : settlement.amount
                              if (amount > 0) {
                                recordSettlement(settlement.from, settlement.to, amount)
                              }
                              setSettlingKey(null)
                              setShowCustomAmount(false)
                              setCustomAmount("")
                            }}
                            disabled={showCustomAmount && (!customAmount || parseFloat(customAmount) <= 0)}
                            className="flex-1 h-11 rounded-[14px] bg-emerald-500 text-white
                                       text-sm font-semibold touch-manipulation active:scale-[0.98] transition-all
                                       flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
                          >
                            <Check className="w-4 h-4" strokeWidth={2.5} />
                            {showCustomAmount ? "Pay Partial" : "Pay Full"}
                          </button>
                        </div>
                      </div>
                    ) : (
                      <button
                        onClick={() => {
                          setSettlingKey(settlementKey)
                          setShowCustomAmount(false)
                          setCustomAmount("")
                        }}
                        className="w-full h-11 rounded-[14px] bg-primary/10 text-primary
                                   text-sm font-semibold touch-manipulation active:scale-[0.98] transition-all
                                   flex items-center justify-center gap-2"
                      >
                        <Check className="w-4 h-4" strokeWidth={2.5} />
                        Mark as Paid
                      </button>
                    )}
                  </div>
                </div>
              )
            })}
          </div>
          
          {/* Share Settlements Button */}
          <button
            onClick={handleShare}
            className="w-full mt-5 h-14 bg-primary text-primary-foreground rounded-[20px] 
                       flex items-center justify-center gap-2.5 font-semibold text-[15px]
                       touch-manipulation active:scale-[0.98] active:opacity-90 
                       transition-all duration-200 elevation-1"
          >
            <Share2 className="w-5 h-5" />
            Share Settlements
          </button>
        </section>
      )}

      {/* All Settled State */}
      {insights.allSettled && (
        <section>
          <h2 className="text-label text-muted-foreground mb-3 px-1">Status</h2>
          <div className="bg-gradient-to-br from-emerald-50 to-emerald-100/50 dark:from-emerald-950/50 dark:to-emerald-900/30 rounded-[24px] p-6 text-center elevation-1 border border-emerald-100 dark:border-emerald-800/50">
            <div className="w-14 h-14 rounded-full bg-emerald-200/70 dark:bg-emerald-800/50 flex items-center justify-center mx-auto mb-3">
              <Check className="w-7 h-7 text-emerald-600 dark:text-emerald-400" strokeWidth={2.5} />
            </div>
            <p className="text-headline text-lg text-emerald-700 dark:text-emerald-300">Everyone is settled up!</p>
            <p className="text-sm text-emerald-600/80 dark:text-emerald-400/70 mt-1">No payments needed</p>
          </div>
        </section>
      )}
    </div>
  )
}
