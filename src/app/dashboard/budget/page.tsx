"use client";

import { useEffect } from "react";
import { useAppStore } from "@/lib/store";
import { motion } from "framer-motion";

export default function BudgetPage() {
  const { budgets, isLoading, fetchData } = useAppStore();

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const totalAllocated = budgets.reduce((acc, curr) => acc + curr.allocated, 0);
  const totalSpent = budgets.reduce((acc, curr) => acc + curr.spent, 0);
  const totalPercentage = totalAllocated > 0 ? Math.min(Math.round((totalSpent / totalAllocated) * 100), 100) : 0;
  const left = Math.max(totalAllocated - totalSpent, 0);

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
      className="space-y-4"
    >
      <div className="grid grid-cols-1 md:grid-cols-2 gap-3.5 mb-4">
        <motion.div variants={itemVariants} className="p-4 rounded-[14px] bg-gradient-to-br from-[var(--color-primary-main)] to-[var(--color-purple-main)] text-white shadow-md">
          <div className="text-[11px] font-medium text-white/70 tracking-[0.04em] uppercase mb-1.5">Monthly budget</div>
          <div className="font-mono text-[22px] font-bold mb-1">₹{totalAllocated.toLocaleString('en-IN')}</div>
          <div className="text-[12px] text-white/70 flex items-center gap-1">
            ₹{totalSpent.toLocaleString('en-IN')} used · ₹{left.toLocaleString('en-IN')} left
          </div>
        </motion.div>
        
        <motion.div variants={itemVariants} className="p-4 rounded-[14px] bg-[var(--color-surface)] border border-[var(--color-border-subtle)]">
          <div className="text-[11px] font-medium text-[var(--color-text-muted)] tracking-[0.04em] uppercase mb-1.5">Budget utilization</div>
          <div className="font-mono text-[22px] font-bold text-[var(--color-text-main)] mb-2">{totalPercentage}%</div>
          <div className="h-1.5 bg-[var(--color-surface-2)] rounded-full overflow-hidden">
            <motion.div 
              initial={{ width: 0 }}
              animate={{ width: `${totalPercentage}%` }}
              transition={{ duration: 1 }}
              className={`h-full rounded-full ${totalPercentage > 90 ? 'bg-[var(--color-danger-main)]' : totalPercentage > 75 ? 'bg-[var(--color-accent-main)]' : 'bg-gradient-to-r from-[var(--color-secondary-main)] to-[var(--color-accent-main)]'}`}
            />
          </div>
        </motion.div>
      </div>

      <motion.div variants={itemVariants} className="bg-[var(--color-surface)] border border-[var(--color-border-subtle)] rounded-[14px] p-4.5 mb-3.5">
        <div className="flex justify-between items-center mb-3.5 border-b border-[var(--color-border-subtle)] pb-3">
          <span className="text-[14px] font-semibold text-[var(--color-text-main)]">Category budgets</span>
          <span className="text-[12px] text-[var(--color-primary-main)] font-medium cursor-pointer">AI optimize ✨</span>
        </div>

        <div className="flex flex-col gap-3.5">
          {isLoading ? (
            <div className="flex justify-center py-6">
              <div className="w-5 h-5 border-2 border-[var(--color-primary-main)] border-t-transparent rounded-full animate-spin" />
            </div>
          ) : budgets.length > 0 ? (
            budgets.map((budget) => (
              <BudgetBarItem key={budget.id} budget={budget} />
            ))
          ) : (
            <div className="text-center py-6">
              <p className="text-[12px] text-[var(--color-text-muted)]">No budgets set. Create your first budget!</p>
            </div>
          )}
        </div>
      </motion.div>

      <motion.div variants={itemVariants} className="bg-[var(--color-surface)] border border-[var(--color-border-subtle)] rounded-[14px] p-4.5">
        <div className="flex justify-between items-center mb-3.5 border-b border-[var(--color-border-subtle)] pb-3">
          <span className="text-[14px] font-semibold text-[var(--color-text-main)]">Savings goals</span>
          <span className="text-[12px] text-[var(--color-primary-main)] font-medium cursor-pointer">+ New goal</span>
        </div>

        <div className="flex flex-col gap-2.5">
          {/* Placeholders for Savings Goals matching the snippet */}
          <GoalCard name="💻 New Laptop" targetDate="Dec 2025" saved={16800} target={40000} percent={42} color="primary" />
          <GoalCard name="🏖 Goa Trip" targetDate="Feb 2026" saved={10650} target={15000} percent={71} color="secondary" />
        </div>
      </motion.div>
    </motion.div>
  );
}

function BudgetBarItem({ budget }: { budget: any }) {
  const percentage = budget.allocated > 0 ? Math.min(Math.round((budget.spent / budget.allocated) * 100), 100) : 0;
  const isOver = budget.spent > budget.allocated;
  const isWarning = percentage > 85 && !isOver;

  let colorClass = "bg-[var(--color-secondary-main)]";
  let textClass = "text-[var(--color-text-muted)]";
  let msg = `${percentage}% — on track`;

  if (isOver) {
    colorClass = "bg-[var(--color-danger-main)]";
    textClass = "text-[var(--color-danger-main)]";
    msg = `🔴 Over budget by ₹${(budget.spent - budget.allocated).toLocaleString('en-IN')}`;
  } else if (isWarning) {
    colorClass = "bg-[var(--color-accent-main)]";
    textClass = "text-[var(--color-accent-main)]";
    msg = `⚠ ${percentage}% — almost at limit`;
  } else if (percentage > 60) {
    colorClass = "bg-[var(--color-secondary-main)]";
    textClass = "text-[var(--color-text-muted)]";
    msg = `${percentage}% — good`;
  }

  return (
    <div className="mb-1">
      <div className="flex justify-between items-center mb-1.5">
        <span className="text-[13px] font-medium text-[var(--color-text-main)] flex items-center gap-1.5">
          {budget.icon || "🎯"} {budget.category}
        </span>
        <span className="text-[12px] text-[var(--color-text-muted)] font-mono">
          ₹{budget.spent.toLocaleString('en-IN')} / ₹{budget.allocated.toLocaleString('en-IN')}
        </span>
      </div>
      <div className="h-2 bg-[var(--color-surface-2)] rounded-full overflow-hidden mb-1">
        <motion.div 
          initial={{ width: 0 }}
          animate={{ width: `${percentage}%` }}
          transition={{ duration: 1 }}
          className={`h-full rounded-full ${colorClass}`}
        />
      </div>
      <div className={`text-[11px] mt-1 ${textClass}`}>{msg}</div>
    </div>
  );
}

function GoalCard({ name, targetDate, saved, target, percent, color }: any) {
  const isPrimary = color === "primary";
  const badgeBg = isPrimary ? "bg-[var(--color-primary-soft)]" : "bg-[var(--color-secondary-soft)]";
  const badgeText = isPrimary ? "text-[var(--color-primary-main)]" : "text-[var(--color-secondary-main)]";
  const barColor = isPrimary ? "bg-[var(--color-primary-main)]" : "bg-[var(--color-secondary-main)]";

  return (
    <div className="bg-[var(--color-surface)] border border-[var(--color-border-subtle)] rounded-[12px] p-3.5 hover:shadow-sm transition-shadow">
      <div className="flex justify-between items-start mb-2.5">
        <div>
          <div className="text-[13px] font-semibold text-[var(--color-text-main)]">{name}</div>
          <div className="text-[11px] text-[var(--color-text-muted)] mt-0.5">Target by {targetDate}</div>
        </div>
        <span className={`text-[11px] px-2.5 py-0.5 rounded-[20px] font-medium ${badgeBg} ${badgeText}`}>
          {percent}%
        </span>
      </div>
      <div className="h-2 bg-[var(--color-surface-2)] rounded-full overflow-hidden mb-1.5">
        <motion.div 
          initial={{ width: 0 }}
          animate={{ width: `${percent}%` }}
          transition={{ duration: 1 }}
          className={`h-full rounded-full ${barColor}`}
        />
      </div>
      <div className="flex justify-between text-[11px] text-[var(--color-text-muted)] mt-1.5">
        <span>₹{saved.toLocaleString('en-IN')} saved</span>
        <span>₹{target.toLocaleString('en-IN')} target</span>
      </div>
    </div>
  );
}
