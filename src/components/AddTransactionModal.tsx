"use client";

import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { X, Plus, Calendar, Tag, FileText, ArrowDownRight, ArrowUpRight } from "lucide-react";
import { useAppStore } from "@/lib/store";

export function AddTransactionModal({ isOpen, onClose }: { isOpen: boolean; onClose: () => void }) {
  const addTransaction = useAppStore(state => state.addTransaction);
  
  const [type, setType] = useState<'EXPENSE' | 'INCOME'>('EXPENSE');
  const [amount, setAmount] = useState('');
  const [title, setTitle] = useState('');
  const [category, setCategory] = useState('');
  
  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!amount || !title || !category) return;
    
    addTransaction({
      title,
      category,
      amount: type === 'EXPENSE' ? -Math.abs(Number(amount)) : Math.abs(Number(amount)),
      date: new Date().toISOString(),
      type
    });
    
    // Reset and close
    setAmount('');
    setTitle('');
    setCategory('');
    onClose();
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center p-4">
          <motion.div 
            initial={{ opacity: 0 }} 
            animate={{ opacity: 1 }} 
            exit={{ opacity: 0 }} 
            className="absolute inset-0 bg-black/40 backdrop-blur-sm"
            onClick={onClose}
          />
          
          <motion.div
            initial={{ opacity: 0, scale: 0.95, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95, y: 20 }}
            className="relative w-full max-w-md bg-[var(--color-surface)] border border-[var(--color-border-subtle)] rounded-[20px] shadow-2xl overflow-hidden backdrop-blur-xl"
            onClick={e => e.stopPropagation()}
          >
            <div className="p-5 border-b border-[var(--color-border-subtle)] flex items-center justify-between bg-black/[0.02]">
              <h2 className="text-[16px] font-semibold text-[var(--color-text-main)] flex items-center gap-2">
                <div className="w-6 h-6 rounded-md bg-[var(--color-primary-soft)] text-[var(--color-primary-main)] flex items-center justify-center">
                  <Plus className="w-4 h-4" />
                </div>
                New Transaction
              </h2>
              <button onClick={onClose} className="w-8 h-8 flex items-center justify-center rounded-full text-[var(--color-text-muted)] hover:text-[var(--color-text-main)] hover:bg-[var(--color-surface-2)] transition-colors">
                <X className="w-4 h-4" />
              </button>
            </div>
            
            <form onSubmit={handleSubmit} className="p-5 space-y-4">
              
              {/* Type Toggle */}
              <div className="flex gap-2 p-1 bg-[var(--color-surface-2)] rounded-[12px]">
                <button
                  type="button"
                  onClick={() => setType('EXPENSE')}
                  className={`flex-1 py-2 text-[13px] font-medium rounded-[10px] transition-all flex items-center justify-center gap-2 ${type === 'EXPENSE' ? 'bg-[var(--color-surface)] text-[var(--color-text-main)] shadow-sm border border-[var(--color-border-subtle)]' : 'text-[var(--color-text-muted)] hover:text-[var(--color-text-main)]'}`}
                >
                  <ArrowDownRight className={`w-4 h-4 ${type === 'EXPENSE' ? 'text-[var(--color-danger-main)]' : ''}`} />
                  Expense
                </button>
                <button
                  type="button"
                  onClick={() => setType('INCOME')}
                  className={`flex-1 py-2 text-[13px] font-medium rounded-[10px] transition-all flex items-center justify-center gap-2 ${type === 'INCOME' ? 'bg-[var(--color-surface)] text-[var(--color-text-main)] shadow-sm border border-[var(--color-border-subtle)]' : 'text-[var(--color-text-muted)] hover:text-[var(--color-text-main)]'}`}
                >
                  <ArrowUpRight className={`w-4 h-4 ${type === 'INCOME' ? 'text-[var(--color-secondary-main)]' : ''}`} />
                  Income
                </button>
              </div>

              {/* Amount Input */}
              <div className="space-y-1.5">
                <label className="text-[12px] font-medium text-[var(--color-text-muted)] ml-1">Amount (₹)</label>
                <div className="relative">
                  <span className="absolute left-4 top-1/2 -translate-y-1/2 text-[var(--color-text-muted)] font-medium">₹</span>
                  <input 
                    type="number"
                    required
                    value={amount}
                    onChange={e => setAmount(e.target.value)}
                    placeholder="0.00"
                    className="w-full pl-8 pr-4 py-3 bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] rounded-[12px] text-[var(--color-text-main)] text-[15px] focus:outline-none focus:border-[var(--color-primary-main)] transition-colors placeholder:text-[var(--color-text-muted)]"
                  />
                </div>
              </div>

              {/* Title Input */}
              <div className="space-y-1.5">
                <label className="text-[12px] font-medium text-[var(--color-text-muted)] ml-1">Description</label>
                <div className="relative">
                  <FileText className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-[var(--color-text-muted)]" />
                  <input 
                    type="text"
                    required
                    value={title}
                    onChange={e => setTitle(e.target.value)}
                    placeholder="What was this for?"
                    className="w-full pl-10 pr-4 py-3 bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] rounded-[12px] text-[var(--color-text-main)] text-[13px] focus:outline-none focus:border-[var(--color-primary-main)] transition-colors placeholder:text-[var(--color-text-muted)]"
                  />
                </div>
              </div>

              {/* Category Input */}
              <div className="space-y-1.5">
                <label className="text-[12px] font-medium text-[var(--color-text-muted)] ml-1">Category</label>
                <div className="relative">
                  <Tag className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-[var(--color-text-muted)]" />
                  <input 
                    type="text"
                    required
                    value={category}
                    onChange={e => setCategory(e.target.value)}
                    placeholder="e.g. Food Delivery"
                    className="w-full pl-10 pr-4 py-3 bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] rounded-[12px] text-[var(--color-text-main)] text-[13px] focus:outline-none focus:border-[var(--color-primary-main)] transition-colors placeholder:text-[var(--color-text-muted)]"
                  />
                </div>
              </div>

              <div className="pt-2">
                <motion.button
                  whileHover={{ scale: 1.01 }}
                  whileTap={{ scale: 0.98 }}
                  type="submit"
                  className="w-full py-3 bg-gradient-to-r from-[var(--color-primary-main)] to-[var(--color-accent-main)] text-white rounded-[12px] font-semibold text-[14px] shadow-[0_0_20px_rgba(45,212,191,0.2)] hover:shadow-[0_0_30px_rgba(45,212,191,0.3)] transition-all"
                >
                  Save Transaction
                </motion.button>
              </div>

            </form>
          </motion.div>
        </div>
      )}
    </AnimatePresence>
  );
}
