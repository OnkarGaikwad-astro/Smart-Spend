import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
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

export type DebtEntry = {
  id: string;
  debt_id?: string;
  amount: number;
  type: 'LENT' | 'BORROWED' | 'REPAID';
  note: string;
  date: string;
};

export type Debt = {
  id: string;
  user_id?: string;
  person_name: string;
  phone_number?: string | null;
  type: 'LENT' | 'BORROWED'; // 'LENT' (You'll Get) or 'BORROWED' (You'll Give)
  entries: DebtEntry[];
  created_at: string;
  updated_at: string;
};

export const getDebtTotalOwed = (debt: Debt): number => {
  let total = 0;
  for (const entry of debt.entries) {
    if (entry.type === 'LENT' || entry.type === 'BORROWED') {
      total += entry.amount;
    } else if (entry.type === 'REPAID') {
      total -= entry.amount;
    }
  }
  return Math.max(0, total);
};

export const getDebtTotalPrincipal = (debt: Debt): number => {
  let total = 0;
  for (const entry of debt.entries) {
    if (entry.type === 'LENT' || entry.type === 'BORROWED') {
      total += entry.amount;
    }
  }
  return total;
};

export const getDebtTotalRepaid = (debt: Debt): number => {
  let total = 0;
  for (const entry of debt.entries) {
    if (entry.type === 'REPAID') {
      total += entry.amount;
    }
  }
  return total;
};

export const isDebtSettled = (debt: Debt): boolean => {
  return getDebtTotalOwed(debt) <= 0 && debt.entries.length > 0;
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
  debts: Debt[];
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

  isAddDebtModalOpen: boolean;
  isRepaymentModalOpen: boolean;
  activeDebtForAction: Debt | null;
  isDebtDetailsModalOpen: boolean;
  activeDebtForDetails: Debt | null;
  
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
  setAddDebtModalOpen: (open: boolean) => void;
  setRepaymentModalOpen: (open: boolean, debt?: Debt) => void;
  setDebtDetailsModalOpen: (open: boolean, debt?: Debt) => void;
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

  addDebt: (data: { person_name: string; phone_number?: string; type: 'LENT' | 'BORROWED'; initial_amount: number; note?: string }) => Promise<void>;
  addDebtEntry: (debtId: string, entry: { amount: number; type: 'LENT' | 'BORROWED' | 'REPAID'; note: string; date?: string }) => Promise<void>;
  deleteDebt: (debtId: string) => Promise<void>;
  deleteDebtEntry: (debtId: string, entryId: string) => Promise<void>;
}

export const useAppStore = create<AppState>()(
  persist(
    (set, get) => ({
  userProfile: null,
  transactions: [],
  budgets: [],
  goals: [],
  debts: [],
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

  isAddDebtModalOpen: false,
  isRepaymentModalOpen: false,
  activeDebtForAction: null,
  isDebtDetailsModalOpen: false,
  activeDebtForDetails: null,
  
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
  setAddDebtModalOpen: (open) => set({ isAddDebtModalOpen: open }),
  setRepaymentModalOpen: (open, debt = undefined) => set({ isRepaymentModalOpen: open, activeDebtForAction: debt || null }),
  setDebtDetailsModalOpen: (open, debt = undefined) => set({ isDebtDetailsModalOpen: open, activeDebtForDetails: debt || null }),
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
      } else if (!get().userProfile && typeof document !== 'undefined') {
        const match = document.cookie.match(/(?:^|; )smartspend_user=([^;]*)/);
        if (match && match[1]) {
          try {
            const parsed = JSON.parse(decodeURIComponent(match[1]));
            if (parsed?.email || parsed?.id) {
              set({ userProfile: parsed as UserProfile });
            }
          } catch {}
        }
      }
      if (!txnsError && txns) set({ transactions: txns as Transaction[] });
      if (!budgetsError && budgets) set({ budgets: budgets as Budget[] });
      if (!goalsError && goals) set({ goals: goals as Goal[] });

      // Fetch Debts & Debt Entries
      const { data: debtsData, error: debtsError } = await supabase.from('debts').select('*').order('updated_at', { ascending: false });
      const { data: entriesData, error: entriesError } = await supabase.from('debt_entries').select('*').order('date', { ascending: true });

      if (!debtsError && debtsData) {
        const assembledDebts: Debt[] = debtsData.map((d: any) => ({
          ...d,
          entries: (entriesData || []).filter((e: any) => e.debt_id === d.id) as DebtEntry[]
        }));
        set({ debts: assembledDebts });
      }
    } catch (e) {
      console.error("Failed to fetch data.", e);
    } finally {
      set({ isLoading: false });
    }
  },

  updateProfile: async (profileUpdates: Partial<UserProfile>) => {
    set((state) => {
      const updated = state.userProfile ? { ...state.userProfile, ...profileUpdates } : null;
      if (updated && typeof document !== 'undefined') {
        const maxAge = 60 * 60 * 24 * 30;
        const secureFlag = window.location.protocol === 'https:' ? '; Secure' : '';
        document.cookie = `smartspend_user=${encodeURIComponent(JSON.stringify(updated))}; path=/; max-age=${maxAge}; SameSite=Lax${secureFlag}`;
      }
      return { userProfile: updated };
    });

    try {
      const supabase = createClient();
      const { data: userData } = await supabase.auth.getUser();
      if (!userData?.user) return;

      await supabase
        .from('profiles')
        .update(profileUpdates)
        .eq('id', userData.user.id);
    } catch (e) {
      console.error("Failed to update profile in Supabase.", e);
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

      // Ensure user_id is set (same as Flutter SyncService)
      const { data: { user } } = await supabase.auth.getUser();
      const payload = {
        ...insertData,
        ...(user?.id ? { user_id: user.id } : {})
      };
      
      const { data, error } = await supabase.from('transactions').insert([payload]).select().single();
      
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
      const { data: { user } } = await supabase.auth.getUser();
      const payload = {
        ...insertData,
        ...(user?.id ? { user_id: user.id } : {})
      };
      
      const { data, error } = await supabase.from('budgets').insert([payload]).select().single();
      
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
      const { data: { user } } = await supabase.auth.getUser();
      const payload = {
        ...insertData,
        ...(user?.id ? { user_id: user.id } : {})
      };
      const { data, error } = await supabase.from('goals').insert([payload]).select().single();
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
  },

  addDebt: async ({ person_name, phone_number, type, initial_amount, note }) => {
    const tempDebtId = Math.random().toString(36).substring(7);
    const tempEntryId = Math.random().toString(36).substring(7);
    const now = new Date().toISOString();

    const initialEntry: DebtEntry = {
      id: tempEntryId,
      debt_id: tempDebtId,
      amount: initial_amount,
      type: type,
      note: note || (type === 'LENT' ? 'Lent money' : 'Borrowed money'),
      date: now,
    };

    const newDebt: Debt = {
      id: tempDebtId,
      person_name,
      phone_number: phone_number || null,
      type,
      entries: [initialEntry],
      created_at: now,
      updated_at: now,
    };

    set((state) => ({ debts: [newDebt, ...state.debts] }));

    try {
      const supabase = createClient();
      const { data: { user } } = await supabase.auth.getUser();

      const debtPayload = {
        person_name,
        phone_number: phone_number || null,
        type,
        ...(user?.id ? { user_id: user.id } : {})
      };

      const { data: createdDebt, error: dErr } = await supabase.from('debts').insert([debtPayload]).select().single();
      if (dErr) throw dErr;

      if (createdDebt) {
        const entryPayload = {
          debt_id: createdDebt.id,
          amount: initial_amount,
          type,
          note: initialEntry.note,
          date: now,
          ...(user?.id ? { user_id: user.id } : {})
        };

        const { data: createdEntry, error: eErr } = await supabase.from('debt_entries').insert([entryPayload]).select().single();
        if (eErr) throw eErr;

        set((state) => ({
          debts: state.debts.map((d) => 
            d.id === tempDebtId 
              ? { ...createdDebt, entries: [createdEntry as DebtEntry] } 
              : d
          )
        }));
      }
    } catch (e) {
      console.error("Failed to sync new debt to Supabase:", e);
    }
  },

  addDebtEntry: async (debtId, entryData) => {
    const tempEntryId = Math.random().toString(36).substring(7);
    const entryDate = entryData.date || new Date().toISOString();
    const newEntry: DebtEntry = {
      id: tempEntryId,
      debt_id: debtId,
      amount: entryData.amount,
      type: entryData.type,
      note: entryData.note,
      date: entryDate,
    };

    set((state) => ({
      debts: state.debts.map((d) => 
        d.id === debtId 
          ? { ...d, entries: [...d.entries, newEntry], updated_at: new Date().toISOString() } 
          : d
      )
    }));

    try {
      const supabase = createClient();
      const { data: { user } } = await supabase.auth.getUser();

      const payload = {
        debt_id: debtId,
        amount: entryData.amount,
        type: entryData.type,
        note: entryData.note,
        date: entryDate,
        ...(user?.id ? { user_id: user.id } : {})
      };

      const { data: createdEntry, error } = await supabase.from('debt_entries').insert([payload]).select().single();
      if (error) throw error;

      if (createdEntry) {
        await supabase.from('debts').update({ updated_at: new Date().toISOString() }).eq('id', debtId);
        set((state) => ({
          debts: state.debts.map((d) => 
            d.id === debtId 
              ? { ...d, entries: d.entries.map((e) => e.id === tempEntryId ? createdEntry as DebtEntry : e) }
              : d
          )
        }));
      }
    } catch (e) {
      console.error("Failed to sync debt entry to Supabase:", e);
    }
  },

  deleteDebt: async (debtId) => {
    set((state) => ({
      debts: state.debts.filter((d) => d.id !== debtId)
    }));

    try {
      const supabase = createClient();
      const { error } = await supabase.from('debts').delete().eq('id', debtId);
      if (error) throw error;
    } catch (e) {
      console.error("Failed to delete debt from Supabase:", e);
    }
  },

  deleteDebtEntry: async (debtId, entryId) => {
    set((state) => ({
      debts: state.debts.map((d) => 
        d.id === debtId 
          ? { ...d, entries: d.entries.filter((e) => e.id !== entryId) }
          : d
      )
    }));

    try {
      const supabase = createClient();
      const { error } = await supabase.from('debt_entries').delete().eq('id', entryId);
      if (error) throw error;
    } catch (e) {
      console.error("Failed to delete debt entry from Supabase:", e);
    }
  }
    }),
    {
      name: 'smartspend-storage',
      storage: createJSONStorage(() => localStorage),
      partialize: (state) => ({
        transactions: state.transactions,
        budgets: state.budgets,
        goals: state.goals,
        debts: state.debts,
        userProfile: state.userProfile,
        theme: state.theme,
      }),
    }
  )
);

export const useStore = useAppStore;

