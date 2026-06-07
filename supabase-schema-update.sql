-- Run this script in the Supabase SQL Editor!

-- 1. Wipe out the old dummy data from existing tables
TRUNCATE TABLE public.transactions;
TRUNCATE TABLE public.budgets;

-- 2. Add the secure user_id column to existing tables
ALTER TABLE public.transactions ADD COLUMN user_id UUID REFERENCES auth.users(id) DEFAULT auth.uid() NOT NULL;
ALTER TABLE public.budgets ADD COLUMN user_id UUID REFERENCES auth.users(id) DEFAULT auth.uid() NOT NULL;

-- 3. Drop the old insecure "public" policies
DROP POLICY IF EXISTS "Enable all actions for public" ON public.transactions;
DROP POLICY IF EXISTS "Enable all actions for public" ON public.budgets;

-- 4. Apply the new strictly secure RLS policies to existing tables
-- Transactions
CREATE POLICY "Users can view their own transactions" ON public.transactions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own transactions" ON public.transactions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own transactions" ON public.transactions FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete their own transactions" ON public.transactions FOR DELETE USING (auth.uid() = user_id);

-- Budgets
CREATE POLICY "Users can view their own budgets" ON public.budgets FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own budgets" ON public.budgets FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own budgets" ON public.budgets FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete their own budgets" ON public.budgets FOR DELETE USING (auth.uid() = user_id);

-- ==========================================
-- 5. CREATE THE MISSING GOALS TABLE
-- Since you didn't have the goals table yet, we will create it from scratch here with Auth already built-in!
-- ==========================================

CREATE TABLE public.goals (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) DEFAULT auth.uid() NOT NULL,
    name TEXT NOT NULL,
    target NUMERIC NOT NULL,
    saved NUMERIC NOT NULL DEFAULT 0,
    target_date TEXT NOT NULL,
    color TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security (RLS) for goals
ALTER TABLE public.goals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own goals" ON public.goals FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own goals" ON public.goals FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own goals" ON public.goals FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete their own goals" ON public.goals FOR DELETE USING (auth.uid() = user_id);
