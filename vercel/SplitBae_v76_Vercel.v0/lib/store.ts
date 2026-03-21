"use client"

// SplitBae Store - Bill Splitting State Management
import { create } from "zustand"
import { persist } from "zustand/middleware"
import type { Person, Transaction, ExpenseItem, Category, Payment, Settlement } from "./types"
import { PERSON_COLORS } from "./types"

interface AppState {
  // Global people directory
  people: Person[]
  
  // All transactions (chronological)
  transactions: Transaction[]
  
  // Currently editing transaction
  editingTransactionId: string | null
  
  // Person actions
  addPerson: (name: string) => Person
  removePerson: (id: string) => void
  getPersonById: (id: string) => Person | undefined
  
  // Get recommended people based on who user frequently transacts with
  getRecommendedPeople: (selectedIds: string[]) => Person[]
  
  // Search people
  searchPeople: (query: string) => Person[]
  
  // Transaction actions
  addTransaction: (
    description: string,
    category: Category,
    items: ExpenseItem[],
    tax: number,
    participantIds: string[],
    payments: Payment[],
    receiptImage?: string,
    date?: Date
  ) => void
  
  updateTransaction: (
    transactionId: string,
    description: string,
    category: Category,
    items: ExpenseItem[],
    tax: number,
    participantIds: string[],
    payments: Payment[],
    receiptImage?: string,
    date?: Date
  ) => void
  
  deleteTransaction: (id: string) => void
  
  setEditingTransaction: (id: string | null) => void
  getEditingTransaction: () => Transaction | undefined
  
  // Calculations
  calculatePersonShare: (transaction: Transaction, personId: string) => number
  calculateBalances: () => Map<string, number>
  calculateSettlements: () => Settlement[]
  
  // Settlement actions
  recordSettlement: (fromId: string, toId: string, amount: number, note?: string) => void
  
  // Data management
  clearAllData: () => void
  importData: (data: { people: Person[]; transactions: Transaction[] }) => void
}

const generateId = () => Math.random().toString(36).substr(2, 9)

const generateInitials = (name: string) => {
  return name.split(" ").map(n => n[0]).join("").toUpperCase().slice(0, 2)
}

// Sample data
const samplePeople: Person[] = [
  { id: "1", name: "Sarah Chen", avatar: "SC", color: PERSON_COLORS[0], frequentWith: ["2", "3", "4"], transactionCount: 5 },
  { id: "2", name: "Michael Adi", avatar: "MA", color: PERSON_COLORS[1], frequentWith: ["1", "3"], transactionCount: 4 },
  { id: "3", name: "Rizky Pratama", avatar: "RP", color: PERSON_COLORS[2], frequentWith: ["1", "2", "4"], transactionCount: 3 },
  { id: "4", name: "Dewi Kartika", avatar: "DK", color: PERSON_COLORS[3], frequentWith: ["1", "3"], transactionCount: 2 },
]

const sampleItems: ExpenseItem[] = [
  { id: "item1", name: "Nasi Goreng Seafood", price: 45000, quantity: 1, assignedTo: ["1"] },
  { id: "item2", name: "Mie Goreng Spesial", price: 35000, quantity: 1, assignedTo: ["2"] },
  { id: "item3", name: "Ayam Bakar", price: 50000, quantity: 1, assignedTo: ["3"] },
  { id: "item4", name: "Es Teh Manis", price: 20000, quantity: 4, assignedTo: [] },
  { id: "item5", name: "Kerupuk", price: 10000, quantity: 1, assignedTo: ["1", "2", "4"] },
]

const sampleTransactions: Transaction[] = [
  {
    id: "txn1",
    description: "Dinner at Warteg Bahari",
    totalAmount: 180000,
    category: "food",
    items: sampleItems,
    tax: 20000,
    participants: ["1", "2", "3", "4"],
    payments: [{ personId: "1", amount: 180000 }],
    createdAt: new Date(),
  },
]

export const useSplitStore = create<AppState>()(
  persist(
    (set, get) => ({
      people: samplePeople,
      transactions: sampleTransactions,
      editingTransactionId: null,
      
      addPerson: (name) => {
        const { people } = get()
        // Assign next available color
        const usedColors = new Set(people.map(p => p.color))
        const availableColor = PERSON_COLORS.find(c => !usedColors.has(c)) || 
          PERSON_COLORS[people.length % PERSON_COLORS.length]
        
        const newPerson: Person = {
          id: generateId(),
          name,
          avatar: generateInitials(name),
          color: availableColor,
          frequentWith: [],
          transactionCount: 0,
        }
        set((state) => ({ people: [...state.people, newPerson] }))
        return newPerson
      },
      
      removePerson: (id) => {
        set((state) => ({
          people: state.people.filter(p => p.id !== id),
        }))
      },
      
      getPersonById: (id) => {
        return get().people.find(p => p.id === id)
      },
      
      // Recommend people who are frequently together with already selected people
      getRecommendedPeople: (selectedIds) => {
        const { people } = get()
        
        if (selectedIds.length === 0) {
          // Return most frequent people
          return [...people].sort((a, b) => b.transactionCount - a.transactionCount)
        }
        
        // Find people who are frequently with selected people
        const frequencyScore = new Map<string, number>()
        
        selectedIds.forEach(selectedId => {
          const person = people.find(p => p.id === selectedId)
          if (person) {
            person.frequentWith.forEach(otherId => {
              if (!selectedIds.includes(otherId)) {
                frequencyScore.set(otherId, (frequencyScore.get(otherId) || 0) + 1)
              }
            })
          }
        })
        
        // Sort by frequency score, then by transaction count
        return people
          .filter(p => !selectedIds.includes(p.id))
          .sort((a, b) => {
            const scoreA = frequencyScore.get(a.id) || 0
            const scoreB = frequencyScore.get(b.id) || 0
            if (scoreB !== scoreA) return scoreB - scoreA
            return b.transactionCount - a.transactionCount
          })
      },
      
      searchPeople: (query) => {
        const { people } = get()
        const lowerQuery = query.toLowerCase().trim()
        if (!lowerQuery) return people
        return people.filter(p => p.name.toLowerCase().includes(lowerQuery))
      },
      
      addTransaction: (description, category, items, tax, participantIds, payments, receiptImage, date) => {
        const itemsTotal = items.reduce((sum, item) => sum + item.price, 0)
        const totalAmount = itemsTotal + tax
        
        const newTransaction: Transaction = {
          id: generateId(),
          description,
          totalAmount,
          category,
          items,
          tax,
          participants: participantIds,
          payments,
          receiptImage,
          createdAt: date || new Date(),
        }
        
        // Update frequency data for participants
        set((state) => {
          const updatedPeople = state.people.map(person => {
            if (participantIds.includes(person.id)) {
              // Add other participants to frequentWith
              const newFrequentWith = new Set(person.frequentWith)
              participantIds.forEach(otherId => {
                if (otherId !== person.id) {
                  newFrequentWith.add(otherId)
                }
              })
              
              return {
                ...person,
                frequentWith: Array.from(newFrequentWith),
                transactionCount: person.transactionCount + 1,
              }
            }
            return person
          })
          
          return {
            people: updatedPeople,
            transactions: [newTransaction, ...state.transactions],
          }
        })
      },
      
      updateTransaction: (transactionId, description, category, items, tax, participantIds, payments, receiptImage, date) => {
        const itemsTotal = items.reduce((sum, item) => sum + item.price, 0)
        const totalAmount = itemsTotal + tax
        
        set((state) => ({
          transactions: state.transactions.map(txn =>
            txn.id === transactionId
              ? {
                  ...txn,
                  description,
                  totalAmount,
                  category,
                  items,
                  tax,
                  participants: participantIds,
                  payments,
                  receiptImage,
                  ...(date ? { createdAt: date } : {}),
                }
              : txn
          ),
          editingTransactionId: null,
        }))
      },
      
      deleteTransaction: (id) => {
        set((state) => ({
          transactions: state.transactions.filter(t => t.id !== id),
        }))
      },
      
      setEditingTransaction: (id) => {
        set({ editingTransactionId: id })
      },
      
      getEditingTransaction: () => {
        const { transactions, editingTransactionId } = get()
        return transactions.find(t => t.id === editingTransactionId)
      },
      
      // Calculate how much a person owes for a transaction
      calculatePersonShare: (transaction, personId) => {
        if (!transaction.participants.includes(personId)) return 0
        
        const participantCount = transaction.participants.length
        
        // First, calculate subtotal for this person and total subtotal
        // Note: item.price is the TOTAL price for that line (price * quantity already multiplied)
        let personItemTotal = 0
        let totalSubtotal = 0
        
        transaction.items.forEach(item => {
          const itemTotal = item.price // Already includes quantity in the stored price
          totalSubtotal += itemTotal
          
          if (item.assignedTo.length === 0) {
            // Shared by all participants equally
            personItemTotal += itemTotal / participantCount
          } else if (item.assignedTo.includes(personId)) {
            // Assigned to specific people including this person
            personItemTotal += itemTotal / item.assignedTo.length
          }
        })
        
        // Tax is split proportionally based on each person's share of the subtotal
        // If total subtotal is 0, fall back to equal split
        const taxShare = totalSubtotal > 0 
          ? (personItemTotal / totalSubtotal) * transaction.tax
          : transaction.tax / participantCount
        
        return Math.round((personItemTotal + taxShare) * 100) / 100 // Round to 2 decimal places
      },
      
      // Calculate net balance for each person
      // Positive = they are owed money (paid more than their share)
      // Negative = they owe money (paid less than their share)
      calculateBalances: () => {
        const { transactions, calculatePersonShare } = get()
        const balances = new Map<string, number>()
        
        transactions.forEach(transaction => {
          // Add what each payer paid (positive - they fronted the money)
          transaction.payments.forEach(payment => {
            const current = balances.get(payment.personId) || 0
            balances.set(payment.personId, current + payment.amount)
          })
          
          // Subtract what each participant owes (their share of the bill)
          transaction.participants.forEach(personId => {
            const owes = calculatePersonShare(transaction, personId)
            const current = balances.get(personId) || 0
            balances.set(personId, current - owes)
          })
        })
        
        // Round all balances to avoid floating point issues
        balances.forEach((balance, id) => {
          balances.set(id, Math.round(balance * 100) / 100)
        })
        
        return balances
      },
      
      // Calculate optimal settlements (who pays whom)
      // Uses a greedy algorithm: match largest debtor with largest creditor
      calculateSettlements: () => {
        const balances = get().calculateBalances()
        
        // Separate into creditors (owed money, positive balance) and debtors (owe money, negative balance)
        // Use rounded amounts to avoid floating point issues
        const creditors: { id: string; amount: number }[] = []
        const debtors: { id: string; amount: number }[] = []
        
        balances.forEach((balance, id) => {
          const rounded = Math.round(balance * 100) / 100
          if (rounded > 0.01) {
            creditors.push({ id, amount: rounded })
          } else if (rounded < -0.01) {
            debtors.push({ id, amount: Math.abs(rounded) })
          }
        })
        
        // Sort by amount (descending) - largest amounts first for fewer transactions
        creditors.sort((a, b) => b.amount - a.amount)
        debtors.sort((a, b) => b.amount - a.amount)
        
        const settlements: Settlement[] = []
        
        // Greedy matching: pair off debtors and creditors
        let i = 0 // debtor index
        let j = 0 // creditor index
        
        while (i < debtors.length && j < creditors.length) {
          const debtor = debtors[i]
          const creditor = creditors[j]
          
          // Settlement amount is the smaller of what debtor owes and what creditor is owed
          const amount = Math.round(Math.min(debtor.amount, creditor.amount) * 100) / 100
          
          if (amount > 0) {
            settlements.push({
              from: debtor.id,
              to: creditor.id,
              amount,
            })
            
            // Reduce remaining amounts
            debtor.amount = Math.round((debtor.amount - amount) * 100) / 100
            creditor.amount = Math.round((creditor.amount - amount) * 100) / 100
          }
          
          // Move to next debtor/creditor if current one is settled
          if (debtor.amount <= 0.01) i++
          if (creditor.amount <= 0.01) j++
        }
        
        return settlements
      },
      
      // Record a settlement (creates a special transaction that offsets balances)
      recordSettlement: (fromId, toId, amount, note) => {
        const { people } = get()
        const fromPerson = people.find(p => p.id === fromId)
        const toPerson = people.find(p => p.id === toId)
        
        if (!fromPerson || !toPerson) return
        
        // Create a settlement transaction
        // The "from" person pays the "to" person, which is recorded as:
        // - Both are participants
        // - "From" person pays the amount
        // - A single item representing the settlement (assigned to "to" person)
        const settlementTransaction: Transaction = {
          id: generateId(),
          description: note || `Settlement: ${fromPerson.name} → ${toPerson.name}`,
          totalAmount: amount,
          category: "settlement",
          items: [{
            id: generateId(),
            name: "Settlement payment",
            price: amount,
            quantity: 1,
            assignedTo: [toId], // The person receiving the money "consumed" this item
          }],
          tax: 0,
          participants: [fromId, toId],
          payments: [{ personId: fromId, amount }], // From pays the amount
          createdAt: new Date(),
        }
        
        set((state) => ({
          transactions: [settlementTransaction, ...state.transactions],
        }))
      },

      // Clear all data
      clearAllData: () => {
        set({ people: [], transactions: [] })
      },
      
      // Import data from backup
      importData: (data) => {
        set({
          people: data.people,
          transactions: data.transactions.map(t => ({
            ...t,
            createdAt: typeof t.createdAt === "string" ? new Date(t.createdAt) : t.createdAt,
          })),
        })
      },
    }),
    {
      name: "splitbae-storage",
      partialize: (state) => ({
        people: state.people,
        transactions: state.transactions.map(t => ({
          ...t,
          createdAt: t.createdAt.toISOString(),
        })),
      }),
      onRehydrateStorage: () => (state) => {
        if (state) {
          state.transactions = state.transactions.map(t => ({
            ...t,
            createdAt: new Date(t.createdAt as unknown as string),
          }))
        }
      },
    }
  )
)
