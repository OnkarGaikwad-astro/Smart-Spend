"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Plus } from "lucide-react";
import { motion } from "framer-motion";
import { AddTransactionModal } from "@/components/AddTransactionModal";
import AIAssistantWidget from "@/components/AIAssistantWidget";
import { useAppStore } from "@/lib/store";

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const { isAddModalOpen, setAddModalOpen } = useAppStore();

  return (
    <div className="min-h-screen text-[var(--color-text-main)] selection:bg-[var(--color-primary-soft)] selection:text-[var(--color-primary-main)] font-sans">
      {/* Top Navigation Bar */}
      <nav className="flex items-center justify-between px-5 py-3.5 bg-[var(--color-surface)] border-b border-[var(--color-border-subtle)] sticky top-0 z-50 shadow-sm">
        <Link href="/dashboard" className="flex items-center gap-2 font-mono font-bold text-[15px] text-[var(--color-primary-main)]">
          <span className="w-7 h-7 bg-[var(--color-primary-main)] rounded-lg flex items-center justify-center text-white text-[13px]">
            ₹
          </span>
          SmartSpend AI
        </Link>
        
        {/* Navigation Tabs (Hidden on very small screens, scrollable on mobile) */}
        <div className="hidden md:flex gap-0.5 bg-[var(--color-surface-2)] rounded-xl p-1">
          <NavTab href="/dashboard" label="Dashboard" active={pathname === "/dashboard"} />
          <NavTab href="/dashboard/transactions" label="Transactions" active={pathname === "/dashboard/transactions"} />
          <NavTab href="/dashboard/budget" label="Budget" active={pathname === "/dashboard/budget"} />
          <NavTab href="/dashboard/reports" label="Reports" active={pathname === "/dashboard/reports"} />
        </div>

        <div className="flex items-center gap-3">
          <motion.button 
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            onClick={() => setAddModalOpen(true)}
            className="hidden sm:flex items-center gap-1.5 px-3 py-1.5 rounded-[10px] bg-[var(--color-primary-soft)] text-[var(--color-primary-main)] text-[13px] font-semibold hover:bg-[var(--color-primary-main)] hover:text-white transition-colors"
          >
            <Plus className="w-4 h-4" />
            New
          </motion.button>
          
          <div className="w-8 h-8 rounded-full bg-gradient-to-br from-[var(--color-primary-main)] to-[var(--color-purple-main)] flex items-center justify-center text-white text-xs font-semibold cursor-pointer shadow-sm">
            AR
          </div>
        </div>
      </nav>

      {/* Mobile Scrollable Tabs */}
      <div className="md:hidden flex overflow-x-auto gap-1 bg-[var(--color-surface)] px-4 py-2 border-b border-[var(--color-border-subtle)] scrollbar-hide">
        <NavTab href="/dashboard" label="Dashboard" active={pathname === "/dashboard"} />
        <NavTab href="/dashboard/transactions" label="Transactions" active={pathname === "/dashboard/transactions"} />
        <NavTab href="/dashboard/budget" label="Budget" active={pathname === "/dashboard/budget"} />
        <NavTab href="/dashboard/reports" label="Reports" active={pathname === "/dashboard/reports"} />
      </div>

      {/* Main Content Area */}
      <main className="p-5 max-w-6xl mx-auto">
        {children}
      </main>

      <AddTransactionModal isOpen={isAddModalOpen} onClose={() => setAddModalOpen(false)} />
      
      {/* Mobile Floating Action Button */}
      <motion.button 
        whileHover={{ scale: 1.05 }}
        whileTap={{ scale: 0.9 }}
        onClick={() => setAddModalOpen(true)}
        className="sm:hidden fixed bottom-24 right-6 w-14 h-14 bg-[var(--color-primary-main)] text-white rounded-full flex items-center justify-center shadow-[0_0_20px_rgba(45,212,191,0.3)] z-40"
      >
        <Plus className="w-6 h-6" />
      </motion.button>

      <AIAssistantWidget />
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
