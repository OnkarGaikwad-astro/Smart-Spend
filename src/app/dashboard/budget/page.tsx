"use client";

import { useEffect } from "react";
import { useAppStore } from "@/lib/store";
import { motion } from "framer-motion";

export default function BudgetPage() {
  const { budgets, transactions, isLoading, fetchData } = useAppStore();

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  // Dynamically calculate 'spent' based on actual transactions in the current month
  const computedBudgets = budgets.map(budget => {
    const currentDate = new Date();
    const currentMonth = currentDate.getMonth();
    const currentYear = currentDate.getFullYear();
    
    const spent = transactions
      .filter(t => {
        const d = new Date(t.date);
        return t.category === budget.category && t.type === 'EXPENSE' && d.getMonth() === currentMonth && d.getFullYear() === currentYear;
      })
      .reduce((sum, t) => sum + Math.abs(t.amount), 0);
    return { ...budget, spent };
  });

  const totalAllocated = computedBudgets.reduce((acc, curr) => acc + curr.allocated, 0);
  const totalSpent = computedBudgets.reduce((acc, curr) => acc + curr.spent, 0);
  const totalPercentage = totalAllocated > 0 ? Math.min(Math.round((totalSpent / totalAllocated) * 100), 100) : 0;
  const left = Math.max(totalAllocated - totalSpent, 0);

  const containerVariants = {
    hidden: { opacity: 0 },
    show: { opacity: 1, transition: { staggerChildren: 0.1 } }
  };

  const itemVariants = {
    hidden: { opacity: 0, y: 10 },
    show: { opacity: 1, y: 0, transition: { type: "spring" as any, stiffness: 300, damping: 24 } }
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
          <span 
            onClick={() => useAppStore.getState().setBudgetModalOpen(true)}
            className="text-[12px] text-[var(--color-primary-main)] font-medium cursor-pointer"
          >
            + Add Category
          </span>
        </div>

        <div className="flex flex-col gap-3.5">
          {isLoading ? (
            <div className="flex justify-center py-6">
              <div className="w-5 h-5 border-2 border-[var(--color-primary-main)] border-t-transparent rounded-full animate-spin" />
            </div>
          ) : computedBudgets.length > 0 ? (
            computedBudgets.map((budget) => (
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
          <span 
            onClick={() => useAppStore.getState().setGoalModalOpen(true)}
            className="text-[12px] text-[var(--color-primary-main)] font-medium cursor-pointer"
          >
            + New goal
          </span>
        </div>

        <div className="flex flex-col gap-2.5">
          {useAppStore.getState().goals.length > 0 ? (
            useAppStore.getState().goals.map((goal) => {
              const percent = goal.target > 0 ? Math.min(Math.round((goal.saved / goal.target) * 100), 100) : 0;
              return (
                <GoalCard 
                  key={goal.id} 
                  goal={goal}
                  percent={percent} 
                />
              );
            })
          ) : (
            <div className="text-center py-4">
              <p className="text-[12px] text-[var(--color-text-muted)]">No savings goals set. Create one to start saving!</p>
            </div>
          )}
        </div>
        
        {useAppStore.getState().goals.length > 0 && (
          <button 
            onClick={() => useAppStore.getState().sweepLeftover()}
            className="w-full mt-4 py-2 bg-[var(--color-surface-2)] hover:bg-[var(--color-primary-soft)] text-[var(--color-primary-main)] font-medium rounded-[10px] text-[12px] transition-colors border border-[var(--color-border-subtle)]"
          >
            🧹 Auto-Sweep Leftover to Goals
          </button>
        )}
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
    <div 
      onClick={() => useAppStore.getState().setBudgetModalOpen(true, budget)}
      className="mb-1 p-2 hover:bg-[var(--color-surface-2)] rounded-[10px] transition-colors cursor-pointer -mx-2 px-2"
    >
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

function GoalCard({ goal, percent }: any) {
  const isPrimary = goal.color === "primary";
  const badgeBg = isPrimary ? "bg-[var(--color-primary-soft)]" : "bg-[var(--color-secondary-soft)]";
  const badgeText = isPrimary ? "text-[var(--color-primary-main)]" : "text-[var(--color-secondary-main)]";
  const barColor = isPrimary ? "bg-[var(--color-primary-main)]" : "bg-[var(--color-secondary-main)]";

  return (
    <div className="bg-[var(--color-surface)] border border-[var(--color-border-subtle)] rounded-[12px] p-3.5 hover:shadow-sm transition-shadow">
      <div className="flex justify-between items-start mb-2.5">
        <div className="flex-1 cursor-pointer" onClick={() => useAppStore.getState().setGoalModalOpen(true, goal)}>
          <div className="text-[13px] font-semibold text-[var(--color-text-main)] hover:text-[var(--color-primary-main)] transition-colors">{goal.name}</div>
          <div className="text-[11px] text-[var(--color-text-muted)] mt-0.5">Target by {goal.target_date}</div>
        </div>
        <div className="flex flex-col items-end gap-1.5">
          <span className={`text-[11px] px-2.5 py-0.5 rounded-[20px] font-medium ${badgeBg} ${badgeText}`}>
            {percent}%
          </span>
          <button 
            onClick={(e) => { e.stopPropagation(); useAppStore.getState().setDepositModalOpen(true, goal); }}
            className="text-[10px] bg-[var(--color-surface-2)] hover:bg-[var(--color-secondary-main)] hover:text-white text-[var(--color-text-muted)] px-2 py-0.5 rounded-full transition-colors"
          >
            + Deposit
          </button>
        </div>
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
        <span>₹{goal.saved.toLocaleString('en-IN')} saved</span>
        <span>₹{goal.target.toLocaleString('en-IN')} target</span>
      </div>
    </div>
  );
}
