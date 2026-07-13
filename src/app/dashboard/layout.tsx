"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Plus, Sun, Moon } from "lucide-react";
import { motion } from "framer-motion";
import { AddTransactionModal } from "@/components/AddTransactionModal";
import { BudgetModal } from "@/components/BudgetModal";
import { GoalModal } from "@/components/GoalModal";
import { DepositModal } from "@/components/DepositModal";
import AIAssistantWidget from "@/components/AIAssistantWidget";
import { useAppStore } from "@/lib/store";

import { useRouter } from 'next/navigation';
import { createClient } from '@/lib/supabase/client';
import { ProfileModal } from '@/components/ProfileModal';

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const router = useRouter();
  const supabase = createClient();
  const { userProfile, isAddModalOpen, setAddModalOpen, isBudgetModalOpen, setBudgetModalOpen, isGoalModalOpen, setGoalModalOpen, isDepositModalOpen, setDepositModalOpen, setProfileModalOpen, theme, toggleTheme } = useAppStore();

  const getInitials = () => {
    if (userProfile?.full_name) {
      return userProfile.full_name.split(' ').map(n => n[0]).join('').substring(0, 2).toUpperCase();
    }
    if (userProfile?.email) {
      return userProfile.email.substring(0, 2).toUpperCase();
    }
    return "U";
  };

  return (
    <div className="min-h-screen text-[var(--color-text-main)] selection:bg-[var(--color-primary-soft)] selection:text-[var(--color-primary-main)] font-sans">
      
      {/* Top Navigation */}
      <nav className="border-b border-[var(--color-border-subtle)] bg-[var(--color-surface)] sticky top-0 z-40 backdrop-blur-md bg-opacity-80">
        <div className="max-w-6xl mx-auto px-5 h-16 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-[14px] overflow-hidden shadow-sm border border-[var(--color-border-subtle)]">
              <img src="/icon.png" alt="SmartSpend Logo" className="w-full h-full object-cover rounded-[14px]" />
            </div>
            <span className="font-semibold text-[17px] tracking-tight">SmartSpend</span>
          </div>
          
          <div className="hidden md:flex items-center space-x-1">
            <Link href="/dashboard" className={`px-4 py-2 text-[13px] font-medium rounded-full transition-colors ${pathname === '/dashboard' ? 'bg-[var(--color-surface-2)] text-[var(--color-text-main)]' : 'text-[var(--color-text-muted)] hover:text-[var(--color-text-main)] hover:bg-[var(--color-surface-2)]'}`}>Overview</Link>
            <Link href="/dashboard/transactions" className={`px-4 py-2 text-[13px] font-medium rounded-full transition-colors ${pathname === '/dashboard/transactions' ? 'bg-[var(--color-surface-2)] text-[var(--color-text-main)]' : 'text-[var(--color-text-muted)] hover:text-[var(--color-text-main)] hover:bg-[var(--color-surface-2)]'}`}>Transactions</Link>
            <Link href="/dashboard/budget" className={`px-4 py-2 text-[13px] font-medium rounded-full transition-colors ${pathname === '/dashboard/budget' ? 'bg-[var(--color-surface-2)] text-[var(--color-text-main)]' : 'text-[var(--color-text-muted)] hover:text-[var(--color-text-main)] hover:bg-[var(--color-surface-2)]'}`}>Budget & Goals</Link>
            <Link href="/dashboard/analytics" className={`px-4 py-2 text-[13px] font-medium rounded-full transition-colors ${pathname === '/dashboard/analytics' ? 'bg-[var(--color-surface-2)] text-[var(--color-text-main)]' : 'text-[var(--color-text-muted)] hover:text-[var(--color-text-main)] hover:bg-[var(--color-surface-2)]'}`}>Analytics</Link>
          </div>

          <div className="flex items-center gap-3">
            <button 
              onClick={async () => {
                await supabase.auth.signOut();
                useAppStore.setState({ userProfile: null, transactions: [], budgets: [], goals: [] });
                router.push('/login');
              }}
              className="px-3 py-1.5 text-[12px] font-medium rounded-md bg-[var(--color-danger-soft)] text-[var(--color-danger-main)] hover:bg-red-100 transition-colors"
            >
              Log Out
            </button>
            <button 
              onClick={() => setProfileModalOpen(true)}
              className="w-8 h-8 rounded-full bg-[var(--color-surface-2)] flex items-center justify-center border border-[var(--color-border-subtle)] text-[12px] font-medium overflow-hidden hover:ring-2 hover:ring-[var(--color-primary-main)] transition-all"
            >
              {userProfile?.avatar_url ? (
                <img src={userProfile.avatar_url} alt="Profile" className="w-full h-full object-cover" />
              ) : (
                getInitials()
              )}
            </button>
          </div>
        </div>

        {/* Mobile Navigation (Top) */}
        <div className="md:hidden flex overflow-x-auto px-4 py-2 gap-2 hide-scrollbar border-t border-[var(--color-border-subtle)] bg-[var(--color-surface)]">
            <Link href="/dashboard" className={`whitespace-nowrap px-4 py-1.5 text-[13px] font-medium rounded-full transition-colors ${pathname === '/dashboard' ? 'bg-[var(--color-surface-2)] text-[var(--color-text-main)]' : 'text-[var(--color-text-muted)] hover:text-[var(--color-text-main)] hover:bg-[var(--color-surface-2)]'}`}>Overview</Link>
            <Link href="/dashboard/transactions" className={`whitespace-nowrap px-4 py-1.5 text-[13px] font-medium rounded-full transition-colors ${pathname === '/dashboard/transactions' ? 'bg-[var(--color-surface-2)] text-[var(--color-text-main)]' : 'text-[var(--color-text-muted)] hover:text-[var(--color-text-main)] hover:bg-[var(--color-surface-2)]'}`}>Transactions</Link>
            <Link href="/dashboard/budget" className={`whitespace-nowrap px-4 py-1.5 text-[13px] font-medium rounded-full transition-colors ${pathname === '/dashboard/budget' ? 'bg-[var(--color-surface-2)] text-[var(--color-text-main)]' : 'text-[var(--color-text-muted)] hover:text-[var(--color-text-main)] hover:bg-[var(--color-surface-2)]'}`}>Budget & Goals</Link>
            <Link href="/dashboard/analytics" className={`whitespace-nowrap px-4 py-1.5 text-[13px] font-medium rounded-full transition-colors ${pathname === '/dashboard/analytics' ? 'bg-[var(--color-surface-2)] text-[var(--color-text-main)]' : 'text-[var(--color-text-muted)] hover:text-[var(--color-text-main)] hover:bg-[var(--color-surface-2)]'}`}>Analytics</Link>
        </div>
      </nav>



      <main className="p-5 md:p-8 md:pt-10 max-w-6xl mx-auto pb-24 md:pb-12 min-h-[calc(100vh-64px)]">
        {children}
      </main>

      <AddTransactionModal isOpen={isAddModalOpen} onClose={() => setAddModalOpen(false)} />
      <BudgetModal isOpen={isBudgetModalOpen} onClose={() => setBudgetModalOpen(false)} />
      <GoalModal isOpen={isGoalModalOpen} onClose={() => setGoalModalOpen(false)} />
      <DepositModal isOpen={isDepositModalOpen} onClose={() => setDepositModalOpen(false)} />
      
      {/* Mobile Floating Action Button */}
      <motion.button 
        whileHover={{ scale: 1.05 }}
        whileTap={{ scale: 0.9 }}
        onClick={() => setAddModalOpen(true)}
        className="sm:hidden fixed bottom-[150px] right-4 w-14 h-14 bg-[var(--color-primary-main)] text-white rounded-full flex items-center justify-center shadow-[0_0_20px_rgba(45,212,191,0.3)] z-40"
      >
        <Plus className="w-6 h-6" />
      </motion.button>

      <AIAssistantWidget />
      <ProfileModal />
    </div>
  );
}

function NavTab({ href, label, active = false }: { href: string; label: string; active?: boolean }) {
  return (
    <Link 
      href={href}
      className={`px-3.5 py-1.5 rounded-[8px] text-[13px] font-medium transition-all whitespace-nowrap ${
        active 
          ? "bg-[var(--color-surface)] text-[var(--color-text-main)] shadow-[0_1px_3px_rgba(0,0,0,0.06)]" 
          : "text-[var(--color-text-muted)] hover:text-[var(--color-text-main)]"
      }`}
    >
      {label}
    </Link>
  );
}


