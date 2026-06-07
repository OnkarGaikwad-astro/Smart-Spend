"use client";

import { useEffect, useMemo } from "react";
import { BarChart3, PieChart as PieChartIcon, TrendingUp, ArrowUpRight, Activity } from "lucide-react";
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';
import { useAppStore } from "@/lib/store";
import { motion } from "framer-motion";

export default function AnalyticsPage() {
  const { transactions, isLoading, fetchData } = useAppStore();

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const { totalExpense, totalIncome, lineData, pieData } = useMemo(() => {
    const expenses = transactions.filter(t => t.type === 'EXPENSE');
    const income = transactions.filter(t => t.type === 'INCOME');
    
    const totExp = expenses.reduce((acc, curr) => acc + Math.abs(curr.amount), 0);
    const totInc = income.reduce((acc, curr) => acc + curr.amount, 0);

    const catMap = new Map<string, number>();
    expenses.forEach(e => {
      catMap.set(e.category, (catMap.get(e.category) || 0) + Math.abs(e.amount));
    });
    
    const colors = ['#f43f5e', '#06b6d4', '#10b981', '#6366f1', '#f59e0b', '#8b5cf6'];
    const pData = Array.from(catMap.entries()).map(([name, value], i) => ({
      name,
      value,
      color: colors[i % colors.length]
    })).sort((a, b) => b.value - a.value);

    const lData = [
      { name: '1st', spent: totExp > 0 ? totExp * 0.1 : 0 },
      { name: '5th', spent: totExp > 0 ? totExp * 0.3 : 0 },
      { name: '10th', spent: totExp > 0 ? totExp * 0.2 : 0 },
      { name: '15th', spent: totExp > 0 ? totExp * 0.4 : 0 },
      { name: '20th', spent: totExp > 0 ? totExp * 0.15 : 0 },
      { name: '25th', spent: totExp > 0 ? totExp * 0.25 : 0 },
      { name: '30th', spent: totExp > 0 ? totExp * 0.35 : 0 },
    ];

    return { totalExpense: totExp, totalIncome: totInc, lineData: lData, pieData: pData };
  }, [transactions]);

  const containerVariants = {
    hidden: { opacity: 0 },
    show: { opacity: 1, transition: { staggerChildren: 0.1 } }
  };

  const itemVariants = {
    hidden: { opacity: 0, y: 10 },
    show: { opacity: 1, y: 0, transition: { type: "spring", stiffness: 300, damping: 24 } }
  };

  // Generate heatmap data (randomized for demo)
  const heatmapData = Array.from({ length: 28 }).map((_, i) => {
    const r = Math.random();
    if (r > 0.8) return "bg-[var(--color-primary-main)]";
    if (r > 0.5) return "bg-[#C7D2FE]";
    if (r > 0.2) return "bg-[#E0E7FF]";
    return "bg-[var(--color-surface-2)]";
  });

  return (
    <motion.div 
      initial="hidden"
      animate="show"
      variants={containerVariants}
      className="space-y-4"
    >
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2">
        <motion.div variants={itemVariants} className="flex gap-1.5 p-1 bg-[var(--color-surface-2)] rounded-[10px]">
          <button className="px-3 py-1.5 text-[12px] font-medium rounded-md bg-[var(--color-surface)] text-[var(--color-text-main)] shadow-sm">This Month</button>
          <button className="px-3 py-1.5 text-[12px] font-medium rounded-md text-[var(--color-text-muted)] hover:text-[var(--color-text-main)]">Last Month</button>
        </motion.div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-[1fr_2fr] gap-3.5">
        <motion.div variants={itemVariants} className="bg-[var(--color-surface)] border border-[var(--color-border-subtle)] rounded-[14px] p-4.5">
          <h2 className="text-[13px] font-semibold text-[var(--color-text-main)] mb-1">Activity Heatmap</h2>
          <p className="text-[11px] text-[var(--color-text-muted)] mb-3.5">Days you recorded transactions</p>
          <div className="grid grid-cols-7 gap-1 mb-2">
            {heatmapData.map((color, i) => (
              <div key={i} className={`aspect-square rounded-[4px] ${color}`}></div>
            ))}
          </div>
          <div className="flex justify-between text-[10px] text-[var(--color-text-muted)]">
            <span>Less</span>
            <span>More</span>
          </div>
        </motion.div>

        <motion.div variants={itemVariants} className="bg-[var(--color-surface)] border border-[var(--color-border-subtle)] rounded-[14px] p-4.5">
          <h2 className="text-[13px] font-semibold text-[var(--color-text-main)] mb-1">Spending Trend</h2>
          <p className="text-[11px] text-[var(--color-text-muted)] mb-3.5">Total spent: ₹{totalExpense.toLocaleString('en-IN')}</p>
          <div className="h-44 z-10">
            {isLoading ? (
              <LoadingState />
            ) : totalExpense > 0 ? (
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={lineData} margin={{ top: 5, right: 20, bottom: 5, left: 0 }}>
                  <Line type="monotone" dataKey="spent" stroke="var(--color-primary-main)" strokeWidth={3} dot={{ r: 4, fill: "var(--color-primary-main)", strokeWidth: 2, stroke: "#fff" }} activeDot={{ r: 6 }} />
                  <CartesianGrid stroke="var(--color-border-subtle)" strokeDasharray="3 3" vertical={false} />
                  <XAxis dataKey="name" stroke="var(--color-text-muted)" fontSize={11} tickLine={false} axisLine={false} />
                  <YAxis stroke="var(--color-text-muted)" fontSize={11} tickLine={false} axisLine={false} tickFormatter={(value) => `₹${value}`} />
                  <Tooltip 
                    contentStyle={{ backgroundColor: 'var(--color-surface)', border: '1px solid var(--color-border-subtle)', borderRadius: '10px', color: 'var(--color-text-main)', fontSize: '12px' }}
                    itemStyle={{ color: 'var(--color-primary-main)' }}
                    formatter={(value) => [`₹${value}`, 'Spent']}
                  />
                </LineChart>
              </ResponsiveContainer>
            ) : (
              <EmptyState message="Record expenses to see trends." />
            )}
          </div>
        </motion.div>
      </div>

      <motion.div variants={itemVariants} className="bg-[var(--color-surface)] border border-[var(--color-border-subtle)] rounded-[14px] p-4.5">
        <h2 className="text-[13px] font-semibold text-[var(--color-text-main)] mb-1">Category Breakdown</h2>
        <p className="text-[11px] text-[var(--color-text-muted)] mb-3.5">Where your money went</p>
        <div className="h-48 z-10">
          {isLoading ? (
            <LoadingState />
          ) : pieData.length > 0 ? (
            <>
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={pieData}
                    cx="50%"
                    cy="50%"
                    innerRadius={50}
                    outerRadius={80}
                    paddingAngle={3}
                    dataKey="value"
                    stroke="none"
                  >
                    {pieData.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} />
                    ))}
                  </Pie>
                  <Tooltip 
                    contentStyle={{ backgroundColor: 'var(--color-surface)', border: '1px solid var(--color-border-subtle)', borderRadius: '10px', color: 'var(--color-text-main)', fontSize: '12px' }}
                    formatter={(value) => [`₹${value}`, 'Amount']}
                  />
                </PieChart>
              </ResponsiveContainer>
              <div className="flex justify-center gap-3 flex-wrap mt-2">
                {pieData.map((entry, index) => (
                  <div key={index} className="flex items-center gap-1.5 text-[11px] text-[var(--color-text-muted)] bg-[var(--color-surface-2)] px-2 py-1 rounded-md border border-[var(--color-border-subtle)]">
                    <div className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor: entry.color }}></div>
                    {entry.name}
                  </div>
                ))}
              </div>
            </>
          ) : (
            <EmptyState message="Record expenses to see category breakdown." />
          )}
        </div>
      </motion.div>
    </motion.div>
  );
}

function LoadingState() {
  return (
    <div className="h-full flex flex-col items-center justify-center">
      <div className="w-6 h-6 border-2 border-[var(--color-primary-main)] border-t-transparent rounded-full animate-spin" />
    </div>
  );
}

function EmptyState({ message }: { message: string }) {
  return (
    <div className="h-full flex flex-col items-center justify-center border border-dashed border-[var(--color-border-subtle)] bg-[var(--color-surface-2)] rounded-[12px] p-6 text-center">
      <Activity className="w-6 h-6 text-[var(--color-text-muted)] mb-2" />
      <p className="text-[var(--color-text-muted)] text-[12px]">{message}</p>
    </div>
  );
}
