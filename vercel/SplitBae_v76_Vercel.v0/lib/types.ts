export type Category = 
  | "food" 
  | "transport" 
  | "accommodation" 
  | "entertainment" 
  | "shopping" 
  | "utilities" 
  | "other"
  | "settlement" // For settle-up transactions

// Person colors for visual identification
export const PERSON_COLORS = [
  "#ef4444", // red
  "#22c55e", // green  
  "#3b82f6", // blue
  "#f97316", // orange
  "#a855f7", // purple
  "#ec4899", // pink
  "#14b8a6", // teal
  "#eab308", // yellow
  "#6366f1", // indigo
  "#84cc16", // lime
] as const

// Person in the app (global, not tied to groups)
export interface Person {
  id: string
  name: string
  avatar: string
  color: string // unique color for visual identification
  // Track who this person is often with (for recommendations)
  frequentWith: string[] // other person IDs
  transactionCount: number
}

// Individual item in a transaction
export interface ExpenseItem {
  id: string
  name: string
  price: number
  quantity: number
  assignedTo: string[] // person ids - empty means shared by all participants
}

// Payment by a person
export interface Payment {
  personId: string
  amount: number
}

// Transaction with multiple items
export interface Transaction {
  id: string
  description: string
  totalAmount: number
  category: Category
  items: ExpenseItem[]
  tax: number
  participants: string[] // person ids in this transaction
  payments: Payment[]
  receiptImage?: string
  createdAt: Date
}

// Settlement represents who owes whom
export interface Settlement {
  from: string // person id who owes
  to: string // person id who is owed
  amount: number
}

export const categoryConfig: Record<Category, { label: string; icon: string; color: string }> = {
  food: { label: "Food & Drinks", icon: "utensils", color: "bg-amber-500" },
  transport: { label: "Transport", icon: "car", color: "bg-blue-500" },
  accommodation: { label: "Accommodation", icon: "home", color: "bg-emerald-500" },
  entertainment: { label: "Entertainment", icon: "music", color: "bg-violet-500" },
  shopping: { label: "Shopping", icon: "shopping-bag", color: "bg-rose-500" },
  utilities: { label: "Utilities", icon: "zap", color: "bg-cyan-500" },
  other: { label: "Other", icon: "more-horizontal", color: "bg-slate-500" },
  settlement: { label: "Settlement", icon: "check-circle", color: "bg-emerald-500" },
}
