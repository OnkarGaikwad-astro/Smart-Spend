"use client";

import { useEffect } from "react";
import { ArrowUpRight, ArrowDownRight, TrendingUp, TrendingDown, DollarSign, Wallet, Activity } from "lucide-react";
import { useAppStore } from "@/lib/store";
import { motion } from "framer-motion";

export default function DashboardPage() {
  const { transactions, isLoading, fetchData } = useAppStore();

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const totalIncome = transactions.filter(t => t.type === 'INCOME').reduce((acc, curr) => acc + curr.amount, 0);
  const totalExpense = transactions.filter(t => t.type === 'EXPENSE').reduce((acc, curr) => acc + Math.abs(curr.amount), 0);
  const totalBalance = totalIncome - totalExpense;
  const recentTxns = transactions.slice(0, 5);

  const containerVariants = {
    hidden: { opacity: 0 },
    show: { opacity: 1, transition: { staggerChildren: 0.1 } }
  };

  const itemVariants = {
    hidden: { opacity: 0, y: 10 },
    show: { opacity: 1, y: 0, transition: { type: "spring", stiffness: 300, damping: 24 } }
  };

  return (
    <motion.div 
      initial="hidden"
      animate="show"
      variants={containerVariants}
      className="space-y-5"
    >
      {/* Overview Cards */}
      <motion.div variants={itemVariants} className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-3">
        <OverviewCard 
          title="Total Balance" 
          amount={`₹${totalBalance.toLocaleString('en-IN')}`} 
          trend="Current available balance"
          icon={<Wallet className="w-4 h-4 text-[var(--color-primary-main)]" />}
          accentBg="bg-[var(--color-primary-soft)]"
          positive={totalBalance >= 0}
        />
        <OverviewCard 
          title="Income" 
          amount={`₹${totalIncome.toLocaleString('en-IN')}`} 
          trend="Total earned"
          icon={<ArrowUpRight className="w-4 h-4 text-[var(--color-secondary-main)]" />}
          accentBg="bg-[var(--color-secondary-soft)]"
          positive
        />
        <OverviewCard 
          title="Expenses" 
          amount={`₹${totalExpense.toLocaleString('en-IN')}`} 
          trend="Total spent"
          icon={<ArrowDownRight className="w-4 h-4 text-[var(--color-danger-main)]" />}
          accentBg="bg-[var(--color-danger-soft)]"
          positive={false}
        />
        <OverviewCard 
          title="Savings Rate" 
          amount={totalIncome > 0 ? `${Math.round(((totalIncome - totalExpense) / totalIncome) * 100)}%` : '0%'} 
          trend="Of total income"
          icon={<DollarSign className="w-4 h-4 text-[var(--color-accent-main)]" />}
          accentBg="bg-[var(--color-accent-soft)]"
          positive={totalIncome > totalExpense}
        />
      </motion.div>

      {/* Main Charts & Recent Txns */}
      <div className="grid grid-cols-1 lg:grid-cols-[1.6fr_1fr] gap-3.5">
        <motion.div variants={itemVariants} className="bg-[var(--color-surface)] border border-[var(--color-border-subtle)] rounded-[14px] p-4.5">
          <h2 className="text-[13px] font-semibold text-[var(--color-text-main)] mb-1">Spending Overview</h2>
          <p className="text-[11px] text-[var(--color-text-muted)] mb-3.5">Income vs Expenses — last 6 months</p>
          <div className="h-44 flex items-center justify-center border border-dashed border-[var(--color-border-subtle)] bg-[var(--color-surface-2)] rounded-xl">
            <p className="text-[var(--color-text-muted)] flex items-center gap-2 text-[12px]">
              <Activity className="w-4 h-4" /> Not enough data to generate chart.
            </p>
          </div>
        </motion.div>

        <motion.div variants={itemVariants} className="bg-[var(--color-surface)] border border-[var(--color-border-subtle)] rounded-[14px] p-4.5">
          <div className="flex justify-between items-center mb-3.5">
            <h2 className="text-[14px] font-semibold text-[var(--color-text-main)]">Recent transactions</h2>
            <Link href="/dashboard/transactions" className="text-[12px] text-[var(--color-primary-main)] font-medium cursor-pointer">View all →</Link>
          </div>
          
          <div className="flex flex-col">
            {isLoading ? (
              <div className="flex justify-center p-4">
                <div className="w-5 h-5 border-2 border-[var(--color-primary-main)] border-t-transparent rounded-full animate-spin" />
              </div>
            ) : recentTxns.length > 0 ? (
              recentTxns.map(txn => (
                <TransactionItem 
                  key={txn.id}
                  title={txn.title} 
                  category={txn.category} 
                  amount={`${txn.type === 'INCOME' ? '+' : '−'}₹${Math.abs(txn.amount).toLocaleString('en-IN')}`} 
                  date={txn.date} 
                  icon={txn.icon || "📝"}
                  positive={txn.type === 'INCOME'}
                />
              ))
            ) : (
              <div className="text-center p-4">
                <p className="text-[12px] text-[var(--color-text-muted)]">No recent transactions.</p>
              </div>
            )}
          </div>
        </motion.div>
      </div>
    </motion.div>
  );
}

import Link from "next/link";

function OverviewCard({ title, amount, trend, icon, accentBg, positive = true }: { title: string, amount: string, trend: string, icon: React.ReactNode, accentBg: string, positive?: boolean }) {
  return (
    <motion.div 
      whileHover={{ y: -2 }}
      className="bg-[var(--color-surface)] border border-[var(--color-border-subtle)] rounded-[14px] p-4 transition-all"
    >
      <div className={`w-8 h-8 rounded-[10px] mb-2.5 flex items-center justify-center ${accentBg}`}>
        {icon}
      </div>
      <div className="text-[11px] font-medium text-[var(--color-text-muted)] tracking-[0.04em] uppercase mb-1.5">{title}</div>
      <div className="font-mono text-[22px] font-bold text-[var(--color-text-main)] mb-1">{amount}</div>
      <div className="text-[12px] text-[var(--color-text-muted)] flex items-center gap-1">
        {positive ? <TrendingUp className="w-3.5 h-3.5 text-[var(--color-secondary-main)]" /> : <TrendingUp className="w-3.5 h-3.5 text-[var(--color-danger-main)]" />}
        <span className={positive ? 'text-[var(--color-secondary-main)]' : 'text-[var(--color-danger-main)]'}>{trend}</span>
      </div>
    </motion.div>
  );
}

const getIcon = (name: string) => {
  switch (name) {
    case 'music': return "🎵";
    case 'pizza': return "🍕";
    case 'briefcase': return "💼";
    case 'car': return "🚗";
    case 'receipt': return "🧾";
    default: return "📄";
  }
};

function TransactionItem({ title, category, amount, date, icon, positive = false }: { title: string, category: string, amount: string, date: string, icon: string, positive?: boolean }) {
  return (
    <div className="flex items-center gap-3 py-2.5 border-b border-[var(--color-border-subtle)] last:border-b-0">
      <div className="w-9 h-9 rounded-[10px] flex items-center justify-center text-[18px] shrink-0 bg-[var(--color-surface-2)] shadow-sm">
        {getIcon(icon)}
      </div>
      <div className="flex-1">
        <div className="text-[13px] font-medium text-[var(--color-text-main)]">{title}</div>
        <div className="text-[11px] text-[var(--color-text-muted)] mt-0.5">{category} · {date}</div>
      </div>
      <div className={`font-mono text-[13px] font-bold ${positive ? 'text-[var(--color-secondary-main)]' : 'text-[var(--color-danger-main)]'}`}>
        {amount}
      </div>
    </div>
  );
}
