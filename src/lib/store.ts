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

export type Goal = {
  id: string;
  name: string;
  target: number;
  saved: number;
  target_date: string;
  color: string;
};

export type UserProfile = {
  id: string;
  email: string;
  full_name: string | null;
  avatar_url: string | null;
};

interface AppState {
  userProfile: UserProfile | null;
  transactions: Transaction[];
  budgets: Budget[];
  goals: Goal[];
  isLoading: boolean;
  
  isAddModalOpen: boolean;
  editingTransaction: Transaction | null;
  
  isBudgetModalOpen: boolean;
  editingBudget: Budget | null;

  isGoalModalOpen: boolean;
  editingGoal: Goal | null;

  isDepositModalOpen: boolean;
  activeGoalForDeposit: Goal | null;

  isProfileModalOpen: boolean;
  
  isAIOpen: boolean;
  aiInitialMsg: string;

  theme: 'light' | 'dark';
  toggleTheme: () => void;

  fetchData: () => Promise<void>;
  
  setAddModalOpen: (open: boolean, txn?: Transaction) => void;
  setBudgetModalOpen: (open: boolean, budget?: Budget) => void;
  setGoalModalOpen: (open: boolean, goal?: Goal) => void;
  setDepositModalOpen: (open: boolean, goal?: Goal) => void;
  setProfileModalOpen: (open: boolean) => void;
  setAIOpen: (open: boolean, msg?: string) => void;

  updateProfile: (profile: Partial<UserProfile>) => Promise<void>;
  addTransaction: (txn: Omit<Transaction, 'id'>) => Promise<void>;
  updateTransaction: (id: string, txn: Partial<Transaction>) => Promise<void>;
  deleteTransaction: (id: string) => Promise<void>;

  addBudget: (budget: Omit<Budget, 'id'>) => Promise<void>;
  updateBudget: (id: string, budget: Partial<Budget>) => Promise<void>;
  deleteBudget: (id: string) => Promise<void>;

  addGoal: (goal: Omit<Goal, 'id' | 'saved'>) => Promise<void>;
  updateGoal: (id: string, goal: Partial<Goal>) => Promise<void>;
  deleteGoal: (id: string) => Promise<void>;
  depositToGoal: (id: string, amount: number) => Promise<void>;
  sweepLeftover: () => Promise<void>;
}

export const useAppStore = create<AppState>((set, get) => ({
  userProfile: null,
  transactions: [],
  budgets: [],
  goals: [],
  isLoading: false,
  
  isAddModalOpen: false,
  editingTransaction: null,
  
  isBudgetModalOpen: false,
  editingBudget: null,

  isGoalModalOpen: false,
  editingGoal: null,

  isDepositModalOpen: false,
  activeGoalForDeposit: null,

  isProfileModalOpen: false,
  
  isAIOpen: false,
  aiInitialMsg: '',

  theme: 'light',
  toggleTheme: () => set((state) => {
    const newTheme = state.theme === 'light' ? 'dark' : 'light';
    if (typeof document !== 'undefined') {
      if (newTheme === 'dark') document.documentElement.classList.add('dark');
      else document.documentElement.classList.remove('dark');
    }
    return { theme: newTheme };
  }),

  setAddModalOpen: (open, txn = undefined) => set({ isAddModalOpen: open, editingTransaction: txn || null }),
  setBudgetModalOpen: (open, budget = undefined) => set({ isBudgetModalOpen: open, editingBudget: budget || null }),
  setGoalModalOpen: (open, goal = undefined) => set({ isGoalModalOpen: open, editingGoal: goal || null }),
  setDepositModalOpen: (open, goal = undefined) => set({ isDepositModalOpen: open, activeGoalForDeposit: goal || null }),
  setProfileModalOpen: (open) => set({ isProfileModalOpen: open }),
  setAIOpen: (open, msg = '') => set({ isAIOpen: open, aiInitialMsg: msg }),

  fetchData: async () => {
    set({ isLoading: true });
    try {
      const supabase = createClient();
      
      const { data: sessionData } = await supabase.auth.getSession();
      const sessionAvatar = sessionData.session?.user?.user_metadata?.avatar_url;

      const { data: profile } = await supabase.from('profiles').select('*').single();
      const { data: txns, error: txnsError } = await supabase.from('transactions').select('*').order('date', { ascending: false });
      const { data: budgets, error: budgetsError } = await supabase.from('budgets').select('*');
      const { data: goals, error: goalsError } = await supabase.from('goals').select('*');

      if (profile) {
        set({ 
          userProfile: {
            ...profile,
            avatar_url: profile.avatar_url || sessionAvatar || null
          } as UserProfile 
        });
      }
      if (!txnsError && txns) set({ transactions: txns as Transaction[] });
      if (!budgetsError && budgets) set({ budgets: budgets as Budget[] });
      if (!goalsError && goals) set({ goals: goals as Goal[] });
    } catch (e) {
      console.error("Failed to fetch data.", e);
    } finally {
      set({ isLoading: false });
    }
  },

  updateProfile: async (profileUpdates: Partial<UserProfile>) => {
    const supabase = createClient();
    const { data: userData } = await supabase.auth.getUser();
    if (!userData.user) return;

    const { error } = await supabase
      .from('profiles')
      .update(profileUpdates)
      .eq('id', userData.user.id);
      
    if (!error) {
      set((state) => ({
        userProfile: state.userProfile ? { ...state.userProfile, ...profileUpdates } : null
      }));
    }
  },

  addTransaction: async (txnData) => {
    const newTxn: Transaction = {
      ...txnData,
      id: Math.random().toString(36).substring(7),
    };

    set((state) => ({ transactions: [newTxn, ...state.transactions] }));

    try {
      const supabase = createClient();
      const { id, ...insertData } = newTxn;
      
      const { data, error } = await supabase.from('transactions').insert([insertData]).select().single();
      
      if (error) throw error;
      
      // Update with real ID from Supabase
      if (data) {
        set((state) => ({
          transactions: state.transactions.map(t => t.id === id ? data as Transaction : t)
        }));
      }
    } catch (e) {
      console.error("Failed to sync new transaction to Supabase.", e);
    }
  },

  updateTransaction: async (id, txnData) => {
    set((state) => ({
      transactions: state.transactions.map(t => t.id === id ? { ...t, ...txnData } : t)
    }));

    try {
      const supabase = createClient();
      const { error } = await supabase.from('transactions').update(txnData).eq('id', id);
      if (error) throw error;
    } catch (e) {
      console.error("Failed to update transaction in Supabase.", e);
    }
  },

  deleteTransaction: async (id) => {
    set((state) => ({
      transactions: state.transactions.filter(t => t.id !== id)
    }));

    try {
      const supabase = createClient();
      const { error } = await supabase.from('transactions').delete().eq('id', id);
      if (error) throw error;
    } catch (e) {
      console.error("Failed to delete transaction in Supabase.", e);
    }
  },

  addBudget: async (budgetData) => {
    const newBudget: Budget = {
      ...budgetData,
      id: Math.random().toString(36).substring(7),
    };

    set((state) => ({ budgets: [...state.budgets, newBudget] }));

    try {
      const supabase = createClient();
      const { id, ...insertData } = newBudget;
      
      const { data, error } = await supabase.from('budgets').insert([insertData]).select().single();
      
      if (error) throw error;
      
      if (data) {
        set((state) => ({
          budgets: state.budgets.map(b => b.id === id ? data as Budget : b)
        }));
      }
    } catch (e) {
      console.error("Failed to sync new budget to Supabase.", e);
    }
  },

  updateBudget: async (id, budgetData) => {
    set((state) => ({
      budgets: state.budgets.map(b => b.id === id ? { ...b, ...budgetData } : b)
    }));

    try {
      const supabase = createClient();
      const { error } = await supabase.from('budgets').update(budgetData).eq('id', id);
      if (error) throw error;
    } catch (e) {
      console.error("Failed to update budget in Supabase.", e);
    }
  },

  deleteBudget: async (id) => {
    set((state) => ({
      budgets: state.budgets.filter(b => b.id !== id)
    }));

    try {
      const supabase = createClient();
      const { error } = await supabase.from('budgets').delete().eq('id', id);
      if (error) throw error;
    } catch (e) {
      console.error("Failed to delete budget in Supabase.", e);
    }
  },

  addGoal: async (goalData) => {
    const newGoal: Goal = {
      ...goalData,
      id: Math.random().toString(36).substring(7),
      saved: 0,
    };
    set(state => ({ goals: [...state.goals, newGoal] }));

    try {
      const supabase = createClient();
      const { id, ...insertData } = newGoal;
      const { data, error } = await supabase.from('goals').insert([insertData]).select().single();
      if (error) throw error;
      if (data) set(state => ({ goals: state.goals.map(g => g.id === id ? data as Goal : g) }));
    } catch (e) {
      console.error(e);
    }
  },

  updateGoal: async (id, goalData) => {
    set(state => ({ goals: state.goals.map(g => g.id === id ? { ...g, ...goalData } : g) }));
    try {
      const supabase = createClient();
      await supabase.from('goals').update(goalData).eq('id', id);
    } catch (e) {
      console.error(e);
    }
  },

  deleteGoal: async (id) => {
    set(state => ({ goals: state.goals.filter(g => g.id !== id) }));
    try {
      const supabase = createClient();
      await supabase.from('goals').delete().eq('id', id);
    } catch (e) {
      console.error(e);
    }
  },

  depositToGoal: async (id, amount) => {
    const state = get();
    const goal = state.goals.find(g => g.id === id);
    if (!goal) return;

    // 1. Update Goal saved amount
    const newSaved = goal.saved + amount;
    set(state => ({ goals: state.goals.map(g => g.id === id ? { ...g, saved: newSaved } : g) }));

    try {
      const supabase = createClient();
      await supabase.from('goals').update({ saved: newSaved }).eq('id', id);
      
      // 2. Add an EXPENSE transaction for the deposit to deduct from Total Balance
      await state.addTransaction({
        title: `Deposit to ${goal.name}`,
        category: 'Savings',
        amount: -amount,
        type: 'EXPENSE',
        date: new Date().toISOString()
      });
    } catch (e) {
      console.error(e);
    }
  },

  sweepLeftover: async () => {
    const state = get();
    const totalIncome = state.transactions.filter(t => t.type === 'INCOME').reduce((acc, curr) => acc + curr.amount, 0);
    const totalExpense = state.transactions.filter(t => t.type === 'EXPENSE').reduce((acc, curr) => acc + Math.abs(curr.amount), 0);
    const leftover = totalIncome - totalExpense;

    if (leftover <= 0 || state.goals.length === 0) return;

    const sweepPerGoal = Math.floor(leftover / state.goals.length);
    if (sweepPerGoal <= 0) return;

    // Distribute to all goals
    for (const goal of state.goals) {
      await state.depositToGoal(goal.id, sweepPerGoal);
    }
  }
}));
