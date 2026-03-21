"use client"

import { useState, useEffect, useRef } from "react"
import { Plus, X, Receipt, FileText, Camera } from "lucide-react"

interface FabMenuProps {
  onAddTransaction: () => void
  onScan: () => void
  onCreateReport: () => void
  scrollContainerRef?: React.RefObject<HTMLElement | null>
}

export function FabMenu({ onAddTransaction, onScan, onCreateReport, scrollContainerRef }: FabMenuProps) {
  const [isOpen, setIsOpen] = useState(false)
  const [isVisible, setIsVisible] = useState(true)
  const lastScrollY = useRef(0)
  const scrollThreshold = 10

  // Scroll-responsive visibility
  useEffect(() => {
    const container = scrollContainerRef?.current || window

    const handleScroll = () => {
      const currentScrollY = scrollContainerRef?.current 
        ? scrollContainerRef.current.scrollTop 
        : window.scrollY
      
      const delta = currentScrollY - lastScrollY.current

      if (Math.abs(delta) > scrollThreshold) {
        if (delta > 0 && currentScrollY > 100) {
          // Scrolling down - hide FAB
          setIsVisible(false)
          setIsOpen(false)
        } else {
          // Scrolling up - show FAB
          setIsVisible(true)
        }
        lastScrollY.current = currentScrollY
      }
    }

    if (scrollContainerRef?.current) {
      scrollContainerRef.current.addEventListener("scroll", handleScroll, { passive: true })
    } else {
      window.addEventListener("scroll", handleScroll, { passive: true })
    }

    return () => {
      if (scrollContainerRef?.current) {
        scrollContainerRef.current.removeEventListener("scroll", handleScroll)
      } else {
        window.removeEventListener("scroll", handleScroll)
      }
    }
  }, [scrollContainerRef])

  const actions = [
    { id: "report", label: "Create Report", icon: FileText, bg: "bg-violet-100 dark:bg-violet-900/60", text: "text-violet-700 dark:text-violet-300", onClick: onCreateReport },
    { id: "scan", label: "Scan Bill", icon: Camera, bg: "bg-amber-100 dark:bg-amber-900/60", text: "text-amber-700 dark:text-amber-300", onClick: onScan },
    { id: "add", label: "New Bill", icon: Receipt, bg: "bg-teal-100 dark:bg-teal-900/60", text: "text-teal-700 dark:text-teal-300", onClick: onAddTransaction },
  ]

  const handleActionClick = (action: typeof actions[0]) => {
    setIsOpen(false)
    action.onClick()
  }

  return (
    <>
      {/* Backdrop */}
      <div 
        className={`fixed inset-0 backdrop-blur-sm z-40 transition-all duration-300
          bg-black/20 dark:bg-black/50
          ${isOpen ? "opacity-100" : "opacity-0 pointer-events-none"}`}
        onClick={() => setIsOpen(false)}
      />

      {/* FAB Container */}
      <div 
        className={`fixed right-5 bottom-[calc(5rem+env(safe-area-inset-bottom))] z-50 
                    transition-all duration-300 ease-[cubic-bezier(0.34,1.56,0.64,1)]
                    ${isVisible ? "translate-y-0 opacity-100" : "translate-y-24 opacity-0"}`}
      >
        {/* Action Buttons - M3 Expressive pill-shaped buttons */}
        <div className={`absolute bottom-20 right-0 flex flex-col-reverse gap-3 items-end
          transition-all duration-300 ${isOpen ? "opacity-100" : "opacity-0 pointer-events-none"}`}
        >
          {actions.map((action, index) => {
            const Icon = action.icon
            return (
              <button
                key={action.id}
                onClick={() => handleActionClick(action)}
                className={`flex items-center gap-3 pl-5 pr-4 h-14 rounded-full 
                          ${action.bg} shadow-lg shadow-foreground/5 
                          touch-manipulation transition-all duration-300 ease-[cubic-bezier(0.34,1.56,0.64,1)]
                          hover:shadow-xl active:scale-95 group
                          ${isOpen ? "translate-x-0 opacity-100 scale-100" : "translate-x-8 opacity-0 scale-90"}`}
                style={{ 
                  transitionDelay: isOpen ? `${index * 60}ms` : `${(actions.length - index) * 40}ms` 
                }}
              >
                <Icon className={`w-5 h-5 ${action.text}`} strokeWidth={2} />
                <span className={`text-sm font-semibold ${action.text} whitespace-nowrap`}>
                  {action.label}
                </span>
              </button>
            )
          })}
        </div>

        {/* Main FAB - M3 Expressive rounded square shape */}
        <button
          onClick={() => setIsOpen(!isOpen)}
          className={`w-16 h-16 flex items-center justify-center
                    shadow-xl shadow-primary/25 touch-manipulation 
                    transition-all duration-300 ease-[cubic-bezier(0.34,1.56,0.64,1)]
                    hover:shadow-2xl hover:shadow-primary/30 active:scale-95
                    ${isOpen 
                      ? "bg-foreground rounded-full rotate-0" 
                      : "bg-primary rounded-[20px] rotate-0"
                    }`}
          aria-label={isOpen ? "Close menu" : "Open action menu"}
          aria-expanded={isOpen}
        >
          <span className={`transition-all duration-300 ${isOpen ? "rotate-45" : "rotate-0"}`}>
            {isOpen ? (
              <X className="w-7 h-7 text-background" strokeWidth={2.5} />
            ) : (
              <Plus className="w-7 h-7 text-primary-foreground" strokeWidth={2.5} />
            )}
          </span>
        </button>
      </div>
    </>
  )
}
