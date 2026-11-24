"use client";

import React, { useState, useEffect } from "react";
import { X, CheckCircle, PlusCircle, Calendar, FileText, IndianRupee } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import { useAppStore, getDebtTotalOwed } from "@/lib/store";

export function RecordRepaymentModal({
  isOpen,
  onClose,
}: {
  isOpen: boolean;
  onClose: () => void;
}) {
  const { activeDebtForAction, addDebtEntry } = useAppStore();
  const [entryType, setEntryType] = useState<"REPAID" | "ADD_MORE">("REPAID");
  const [amount, setAmount] = useState("");
  const [note, setNote] = useState("");
  const [date, setDate] = useState(() => new Date().toISOString().slice(0, 10));
  const [isSubmitting, setIsSubmitting] = useState(false);

  const debt = activeDebtForAction;
  const totalOwed = debt ? getDebtTotalOwed(debt) : 0;
  const isLent = debt?.type === "LENT";

  useEffect(() => {
    if (isOpen && debt) {
      setEntryType("REPAID");
      setAmount(totalOwed > 0 ? totalOwed.toString() : "");
      setNote("");
      setDate(new Date().toISOString().slice(0, 10));
    }
  }, [isOpen, debt, totalOwed]);

  if (!isOpen || !debt) return null;

  const handleQuickAdd = (val: number) => {
    const current = parseFloat(amount) || 0;
    setAmount((current + val).toString());
  };

  const handleFullAmount = () => {
    setAmount(totalOwed.toString());
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const parsedAmount = parseFloat(amount);
    if (isNaN(parsedAmount) || parsedAmount <= 0) return;

    setIsSubmitting(true);
    try {
      const actualType = entryType === "REPAID" ? "REPAID" : debt.type;
      const defaultNote =
        entryType === "REPAID"
          ? isLent
            ? "Repayment received"
            : "Repayment paid"
          : isLent
          ? "Additional money lent"
          : "Additional money borrowed";

      await addDebtEntry(debt.id, {
        amount: parsedAmount,
        type: actualType,
        note: note.trim() || defaultNote,
        date: new Date(date).toISOString(),
      });

      onClose();
    } catch (err) {
      console.error(err);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
        <motion.div
          initial={{ opacity: 0, scale: 0.95, y: 20 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.95, y: 20 }}
          className="w-full max-w-lg bg-[var(--color-surface)] border border-[var(--color-border-subtle)] rounded-[28px] p-6 md:p-8 shadow-2xl backdrop-blur-2xl relative overflow-hidden"
        >
          {/* Header */}
          <div className="flex items-center justify-between pb-5 border-b border-[var(--color-border-subtle)]">
            <div className="flex items-center gap-3">
              <div
                className={`w-10 h-10 rounded-[14px] flex items-center justify-center ${
                  entryType === "REPAID"
                    ? "bg-emerald-500/15 text-emerald-600 dark:text-emerald-400"
                    : isLent
                    ? "bg-[var(--color-primary-soft)] text-[var(--color-primary-main)]"
                    : "bg-[var(--color-secondary-soft)] text-[var(--color-secondary-main)]"
                }`}
              >
                {entryType === "REPAID" ? (
                  <CheckCircle className="w-5 h-5" />
                ) : (
                  <PlusCircle className="w-5 h-5" />
                )}
              </div>
              <div>
                <h2 className="text-[18px] font-bold text-[var(--color-text-main)]">
                  {entryType === "REPAID"
                    ? isLent
                      ? "Record Payment Received"
                      : "Record Payment Made"
                    : isLent
                    ? "Lend More Money"
                    : "Borrow More Money"}
                </h2>
                <p className="text-[12px] text-[var(--color-text-muted)]">
                  {debt.person_name} • Outstanding: ₹{totalOwed.toLocaleString("en-IN")}
                </p>
              </div>
            </div>
            <button
              onClick={onClose}
              className="w-8 h-8 rounded-full bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] flex items-center justify-center text-[var(--color-text-muted)] hover:text-[var(--color-text-main)] transition-colors"
            >
              <X className="w-4 h-4" />
            </button>
          </div>

          <form onSubmit={handleSubmit} className="mt-5 space-y-4">
            {/* Mode Switcher */}
            <div className="grid grid-cols-2 gap-2 p-1.5 rounded-[16px] bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)]">
              <button
                type="button"
                onClick={() => setEntryType("REPAID")}
                className={`py-2 px-3 rounded-[12px] text-[13px] font-semibold transition-all flex items-center justify-center gap-1.5 ${
                  entryType === "REPAID"
                    ? "bg-emerald-600 text-white shadow-sm"
                    : "text-[var(--color-text-muted)] hover:text-[var(--color-text-main)]"
                }`}
              >
                <CheckCircle className="w-4 h-4" />
                <span>Payment Repaid</span>
              </button>

              <button
                type="button"
                onClick={() => setEntryType("ADD_MORE")}
                className={`py-2 px-3 rounded-[12px] text-[13px] font-semibold transition-all flex items-center justify-center gap-1.5 ${
                  entryType === "ADD_MORE"
                    ? isLent
                      ? "bg-[var(--color-primary-main)] text-white shadow-sm"
                      : "bg-[var(--color-secondary-main)] text-white shadow-sm"
                    : "text-[var(--color-text-muted)] hover:text-[var(--color-text-main)]"
                }`}
              >
                <PlusCircle className="w-4 h-4" />
                <span>Add More</span>
              </button>
            </div>

            {/* Amount */}
            <div>
              <div className="flex items-center justify-between mb-1.5">
                <label className="text-[12px] font-semibold text-[var(--color-text-muted)] uppercase tracking-wider">
                  Amount (₹) *
                </label>
                {entryType === "REPAID" && totalOwed > 0 && (
                  <button
                    type="button"
                    onClick={handleFullAmount}
                    className="text-[11px] font-bold text-emerald-600 dark:text-emerald-400 hover:underline"
                  >
                    Settle Full (₹{totalOwed.toLocaleString("en-IN")})
                  </button>
                )}
              </div>
              <div className="relative">
                <span className="w-5 h-5 absolute left-3.5 top-1/2 -translate-y-1/2 text-[var(--color-text-muted)] font-bold flex items-center justify-center">
                  ₹
                </span>
                <input
                  type="number"
                  step="any"
                  min="0.01"
                  required
                  autoFocus
                  value={amount}
                  onChange={(e) => setAmount(e.target.value)}
                  placeholder="0.00"
                  className="w-full pl-10 pr-4 py-3 bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] rounded-[14px] text-[16px] font-bold text-[var(--color-text-main)] placeholder-[var(--color-text-muted)] focus:outline-none focus:border-[var(--color-primary-main)] transition-colors"
                />
              </div>

              {/* Quick Amount Chips */}
              <div className="flex flex-wrap gap-2 mt-2">
                {[100, 500, 1000, 2000, 5000].map((quick) => (
                  <button
                    key={quick}
                    type="button"
                    onClick={() => handleQuickAdd(quick)}
                    className="px-2.5 py-1 text-[11px] font-medium rounded-lg bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] text-[var(--color-text-muted)] hover:text-[var(--color-text-main)] hover:border-[var(--color-primary-main)] transition-colors"
                  >
                    +₹{quick.toLocaleString("en-IN")}
                  </button>
                ))}
              </div>
            </div>

            {/* Note */}
            <div>
              <label className="block text-[12px] font-semibold text-[var(--color-text-muted)] uppercase tracking-wider mb-1.5">
                Note / Description (Optional)
              </label>
              <div className="relative">
                <FileText className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-[var(--color-text-muted)]" />
                <input
                  type="text"
                  value={note}
                  onChange={(e) => setNote(e.target.value)}
                  placeholder={
                    entryType === "REPAID"
                      ? "e.g. GPay, cash returned, settled"
                      : "e.g. Lunch split, cab fare, groceries"
                  }
                  className="w-full pl-10 pr-4 py-2.5 bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] rounded-[14px] text-[13px] text-[var(--color-text-main)] placeholder-[var(--color-text-muted)] focus:outline-none focus:border-[var(--color-primary-main)] transition-colors"
                />
              </div>
            </div>

            {/* Date */}
            <div>
              <label className="block text-[12px] font-semibold text-[var(--color-text-muted)] uppercase tracking-wider mb-1.5">
                Date
              </label>
              <div className="relative">
                <Calendar className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-[var(--color-text-muted)]" />
                <input
                  type="date"
                  value={date}
                  onChange={(e) => setDate(e.target.value)}
                  className="w-full pl-10 pr-4 py-2.5 bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] rounded-[14px] text-[13px] text-[var(--color-text-main)] focus:outline-none focus:border-[var(--color-primary-main)] transition-colors"
                />
              </div>
            </div>

            {/* Submit Button */}
            <div className="pt-2">
              <button
                type="submit"
                disabled={isSubmitting || !amount}
                className={`w-full py-3 px-6 rounded-[16px] text-white font-bold text-[14px] shadow-lg transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed ${
                  entryType === "REPAID"
                    ? "bg-emerald-600 hover:bg-emerald-700 shadow-emerald-600/20"
                    : isLent
                    ? "bg-[var(--color-primary-main)] hover:brightness-110 shadow-[var(--color-primary-main)]/20"
                    : "bg-[var(--color-secondary-main)] hover:brightness-110 shadow-[var(--color-secondary-main)]/20"
                }`}
              >
                {isSubmitting
                  ? "Saving..."
                  : entryType === "REPAID"
                  ? "Save Repayment"
                  : "Save Additional Amount"}
              </button>
            </div>
          </form>
        </motion.div>
      </div>
    </AnimatePresence>
  );
}
