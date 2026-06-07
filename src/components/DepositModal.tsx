import React, { useState } from "react";
import { X, PiggyBank } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import { useAppStore } from "@/lib/store";

export function DepositModal({ isOpen, onClose }: { isOpen: boolean; onClose: () => void }) {
  const { depositToGoal, activeGoalForDeposit } = useAppStore();
  const [amount, setAmount] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!amount || !activeGoalForDeposit) return;

    setIsSubmitting(true);
    const parsedAmount = Math.abs(parseFloat(amount));

    try {
      await depositToGoal(activeGoalForDeposit.id, parsedAmount);
      setAmount("");
      onClose();
    } catch (e) {
      console.error(e);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <AnimatePresence>
      {isOpen && activeGoalForDeposit && (
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
            className="relative w-full max-w-sm bg-[var(--color-surface)] border border-[var(--color-border-subtle)] rounded-[20px] shadow-2xl overflow-hidden backdrop-blur-xl"
            onClick={e => e.stopPropagation()}
          >
            <div className="p-5 border-b border-[var(--color-border-subtle)] flex items-center justify-between bg-black/[0.02]">
              <h2 className="text-[16px] font-semibold text-[var(--color-text-main)] flex items-center gap-2">
                <div className="w-6 h-6 rounded-md bg-[var(--color-secondary-soft)] text-[var(--color-secondary-main)] flex items-center justify-center">
                  <PiggyBank className="w-4 h-4" />
                </div>
                Deposit to Savings
              </h2>
              <button onClick={onClose} className="w-8 h-8 flex items-center justify-center rounded-full text-[var(--color-text-muted)] hover:text-[var(--color-text-main)] hover:bg-[var(--color-surface-2)] transition-colors">
                <X className="w-4 h-4" />
              </button>
            </div>
            
            <form onSubmit={handleSubmit} className="p-5 space-y-4">
              <div className="text-center mb-2">
                <div className="text-[13px] font-semibold text-[var(--color-text-main)]">{activeGoalForDeposit.name}</div>
                <div className="text-[11px] text-[var(--color-text-muted)] mt-1">
                  Target: ₹{activeGoalForDeposit.target.toLocaleString('en-IN')} | Currently Saved: ₹{activeGoalForDeposit.saved.toLocaleString('en-IN')}
                </div>
              </div>

              <div>
                <label className="block text-[12px] font-medium text-[var(--color-text-muted)] mb-1.5">Amount to Deposit (₹)</label>
                <input 
                  type="number" 
                  required
                  value={amount}
                  onChange={(e) => setAmount(e.target.value)}
                  placeholder="0.00"
                  className="w-full px-3.5 py-2.5 bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] rounded-[10px] text-[var(--color-text-main)] text-[16px] font-mono focus:outline-none focus:border-[var(--color-primary-main)] transition-colors"
                />
              </div>

              <button 
                type="submit" 
                disabled={isSubmitting}
                className="w-full py-2.5 mt-2 bg-gradient-to-r from-[var(--color-secondary-main)] to-[var(--color-accent-main)] text-white font-medium rounded-[10px] text-[14px] hover:opacity-90 transition-opacity disabled:opacity-50"
              >
                {isSubmitting ? "Processing..." : "Confirm Deposit"}
              </button>
            </form>
          </motion.div>
        </div>
      )}
    </AnimatePresence>
  );
}
