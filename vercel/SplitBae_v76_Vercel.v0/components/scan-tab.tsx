"use client"

import { useState, useRef, useEffect, useCallback } from "react"
import { Camera, Image as ImageIcon, X, Loader2, Plus, Trash2, ArrowRight, ScanLine, Sparkles } from "lucide-react"
import { useSplitStore } from "@/lib/store"
import { AddExpenseSheet } from "./add-expense-sheet"
import { useCurrency } from "@/hooks/use-currency"
import type { ExpenseItem } from "@/lib/types"

interface ExtractedItem {
  id: string
  name: string
  quantity: number
  price: number
  assignedTo: string[]
}

interface ExtractedData {
  vendor: string
  items: ExtractedItem[]
  subtotal: number
  tax: number
  total: number
}

interface ScanTabProps {
  onExpenseCreated: () => void
  onBack: () => void
}

const generateId = () => Math.random().toString(36).substr(2, 9)

export function ScanTab({ onExpenseCreated, onBack }: ScanTabProps) {
  const [capturedImage, setCapturedImage] = useState<string | null>(null)
  const [isProcessing, setIsProcessing] = useState(false)
  const [extractedData, setExtractedData] = useState<ExtractedData | null>(null)
  const [showAddExpense, setShowAddExpense] = useState(false)
  
  const fileInputRef = useRef<HTMLInputElement>(null)
  const cameraInputRef = useRef<HTMLInputElement>(null)
  const [buttonVisible, setButtonVisible] = useState(true)
  const lastScrollY = useRef(0)
  const ticking = useRef(false)
  const scrollHandlerRef = useRef<(() => void) | null>(null)

  // Keep scroll handler up-to-date each render
  useEffect(() => {
    scrollHandlerRef.current = () => {
      if (ticking.current) return
      ticking.current = true
      requestAnimationFrame(() => {
        const el = scrollSectionRef.current
        if (!el) { ticking.current = false; return }
        const y = el.scrollTop
        if (y < 10) {
          setButtonVisible(true)
        } else if (y > lastScrollY.current + 6) {
          setButtonVisible(false)
        } else if (y < lastScrollY.current - 6) {
          setButtonVisible(true)
        }
        lastScrollY.current = y
        ticking.current = false
      })
    }
  })

  const scrollSectionRef = useRef<HTMLElement | null>(null)
  const setScrollSection = useCallback((node: HTMLElement | null) => {
    if (scrollSectionRef.current) {
      scrollSectionRef.current.removeEventListener("scroll", scrollHandlerRef.current!)
    }
    scrollSectionRef.current = node
    if (node) {
      node.addEventListener("scroll", scrollHandlerRef.current!, { passive: true })
    }
  }, [])

  const { formatAmount: formatRupiah } = useCurrency()

  const handleCapture = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (file) {
      const reader = new FileReader()
      reader.onloadend = () => {
        setCapturedImage(reader.result as string)
        processReceipt()
      }
      reader.readAsDataURL(file)
    }
  }

  const processReceipt = () => {
    setIsProcessing(true)
    setTimeout(() => {
      const mockData: ExtractedData = {
        vendor: "The Rustic Fork Bistro",
        items: [
          { id: generateId(), name: "Sourdough G&H", quantity: 2, price: 24000, assignedTo: [] },
          { id: generateId(), name: "Grazing Platter", quantity: 1, price: 38000, assignedTo: [] },
          { id: generateId(), name: "Lrg Fries w/ Aioli", quantity: 3, price: 42000, assignedTo: [] },
          { id: generateId(), name: "Wagyu Burger", quantity: 2, price: 56000, assignedTo: [] },
          { id: generateId(), name: "Seared Barra", quantity: 1, price: 34000, assignedTo: [] },
          { id: generateId(), name: "Pumpkin Risotto", quantity: 2, price: 52000, assignedTo: [] },
          { id: generateId(), name: "Pint Carlton", quantity: 3, price: 40500, assignedTo: [] },
          { id: generateId(), name: "Espresso Martini", quantity: 1, price: 21000, assignedTo: [] },
          { id: generateId(), name: "Lemon Lime Bitters", quantity: 1, price: 6500, assignedTo: [] },
        ],
        subtotal: 314000,
        tax: 28550,
        total: 314000,
      }
      setExtractedData(mockData)
      setIsProcessing(false)
    }, 2000)
  }

  const updateItemPrice = (itemId: string, price: number) => {
    if (!extractedData) return
    setExtractedData({
      ...extractedData,
      items: extractedData.items.map(item =>
        item.id === itemId ? { ...item, price } : item
      )
    })
  }

  const removeItem = (itemId: string) => {
    if (!extractedData || extractedData.items.length <= 1) return
    setExtractedData({
      ...extractedData,
      items: extractedData.items.filter(item => item.id !== itemId)
    })
  }

  const addItem = () => {
    if (!extractedData) return
    setExtractedData({
      ...extractedData,
      items: [...extractedData.items, { id: generateId(), name: "", quantity: 1, price: 0, assignedTo: [] }]
    })
  }

  const updateItemName = (itemId: string, name: string) => {
    if (!extractedData) return
    setExtractedData({
      ...extractedData,
      items: extractedData.items.map(item =>
        item.id === itemId ? { ...item, name } : item
      )
    })
  }

  const updateItemQuantity = (itemId: string, quantity: number) => {
    if (!extractedData) return
    setExtractedData({
      ...extractedData,
      items: extractedData.items.map(item =>
        item.id === itemId ? { ...item, quantity } : item
      )
    })
  }

  const handleContinue = () => {
    setShowAddExpense(true)
  }

  const handleExpenseAdded = () => {
    setShowAddExpense(false)
    setCapturedImage(null)
    setExtractedData(null)
    onExpenseCreated()
  }

  const handleReset = () => {
    setCapturedImage(null)
    setExtractedData(null)
    setIsProcessing(false)
  }

  const calculatedTotal = extractedData 
    ? extractedData.items.reduce((sum, item) => sum + (item.price * item.quantity), 0) + extractedData.tax
    : 0

  const expenseItems: ExpenseItem[] = extractedData?.items
    .filter(item => item.name.trim() && item.price > 0)
    .map(item => ({
      id: item.id,
      name: item.name,
      price: item.price,
      quantity: item.quantity,
      assignedTo: item.assignedTo
    })) || []

  return (
    <div className="flex-1 flex flex-col">
      {/* Header — back button in document flow, title below it */}
      <header className="px-5 pt-[calc(env(safe-area-inset-top)+0.75rem)] pb-5">
        {/* Back button row */}
        <div className="mb-4">
          <button
            onClick={onBack}
            className="w-11 h-11 rounded-full bg-card/90 backdrop-blur-xl border border-border/50
                       flex items-center justify-center shadow-sm touch-manipulation
                       active:scale-95 transition-all"
            aria-label="Go back"
          >
            <svg className="w-5 h-5 text-foreground" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
            </svg>
          </button>
        </div>

        {/* Title row */}
        <div className="mb-5">
          <h1 className="text-display text-3xl text-foreground">Scan Receipt</h1>
          <p className="text-sm text-muted-foreground mt-0.5">Capture to add expenses quickly</p>
        </div>
        
        {/* Hero Card */}
        <div className="relative overflow-hidden bg-gradient-to-br from-primary via-primary to-primary/80 
                        rounded-[28px] p-5 elevation-2">
          <div className="absolute -top-12 -right-12 w-40 h-40 bg-white/10 rounded-full blur-2xl" />
          <div className="absolute -bottom-8 -left-8 w-32 h-32 bg-white/5 rounded-full blur-xl" />
          
          <div className="relative flex items-center gap-4">
            <div className="w-14 h-14 rounded-[20px] bg-white/20 backdrop-blur-sm
                            flex items-center justify-center shrink-0">
              <ScanLine className="w-7 h-7 text-primary-foreground" strokeWidth={2} />
            </div>
            <div>
              <p className="text-xs font-medium text-primary-foreground/70 uppercase tracking-wide mb-0.5">Quick Add</p>
              <p className="text-lg font-semibold text-primary-foreground">
                {extractedData ? `${extractedData.items.length} items detected` : "Point camera at receipt"}
              </p>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <section ref={setScrollSection} className="flex-1 overflow-y-auto px-5 pb-36">
        {/* Hidden file inputs */}
        <input
          ref={cameraInputRef}
          type="file"
          accept="image/*"
          capture="environment"
          onChange={handleCapture}
          className="hidden"
        />
        <input
          ref={fileInputRef}
          type="file"
          accept="image/*"
          onChange={handleCapture}
          className="hidden"
        />

        {!capturedImage ? (
          <div className="flex flex-col items-center justify-center min-h-[50vh]">
            <div className="w-full max-w-sm space-y-4">
              {/* Camera Button - Primary action */}
              <button
                onClick={() => cameraInputRef.current?.click()}
                className="w-full aspect-[4/3] bg-card rounded-[24px] flex flex-col items-center justify-center gap-5
                           touch-manipulation active:scale-[0.98] transition-all duration-300 
                           border-2 border-dashed border-primary/30 hover:border-primary/50 
                           dark:border-primary/40 dark:hover:border-primary/60 elevation-1"
              >
                <div className="w-20 h-20 rounded-[20px] bg-primary/10 dark:bg-primary/20 flex items-center justify-center">
                  <Camera className="w-10 h-10 text-primary" strokeWidth={1.5} />
                </div>
                <div className="text-center px-4">
                  <p className="text-headline text-xl text-foreground">Take Photo</p>
                  <p className="text-sm text-muted-foreground mt-1.5">
                    Snap a picture of your receipt
                  </p>
                </div>
              </button>

              {/* Gallery Button - Secondary action */}
              <button
                onClick={() => fileInputRef.current?.click()}
                className="w-full h-14 bg-secondary dark:bg-secondary/60 rounded-[18px] flex items-center justify-center gap-3
                           touch-manipulation active:scale-[0.98] active:bg-secondary/80 transition-all duration-200"
              >
                <ImageIcon className="w-5 h-5 text-secondary-foreground" strokeWidth={2} />
                <span className="font-semibold text-secondary-foreground">Choose from Gallery</span>
              </button>
            </div>
          </div>
        ) : (
          <div className="space-y-4">
            {/* Captured Image */}
            <div className="relative">
              <img
                src={capturedImage}
                alt="Captured receipt"
                className="w-full aspect-[3/4] object-cover rounded-[24px] elevation-2"
              />
              <button
                onClick={handleReset}
                className="absolute top-3 right-3 w-10 h-10 rounded-full bg-black/60 backdrop-blur-sm
                           flex items-center justify-center touch-manipulation active:scale-95 transition-transform"
                aria-label="Remove image"
              >
                <X className="w-4.5 h-4.5 text-white" strokeWidth={2.5} />
              </button>

              {/* Processing Overlay */}
              {isProcessing && (
                <div className="absolute inset-0 bg-primary/90 backdrop-blur-md rounded-[24px] 
                               flex flex-col items-center justify-center gap-5">
                  <div className="relative">
                    <div className="w-16 h-16 rounded-full bg-white/20 flex items-center justify-center">
                      <Loader2 className="w-8 h-8 text-primary-foreground animate-spin" strokeWidth={2.5} />
                    </div>
                    <Sparkles className="absolute -top-1 -right-1 w-5 h-5 text-primary-foreground animate-pulse" />
                  </div>
                  <div className="text-center">
                    <p className="text-primary-foreground font-semibold text-lg">Extracting items...</p>
                    <p className="text-primary-foreground/70 text-sm mt-1">This may take a moment</p>
                  </div>
                </div>
              )}
            </div>

            {/* Extracted Data */}
            {extractedData && !isProcessing && (
              <div className="space-y-4">
                {/* Vendor */}
                <div className="bg-card rounded-[24px] p-5 border border-border/40 elevation-1">
                  <label className="text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-3 block">
                    Vendor Name
                  </label>
                  <input
                    type="text"
                    value={extractedData.vendor}
                    onChange={(e) => setExtractedData({ ...extractedData, vendor: e.target.value })}
                    className="w-full h-12 text-[15px] font-medium text-foreground bg-input rounded-[14px] px-4
                               border border-border outline-none focus:ring-2 focus:ring-primary/30 transition-all"
                  />
                </div>

                {/* Items */}
                <div className="bg-card rounded-[24px] p-5 border border-border/40 elevation-1">
                  <div className="flex items-center justify-between mb-4">
                    <span className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">
                      Items ({extractedData.items.length})
                    </span>
                    <button
                      onClick={addItem}
                      className="flex items-center gap-1.5 px-3.5 py-2 rounded-full bg-primary/10 dark:bg-primary/20
                                 text-primary text-sm font-semibold touch-manipulation 
                                 active:bg-primary/20 dark:active:bg-primary/30 transition-colors"
                    >
                      <Plus className="w-4 h-4" strokeWidth={2.5} />
                      Add
                    </button>
                  </div>
                  
                  <div className="space-y-3">
                    {extractedData.items.map((item) => {
                      const subtotal = item.price * item.quantity
                      const showSubtotal = item.quantity > 1 && item.price > 0
                      
                      return (
                        <div key={item.id} className="bg-muted/50 dark:bg-muted/30 rounded-[16px] p-3">
                          {/* Row 1: Item name + delete button */}
                          <div className="flex items-center gap-2 mb-2">
                            <input
                              type="text"
                              value={item.name}
                              onChange={(e) => updateItemName(item.id, e.target.value)}
                              placeholder="Item name"
                              className="flex-1 h-11 px-3.5 text-sm font-medium text-foreground bg-card rounded-[12px] 
                                         border border-border outline-none focus:ring-2 focus:ring-primary/30"
                            />
                            {extractedData.items.length > 1 && (
                              <button
                                onClick={() => removeItem(item.id)}
                                className="w-10 h-10 rounded-[10px] bg-destructive/10 dark:bg-destructive/20 flex items-center justify-center 
                                           touch-manipulation active:bg-destructive/20 dark:active:bg-destructive/30 transition-colors shrink-0"
                                aria-label="Remove item"
                              >
                                <Trash2 className="w-4 h-4 text-destructive" strokeWidth={2.5} />
                              </button>
                            )}
                          </div>
                          
                          {/* Row 2: Qty + Unit Price */}
                          <div className="flex items-center gap-2">
                            <div className="flex items-center gap-1.5">
                              <span className="text-xs text-muted-foreground shrink-0">Qty</span>
                              <input
                                type="number"
                                inputMode="numeric"
                                value={item.quantity || ""}
                                onChange={(e) => updateItemQuantity(item.id, parseInt(e.target.value) || 1)}
                                className="w-12 h-10 px-2 text-sm text-center font-medium text-foreground bg-card rounded-[10px] 
                                           border border-border outline-none focus:ring-2 focus:ring-primary/30"
                              />
                            </div>
                            <div className="flex items-center gap-1.5 flex-1 min-w-0">
                              <span className="text-xs text-muted-foreground shrink-0">Rp</span>
                              <input
                                type="text"
                                inputMode="numeric"
                                value={item.price > 0 ? item.price.toLocaleString("id-ID") : ""}
                                onChange={(e) => {
                                  const rawValue = e.target.value.replace(/\D/g, "")
                                  updateItemPrice(item.id, parseInt(rawValue, 10) || 0)
                                }}
                                placeholder="0"
                                className="flex-1 min-w-0 h-10 px-3 text-sm text-right font-semibold text-foreground bg-card rounded-[10px] 
                                           border border-border outline-none focus:ring-2 focus:ring-primary/30"
                              />
                            </div>
                          </div>
                          
                          {/* Row 3: Subtotal (only when qty > 1) */}
                          {showSubtotal && (
                            <div className="mt-2 pt-2 border-t border-border/30 flex items-center justify-end">
                              <span className="text-xs text-muted-foreground mr-1.5">Subtotal:</span>
                              <span className="text-sm font-semibold text-primary">
                                {formatRupiah(subtotal)}
                              </span>
                            </div>
                          )}
                        </div>
                      )
                    })}
                  </div>
                </div>

                {/* Tax */}
                <div className="bg-card rounded-[24px] p-5 border border-border/40 elevation-1">
                  <label className="text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-3 block">
                    Tax (proportional split)
                  </label>
                  <div className="flex items-center gap-2">
                    <span className="text-sm text-muted-foreground shrink-0">Rp</span>
                    <input
                      type="text"
                      inputMode="numeric"
                      value={extractedData.tax > 0 ? extractedData.tax.toLocaleString("id-ID") : ""}
                      onChange={(e) => {
                        const rawValue = e.target.value.replace(/\D/g, "")
                        setExtractedData({ ...extractedData, tax: parseInt(rawValue, 10) || 0 })
                      }}
                      placeholder="0"
                      className="w-full h-12 text-[15px] font-medium text-foreground bg-input rounded-[14px] px-4
                                 border border-border outline-none focus:ring-2 focus:ring-primary/30 transition-all"
                    />
                  </div>
                </div>

                {/* Total */}
                <div className="bg-gradient-to-r from-primary/15 to-primary/5 dark:from-primary/25 dark:to-primary/10 
                                rounded-[24px] p-5 border border-primary/20 dark:border-primary/30">
                  <div className="flex items-center justify-between">
                    <span className="text-sm font-semibold text-foreground">Total</span>
                    <span className="text-display text-2xl text-primary">
                      {formatRupiah(calculatedTotal)}
                    </span>
                  </div>
                </div>
              </div>
            )}
          </div>
        )}
      </section>

      {/* Continue Button — anchored to bottom, hides on scroll-down */}
      {extractedData && !isProcessing && (
        <div
          className={`fixed left-4 right-4 z-30 transition-all duration-300 ease-in-out
                      ${buttonVisible
                        ? "bottom-[calc(env(safe-area-inset-bottom)+1.25rem)] opacity-100 translate-y-0"
                        : "bottom-[calc(env(safe-area-inset-bottom)+1.25rem)] opacity-0 translate-y-6 pointer-events-none"
                      }`}
        >
          <button
            onClick={handleContinue}
            className="w-full h-14 bg-primary text-primary-foreground rounded-full
                       font-semibold text-[15px] elevation-3
                       flex items-center justify-center gap-2.5
                       touch-manipulation active:scale-[0.98]
                       transition-transform duration-150"
          >
            <span>Continue to Split</span>
            <ArrowRight className="w-5 h-5" strokeWidth={2.5} />
          </button>
        </div>
      )}

      {/* Add Expense Sheet */}
      <AddExpenseSheet
        open={showAddExpense}
        onOpenChange={(open) => setShowAddExpense(open)}
        initialItems={expenseItems}
        initialTax={extractedData?.tax}
        initialImage={capturedImage || undefined}
        initialDescription={extractedData?.vendor}
        onExpenseAdded={handleExpenseAdded}
      />
    </div>
  )
}
