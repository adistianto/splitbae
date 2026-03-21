"use client"

import { Receipt, Wallet } from "lucide-react"

type Tab = "transactions" | "balances"

interface BottomNavProps {
  activeTab: Tab
  onTabChange: (tab: Tab) => void
}

export function BottomNav({ activeTab, onTabChange }: BottomNavProps) {
  const tabs: { id: Tab; label: string; icon: typeof Receipt }[] = [
    { id: "transactions", label: "Bills", icon: Receipt },
    { id: "balances", label: "Balances", icon: Wallet },
  ]

  return (
    <nav 
      className="fixed bottom-0 left-0 right-0 bg-card/95 backdrop-blur-2xl border-t border-border/20 
                 px-6 pt-2 pb-[calc(0.5rem+env(safe-area-inset-bottom))] z-30"
      aria-label="Main navigation"
    >
      <div role="tablist" aria-label="Main sections" className="flex items-center justify-center gap-2 max-w-md mx-auto">
        {tabs.map((tab) => {
          const Icon = tab.icon
          const isActive = activeTab === tab.id
          
          return (
              <button
                key={tab.id}
                role="tab"
                id={`tab-${tab.id}`}
                aria-selected={isActive}
                aria-controls={`panel-${tab.id}`}
                tabIndex={isActive ? 0 : -1}
                onClick={() => onTabChange(tab.id)}
                className="relative flex-1 flex flex-col items-center gap-1 py-2
                           touch-manipulation transition-all duration-300 ease-out group"
              >
                {/* M3 Expressive pill indicator - animates from fully rounded to less rounded */}
                <span 
                  className={`absolute top-1 flex items-center justify-center transition-all duration-300 ease-[cubic-bezier(0.34,1.56,0.64,1)]
                    ${isActive 
                      ? "w-16 h-9 rounded-[18px] bg-primary/15 scale-100 opacity-100" 
                      : "w-12 h-9 rounded-full scale-90 opacity-0 group-active:scale-95 group-active:opacity-60 group-active:bg-muted"
                    }`} 
                />
                
                {/* Icon */}
                <span className={`relative z-10 flex items-center justify-center transition-all duration-300
                  ${isActive 
                    ? "text-primary" 
                    : "text-muted-foreground group-hover:text-foreground/70"
                  }`}
                >
                  <Icon 
                    className={`w-6 h-6 transition-all duration-300 ${isActive ? "stroke-[2.5px]" : "stroke-[1.75px]"}`} 
                  />
                </span>
                
                {/* Label */}
                <span className={`relative z-10 text-xs font-medium transition-all duration-300 mt-0.5
                  ${isActive 
                    ? "text-primary font-semibold" 
                    : "text-muted-foreground/70"
                  }`}
                >
                  {tab.label}
                </span>
              </button>
          )
        })}
      </div>
    </nav>
  )
}
