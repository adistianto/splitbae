"use client"

import { useState, useMemo } from "react"
import { User, Bell, Palette, HelpCircle, Info, ChevronRight, Moon, Sun, Trash2, TrendingUp, Calendar, Utensils, Car, Home, Music, ShoppingBag, Zap, MoreHorizontal, Clock } from "lucide-react"
import { useSplitStore } from "@/lib/store"
import { useCurrency } from "@/hooks/use-currency"

export function SettingsTab() {
  const { people, transactions, calculateBalances } = useSplitStore()
  const { formatAmount } = useCurrency()
  const [darkMode, setDarkMode] = useState(false)

  // Calculate activity insights
  const insights = useMemo(() => {
    const totalExpenses = transactions.reduce((sum, t) => sum + t.totalAmount, 0)
    
    // Category breakdown
    const categoryTotals = transactions.reduce((acc, t) => {
      acc[t.category] = (acc[t.category] || 0) + t.totalAmount
      return acc
    }, {} as Record<string, number>)
    
    const sortedCategories = Object.entries(categoryTotals)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 3)
    
    // Time analysis
    const now = new Date()
    const thisMonth = transactions.filter(t => {
      const date = new Date(t.createdAt)
      return date.getMonth() === now.getMonth() && date.getFullYear() === now.getFullYear()
    })
    const thisMonthTotal = thisMonth.reduce((sum, t) => sum + t.totalAmount, 0)
    
    // Average transaction size
    const avgTransaction = transactions.length > 0 ? totalExpenses / transactions.length : 0
    
    // Most frequent split partner
    const partnerCount = transactions.reduce((acc, t) => {
      t.participants.forEach(p => {
        acc[p] = (acc[p] || 0) + 1
      })
      return acc
    }, {} as Record<string, number>)
    const topPartner = Object.entries(partnerCount)
      .sort((a, b) => b[1] - a[1])[0]
    const topPartnerPerson = topPartner ? people.find(p => p.id === topPartner[0]) : null
    
    // Your balance
    const balances = calculateBalances()
    const myBalance = balances.get("1") || 0
    
    return {
      totalExpenses,
      thisMonthTotal,
      avgTransaction,
      topCategories: sortedCategories,
      topPartner: topPartnerPerson,
      myBalance,
      transactionCount: transactions.length,
      peopleCount: people.length,
    }
  }, [transactions, people, calculateBalances])

const formatRupiah = (value: number) => formatAmount(Math.abs(value))

  const categoryIcons: Record<string, typeof Utensils> = {
    food: Utensils,
    transport: Car,
    accommodation: Home,
    entertainment: Music,
    shopping: ShoppingBag,
    utilities: Zap,
    other: MoreHorizontal,
  }

  const categoryColors: Record<string, string> = {
    food: "bg-orange-100 dark:bg-orange-900/60 text-orange-600 dark:text-orange-400",
    transport: "bg-blue-100 dark:bg-blue-900/60 text-blue-600 dark:text-blue-400",
    accommodation: "bg-violet-100 dark:bg-violet-900/60 text-violet-600 dark:text-violet-400",
    entertainment: "bg-pink-100 dark:bg-pink-900/60 text-pink-600 dark:text-pink-400",
    shopping: "bg-emerald-100 dark:bg-emerald-900/60 text-emerald-600 dark:text-emerald-400",
    utilities: "bg-amber-100 dark:bg-amber-900/60 text-amber-600 dark:text-amber-400",
    other: "bg-slate-100 dark:bg-slate-800/60 text-slate-600 dark:text-slate-400",
  }

  const settingsSections = [
    {
      title: "Account",
      items: [
        { id: "profile", label: "Profile", icon: User, description: "Manage your profile" },
        { id: "notifications", label: "Notifications", icon: Bell, description: "Push notifications" },
      ]
    },
    {
      title: "Preferences",
      items: [
        { id: "appearance", label: "Appearance", icon: Palette, description: "Theme and colors" },
      ]
    },
    {
      title: "Support",
      items: [
        { id: "help", label: "Help Center", icon: HelpCircle, description: "FAQs and guides" },
        { id: "about", label: "About", icon: Info, description: "Version 1.0.0" },
      ]
    }
  ]

  return (
    <div className="flex-1 flex flex-col">
      {/* Header */}
      <div className="px-5 pt-5 pb-4">
        <h2 className="text-headline text-2xl text-foreground">Settings</h2>
        <p className="text-sm text-muted-foreground mt-1">Manage your preferences</p>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto px-4 pb-32">
        {/* Activity Summary Card */}
        <div className="bg-gradient-to-br from-primary/10 via-primary/5 to-transparent rounded-[24px] p-5 mb-4 border border-primary/10">
          <div className="flex items-center gap-2 mb-4">
            <TrendingUp className="w-4 h-4 text-primary" />
            <p className="text-label text-muted-foreground">Your Activity</p>
          </div>
          
          {/* Main Stats */}
          <div className="grid grid-cols-2 gap-3 mb-4">
            <div className="bg-white/60 rounded-[16px] p-3.5">
              <p className="text-[11px] text-muted-foreground uppercase tracking-wide mb-1">Total Spent</p>
              <p className="text-xl font-bold text-foreground">{formatRupiah(insights.totalExpenses)}</p>
            </div>
            <div className="bg-white/60 rounded-[16px] p-3.5">
              <p className="text-[11px] text-muted-foreground uppercase tracking-wide mb-1">This Month</p>
              <p className="text-xl font-bold text-foreground">{formatRupiah(insights.thisMonthTotal)}</p>
            </div>
          </div>
          
          {/* Secondary Stats */}
          <div className="flex gap-2">
            <div className="flex-1 flex items-center gap-2.5 bg-white/40 rounded-[12px] px-3 py-2.5">
              <Calendar className="w-4 h-4 text-violet-500" />
              <div>
                <p className="text-sm font-bold text-foreground">{insights.transactionCount}</p>
                <p className="text-[10px] text-muted-foreground">Transactions</p>
              </div>
            </div>
            <div className="flex-1 flex items-center gap-2.5 bg-white/40 rounded-[12px] px-3 py-2.5">
              <User className="w-4 h-4 text-amber-500" />
              <div>
                <p className="text-sm font-bold text-foreground">{insights.peopleCount}</p>
                <p className="text-[10px] text-muted-foreground">Friends</p>
              </div>
            </div>
            <div className="flex-1 flex items-center gap-2.5 bg-white/40 rounded-[12px] px-3 py-2.5">
              <Clock className="w-4 h-4 text-emerald-500" />
              <div>
                <p className="text-sm font-bold text-foreground truncate">{formatRupiah(insights.avgTransaction).replace("Rp ", "")}</p>
                <p className="text-[10px] text-muted-foreground">Avg/Txn</p>
              </div>
            </div>
          </div>
        </div>

        {/* Top Categories */}
        {insights.topCategories.length > 0 && (
          <div className="bg-card rounded-[20px] border border-border/50 p-4 mb-4">
            <p className="text-label text-muted-foreground mb-3">Top Categories</p>
            <div className="space-y-2.5">
              {insights.topCategories.map(([category, amount]) => {
                const Icon = categoryIcons[category] || MoreHorizontal
                const colorClass = categoryColors[category] || categoryColors.other
                const percentage = Math.round((amount / insights.totalExpenses) * 100)
                
                return (
                  <div key={category} className="flex items-center gap-3">
                    <div className={`w-9 h-9 rounded-[10px] flex items-center justify-center ${colorClass}`}>
                      <Icon className="w-4 h-4" strokeWidth={2} />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between mb-1">
                        <p className="text-sm font-semibold text-foreground capitalize">{category}</p>
                        <p className="text-sm font-bold text-foreground">{formatRupiah(amount)}</p>
                      </div>
                      <div className="h-1.5 bg-muted rounded-full overflow-hidden">
                        <div 
                          className={`h-full rounded-full ${colorClass.includes("orange") ? "bg-orange-500" : colorClass.includes("blue") ? "bg-blue-500" : colorClass.includes("violet") ? "bg-violet-500" : colorClass.includes("pink") ? "bg-pink-500" : colorClass.includes("emerald") ? "bg-emerald-500" : colorClass.includes("amber") ? "bg-amber-500" : "bg-slate-500"}`}
                          style={{ width: `${percentage}%` }}
                        />
                      </div>
                    </div>
                    <span className="text-xs text-muted-foreground w-10 text-right">{percentage}%</span>
                  </div>
                )
              })}
            </div>
          </div>
        )}

        {/* Top Split Partner */}
        {insights.topPartner && (
          <div className="bg-card rounded-[20px] border border-border/50 p-4 mb-4">
            <p className="text-label text-muted-foreground mb-3">Most Frequent Partner</p>
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 rounded-[14px] bg-primary/10 flex items-center justify-center">
                <span className="text-sm font-bold text-primary">{insights.topPartner.avatar}</span>
              </div>
              <div>
                <p className="text-[15px] font-semibold text-foreground">{insights.topPartner.name}</p>
                <p className="text-sm text-muted-foreground">{insights.topPartner.transactionCount} transactions together</p>
              </div>
            </div>
          </div>
        )}

        {/* Dark Mode Toggle */}
        <div className="bg-card rounded-[20px] border border-border/50 p-4 mb-4">
          <button 
            onClick={() => setDarkMode(!darkMode)}
            className="w-full flex items-center justify-between"
          >
            <div className="flex items-center gap-4">
              <span className="w-11 h-11 rounded-[14px] bg-amber-100 flex items-center justify-center">
                {darkMode ? (
                  <Moon className="w-5 h-5 text-amber-600" strokeWidth={2} />
                ) : (
                  <Sun className="w-5 h-5 text-amber-600" strokeWidth={2} />
                )}
              </span>
              <div className="text-left">
                <p className="text-[15px] font-semibold text-foreground">Dark Mode</p>
                <p className="text-sm text-muted-foreground">{darkMode ? "On" : "Off"}</p>
              </div>
            </div>
            <div className={`w-12 h-7 rounded-full transition-all duration-300 relative
              ${darkMode ? "bg-primary" : "bg-muted"}`}
            >
              <div className={`absolute top-1 w-5 h-5 rounded-full bg-white shadow-sm transition-all duration-300
                ${darkMode ? "left-6" : "left-1"}`} 
              />
            </div>
          </button>
        </div>

        {/* Settings Sections */}
        {settingsSections.map((section) => (
          <div key={section.title} className="mb-4">
            <p className="text-label text-muted-foreground mb-2 px-1">{section.title}</p>
            <div className="bg-card rounded-[20px] border border-border/50 divide-y divide-border/30">
              {section.items.map((item) => {
                const Icon = item.icon
                return (
                  <button
                    key={item.id}
                    className="w-full flex items-center justify-between p-4 touch-manipulation
                              hover:bg-muted/30 active:bg-muted/50 transition-colors first:rounded-t-[20px] last:rounded-b-[20px]"
                  >
                    <div className="flex items-center gap-4">
                      <span className="w-11 h-11 rounded-[14px] bg-muted flex items-center justify-center">
                        <Icon className="w-5 h-5 text-muted-foreground" strokeWidth={2} />
                      </span>
                      <div className="text-left">
                        <p className="text-[15px] font-semibold text-foreground">{item.label}</p>
                        <p className="text-sm text-muted-foreground">{item.description}</p>
                      </div>
                    </div>
                    <ChevronRight className="w-5 h-5 text-muted-foreground" />
                  </button>
                )
              })}
            </div>
          </div>
        ))}

        {/* Clear Data */}
        <div className="mt-6">
          <button className="w-full flex items-center justify-center gap-2 p-4 rounded-[20px] 
                            bg-destructive/10 text-destructive touch-manipulation
                            hover:bg-destructive/15 active:bg-destructive/20 transition-colors">
            <Trash2 className="w-5 h-5" strokeWidth={2} />
            <span className="font-semibold">Clear All Data</span>
          </button>
        </div>

        {/* Version Info */}
        <p className="text-center text-sm text-muted-foreground mt-8">
          SplitBae v1.0.0
        </p>
      </div>
    </div>
  )
}
