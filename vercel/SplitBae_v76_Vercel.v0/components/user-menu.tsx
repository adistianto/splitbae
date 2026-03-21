"use client"

import { useState, useMemo } from "react"
import { 
  User, Bell, Moon, Sun, HelpCircle, Info, ChevronRight, Trash2, 
  CalendarDays, Users, PiggyBank, Sparkles, ChevronDown,
  Download, Upload, Star, Mail, DollarSign, UserCircle, FileText
} from "lucide-react"
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetDescription } from "@/components/ui/sheet"
import { useSplitStore } from "@/lib/store"
import { useTheme } from "@/hooks/use-theme"
import { useCurrencyStore, useCurrency, CURRENCIES, type CurrencyCode } from "@/hooks/use-currency"

interface UserMenuProps {
  open: boolean
  onOpenChange: (open: boolean) => void
}

// Format preview for currency picker
const CURRENCY_LIST = Object.values(CURRENCIES).map(c => ({
  code: c.code,
  name: c.name,
  format: new Intl.NumberFormat(c.locale, { 
    style: "currency", 
    currency: c.code, 
    minimumFractionDigits: 0 
  }).format(1234567),
}))

const REPORT_TYPES = [
  { id: "full", name: "Full Report", desc: "All transactions with details" },
  { id: "summary", name: "Summary", desc: "Totals and balances only" },
  { id: "settlements", name: "Settlements Only", desc: "Who owes whom" },
]

export function UserMenu({ open, onOpenChange }: UserMenuProps) {
  const { people, transactions, clearAllData, importData } = useSplitStore()
  const { isDark, toggle: toggleDark } = useTheme()
  const { currency, showFractional, setCurrency, setShowFractional } = useCurrencyStore()
  const { formatAmount } = useCurrency()
  const [showClearConfirm, setShowClearConfirm] = useState(false)
  
  // Settings states
  const [defaultPerson, setDefaultPerson] = useState(people[0]?.id || "")
  const [reportType, setReportType] = useState("full")
  
  // Dropdown states
  const [showCurrencyPicker, setShowCurrencyPicker] = useState(false)
  const [showPersonPicker, setShowPersonPicker] = useState(false)
  const [showReportPicker, setShowReportPicker] = useState(false)

  // Calculate unique stats for settings
  const stats = useMemo(() => {
    const sortedDates = transactions
      .map(t => new Date(t.createdAt).getTime())
      .sort((a, b) => a - b)
    const userSince = sortedDates.length > 0 
      ? new Date(sortedDates[0]) 
      : new Date()
    
    const totalSpent = transactions.reduce((sum, t) => sum + t.totalAmount, 0)
    const avgParticipants = transactions.length > 0
      ? transactions.reduce((sum, t) => sum + t.participants.length, 0) / transactions.length
      : 1
    const yourShare = avgParticipants > 1 ? totalSpent / avgParticipants : totalSpent
    const totalSaved = totalSpent - yourShare
    
    const partnerCount: Record<string, number> = {}
    transactions.forEach(t => {
      t.participants.forEach(pId => {
        if (pId !== "1") {
          partnerCount[pId] = (partnerCount[pId] || 0) + 1
        }
      })
    })
    const topPartner = Object.entries(partnerCount).sort((a, b) => b[1] - a[1])[0]
    const topPartnerPerson = topPartner ? people.find(p => p.id === topPartner[0]) : null
    
    return { userSince, totalSaved, topPartnerPerson, friendCount: people.length, billCount: transactions.length }
  }, [transactions, people])

const formatRupiah = formatAmount

  const handleClearData = () => {
    if (showClearConfirm) {
      clearAllData?.()
      setShowClearConfirm(false)
      onOpenChange(false)
    } else {
      setShowClearConfirm(true)
    }
  }

  const handleExport = () => {
    const data = {
      version: "1.0.0",
      exportedAt: new Date().toISOString(),
      people,
      transactions: transactions.map(t => ({
        ...t,
        createdAt: t.createdAt.toISOString(),
      })),
    }
    const blob = new Blob([JSON.stringify(data, null, 2)], { type: "application/json" })
    const url = URL.createObjectURL(blob)
    const a = document.createElement("a")
    a.href = url
    a.download = `splitbae-backup-${new Date().toISOString().split("T")[0]}.json`
    a.click()
    URL.revokeObjectURL(url)
  }

  const handleImport = () => {
    const input = document.createElement("input")
    input.type = "file"
    input.accept = ".json"
    input.onchange = async (e) => {
      const file = (e.target as HTMLInputElement).files?.[0]
      if (!file) return
      try {
        const text = await file.text()
        const data = JSON.parse(text)
        if (data.version && data.people && data.transactions) {
          importData({ people: data.people, transactions: data.transactions })
          alert("Backup imported successfully!")
          onOpenChange(false)
        } else {
          alert("Invalid backup file format")
        }
      } catch {
        alert("Failed to read backup file")
      }
    }
    input.click()
  }

  const selectedCurrency = CURRENCY_LIST.find(c => c.code === currency) || CURRENCY_LIST[0]
  const selectedReport = REPORT_TYPES.find(r => r.id === reportType) || REPORT_TYPES[0]
  const selectedPerson = people.find(p => p.id === defaultPerson)

  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent side="right" className="w-[340px] p-0 rounded-l-[32px] border-l-0">
        {/* Profile Header */}
        <SheetHeader className="p-6 pb-4">
          <div className="flex flex-col items-center text-center">
            <div className="relative mb-3">
              <div className="w-20 h-20 rounded-full p-[3px] bg-gradient-to-br from-primary via-emerald-400 to-amber-400">
                <div className="w-full h-full rounded-full bg-card flex items-center justify-center">
                  <User className="w-9 h-9 text-foreground/70" strokeWidth={1.5} />
                </div>
              </div>
            </div>
            <SheetTitle className="text-xl font-semibold text-foreground">Settings</SheetTitle>
            <SheetDescription className="text-sm text-muted-foreground mt-1">
              Manage your preferences
            </SheetDescription>
          </div>
        </SheetHeader>
        
        <div className="px-4 pb-24 space-y-3 overflow-y-auto max-h-[calc(100vh-200px)]">
          {/* Primary Stats Card - Large Box Style */}
          <div className="relative overflow-hidden bg-gradient-to-br from-primary via-primary to-primary/80 
                          rounded-[24px] p-5 elevation-1">
            <div className="absolute -top-10 -right-10 w-32 h-32 bg-white/10 rounded-full blur-2xl" />
            <div className="absolute -bottom-6 -left-6 w-24 h-24 bg-white/5 rounded-full blur-xl" />
            
            <div className="relative">
              <div className="flex items-center gap-2 mb-1">
                <Sparkles className="w-4 h-4 text-primary-foreground/70" />
                <p className="text-xs font-medium text-primary-foreground/70 uppercase tracking-wide">Your Journey</p>
              </div>
              <p className="text-sm text-primary-foreground/80 mb-4">
                Member since {stats.userSince.toLocaleDateString("en-US", { month: "long", year: "numeric" })}
              </p>
              
              {/* Stats Row */}
              <div className="flex gap-2">
                <div className="flex-1 bg-white/15 backdrop-blur-sm rounded-[14px] px-3 py-2.5 text-center">
                  <p className="text-xl font-bold text-primary-foreground">{stats.billCount}</p>
                  <p className="text-[10px] text-primary-foreground/70 uppercase tracking-wide">Bills</p>
                </div>
                <div className="flex-1 bg-white/15 backdrop-blur-sm rounded-[14px] px-3 py-2.5 text-center">
                  <p className="text-xl font-bold text-primary-foreground">{stats.friendCount}</p>
                  <p className="text-[10px] text-primary-foreground/70 uppercase tracking-wide">Friends</p>
                </div>
              </div>
            </div>
          </div>
          
          {/* Secondary Stats Chips */}
          <div className="flex gap-2 overflow-x-auto pb-1 -mx-4 px-4 scrollbar-hide">
            <div className="flex items-center gap-2 px-4 py-2.5 bg-emerald-100 dark:bg-emerald-950/50 rounded-full shrink-0">
              <PiggyBank className="w-4 h-4 text-emerald-600 dark:text-emerald-400" strokeWidth={2.5} />
              <span className="text-sm font-semibold text-emerald-700 dark:text-emerald-300">Saved {formatRupiah(stats.totalSaved)}</span>
            </div>
            {stats.topPartnerPerson && (
              <div className="flex items-center gap-2 px-4 py-2.5 bg-amber-100 dark:bg-amber-950/50 rounded-full shrink-0">
                <Users className="w-4 h-4 text-amber-600 dark:text-amber-400" strokeWidth={2.5} />
                <span className="text-sm font-semibold text-amber-700 dark:text-amber-300">Top: {stats.topPartnerPerson.name.split(" ")[0]}</span>
              </div>
            )}
          </div>

          {/* Currency Settings */}
          <div className="bg-card rounded-[20px] border border-border/30 overflow-hidden">
            <div className="px-4 py-2.5 bg-muted/30">
              <p className="text-xs font-medium text-muted-foreground uppercase tracking-wide">Currency</p>
            </div>
            
            <button 
              onClick={() => setShowCurrencyPicker(!showCurrencyPicker)}
              className="w-full flex items-center justify-between p-4 hover:bg-muted/30 active:bg-muted/50 transition-colors"
            >
              <div className="flex items-center gap-3">
                <DollarSign className="w-5 h-5 text-muted-foreground" />
                <span className="text-[15px] text-foreground">{selectedCurrency.name}</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="text-sm text-muted-foreground">{selectedCurrency.format}</span>
                <ChevronDown className={`w-4 h-4 text-muted-foreground transition-transform ${showCurrencyPicker ? "rotate-180" : ""}`} />
              </div>
            </button>
            
            {showCurrencyPicker && (
              <div className="border-t border-border/20">
                {CURRENCY_LIST.map(c => (
                  <button
                    key={c.code}
                    onClick={() => { setCurrency(c.code as CurrencyCode); setShowCurrencyPicker(false) }}
                    className={`w-full flex items-center justify-between px-4 py-3 hover:bg-muted/30
                      ${c.code === currency ? "bg-primary/5" : ""}`}
                  >
                    <span className="text-sm text-foreground">{c.name}</span>
                    <span className="text-xs text-muted-foreground">{c.format}</span>
                  </button>
                ))}
              </div>
            )}
            
            <div className="h-px bg-border/20 mx-4" />
            
            <button 
              onClick={() => setShowFractional(!showFractional)}
              className="w-full flex items-center justify-between p-4 hover:bg-muted/30"
            >
              <span className="text-[15px] text-foreground">Show fractional</span>
              <div className={`w-12 h-7 rounded-full transition-all duration-300 relative p-0.5
                ${showFractional ? "bg-primary" : "bg-muted"}`}
              >
                <div className={`w-6 h-6 rounded-full bg-white shadow-sm transition-all duration-300
                  ${showFractional ? "translate-x-5" : "translate-x-0"}`} />
              </div>
            </button>
          </div>

          {/* Default Person */}
          <div className="bg-card rounded-[20px] border border-border/30 overflow-hidden">
            <div className="px-4 py-2.5 bg-muted/30">
              <p className="text-xs font-medium text-muted-foreground uppercase tracking-wide">Default Person</p>
            </div>
            
            <button 
              onClick={() => setShowPersonPicker(!showPersonPicker)}
              className="w-full flex items-center justify-between p-4 hover:bg-muted/30"
            >
              <div className="flex items-center gap-3">
                <UserCircle className="w-5 h-5 text-muted-foreground" />
                <span className="text-[15px] text-foreground">{selectedPerson?.name || "Select person"}</span>
              </div>
              <ChevronDown className={`w-4 h-4 text-muted-foreground transition-transform ${showPersonPicker ? "rotate-180" : ""}`} />
            </button>
            
            {showPersonPicker && (
              <div className="border-t border-border/20 max-h-40 overflow-y-auto">
                {people.map(p => (
                  <button
                    key={p.id}
                    onClick={() => { setDefaultPerson(p.id); setShowPersonPicker(false) }}
                    className={`w-full flex items-center gap-3 px-4 py-3 hover:bg-muted/30
                      ${p.id === defaultPerson ? "bg-primary/5" : ""}`}
                  >
                    <div className="w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium text-white"
                         style={{ backgroundColor: p.color }}>
                      {p.avatar}
                    </div>
                    <span className="text-sm text-foreground">{p.name}</span>
                  </button>
                ))}
              </div>
            )}
          </div>

          {/* Report Type */}
          <div className="bg-card rounded-[20px] border border-border/30 overflow-hidden">
            <div className="px-4 py-2.5 bg-muted/30">
              <p className="text-xs font-medium text-muted-foreground uppercase tracking-wide">Report Type</p>
            </div>
            
            <button 
              onClick={() => setShowReportPicker(!showReportPicker)}
              className="w-full flex items-center justify-between p-4 hover:bg-muted/30"
            >
              <div className="flex items-center gap-3">
                <FileText className="w-5 h-5 text-muted-foreground" />
                <span className="text-[15px] text-foreground">{selectedReport.name}</span>
              </div>
              <ChevronDown className={`w-4 h-4 text-muted-foreground transition-transform ${showReportPicker ? "rotate-180" : ""}`} />
            </button>
            
            {showReportPicker && (
              <div className="border-t border-border/20">
                {REPORT_TYPES.map(r => (
                  <button
                    key={r.id}
                    onClick={() => { setReportType(r.id); setShowReportPicker(false) }}
                    className={`w-full flex flex-col items-start px-4 py-3 hover:bg-muted/30
                      ${r.id === reportType ? "bg-primary/5" : ""}`}
                  >
                    <span className="text-sm font-medium text-foreground">{r.name}</span>
                    <span className="text-xs text-muted-foreground">{r.desc}</span>
                  </button>
                ))}
              </div>
            )}
          </div>

          {/* Backup Section */}
          <div className="bg-card rounded-[20px] border border-border/30 overflow-hidden">
            <div className="px-4 py-2.5 bg-muted/30">
              <p className="text-xs font-medium text-muted-foreground uppercase tracking-wide">Backup</p>
            </div>
            
            <button 
              onClick={handleExport}
              className="w-full flex items-center justify-between p-4 hover:bg-muted/30 active:bg-muted/50"
            >
              <div className="flex items-center gap-3">
                <Download className="w-5 h-5 text-primary" />
                <span className="text-[15px] text-foreground">Export Backup</span>
              </div>
              <ChevronRight className="w-4 h-4 text-muted-foreground" />
            </button>
            
            <div className="h-px bg-border/20 mx-4" />
            
            <button 
              onClick={handleImport}
              className="w-full flex items-center justify-between p-4 hover:bg-muted/30 active:bg-muted/50"
            >
              <div className="flex items-center gap-3">
                <Upload className="w-5 h-5 text-primary" />
                <span className="text-[15px] text-foreground">Import Backup</span>
              </div>
              <ChevronRight className="w-4 h-4 text-muted-foreground" />
            </button>
          </div>

          {/* Appearance */}
          <div className="bg-card rounded-[20px] border border-border/30 overflow-hidden">
            <button 
              onClick={toggleDark}
              className="w-full flex items-center justify-between p-4 hover:bg-muted/30"
            >
              <div className="flex items-center gap-3">
                {isDark ? <Moon className="w-5 h-5 text-primary" /> : <Sun className="w-5 h-5 text-amber-500" />}
                <span className="text-[15px] text-foreground">Dark Mode</span>
              </div>
              <div className={`w-12 h-7 rounded-full transition-all duration-300 relative p-0.5
                ${isDark ? "bg-primary" : "bg-muted"}`}
              >
                <div className={`w-6 h-6 rounded-full bg-white shadow-sm transition-all duration-300
                  ${isDark ? "translate-x-5" : "translate-x-0"}`} />
              </div>
            </button>
            
            <div className="h-px bg-border/20 mx-4" />
            
            <button className="w-full flex items-center justify-between p-4 hover:bg-muted/30">
              <div className="flex items-center gap-3">
                <Bell className="w-5 h-5 text-muted-foreground" />
                <span className="text-[15px] text-foreground">Notifications</span>
              </div>
              <ChevronRight className="w-4 h-4 text-muted-foreground" />
            </button>
          </div>

          {/* Contacts */}
          <div className="bg-card rounded-[20px] border border-border/30 overflow-hidden">
            <div className="px-4 py-2.5 bg-muted/30">
              <p className="text-xs font-medium text-muted-foreground uppercase tracking-wide">Contacts</p>
            </div>
            
            <button className="w-full flex items-center gap-3 p-4 hover:bg-muted/30">
              <Star className="w-5 h-5 text-amber-500" />
              <span className="text-[15px] text-foreground">Rate the app...</span>
            </button>
            
            <div className="h-px bg-border/20 mx-4" />
            
            <button className="w-full flex items-center gap-3 p-4 hover:bg-muted/30">
              <Mail className="w-5 h-5 text-rose-500" />
              <span className="text-[15px] text-foreground">Contact the developer...</span>
            </button>
          </div>

          {/* About & Help */}
          <div className="bg-card rounded-[20px] border border-border/30 overflow-hidden">
            <button className="w-full flex items-center justify-between p-4 hover:bg-muted/30">
              <div className="flex items-center gap-3">
                <HelpCircle className="w-5 h-5 text-muted-foreground" />
                <span className="text-[15px] text-foreground">Help Center</span>
              </div>
              <ChevronRight className="w-4 h-4 text-muted-foreground" />
            </button>
            
            <div className="h-px bg-border/20 mx-4" />
            
            <div className="flex items-center justify-between p-4">
              <div className="flex items-center gap-3">
                <Info className="w-5 h-5 text-muted-foreground" />
                <span className="text-[15px] text-foreground">Version</span>
              </div>
              <span className="text-sm text-muted-foreground">1.0.0 (1)</span>
            </div>
          </div>

          {/* Clear Data */}
          <button 
            onClick={handleClearData}
            className={`w-full flex items-center justify-center gap-2.5 p-4 rounded-full
                        touch-manipulation transition-all duration-200
                        ${showClearConfirm 
                          ? "bg-destructive text-destructive-foreground" 
                          : "bg-destructive/10 text-destructive hover:bg-destructive/15"
                        }`}
          >
            <Trash2 className="w-5 h-5" strokeWidth={2} />
            <span className="font-semibold">
              {showClearConfirm ? "Tap again to confirm" : "Clear All Data"}
            </span>
          </button>
          
          {showClearConfirm && (
            <button 
              onClick={() => setShowClearConfirm(false)}
              className="w-full flex items-center justify-center gap-2 p-3 rounded-full 
                         bg-muted text-muted-foreground font-medium"
            >
              Cancel
            </button>
          )}
        </div>
      </SheetContent>
    </Sheet>
  )
}
