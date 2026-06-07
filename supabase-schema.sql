-- SmartSpend AI - Supabase Database Schema
-- Run this in the Supabase SQL Editor to set up your tables

-- 1. Create the Transactions table
CREATE TABLE public.transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    category TEXT NOT NULL,
    amount NUMERIC NOT NULL,
    date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    type TEXT CHECK (type IN ('INCOME', 'EXPENSE')) NOT NULL,
    icon TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security (RLS) for transactions (optional but recommended)
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

-- Create policy to allow all actions for now (since we don't have auth yet)
-- WARNING: In a production app, you would restrict this to authenticated users
CREATE POLICY "Enable all actions for public" ON public.transactions
    FOR ALL
    USING (true)
    WITH CHECK (true);

-- 2. Create the Budgets table
CREATE TABLE public.budgets (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    category TEXT NOT NULL,
    allocated NUMERIC NOT NULL DEFAULT 0,
    spent NUMERIC NOT NULL DEFAULT 0,
    icon TEXT NOT NULL,
    color TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security (RLS) for budgets
ALTER TABLE public.budgets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable all actions for public" ON public.budgets
    FOR ALL
    USING (true)
    WITH CHECK (true);

-- 3. Insert some initial dummy budget data so the dashboard isn't completely empty when you switch from the mock fallback
INSERT INTO public.budgets (category, allocated, spent, icon, color)
VALUES 
    ('Food Delivery', 4000, 3200, 'pizza', 'rose'),
    ('Subscriptions', 1000, 850, 'music', 'indigo'),
    ('Transport', 2500, 1200, 'car', 'amber');

-- 4. Insert initial dummy transaction data
INSERT INTO public.transactions (title, category, amount, date, type, icon)
VALUES 
    ('Spotify Premium', 'Subscriptions', -119, NOW(), 'EXPENSE', 'music'),
    ('Swiggy Dinner', 'Food Delivery', -350, NOW() - INTERVAL '1 day', 'EXPENSE', 'pizza'),
    ('Freelance Design', 'Income', 5000, NOW() - INTERVAL '2 days', 'INCOME', 'briefcase'),
    ('Uber to College', 'Transport', -180, NOW() - INTERVAL '3 days', 'EXPENSE', 'car');
