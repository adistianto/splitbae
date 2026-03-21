"use client"

import { useState, useRef, useEffect, useMemo } from "react"
import {
  Camera, X, Plus, Check, CheckCircle, Search, UserPlus,
  Trash2, ChevronDown, CalendarDays, ArrowRightLeft, Receipt,
  Utensils, Car, Home, Music, ShoppingBag, Zap, MoreHorizontal
} from "lucide-react"
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetDescription } from "@/components/ui/sheet"
import { useSplitStore } from "@/lib/store"
import { useCurrency } from "@/hooks/use-currency"
import type { Category, ExpenseItem, Payment, Transaction } from "@/lib/types"

const CATEGORIES: { id: Category; label: string; icon: typeof Utensils; bg: string; activeBg: string }[] = [
  { id: "food",          label: "Food",       icon: Utensils,      bg: "bg-orange-100 text-orange-700",   activeBg: "bg-orange-500 text-white" },
  { id: "transport",     label: "Transport",  icon: Car,           bg: "bg-blue-100 text-blue-700",       activeBg: "bg-blue-500 text-white" },
  { id: "accommodation", label: "Stay",       icon: Home,          bg: "bg-violet-100 text-violet-700",   activeBg: "bg-violet-500 text-white" },
  { id: "entertainment", label: "Fun",        icon: Music,         bg: "bg-pink-100 text-pink-700",       activeBg: "bg-pink-500 text-white" },
  { id: "shopping",      label: "Shop",       icon: ShoppingBag,   bg: "bg-emerald-100 text-emerald-700", activeBg: "bg-emerald-500 text-white" },
  { id: "utilities",     label: "Bills",      icon: Zap,           bg: "bg-amber-100 text-amber-700",     activeBg: "bg-amber-500 text-white" },
  { id: "other",         label: "Other",      icon: MoreHorizontal,bg: "bg-slate-100 text-slate-700",     activeBg: "bg-slate-500 text-white" },
  { id: "settlement",    label: "Settlement", icon: CheckCircle,   bg: "bg-teal-100 text-teal-700",       activeBg: "bg-teal-500 text-white" },
]

interface AddExpenseSheetProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  editingTransaction?: Transaction | null
  initialItems?: ExpenseItem[]
  initialTax?: number
  initialImage?: string
  initialDescription?: string
  onExpenseAdded?: () => void
}

const generateId = () => Math.random().toString(36).substr(2, 9)

// Date helpers
const isToday = (date: Date) => {
  const today = new Date()
  return date.toDateString() === today.toDateString()
}

const isYesterday = (date: Date) => {
  const yesterday = new Date()
  yesterday.setDate(yesterday.getDate() - 1)
  return date.toDateString() === yesterday.toDateString()
}

const toLocalDateTimeString = (date: Date) => {
  // Format: YYYY-MM-DDTHH:mm for datetime-local input
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, "0")
  const day = String(date.getDate()).padStart(2, "0")
  const hours = String(date.getHours()).padStart(2, "0")
  const minutes = String(date.getMinutes()).padStart(2, "0")
  return `${year}-${month}-${day}T${hours}:${minutes}`
}

const CATEGORY_KEYWORDS: Record<Category, string[]> = {
  food:          ["restaurant","cafe","coffee","lunch","dinner","breakfast","eat","food","pizza","burger","ramen","sushi","nasi","mie","bakso","warung","resto","bar","grill","kitchen","bistro","boba","drink","snack","brunch","dessert","bbq","seafood","chicken","steak"],
  transport:     ["uber","grab","taxi","gojek","ojek","bus","train","mrt","lrt","flight","airport","toll","parking","fuel","gas","petrol","transport","car","motorbike","ferry","boat","commute","ride"],
  accommodation: ["hotel","hostel","airbnb","villa","resort","inn","motel","stay","lodge","apartment","room","rental","booking","accommodation"],
  entertainment: ["cinema","movie","concert","karaoke","bowling","game","ticket","event","show","theater","club","night","party","festival","museum","zoo","park","fun","sport","gym","swim"],
  shopping:      ["shop","mall","store","market","buy","purchase","clothes","fashion","shoes","bag","groceries","supermarket","indomaret","alfamart","minimart"],
  utilities:     ["electricity","water","internet","wifi","phone","bill","subscription","netflix","spotify","insurance","rent","utility"],
  other: [],
}

function suggestCategory(description: string): Category | null {
  if (!description.trim()) return null
  const lower = description.toLowerCase()
  for (const [cat, keywords] of Object.entries(CATEGORY_KEYWORDS) as [Category, string[]][]) {
    if (cat === "other") continue
    if (keywords.some(kw => lower.includes(kw))) return cat
  }
  return null
}

// ── Section label ──────────────────────────────────────────────────────────
function SectionLabel({ children }: { children: React.ReactNode }) {
  return (
    <p className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">
      {children}
    </p>
  )
}

export function AddExpenseSheet({
  open,
  onOpenChange,
  editingTransaction,
  initialItems,
  initialTax,
  initialImage,
  initialDescription,
  onExpenseAdded,
}: AddExpenseSheetProps) {
  const { people, addTransaction, updateTransaction, getRecommendedPeople, addPerson } = useSplitStore()
  const { formatAmount } = useCurrency()

  const [description,      setDescription]      = useState("")
  const [category,         setCategory]         = useState<Category>("food")
  const [items,            setItems]            = useState<ExpenseItem[]>([
    { id: generateId(), name: "", price: 0, quantity: 1, assignedTo: [] },
  ])
  const [tax,              setTax]              = useState(0)
  const [receiptImage,     setReceiptImage]     = useState<string | undefined>()
  const [transactionDate,  setTransactionDate]  = useState<Date>(new Date())
  const [selectedPeopleIds,setSelectedPeopleIds]= useState<string[]>([])
  const [payments,         setPayments]         = useState<Payment[]>([])
  const [paymentMode,      setPaymentMode]      = useState<"single" | "split">("single")
  const [searchQuery,      setSearchQuery]      = useState("")
  const [showDropdown,     setShowDropdown]     = useState(false)
  const [suggestedCategory,setSuggestedCategory]= useState<Category | null>(null)

  const fileInputRef  = useRef<HTMLInputElement>(null)
  const searchInputRef= useRef<HTMLInputElement>(null)
  const initialDescRef= useRef<string | undefined>(initialDescription)

  // Keep ref synced with prop
  useEffect(() => {
    initialDescRef.current = initialDescription
  }, [initialDescription])

  const recommendedPeople = useMemo(() => getRecommendedPeople(selectedPeopleIds), [selectedPeopleIds, getRecommendedPeople])

  const filteredPeople = useMemo(() => {
    if (!searchQuery.trim()) return people
    return people.filter(p => p.name.toLowerCase().includes(searchQuery.toLowerCase()))
  }, [people, searchQuery])

  // Create a stable key for when the sheet should reset its form
  const formResetKey = `${open}-${editingTransaction?.id ?? "new"}-${initialItems ? "scan" : "manual"}`

  // Reset form when sheet opens
  useEffect(() => {
    if (!open) return
    if (editingTransaction) {
      setDescription(editingTransaction.description)
      setCategory(editingTransaction.category)
      setItems(editingTransaction.items.length > 0
        ? editingTransaction.items
        : [{ id: generateId(), name: "", price: 0, quantity: 1, assignedTo: [] }])
      setTax(editingTransaction.tax)
      setReceiptImage(editingTransaction.receiptImage)
      setTransactionDate(editingTransaction.createdAt)
      setSelectedPeopleIds(editingTransaction.participants)
      setPayments(editingTransaction.payments)
      setPaymentMode(editingTransaction.payments.length > 1 ? "split" : "single")
    } else if (initialItems) {
      setDescription(initialDescRef.current || ""); setCategory("food"); setItems(initialItems)
      setTax(initialTax || 0); setReceiptImage(initialImage)
      setTransactionDate(new Date())
      setSelectedPeopleIds([]); setPayments([]); setPaymentMode("single")
      // Auto-suggest category based on vendor name
      if (initialDescRef.current) {
        const s = suggestCategory(initialDescRef.current)
        if (s) setCategory(s)
      }
    } else {
      setDescription(""); setCategory("food")
      setItems([{ id: generateId(), name: "", price: 0, quantity: 1, assignedTo: [] }])
      setTax(0); setReceiptImage(undefined); setTransactionDate(new Date())
      setSelectedPeopleIds([]); setPayments([]); setPaymentMode("single")
    }
    setSearchQuery(""); setShowDropdown(false); setSuggestedCategory(null)
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [formResetKey])

// Alias for formatting currency
  const formatRupiah = formatAmount

  const handleTaxChange = (e: React.ChangeEvent<HTMLInputElement>) =>
    setTax(parseInt(e.target.value.replace(/\D/g, ""), 10) || 0)

  const handleImageUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return
    const reader = new FileReader()
    reader.onloadend = () => setReceiptImage(reader.result as string)
    reader.readAsDataURL(file)
  }

  const addItem    = () => setItems([...items, { id: generateId(), name: "", price: 0, quantity: 1, assignedTo: [] }])
  const removeItem = (id: string) => { if (items.length > 1) setItems(items.filter(i => i.id !== id)) }
  const updateItem = (id: string, u: Partial<ExpenseItem>) => setItems(items.map(i => i.id === id ? { ...i, ...u } : i))

  const togglePerson = (personId: string) => {
    if (selectedPeopleIds.includes(personId)) {
      setSelectedPeopleIds(selectedPeopleIds.filter(id => id !== personId))
      setItems(items.map(item => ({ ...item, assignedTo: item.assignedTo.filter(id => id !== personId) })))
      setPayments(payments.filter(p => p.personId !== personId))
    } else {
      setSelectedPeopleIds([...selectedPeopleIds, personId])
    }
    setSearchQuery(""); setShowDropdown(false)
  }

  const handleAddNewPerson = () => {
    if (!searchQuery.trim()) return
    const newPerson = addPerson(searchQuery.trim())
    setSelectedPeopleIds([...selectedPeopleIds, newPerson.id])
    setSearchQuery(""); setShowDropdown(false)
  }

  const toggleItemAssignment = (itemId: string, personId: string) => {
    const item = items.find(i => i.id === itemId)
    if (!item) return
    const newAssigned = item.assignedTo.includes(personId)
      ? item.assignedTo.filter(id => id !== personId)
      : [...item.assignedTo, personId]
    updateItem(itemId, { assignedTo: newAssigned })
  }

  // When settlement category is selected, auto-populate description and items
  const handleCategorySelect = (cat: Category) => {
    setCategory(cat)
    setSuggestedCategory(null)
    if (cat === "settlement" && selectedPeopleIds.length >= 2) {
      const [fromId, toId] = selectedPeopleIds
      const fromPerson = people.find(p => p.id === fromId)
      const toPerson   = people.find(p => p.id === toId)
      if (fromPerson && toPerson) {
        const label = `${fromPerson.name.split(" ")[0]} → ${toPerson.name.split(" ")[0]}`
        setDescription(`Settlement: ${label}`)
        setItems([{ id: generateId(), name: `Settlement: ${label}`, price: 0, quantity: 1, assignedTo: [] }])
      }
    } else if (cat === "settlement" && selectedPeopleIds.length < 2) {
      setDescription("Settlement")
      setItems([{ id: generateId(), name: "Settlement", price: 0, quantity: 1, assignedTo: [] }])
    }
  }

  const itemsTotal = items.reduce((s, i) => s + i.price * (i.quantity || 1), 0)
  const grandTotal = itemsTotal + tax

  useEffect(() => {
    if (paymentMode === "single" && payments.length === 1 && selectedPeopleIds.length > 0) {
      setPayments([{ ...payments[0], amount: grandTotal }])
    }
  }, [grandTotal, paymentMode])

  const handleSinglePayerSelect = (personId: string) => setPayments([{ personId, amount: grandTotal }])

  const handlePaymentAmountChange = (personId: string, amount: number) => {
    const existing = payments.find(p => p.personId === personId)
    if (existing) setPayments(payments.map(p => p.personId === personId ? { ...p, amount } : p))
    else setPayments([...payments, { personId, amount }])
  }

  const totalPaid      = payments.reduce((s, p) => s + p.amount, 0)
  const paymentBalance = grandTotal - totalPaid

  const handleSubmit = () => {
    const validItems = items.filter(i => i.name.trim() && i.price > 0)
    if (validItems.length === 0 || selectedPeopleIds.length === 0) return
    let finalPayments = payments.filter(p => p.amount > 0)
    if (finalPayments.length === 0 && selectedPeopleIds.length > 0)
      finalPayments = [{ personId: selectedPeopleIds[0], amount: grandTotal }]

    if (editingTransaction) {
      updateTransaction(editingTransaction.id, description.trim() || validItems[0].name, category, validItems, tax, selectedPeopleIds, finalPayments, receiptImage, transactionDate)
    } else {
      addTransaction(description.trim() || validItems[0].name, category, validItems, tax, selectedPeopleIds, finalPayments, receiptImage, transactionDate)
    }
    onOpenChange(false)
    onExpenseAdded?.()
  }

  const getPersonById  = (id: string) => people.find(p => p.id === id)
  const selectedPeople = selectedPeopleIds.map(id => getPersonById(id)).filter(Boolean)
  const isSubmittable  = items.filter(i => i.name.trim() && i.price > 0).length > 0 && selectedPeopleIds.length > 0

  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent
        side="bottom"
        className="rounded-t-[32px] pb-[env(safe-area-inset-bottom)] h-[92vh] flex flex-col overflow-hidden max-w-full"
      >
        {/* ── Header ─────────────────────────────────────────────── */}
        <SheetHeader className="px-6 pt-6 pb-1 shrink-0 border-b border-border/30">
          <SheetTitle className="text-xl font-bold text-foreground">
            {editingTransaction ? "Edit Transaction" : "Add Transaction"}
          </SheetTitle>
          <SheetDescription className="sr-only">
            Fill in the bill details and assign items to participants.
          </SheetDescription>
        </SheetHeader>

        {/* ── Scrollable body ─────────────────────────────────────── */}
        <div className="flex-1 overflow-y-auto">
          <div className="px-6 pt-5 pb-32 space-y-6">

            {/* Receipt Photo */}
            <div>
              <input
                ref={fileInputRef}
                type="file"
                accept="image/*"
                capture="environment"
                onChange={handleImageUpload}
                className="hidden"
              />
              {receiptImage ? (
                <div className="relative rounded-[20px] overflow-hidden">
                  <img src={receiptImage} alt="Receipt" className="w-full h-36 object-cover" />
                  <div className="absolute inset-0 bg-gradient-to-t from-black/40 to-transparent" />
                  <button
                    onClick={() => setReceiptImage(undefined)}
                    className="absolute top-3 right-3 w-9 h-9 rounded-full bg-black/60 backdrop-blur-sm
                               flex items-center justify-center touch-manipulation active:scale-95"
                    aria-label="Remove receipt"
                  >
                    <X className="w-4 h-4 text-white" strokeWidth={2.5} />
                  </button>
                </div>
              ) : (
                <button
                  onClick={() => fileInputRef.current?.click()}
                  className="w-full h-16 bg-secondary rounded-[18px] flex items-center justify-center gap-3
                             text-secondary-foreground touch-manipulation active:bg-secondary/70 transition-all"
                >
                  <Camera className="w-5 h-5" strokeWidth={2} />
                  <span className="font-semibold text-[15px]">Add Receipt Photo</span>
                </button>
              )}
            </div>

            {/* Description */}
            <div className="space-y-2">
              <div className="flex items-baseline justify-between">
                <SectionLabel>Description</SectionLabel>
                <span className="text-[10px] text-muted-foreground">Auto-fills from first item if empty</span>
              </div>
              <input
                type="text"
                value={description}
                onChange={(e) => {
                  const val = e.target.value
                  setDescription(val)
                  const s = suggestCategory(val)
                  setSuggestedCategory(s && s !== category ? s : null)
                }}
                placeholder="e.g., Dinner at Restaurant"
                className="w-full h-12 px-4 bg-input rounded-[16px] text-[15px] text-foreground
                           placeholder:text-muted-foreground border border-border
                           focus:outline-none focus:ring-2 focus:ring-primary/30"
              />
              {suggestedCategory && (
                <div className="flex items-center gap-2 pt-0.5">
                  <span className="text-xs text-muted-foreground">Suggested:</span>
                  <button
                    type="button"
                    onClick={() => handleCategorySelect(suggestedCategory)}
                    className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-primary/10 text-primary
                               text-xs font-semibold touch-manipulation active:scale-95 transition-all"
                  >
                    {(() => { const cat = CATEGORIES.find(c => c.id === suggestedCategory); const I = cat?.icon; return I ? <I className="w-3.5 h-3.5" /> : null })()}
                    {CATEGORIES.find(c => c.id === suggestedCategory)?.label}
                  </button>
                </div>
              )}
            </div>

            {/* Category */}
            <div className="space-y-2.5">
              <SectionLabel>Category</SectionLabel>
              <div className="flex gap-2 overflow-x-auto pb-1 -mx-6 px-6 scrollbar-hide">
                {CATEGORIES.map((cat) => {
                  const Icon = cat.icon
                  const isActive = category === cat.id
                  return (
                    <button
                      key={cat.id}
                      onClick={() => handleCategorySelect(cat.id)}
                      className={`flex items-center gap-2 px-4 py-2.5 rounded-[14px] flex-shrink-0
                                 text-sm font-semibold touch-manipulation transition-all active:scale-95
                                 ${isActive ? cat.activeBg : cat.bg}`}
                    >
                      <Icon className="w-4 h-4" strokeWidth={2.5} />
                      <span>{cat.label}</span>
                    </button>
                  )
                })}
              </div>
            </div>

            {/* Transaction Date */}
            <div className="space-y-2.5">
              <SectionLabel>Date</SectionLabel>
              {/* Quick buttons row */}
              <div className="flex gap-2">
                <button
                  type="button"
                  onClick={() => setTransactionDate(new Date())}
                  className={`px-4 py-2.5 rounded-[14px] text-sm font-semibold touch-manipulation transition-all active:scale-95
                    ${isToday(transactionDate) ? "bg-primary text-primary-foreground" : "bg-muted text-muted-foreground"}`}
                >
                  Today
                </button>
                <button
                  type="button"
                  onClick={() => {
                    const yesterday = new Date()
                    yesterday.setDate(yesterday.getDate() - 1)
                    setTransactionDate(yesterday)
                  }}
                  className={`px-4 py-2.5 rounded-[14px] text-sm font-semibold touch-manipulation transition-all active:scale-95
                    ${isYesterday(transactionDate) ? "bg-primary text-primary-foreground" : "bg-muted text-muted-foreground"}`}
                >
                  Yesterday
                </button>
              </div>
              {/* Date-time input on its own full-width row so the native popup doesn't overflow */}
              <div className="relative w-full">
                <CalendarDays className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground pointer-events-none z-10" />
                <input
                  type="datetime-local"
                  value={toLocalDateTimeString(transactionDate)}
                  onChange={(e) => {
                    const val = e.target.value
                    if (val) setTransactionDate(new Date(val))
                  }}
                  className="w-full h-11 pl-10 pr-3 bg-input rounded-[14px] text-sm text-foreground
                             border border-border focus:outline-none focus:ring-2 focus:ring-primary/30"
                />
              </div>
            </div>

            {/* Who's Splitting */}
            <div className="space-y-3">
              <SectionLabel>
                Who's splitting?{selectedPeopleIds.length > 0 ? ` (${selectedPeopleIds.length})` : ""}
              </SectionLabel>

              {/* Selected people chips */}
              {selectedPeople.length > 0 && (
                <div className="flex gap-2 flex-wrap">
                  {selectedPeople.map((person) => {
                    if (!person) return null
                    return (
                      <button
                        key={person.id}
                        onClick={() => togglePerson(person.id)}
                        className="h-10 pl-2 pr-3 rounded-full bg-primary text-primary-foreground text-sm font-medium
                                   flex items-center gap-2 touch-manipulation active:scale-95 transition-all"
                      >
                        <span className="w-6 h-6 rounded-full bg-white/25 text-[11px] flex items-center justify-center font-bold shrink-0">
                          {person.avatar}
                        </span>
                        <span className="max-w-[90px] truncate">{person.name}</span>
                        <X className="w-3.5 h-3.5 opacity-70 shrink-0" />
                      </button>
                    )
                  })}
                </div>
              )}

              {/* Frequency suggestions — single row, scrollable, max 3 */}
              {recommendedPeople.length > 0 && (
                <div className="flex items-center gap-2 overflow-x-auto scrollbar-hide -mx-6 px-6">
                  <p className="text-xs text-muted-foreground shrink-0">
                    {selectedPeopleIds.length === 0 ? "Frequent:" : "Also:"}
                  </p>
                  {recommendedPeople.slice(0, 3).map((person) => {
                    const isSelected = selectedPeopleIds.includes(person.id)
                    return (
                      <button
                        key={person.id}
                        onClick={() => togglePerson(person.id)}
                        className={`h-9 pl-2 pr-3 rounded-full text-sm font-medium flex items-center gap-2
                                   touch-manipulation active:scale-95 transition-all shrink-0
                                   ${isSelected
                                     ? "bg-primary text-primary-foreground"
                                     : "bg-primary/10 text-foreground"}`}
                      >
                        <span className={`w-5 h-5 rounded-full text-[10px] flex items-center justify-center font-semibold shrink-0
                                        ${isSelected ? "bg-white/25 text-primary-foreground" : "bg-primary/20 text-primary"}`}>
                          {person.avatar}
                        </span>
                        <span>{person.name.split(" ")[0]}</span>
                        {isSelected && <X className="w-3 h-3 opacity-70 shrink-0" />}
                      </button>
                    )
                  })}
                </div>
              )}

              {/* Search / add person */}
              <div className="relative">
                <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground pointer-events-none" />
                <input
                  ref={searchInputRef}
                  type="text"
                  value={searchQuery}
                  onChange={(e) => { setSearchQuery(e.target.value); setShowDropdown(true) }}
                  onFocus={() => setShowDropdown(true)}
                  placeholder="Search or add person..."
                  className="w-full h-12 pl-11 pr-4 bg-input rounded-[14px] text-sm text-foreground
                             placeholder:text-muted-foreground border border-border
                             focus:outline-none focus:ring-2 focus:ring-primary/30"
                />
              </div>

              {/* Dropdown */}
              {showDropdown && (
                <div className="bg-card rounded-[16px] border border-border shadow-md overflow-hidden max-h-52 overflow-y-auto">
                  {filteredPeople.filter(p => !selectedPeopleIds.includes(p.id)).map((person) => (
                    <button
                      key={person.id}
                      onClick={() => togglePerson(person.id)}
                      className="w-full h-12 px-4 flex items-center gap-3 hover:bg-muted/60 active:bg-muted transition-colors text-left"
                    >
                      <span className="w-8 h-8 rounded-full bg-primary/10 text-sm flex items-center justify-center text-primary font-semibold shrink-0">
                        {person.avatar}
                      </span>
                      <span className="text-sm font-medium text-foreground">{person.name}</span>
                    </button>
                  ))}
                  {searchQuery.trim() && !people.some(p => p.name.toLowerCase() === searchQuery.toLowerCase()) && (
                    <button
                      onClick={handleAddNewPerson}
                      className="w-full h-12 px-4 flex items-center gap-3 hover:bg-emerald-50 active:bg-emerald-100 transition-colors text-left border-t border-border"
                    >
                      <span className="w-8 h-8 rounded-full bg-emerald-500/15 flex items-center justify-center shrink-0">
                        <UserPlus className="w-4 h-4 text-emerald-600" />
                      </span>
                      <span className="text-sm font-medium text-foreground">Add "{searchQuery}"</span>
                    </button>
                  )}
                  {filteredPeople.filter(p => !selectedPeopleIds.includes(p.id)).length === 0 && !searchQuery && (
                    <p className="p-4 text-sm text-muted-foreground text-center">
                      {people.length === 0 ? "Start typing to add people" : "All people added"}
                    </p>
                  )}
                </div>
              )}
            </div>

            {/* Items */}
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <SectionLabel>Items ({items.length})</SectionLabel>
                <button
                  onClick={addItem}
                  className="flex items-center gap-1.5 px-4 py-2 rounded-full bg-primary/10
                             text-primary text-sm font-semibold touch-manipulation active:bg-primary/20 transition-all"
                >
                  <Plus className="w-4 h-4" strokeWidth={2.5} />
                  Add Item
                </button>
              </div>

              <div className="space-y-3">
                {items.map((item) => (
                  <div key={item.id} className="bg-muted/50 rounded-[20px] p-4 space-y-3 border border-border/30">
                    {/* Item name row */}
                    <div className="flex gap-2 items-center">
                      <input
                        type="text"
                        value={item.name}
                        onChange={(e) => updateItem(item.id, { name: e.target.value })}
                        placeholder="Item name"
                        className="flex-1 h-11 px-3.5 bg-card rounded-[12px] text-foreground placeholder:text-muted-foreground
                                   border border-border text-sm font-medium focus:outline-none focus:ring-2 focus:ring-primary/30"
                      />
                      {items.length > 1 && (
                        <button
                          onClick={() => removeItem(item.id)}
                          className="w-9 h-9 flex items-center justify-center rounded-full bg-destructive/10 text-destructive shrink-0
                                     touch-manipulation active:scale-95 transition-all"
                          aria-label="Remove item"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      )}
                    </div>

                    {/* Qty + Price row */}
                    <div className="flex gap-2 items-center">
                      <div className="flex items-center gap-1.5 bg-card border border-border rounded-[12px] px-3 h-11 w-[90px]">
                        <span className="text-xs text-muted-foreground shrink-0">Qty</span>
                        <input
                          type="number"
                          inputMode="numeric"
                          min="1"
                          value={item.quantity || ""}
                          onChange={(e) => updateItem(item.id, { quantity: parseInt(e.target.value) || 1 })}
                          className="w-full text-sm font-semibold text-foreground bg-transparent border-0 outline-none text-right"
                        />
                      </div>
                      <div className="flex-1 flex items-center gap-2 bg-card border border-border rounded-[12px] px-3 h-11">
                        <span className="text-xs text-muted-foreground shrink-0">Rp</span>
                        <input
                          type="text"
                          inputMode="numeric"
                          value={item.price > 0 ? item.price.toLocaleString("id-ID") : ""}
                          onChange={(e) => updateItem(item.id, { price: parseInt(e.target.value.replace(/\D/g, "")) || 0 })}
                          placeholder="0"
                          className="flex-1 text-sm font-semibold text-foreground bg-transparent border-0 outline-none text-right
                                     placeholder:text-muted-foreground/50"
                        />
                      </div>
                      {item.price > 0 && item.quantity > 1 && (
                        <span className="text-xs text-muted-foreground whitespace-nowrap">
                          = {formatRupiah(item.price * item.quantity)}
                        </span>
                      )}
                    </div>

                    {/* Item assignment avatars */}
                    {selectedPeopleIds.length > 0 && (
                      <div>
                        <p className="text-xs text-muted-foreground mb-2">
                          {item.assignedTo.length === 0 ? "Shared by all" : `Assigned to ${item.assignedTo.length}`}
                        </p>
                        <div className="flex gap-1.5 flex-wrap">
                          {selectedPeopleIds.map((personId) => {
                            const person = getPersonById(personId)
                            if (!person) return null
                            const isAssigned = item.assignedTo.includes(personId)
                            const isShared   = item.assignedTo.length === 0
                            return (
                              <button
                                key={personId}
                                onClick={() => toggleItemAssignment(item.id, personId)}
                                className={`h-7 px-2.5 rounded-full text-xs font-medium flex items-center gap-1 transition-all
                                            ${isAssigned
                                              ? "bg-primary text-primary-foreground"
                                              : isShared
                                                ? "bg-primary/20 text-primary border border-primary/30"
                                                : "bg-muted-foreground/15 text-muted-foreground"}`}
                              >
                                {person.avatar}
                              </button>
                            )
                          })}
                        </div>
                      </div>
                    )}
                  </div>
                ))}
              </div>
            </div>

            {/* Tax */}
            <div className="space-y-2">
              <SectionLabel>Tax / Service charge</SectionLabel>
              <div className="flex items-center gap-3 bg-input rounded-[14px] px-4 h-12 border border-border">
                <Receipt className="w-4 h-4 text-muted-foreground shrink-0" strokeWidth={2} />
                <span className="text-sm text-muted-foreground shrink-0">Rp</span>
                <input
                  type="text"
                  inputMode="numeric"
                  value={tax > 0 ? tax.toLocaleString("id-ID") : ""}
                  onChange={handleTaxChange}
                  placeholder="0"
                  className="flex-1 text-sm font-semibold text-foreground bg-transparent border-0 outline-none
                             text-right placeholder:text-muted-foreground/50"
                />
              </div>
              <p className="text-xs text-muted-foreground px-1">Split proportionally among participants</p>
            </div>

            {/* Totals Summary */}
            <div className="bg-muted/60 rounded-[18px] p-4 border border-border/30 space-y-2.5">
              <div className="flex items-center justify-between text-sm">
                <span className="text-muted-foreground">Subtotal ({items.filter(i => i.price > 0).length} items)</span>
                <span className="font-medium text-foreground">{formatRupiah(itemsTotal)}</span>
              </div>
              <div className="flex items-center justify-between text-sm">
                <span className="text-muted-foreground">Tax & service</span>
                <span className="font-medium text-foreground">{formatRupiah(tax)}</span>
              </div>
              <div className="h-px bg-border/60" />
              <div className="flex items-center justify-between">
                <span className="font-semibold text-foreground text-sm">Grand Total</span>
                <span className="text-xl font-bold text-primary">{formatRupiah(grandTotal)}</span>
              </div>
            </div>

            {/* Paid By */}
            {selectedPeopleIds.length > 0 && (
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <SectionLabel>Paid by</SectionLabel>
                  <div className="flex gap-1 bg-muted rounded-full p-1">
                    <button
                      onClick={() => {
                        setPaymentMode("single")
                        const firstPayer = payments[0]?.personId || selectedPeopleIds[0]
                        setPayments([{ personId: firstPayer, amount: grandTotal }])
                      }}
                      className={`px-3 py-1.5 rounded-full text-xs font-medium transition-all
                                 ${paymentMode === "single" ? "bg-card text-foreground shadow-sm" : "text-muted-foreground"}`}
                    >
                      One person
                    </button>
                    <button
                      onClick={() => setPaymentMode("split")}
                      className={`px-3 py-1.5 rounded-full text-xs font-medium transition-all
                                 ${paymentMode === "split" ? "bg-card text-foreground shadow-sm" : "text-muted-foreground"}`}
                    >
                      Multiple
                    </button>
                  </div>
                </div>

                {paymentMode === "single" ? (
                  <div className="flex gap-2 flex-wrap">
                    {selectedPeopleIds.map((personId) => {
                      const person    = getPersonById(personId)
                      if (!person) return null
                      const isSelected = payments.length > 0 && payments[0].personId === personId
                      return (
                        <button
                          key={personId}
                          onClick={() => handleSinglePayerSelect(personId)}
                          className={`flex items-center gap-2 px-4 h-11 rounded-full flex-shrink-0
                                     touch-manipulation transition-all
                                     ${isSelected
                                       ? "bg-primary text-primary-foreground"
                                       : "bg-muted text-foreground active:bg-muted/70 border border-border/40"}`}
                        >
                          <span className={`w-6 h-6 rounded-full text-[11px] font-bold flex items-center justify-center shrink-0
                                           ${isSelected ? "bg-white/20" : "bg-primary/15 text-primary"}`}>
                            {person.avatar}
                          </span>
                          <span className="text-sm font-medium">{person.name.split(" ")[0]}</span>
                          {isSelected && <Check className="w-4 h-4 shrink-0" strokeWidth={2.5} />}
                        </button>
                      )
                    })}
                  </div>
                ) : (
                  <div className="space-y-2.5">
                    {selectedPeopleIds.map((personId) => {
                      const person  = getPersonById(personId)
                      if (!person) return null
                      const payment = payments.find(p => p.personId === personId)
                      return (
                        <div key={personId} className="bg-input rounded-[14px] h-14 px-4 flex items-center gap-3 border border-border">
                          <span className="w-8 h-8 rounded-full bg-primary/10 text-sm flex items-center justify-center text-primary font-semibold shrink-0">
                            {person.avatar}
                          </span>
                          <span className="flex-1 text-sm font-medium text-foreground">{person.name}</span>
                          <span className="text-sm text-muted-foreground shrink-0">Rp</span>
                          <input
                            type="text"
                            inputMode="numeric"
                            value={payment && payment.amount > 0 ? payment.amount.toLocaleString("id-ID") : ""}
                            onChange={(e) => handlePaymentAmountChange(personId, parseInt(e.target.value.replace(/\D/g, "")) || 0)}
                            placeholder="0"
                            className="w-24 text-right text-sm font-semibold text-foreground bg-transparent border-0 outline-none placeholder:text-muted-foreground/50"
                          />
                        </div>
                      )
                    })}
                    <div className={`px-4 py-3 rounded-[14px] flex items-center justify-between
                                    ${Math.abs(paymentBalance) < 1 ? "bg-emerald-500/10" : "bg-amber-500/10"}`}>
                      <span className="text-sm text-muted-foreground">
                        {paymentBalance > 0 ? "Remaining" : paymentBalance < 0 ? "Over" : "Balanced"}
                      </span>
                      <span className={`text-sm font-semibold ${Math.abs(paymentBalance) < 1 ? "text-emerald-600" : "text-amber-600"}`}>
                        {formatRupiah(Math.abs(paymentBalance))}
                      </span>
                    </div>
                  </div>
                )}
              </div>
            )}

          </div>{/* end scrollable body */}
        </div>

        {/* ── Submit button ──────────────────────────────────────── */}
        <div
          className="absolute bottom-0 left-0 right-0 px-6 pt-3 pb-5 bg-background/98 backdrop-blur-xl border-t border-border/20"
          style={{ paddingBottom: "calc(1.25rem + env(safe-area-inset-bottom))" }}
        >
          <button
            onClick={handleSubmit}
            disabled={!isSubmittable}
            className="w-full h-14 bg-primary text-primary-foreground rounded-full
                       flex items-center justify-center gap-2.5 font-semibold text-[15px]
                       touch-manipulation active:scale-[0.98] active:opacity-90 transition-all duration-200
                       disabled:opacity-35 disabled:pointer-events-none shadow-lg shadow-primary/25"
          >
            <Check className="w-5 h-5" strokeWidth={2.5} />
            <span>{editingTransaction ? "Save Changes" : "Add Transaction"}</span>
          </button>
        </div>
      </SheetContent>
    </Sheet>
  )
}
