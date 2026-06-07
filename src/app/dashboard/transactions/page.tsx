"use client";

import { useState, useEffect } from "react";
import { Plus, Search, Filter, Download } from "lucide-react";
import { useAppStore } from "@/lib/store";
import { motion } from "framer-motion";

export default function TransactionsPage() {
  const { transactions, isLoading, fetchData, setAddModalOpen } = useAppStore();
  const [searchTerm, setSearchTerm] = useState("");
  const [categoryFilter, setCategoryFilter] = useState("All categories");

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const filteredTxns = transactions.filter(t => {
    const matchesSearch = t.title.toLowerCase().includes(searchTerm.toLowerCase()) || t.category.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesCat = categoryFilter === "All categories" || t.category === categoryFilter;
    return matchesSearch && matchesCat;
  });

  const totalSpent = filteredTxns.filter(t => t.type === 'EXPENSE').reduce((acc, curr) => acc + Math.abs(curr.amount), 0);

  const containerVariants = {
    hidden: { opacity: 0 },
    show: { opacity: 1, transition: { staggerChildren: 0.05 } }
  };

  const itemVariants = {
    hidden: { opacity: 0, x: -10 },
    show: { opacity: 1, x: 0, transition: { type: "spring", stiffness: 300, damping: 24 } }
  };

  return (
    <motion.div 
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      className="space-y-4"
    >
      <div className="flex flex-col sm:flex-row gap-2.5 mb-2 sm:items-center">
        <input 
          type="text" 
          placeholder="Search transactions..." 
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="flex-1 min-w-[180px] px-3.5 py-2.5 border border-[var(--color-border-subtle)] rounded-[10px] bg-[var(--color-surface)] text-[var(--color-text-main)] text-[13px] focus:outline-none focus:border-[var(--color-primary-main)] transition-colors placeholder:text-[var(--color-text-muted)]"
        />
        <div className="flex gap-2.5 w-full sm:w-auto">
          <select 
            value={categoryFilter}
            onChange={(e) => setCategoryFilter(e.target.value)}
            className="flex-1 sm:flex-none px-3.5 py-2.5 border border-[var(--color-border-subtle)] rounded-[10px] bg-[var(--color-surface)] text-[var(--color-text-main)] text-[13px] focus:outline-none focus:border-[var(--color-primary-main)] transition-colors appearance-none cursor-pointer"
          >
            <option>All categories</option>
            <option>Food</option>
            <option>Travel</option>
            <option>Entertainment</option>
            <option>Education</option>
            <option>Income</option>
          </select>
          <motion.button 
            whileHover={{ scale: 1.03 }}
            whileTap={{ scale: 0.97 }}
            onClick={() => setAddModalOpen(true)}
            className="flex-1 sm:flex-none flex justify-center items-center gap-1.5 px-4 py-2.5 bg-[var(--color-primary-main)] text-white border-none rounded-[10px] text-[13px] font-medium cursor-pointer transition-colors shadow-sm"
          >
            <Plus className="w-4 h-4" /> Add
          </motion.button>
        </div>
      </div>

      <div className="flex flex-wrap gap-1.5">
        <AiChip text="🤖 Spending this week" />
        <AiChip text="🤖 Find subscriptions" />
        <AiChip text="🤖 Unusual expenses" />
      </div>

      <div className="bg-[var(--color-surface)] border border-[var(--color-border-subtle)] rounded-[14px] p-4.5 mt-2">
        <div className="flex justify-between items-center mb-3.5 border-b border-[var(--color-border-subtle)] pb-3">
          <span className="text-[14px] font-semibold text-[var(--color-text-main)]">
            {filteredTxns.length} transactions
          </span>
          <span className="text-[11px] text-[var(--color-text-muted)]">
            Total: ₹{totalSpent.toLocaleString('en-IN')} spent
          </span>
        </div>

        <div className="flex flex-col min-h-[400px]">
          {isLoading ? (
            <div className="flex flex-col items-center justify-center h-[300px]">
              <div className="w-6 h-6 border-2 border-[var(--color-primary-main)] border-t-transparent rounded-full animate-spin" />
              <p className="text-[var(--color-text-muted)] mt-4 text-[12px]">Loading transactions...</p>
            </div>
          ) : (
            <motion.div 
              variants={containerVariants}
              initial="hidden"
              animate="show"
            >
              {filteredTxns.map((txn) => (
                <motion.div variants={itemVariants} key={txn.id}>
                  <TransactionItem 
                    title={txn.title} 
                    category={txn.category} 
                    amount={`${txn.type === 'INCOME' ? '+' : '−'}₹${Math.abs(txn.amount).toLocaleString('en-IN')}`} 
                    date={txn.date} 
                    icon={txn.icon || "📝"}
                    positive={txn.type === 'INCOME'}
                  />
                </motion.div>
              ))}
              
              {!isLoading && filteredTxns.length === 0 && (
                <motion.div 
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  className="flex flex-col items-center justify-center h-[300px] text-center"
                >
                  <div className="w-16 h-16 mb-4 bg-[var(--color-surface-2)] rounded-full flex items-center justify-center border border-[var(--color-border-subtle)]">
                    <Search className="w-6 h-6 text-[var(--color-text-muted)]" />
                  </div>
                  <h3 className="text-[15px] font-semibold text-[var(--color-text-main)] mb-1">No transactions found</h3>
                  <p className="text-[13px] text-[var(--color-text-muted)] max-w-xs">
                    {searchTerm || categoryFilter !== "All categories" ? "Try adjusting your search or filters." : "You haven't recorded any transactions yet."}
                  </p>
                </motion.div>
              )}
            </motion.div>
          )}
        </div>
      </div>
    </motion.div>
  );
}

function AiChip({ text }: { text: string }) {
  return (
    <motion.button 
      whileHover={{ scale: 1.05 }}
      whileTap={{ scale: 0.95 }}
      className="px-3 py-1.5 bg-[var(--color-primary-soft)] text-[var(--color-primary-main)] border border-[rgba(79,70,229,0.25)] rounded-[20px] text-[12px] cursor-pointer"
    >
      {text}
    </motion.button>
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
    <div className="flex items-center gap-3 py-2.5 border-b border-[var(--color-border-subtle)] last:border-b-0 hover:bg-[var(--color-surface-2)] -mx-2 px-2 rounded-lg transition-colors cursor-pointer">
      <div className="w-9 h-9 rounded-[10px] flex items-center justify-center text-[18px] shrink-0 bg-[var(--color-primary-soft)] text-[var(--color-primary-main)] shadow-sm">
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
