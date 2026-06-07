import { create } from 'zustand';
import { createClient } from './supabase/client';

export type Transaction = {
  id: string;
  title: string;
  category: string;
  amount: number;
  date: string;
  type: 'INCOME' | 'EXPENSE';
  icon?: string;
};

export type Budget = {
  id: string;
  category: string;
  allocated: number;
  spent: number;
  icon: string;
  color: string;
};

interface AppState {
  transactions: Transaction[];
  budgets: Budget[];
  isLoading: boolean;
  isAddModalOpen: boolean;
  fetchData: () => Promise<void>;
  addTransaction: (txn: Omit<Transaction, 'id' | 'icon'>) => Promise<void>;
  setAddModalOpen: (open: boolean) => void;
}

// Mock fallback data for when Supabase isn't configured
const MOCK_TRANSACTIONS: Transaction[] = [
  { id: '1', title: 'Spotify Premium', category: 'Subscriptions', amount: -119, date: new Date().toISOString(), type: 'EXPENSE', icon: 'music' },
  { id: '2', title: 'Swiggy Dinner', category: 'Food Delivery', amount: -350, date: new Date(Date.now() - 86400000).toISOString(), type: 'EXPENSE', icon: 'pizza' },
  { id: '3', title: 'Freelance Design', category: 'Income', amount: 5000, date: new Date(Date.now() - 172800000).toISOString(), type: 'INCOME', icon: 'briefcase' },
  { id: '4', title: 'Uber to College', category: 'Transport', amount: -180, date: new Date(Date.now() - 259200000).toISOString(), type: 'EXPENSE', icon: 'car' },
];

const MOCK_BUDGETS: Budget[] = [
  { id: '1', category: 'Food Delivery', allocated: 4000, spent: 3200, icon: 'pizza', color: 'rose' },
  { id: '2', category: 'Subscriptions', allocated: 1000, spent: 850, icon: 'music', color: 'indigo' },
  { id: '3', category: 'Transport', allocated: 2500, spent: 1200, icon: 'car', color: 'amber' },
];

export const useAppStore = create<AppState>((set, get) => ({
  transactions: [],
  budgets: [],
  isLoading: false,
  isAddModalOpen: false,
  setAddModalOpen: (open) => set({ isAddModalOpen: open }),
  fetchData: async () => {
    set({ isLoading: true });
    try {
      const supabase = createClient();
      
      const { data: txns, error: txnsError } = await supabase.from('transactions').select('*').order('date', { ascending: false });
      const { data: budgets, error: budgetsError } = await supabase.from('budgets').select('*');

      if (!txnsError && txns && txns.length > 0) {
        set({ transactions: txns as Transaction[] });
      } else {
        set({ transactions: MOCK_TRANSACTIONS });
      }
      
      if (!budgetsError && budgets && budgets.length > 0) {
        set({ budgets: budgets as Budget[] });
      } else {
        set({ budgets: MOCK_BUDGETS });
      }
    } catch (e) {
      console.warn("Using fallback mock data.", e);
      set({ transactions: MOCK_TRANSACTIONS, budgets: MOCK_BUDGETS });
    } finally {
      set({ isLoading: false });
    }
  },
  addTransaction: async (txnData) => {
    const newTxn: Transaction = {
      ...txnData,
      id: Math.random().toString(36).substring(7),
      icon: 'receipt', // Default icon
    };

    // Optimistic update
    set((state) => ({ transactions: [newTxn, ...state.transactions] }));

    try {
      const supabase = createClient();
      // Omit the locally generated non-UUID 'id' so Supabase can generate a valid UUID
      const { id, ...insertData } = newTxn;
      
      const { error } = await supabase.from('transactions').insert([insertData]);
      
      if (error) {
        console.error("Supabase insert error:", error);
      }
    } catch (e) {
      console.error("Failed to sync new transaction to Supabase. Kept locally.", e);
    }
  }
}));
