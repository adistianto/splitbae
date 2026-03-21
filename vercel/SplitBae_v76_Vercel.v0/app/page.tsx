"use client"

import { useState, useRef, useEffect, useCallback } from "react"
import { User, Search, X } from "lucide-react"
import { BottomNav } from "@/components/bottom-nav"
import { TransactionsTab } from "@/components/transactions-tab"
import { BalancesTab } from "@/components/balances-tab"
import { FabMenu } from "@/components/fab-menu"
import { ScanTab } from "@/components/scan-tab"
import { AddExpenseSheet } from "@/components/add-expense-sheet"
import { UserMenu } from "@/components/user-menu"

type Tab = "transactions" | "balances"

export default function SplitBaePage() {
  const [activeTab, setActiveTab] = useState<Tab>("transactions")
  const [showAddTransaction, setShowAddTransaction] = useState(false)
  const [showScan, setShowScan] = useState(false)
  const [showUserMenu, setShowUserMenu] = useState(false)
  const [showSearch, setShowSearch] = useState(false)
  const [searchQuery, setSearchQuery] = useState("")
  const [headerVisible, setHeaderVisible] = useState(true)
  const [filtersOpen, setFiltersOpen] = useState(false)
  const lastScrollY = useRef(0)
  const ticking = useRef(false)
  const scrollContainerRef = useRef<HTMLDivElement | null>(null)

  // Callback ref — fires when the div mounts/unmounts, guaranteeing the listener attaches
  const setScrollContainer = useCallback((node: HTMLDivElement | null) => {
    if (scrollContainerRef.current) {
      scrollContainerRef.current.removeEventListener("scroll", handleScrollRef.current!)
    }
    scrollContainerRef.current = node
    if (node) {
      node.addEventListener("scroll", handleScrollRef.current!, { passive: true })
    }
  }, []) // eslint-disable-line react-hooks/exhaustive-deps

  const handleScrollRef = useRef<(() => void) | null>(null)
  useEffect(() => {
    handleScrollRef.current = () => {
      if (ticking.current) return
      ticking.current = true
      requestAnimationFrame(() => {
        const currentY = scrollContainerRef.current?.scrollTop ?? 0
        if (currentY < 10) {
          setHeaderVisible(true)
        } else if (currentY > lastScrollY.current + 6) {
          setHeaderVisible(false)
          setShowSearch(false)
        } else if (currentY < lastScrollY.current - 6) {
          setHeaderVisible(true)
        }
        lastScrollY.current = currentY
        ticking.current = false
      })
    }
  })

  // Reset search when tab changes
  useEffect(() => {
    setSearchQuery("")
    setShowSearch(false)
  }, [activeTab])

  const handleAddTransaction = () => {
    setShowAddTransaction(true)
  }

  const handleScan = () => {
    setShowScan(true)
  }

  const handleCreateReport = () => {
    setActiveTab("balances")
  }

  const handleExpenseCreated = () => {
    setShowScan(false)
    setActiveTab("transactions")
  }

  return (
    <main id="main-content" className="min-h-dvh bg-background flex flex-col" tabIndex={-1}>
      {/* iOS Safe Area Top */}
      <div className="h-[env(safe-area-inset-top)]" />

      {/* Floating Header Buttons — search + user side by side */}
      {!showScan && (
        <div
          className={`fixed top-[calc(env(safe-area-inset-top)+0.75rem)] right-4 z-40
                      flex items-center gap-2 transition-all duration-300
                      ${headerVisible && !filtersOpen ? "opacity-100 translate-y-0" : "opacity-0 -translate-y-3 pointer-events-none"}`}
        >
          <button
            onClick={() => setShowSearch(!showSearch)}
            className="w-11 h-11 rounded-full bg-card/90 backdrop-blur-xl border border-border/50
                       flex items-center justify-center shadow-lg touch-manipulation
                       active:scale-95 transition-all"
            aria-label={showSearch ? "Close search" : "Open search"}
          >
            {showSearch
              ? <X className="w-5 h-5 text-foreground" strokeWidth={2} />
              : <Search className="w-5 h-5 text-foreground" strokeWidth={2} />
            }
          </button>
          <button
            onClick={() => setShowUserMenu(true)}
            className="w-11 h-11 rounded-full bg-card/90 backdrop-blur-xl border border-border/50
                       flex items-center justify-center shadow-lg touch-manipulation
                       active:scale-95 transition-all"
            aria-label="Open user menu"
          >
            <User className="w-5 h-5 text-foreground" strokeWidth={2} />
          </button>
        </div>
      )}

      {/* Floating Search Bar */}
      {!showScan && showSearch && (
        <div
          className={`fixed top-[calc(env(safe-area-inset-top)+4rem)] left-4 right-4 z-40
                      transition-all duration-200
                      ${headerVisible ? "opacity-100 translate-y-0" : "opacity-0 -translate-y-2 pointer-events-none"}`}
        >
          <div className="relative">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground pointer-events-none" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder={activeTab === "transactions" ? "Search bills, items..." : "Search people..."}
              autoFocus
              className="w-full h-12 pl-11 pr-4 bg-card/95 backdrop-blur-xl rounded-[16px]
                         text-[15px] text-foreground placeholder:text-muted-foreground
                         border border-border/50 shadow-lg
                         focus:outline-none focus:ring-2 focus:ring-primary/30
                         transition-all duration-200"
            />
            {searchQuery && (
              <button
                onClick={() => setSearchQuery("")}
                className="absolute right-3 top-1/2 -translate-y-1/2 w-6 h-6 rounded-full
                           bg-muted-foreground/20 flex items-center justify-center touch-manipulation"
              >
                <X className="w-3.5 h-3.5 text-muted-foreground" />
              </button>
            )}
          </div>
        </div>
      )}
      
      {/* Tab Content */}
      <div ref={setScrollContainer} className="flex-1 flex flex-col overflow-y-auto overflow-x-hidden pb-20">
        {activeTab === "transactions" && !showScan && (
          <TransactionsTab searchQuery={searchQuery} onFiltersOpenChange={setFiltersOpen} />
        )}
        {activeTab === "balances" && !showScan && (
          <BalancesTab searchQuery={searchQuery} />
        )}
        {showScan && (
          <ScanTab onExpenseCreated={handleExpenseCreated} onBack={() => setShowScan(false)} />
        )}
      </div>

      {/* FAB Menu */}
      {!showScan && (
        <FabMenu 
          onAddTransaction={handleAddTransaction}
          onScan={handleScan}
          onCreateReport={handleCreateReport}
        />
      )}


      
      {/* Bottom Navigation */}
      {!showScan && (
        <BottomNav activeTab={activeTab} onTabChange={setActiveTab} />
      )}

      {/* Add Transaction Sheet */}
      <AddExpenseSheet
        open={showAddTransaction}
        onOpenChange={setShowAddTransaction}
      />

      {/* User Menu */}
      <UserMenu open={showUserMenu} onOpenChange={setShowUserMenu} />
    </main>
  )
}
