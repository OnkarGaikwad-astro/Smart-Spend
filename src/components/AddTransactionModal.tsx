import React, { useState, useEffect } from "react";
import { X, Plus, Trash2 } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import { useAppStore } from "@/lib/store";

export function AddTransactionModal({ isOpen, onClose }: { isOpen: boolean; onClose: () => void }) {
  const { addTransaction, updateTransaction, deleteTransaction, editingTransaction, budgets } = useAppStore();
  
  const getLocalISODateTime = (dateToUse?: string) => {
    const d = dateToUse ? new Date(dateToUse) : new Date();
    d.setMinutes(d.getMinutes() - d.getTimezoneOffset());
    return d.toISOString().slice(0, 16);
  };

  const [type, setType] = useState<"EXPENSE" | "INCOME">("EXPENSE");
  const [amount, setAmount] = useState("");
  const [title, setTitle] = useState("");
  const [category, setCategory] = useState("Food");
  const [date, setDate] = useState(getLocalISODateTime());
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    if (isOpen) {
      if (editingTransaction) {
        setType(editingTransaction.type);
        setAmount(Math.abs(editingTransaction.amount).toString());
        setTitle(editingTransaction.title);
        setCategory(editingTransaction.category);
        setDate(getLocalISODateTime(editingTransaction.date));
      } else {
        setType("EXPENSE");
        setAmount("");
        setTitle("");
        setCategory("Food");
        setDate(getLocalISODateTime());
      }
    }
  }, [isOpen, editingTransaction]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!amount || !title) return;

    setIsSubmitting(true);
    const parsedAmount = type === "EXPENSE" ? -Math.abs(parseFloat(amount)) : Math.abs(parseFloat(amount));

    try {
      if (editingTransaction) {
        await updateTransaction(editingTransaction.id, {
          title,
          amount: parsedAmount,
          type,
          category,
          date: new Date(date).toISOString(),
        });
      } else {
        await addTransaction({
          title,
          amount: parsedAmount,
          type,
          category,
          date: new Date(date).toISOString(),
        });
      }
      onClose();
    } catch (e) {
      console.error(e);
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDelete = async () => {
    if (!editingTransaction) return;
    if (confirm("Are you sure you want to delete this transaction?")) {
      setIsSubmitting(true);
      await deleteTransaction(editingTransaction.id);
      setIsSubmitting(false);
      onClose();
    }
  };

  const budgetCategories = budgets.map(b => b.category);
  const defaultExpenseCategories = ["Food", "Transport", "Subscriptions", "Entertainment", "Shopping", "Bills"];
  const expenseCategories = Array.from(new Set([...budgetCategories, ...defaultExpenseCategories, "Other"]));

  const categories = type === "EXPENSE" 
    ? expenseCategories
    : ["Scholarship", "Parents", "Sister", "Friends", "Other"];

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
                {editingTransaction ? "Edit Transaction" : "New Transaction"}
              </h2>
              <div className="flex items-center gap-2">
                {editingTransaction && (
                  <button onClick={handleDelete} className="w-8 h-8 flex items-center justify-center rounded-full text-[var(--color-danger-main)] hover:bg-[var(--color-danger-soft)] transition-colors">
                    <Trash2 className="w-4 h-4" />
                  </button>
                )}
                <button onClick={onClose} className="w-8 h-8 flex items-center justify-center rounded-full text-[var(--color-text-muted)] hover:text-[var(--color-text-main)] hover:bg-[var(--color-surface-2)] transition-colors">
                  <X className="w-4 h-4" />
                </button>
              </div>
            </div>
            
            <form onSubmit={handleSubmit} className="p-5 space-y-4">
              
              {/* Type Toggle */}
              <div className="flex gap-2 p-1 bg-[var(--color-surface-2)] rounded-[12px]">
                <button
                  type="button"
                  onClick={() => setType("EXPENSE")}
                  className={`flex-1 py-1.5 text-[13px] font-medium rounded-[8px] transition-all ${type === "EXPENSE" ? "bg-[var(--color-danger-soft)] text-[var(--color-danger-main)] shadow-sm" : "text-[var(--color-text-muted)] hover:text-[var(--color-text-main)]"}`}
                >
                  Expense
                </button>
                <button
                  type="button"
                  onClick={() => setType("INCOME")}
                  className={`flex-1 py-1.5 text-[13px] font-medium rounded-[8px] transition-all ${type === "INCOME" ? "bg-[var(--color-secondary-soft)] text-[var(--color-secondary-main)] shadow-sm" : "text-[var(--color-text-muted)] hover:text-[var(--color-text-main)]"}`}
                >
                  Income
                </button>
              </div>

              {/* Amount */}
              <div>
                <label className="block text-[12px] font-medium text-[var(--color-text-muted)] mb-1.5">Amount (₹)</label>
                <input 
                  type="number" 
                  required
                  value={amount}
                  onChange={(e) => setAmount(e.target.value)}
                  placeholder="0.00"
                  className="w-full px-3.5 py-2.5 bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] rounded-[10px] text-[var(--color-text-main)] text-[16px] font-mono focus:outline-none focus:border-[var(--color-primary-main)] transition-colors"
                />
              </div>

              {/* Title & Category */}
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-[12px] font-medium text-[var(--color-text-muted)] mb-1.5">Title</label>
                  <input 
                    type="text" 
                    required
                    value={title}
                    onChange={(e) => setTitle(e.target.value)}
                    placeholder="e.g. Netflix"
                    className="w-full px-3.5 py-2.5 bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] rounded-[10px] text-[var(--color-text-main)] text-[13px] focus:outline-none focus:border-[var(--color-primary-main)] transition-colors"
                  />
                </div>
                <div>
                  <label className="block text-[12px] font-medium text-[var(--color-text-muted)] mb-1.5">Category</label>
                  <select 
                    value={category}
                    onChange={(e) => setCategory(e.target.value)}
                    className="w-full px-3.5 py-2.5 bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] rounded-[10px] text-[var(--color-text-main)] text-[13px] focus:outline-none focus:border-[var(--color-primary-main)] transition-colors appearance-none cursor-pointer"
                  >
                    {categories.map(cat => <option key={cat} value={cat}>{cat}</option>)}
                  </select>
                </div>
              </div>

              {/* Date */}
              <div>
                <label className="block text-[12px] font-medium text-[var(--color-text-muted)] mb-1.5">Date & Time</label>
                <input 
                  type="datetime-local" 
                  required
                  value={date}
                  onChange={(e) => setDate(e.target.value)}
                  className="w-full px-3.5 py-2.5 bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] rounded-[10px] text-[var(--color-text-main)] text-[13px] focus:outline-none focus:border-[var(--color-primary-main)] transition-colors [color-scheme:dark]"
                />
              </div>

              <button 
                type="submit" 
                disabled={isSubmitting}
                className="w-full py-2.5 mt-2 bg-gradient-to-r from-[var(--color-primary-main)] to-[var(--color-purple-main)] text-white font-medium rounded-[10px] text-[14px] hover:opacity-90 transition-opacity disabled:opacity-50"
              >
                {isSubmitting ? "Saving..." : (editingTransaction ? "Save Changes" : "Save Transaction")}
              </button>
            </form>
          </motion.div>
        </div>
      )}
    </AnimatePresence>
  );
}
