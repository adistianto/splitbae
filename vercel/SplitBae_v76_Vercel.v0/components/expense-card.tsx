"use client"

import { useState } from "react"
import { 
  ChevronDown, 
  Pencil, 
  Trash2, 
  Users, 
  Receipt,
  Wallet,
  Share2,
} from "lucide-react"
import { useSplitStore } from "@/lib/store"
import { useCurrency } from "@/hooks/use-currency"
import { useSwipeGesture } from "@/hooks/use-swipe-gesture"
import { CATEGORY_CONFIG, getCategoryClasses } from "@/lib/category-config"
import type { Transaction } from "@/lib/types"

type DetailTab = "items" | "persons" | "payments"

interface ExpenseCardProps {
  transaction: Transaction
  onEdit?: () => void
}

export function ExpenseCard({ transaction, onEdit }: ExpenseCardProps) {
  const { people, deleteTransaction, calculatePersonShare } = useSplitStore()
  const { formatAmount } = useCurrency()
  const [isExpanded, setIsExpanded] = useState(false)
  const [activeTab, setActiveTab] = useState<DetailTab>("items")
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false)
  const [showSwipeDelete, setShowSwipeDelete] = useState(false)
  
  // Swipe to delete gesture
  const swipeRef = useSwipeGesture({
    onSwipeLeft: () => setShowSwipeDelete(true),
    onSwipeRight: () => setShowSwipeDelete(false),
    threshold: 50,
  })

  // Format date for subtitle display (e.g. "21 Mar")
  const transactionDate = new Date(transaction.createdAt)
  const dayMonth = `${transactionDate.getDate()} ${transactionDate.toLocaleDateString("en-US", { month: "short" })}`

  // Alias for compatibility with existing code
  const formatRupiah = formatAmount

  const getPersonById = (id: string) => people.find(p => p.id === id)

  const catConfig = CATEGORY_CONFIG[transaction.category]
  const Icon = catConfig.icon

  const participants = transaction.participants
    .map(id => getPersonById(id))
    .filter(Boolean)

  const payers = transaction.payments
    .filter(p => p.amount > 0)
    .map(p => {
      const person = getPersonById(p.personId)
      return person ? { ...person, amount: p.amount } : null
    })
    .filter(Boolean)

  const getItemAssignees = (assignedTo: string[]) => {
    if (assignedTo.length === 0) return participants
    return assignedTo.map(id => getPersonById(id)).filter(Boolean)
  }

  const handleDelete = () => {
    deleteTransaction(transaction.id)
    setShowDeleteConfirm(false)
  }

  const handleShare = async () => {
    // Generate shareable text
    let text = `${transaction.description}\n`
    text += `${dayMonth} - ${formatRupiah(transaction.totalAmount)}\n\n`
    text += `Items:\n`
    transaction.items.forEach(item => {
      text += `- ${item.name} x${item.quantity}: ${formatRupiah(item.price * item.quantity)}\n`
    })
    text += `\nSplit between: ${participants.map(p => p?.name).filter(Boolean).join(", ")}`
    text += `\n\nShared via SplitBae`

    if (navigator.share) {
      try {
        await navigator.share({ title: transaction.description, text })
      } catch {
        await navigator.clipboard.writeText(text)
      }
    } else {
      await navigator.clipboard.writeText(text)
      alert("Bill details copied to clipboard!")
    }
  }

  const tabs: { id: DetailTab; label: string; icon: typeof Receipt }[] = [
    { id: "items", label: "Items", icon: Receipt },
    { id: "persons", label: "Persons", icon: Users },
    { id: "payments", label: "Payments", icon: Wallet },
  ]

  return (
    <article 
      ref={swipeRef}
      className={`relative bg-card rounded-[24px] border border-border/40 overflow-hidden elevation-1 
                  transition-all duration-300 hover:elevation-2 ${showSwipeDelete ? "bg-destructive/5" : ""}`}
    >
      {/* Swipe Delete Background */}
      {showSwipeDelete && (
        <div className="absolute inset-0 bg-gradient-to-r from-destructive/10 to-transparent flex items-center justify-end pr-4">
          <div className="flex items-center gap-2 text-destructive">
            <Trash2 className="w-5 h-5" />
            <span className="text-sm font-medium">Swipe to delete</span>
          </div>
        </div>
      )}
      
      {/* Main Content */}
      {/* Header - Always visible */}
      <button
        onClick={() => {
          if (showSwipeDelete) {
            setShowDeleteConfirm(true)
            setShowSwipeDelete(false)
          } else {
            setIsExpanded(!isExpanded)
          }
        }}
        className="w-full p-4 flex items-center gap-3 text-left touch-manipulation group relative z-10"
      >
        {/* Category Icon */}
        <div className={`w-12 h-12 rounded-[16px] ${getCategoryClasses(transaction.category, "icon")} flex items-center justify-center shrink-0`}>
          <Icon className="w-5 h-5" strokeWidth={2.5} />
        </div>

        {/* Info */}
        <div className="flex-1 min-w-0">
          <h3 className={`text-title text-[15px] text-foreground ${isExpanded ? "" : "truncate"}`}>
            {transaction.description}
          </h3>
          <div className="flex items-center gap-2 text-xs text-muted-foreground mt-1">
            <span>{dayMonth}</span>
            <span className="w-1 h-1 rounded-full bg-muted-foreground/40 shrink-0" />
            <Users className="w-3 h-3 shrink-0" />
            <span>{participants.length}</span>
          </div>
        </div>

        {/* Amount */}
        <div className="text-right shrink-0">
          <p className="text-title text-base text-foreground">{formatRupiah(transaction.totalAmount)}</p>
        </div>

        {/* Chevron */}
        <div className={`shrink-0 w-8 h-8 rounded-full flex items-center justify-center transition-all duration-300
          ${isExpanded ? "bg-primary/10 rotate-180" : "bg-transparent"}`}>
          <ChevronDown className={`w-5 h-5 transition-colors ${isExpanded ? "text-primary" : "text-muted-foreground"}`} />
        </div>
      </button>

      {/* Expanded Content */}
      {isExpanded && (
        <div className="px-4 pb-5 space-y-4 animate-in slide-in-from-top-2 duration-300">
          {/* Receipt Image */}
          {transaction.receiptImage && (
            <img 
              src={transaction.receiptImage} 
              alt="Receipt" 
              className="w-full h-40 object-cover rounded-[16px]"
            />
          )}

          {/* Tab Navigation */}
          <div className="flex gap-1 p-1 bg-muted/60 rounded-[14px]">
            {tabs.map((tab) => {
              const TabIcon = tab.icon
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`flex-1 flex items-center justify-center gap-1.5 py-2.5 rounded-[10px] text-sm font-medium transition-all duration-200
                    ${activeTab === tab.id 
                      ? "bg-card text-foreground shadow-sm" 
                      : "text-muted-foreground hover:text-foreground"}`}
                >
                  <TabIcon className="w-4 h-4" />
                  {tab.label}
                </button>
              )
            })}
          </div>

          {/* Items Tab */}
          {activeTab === "items" && (
            <div className="bg-muted/40 rounded-[20px] p-4 space-y-3">
              {transaction.items.map((item) => {
                const assignees = getItemAssignees(item.assignedTo)
                return (
                  <div key={item.id} className="space-y-2">
                    <div className="flex items-start justify-between gap-3">
                      <div className="flex-1">
                        <p className="text-sm font-semibold text-foreground">
                          {item.quantity > 1 && <span className="text-muted-foreground">{item.quantity}x </span>}
                          {item.name}
                        </p>
                      </div>
                      <span className="text-sm font-bold text-foreground shrink-0">
                        {formatRupiah(item.price * item.quantity)}
                      </span>
                    </div>
                    {/* Person breakdown */}
                    <div className="pl-1 space-y-1">
                      {assignees.map((person) => {
                        if (!person) return null
                        const perPersonAmount = (item.price * item.quantity) / assignees.length
                        return (
                          <div key={person.id} className="flex items-center justify-between text-xs">
                            <span className="text-muted-foreground">{person.name}</span>
                            <span className="text-muted-foreground">{formatRupiah(perPersonAmount)}</span>
                          </div>
                        )
                      })}
                    </div>
                  </div>
                )
              })}
              {transaction.tax > 0 && (
                <>
                  <div className="h-px bg-border/60 my-2" />
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm font-semibold text-foreground">Tax / Service</p>
                      <p className="text-xs text-muted-foreground">Proportional split</p>
                    </div>
                    <span className="text-sm font-bold text-foreground">{formatRupiah(transaction.tax)}</span>
                  </div>
                </>
              )}
            </div>
          )}

          {/* Persons Tab - Person-centric view */}
          {activeTab === "persons" && (
            <div className="space-y-3">
              {participants.map((person) => {
                if (!person) return null
                const share = calculatePersonShare(transaction, person.id)
                const personItems = transaction.items.filter(item => 
                  item.assignedTo.length === 0 || item.assignedTo.includes(person.id)
                )
                
                return (
                  <div key={person.id} className="bg-muted/40 rounded-[20px] p-4">
                    {/* Person header */}
                    <div className="flex items-center justify-between mb-3">
                      <span className="text-sm font-bold text-foreground">{person.name}</span>
                      <span className="text-base font-bold text-foreground">{formatRupiah(share)}</span>
                    </div>
                    {/* Dashed divider */}
                    <div className="border-t border-dashed border-border/60 mb-3" />
                    {/* Items this person owes for */}
                    <div className="space-y-2">
                      {personItems.map((item) => {
                        const assignees = getItemAssignees(item.assignedTo)
                        const perPersonAmount = (item.price * item.quantity) / assignees.length
                        return (
                          <div key={item.id} className="flex items-center justify-between text-sm">
                            <span className="text-muted-foreground">{item.name}</span>
                            <span className="text-foreground">{formatRupiah(perPersonAmount)}</span>
                          </div>
                        )
                      })}
                      {transaction.tax > 0 && (
                        <div className="flex items-center justify-between text-sm">
                          <span className="text-muted-foreground">Tax (proportional)</span>
                          <span className="text-foreground">
                            {formatRupiah(share - personItems.reduce((sum, item) => {
                              const assignees = getItemAssignees(item.assignedTo)
                              return sum + (item.price * item.quantity) / assignees.length
                            }, 0))}
                          </span>
                        </div>
                      )}
                    </div>
                  </div>
                )
              })}
            </div>
          )}

          {/* Payments Tab */}
          {activeTab === "payments" && (
            <div className="space-y-4" role="region" aria-label="Payment details">
              {/* Who Paid - Accessible table structure */}
              <div 
                className="bg-emerald-50 dark:bg-emerald-950/40 rounded-[20px] p-4"
                role="table"
                aria-label="Who paid the bill"
              >
                <p className="text-sm font-semibold text-emerald-700 dark:text-emerald-400 mb-3 text-center" role="caption">
                  Who Paid the Bill
                </p>
                <div className="border-t border-dashed border-emerald-300 dark:border-emerald-700 mb-3" aria-hidden="true" />
                
                {/* Summary rows */}
                <div role="rowgroup">
                  <div className="flex items-center justify-between mb-2" role="row">
                    <span className="text-sm font-medium text-emerald-800 dark:text-emerald-200" role="rowheader">Total</span>
                    <span className="text-sm font-bold text-emerald-900 dark:text-emerald-100" role="cell">
                      {formatRupiah(transaction.totalAmount)}
                    </span>
                  </div>
                  <div className="flex items-center justify-between" role="row">
                    <span className="text-sm font-semibold text-emerald-700 dark:text-emerald-300" role="rowheader">Paid</span>
                    <span className="text-sm font-bold text-emerald-700 dark:text-emerald-300" role="cell">
                      {formatRupiah(transaction.payments.reduce((s, p) => s + p.amount, 0))}
                    </span>
                  </div>
                </div>
                
                <div className="border-t border-dashed border-emerald-300 dark:border-emerald-700 my-3" aria-hidden="true" />
                
                {/* Individual payers */}
                <div role="rowgroup" aria-label="Individual payments">
                  {payers.map((payer) => payer && (
                    <div key={payer.id} className="flex items-center justify-between py-1.5" role="row">
                      <span className="text-sm font-medium text-emerald-800 dark:text-emerald-200" role="rowheader">
                        {payer.name}
                      </span>
                      <span className="text-sm font-bold text-emerald-900 dark:text-emerald-100" role="cell">
                        {formatRupiah(payer.amount)}
                      </span>
                    </div>
                  ))}
                </div>
              </div>

              {/* Who Owes Whom - Two-line layout with accessibility */}
              <div 
                className="bg-secondary/60 dark:bg-secondary/40 rounded-[20px] p-4"
                role="list"
                aria-label="Settlement details - who owes whom"
              >
                <p className="text-sm font-semibold text-secondary-foreground mb-3 text-center">Who Owes Whom</p>
                <div className="border-t border-dashed border-secondary-foreground/30 mb-3" aria-hidden="true" />
                <div className="space-y-4">
                  {participants.map((person) => {
                    if (!person) return null
                    const share = calculatePersonShare(transaction, person.id)
                    const payment = transaction.payments.find(p => p.personId === person.id)
                    const paidAmount = payment?.amount || 0
                    const netOwed = share - paidAmount
                    
                    if (Math.abs(netOwed) < 0.01) return null
                    
                    // Find who they owe to (the person who paid)
                    const payerPerson = payers.find(p => p && p.id !== person.id)
                    if (!payerPerson || netOwed <= 0) return null
                    
                    return (
                      <div 
                        key={person.id} 
                        className="pb-3 border-b border-dashed border-secondary-foreground/20 last:border-0 last:pb-0"
                        role="listitem"
                        aria-label={`${person.name} owes ${payerPerson.name} ${formatRupiah(netOwed)}`}
                      >
                        {/* Line 1: Debtor name */}
                        <p className="text-[15px] font-semibold text-foreground mb-0.5">{person.name}</p>
                        {/* Line 2: owes creditor + amount */}
                        <div className="flex items-center justify-between">
                          <p className="text-sm text-muted-foreground">
                            owes <span className="text-foreground font-medium">{payerPerson.name}</span>
                          </p>
                          <span className="text-base font-bold text-primary">{formatRupiah(netOwed)}</span>
                        </div>
                      </div>
                    )
                  })}
                </div>
              </div>
            </div>
          )}

          {/* Actions - positioned at bottom for easy reach */}
          <div className="flex gap-2 pt-2">
            <button
              onClick={handleShare}
              className="flex-1 h-11 rounded-full bg-primary/10 flex items-center justify-center gap-2
                         text-primary font-medium text-sm touch-manipulation 
                         active:scale-[0.98] transition-all duration-200"
            >
              <Share2 className="w-4 h-4" />
              Share
            </button>
            <button
              onClick={onEdit}
              className="flex-1 h-11 rounded-full bg-muted flex items-center justify-center gap-2
                         text-foreground font-medium text-sm touch-manipulation 
                         active:scale-[0.98] transition-all duration-200"
            >
              <Pencil className="w-4 h-4" />
              Edit
            </button>
            <button
              onClick={() => showDeleteConfirm ? handleDelete() : setShowDeleteConfirm(true)}
              className={`h-11 rounded-full flex items-center justify-center gap-2 touch-manipulation 
                         active:scale-[0.98] transition-all duration-200
                         ${showDeleteConfirm 
                           ? "px-4 bg-destructive text-destructive-foreground font-medium text-sm" 
                           : "w-11 bg-destructive/10 text-destructive"}`}
            >
              <Trash2 className="w-4 h-4" />
              {showDeleteConfirm && <span>Delete</span>}
            </button>
          </div>
        </div>
      )}
    </article>
  )
}
