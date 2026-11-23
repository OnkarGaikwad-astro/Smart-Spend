-- SmartSpend AI - Debts & Khata Table Schema
-- Run this in the Supabase SQL Editor to enable cloud sync for Lent & Borrowed money!

-- 1. Create the debts table
CREATE TABLE IF NOT EXISTS public.debts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) DEFAULT auth.uid() NOT NULL,
    person_name TEXT NOT NULL,
    phone_number TEXT,
    type TEXT CHECK (type IN ('LENT', 'BORROWED')) NOT NULL DEFAULT 'LENT',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security (RLS) for debts
ALTER TABLE public.debts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own debts" ON public.debts
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own debts" ON public.debts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own debts" ON public.debts
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own debts" ON public.debts
    FOR DELETE USING (auth.uid() = user_id);


-- 2. Create the debt_entries table
CREATE TABLE IF NOT EXISTS public.debt_entries (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    debt_id UUID REFERENCES public.debts(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) DEFAULT auth.uid() NOT NULL,
    amount NUMERIC NOT NULL,
    type TEXT CHECK (type IN ('LENT', 'BORROWED', 'REPAID')) NOT NULL,
    note TEXT DEFAULT '',
    date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security (RLS) for debt_entries
ALTER TABLE public.debt_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own debt_entries" ON public.debt_entries
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own debt_entries" ON public.debt_entries
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own debt_entries" ON public.debt_entries
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own debt_entries" ON public.debt_entries
    FOR DELETE USING (auth.uid() = user_id);
