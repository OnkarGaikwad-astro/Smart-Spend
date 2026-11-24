"use client";

import React, { useState } from "react";
import { X, HandCoins, ArrowDownLeft, ArrowUpRight, User, Phone, DollarSign, FileText } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import { useAppStore } from "@/lib/store";

export function AddDebtModal({
  isOpen,
  onClose,
  initialType = "LENT",
}: {
  isOpen: boolean;
  onClose: () => void;
  initialType?: "LENT" | "BORROWED";
}) {
  const { addDebt } = useAppStore();
  const [type, setType] = useState<"LENT" | "BORROWED">(initialType);
  const [personName, setPersonName] = useState("");
  const [phoneNumber, setPhoneNumber] = useState("");
  const [amount, setAmount] = useState("");
  const [note, setNote] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const parsedAmount = parseFloat(amount);
    if (!personName.trim() || isNaN(parsedAmount) || parsedAmount <= 0) return;

    setIsSubmitting(true);
    try {
      await addDebt({
        person_name: personName.trim(),
        phone_number: phoneNumber.trim() || undefined,
        type,
        initial_amount: parsedAmount,
        note: note.trim() || undefined,
      });
      // Reset form
      setPersonName("");
      setPhoneNumber("");
      setAmount("");
      setNote("");
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
          <div className="flex items-center justify-between pb-6 border-b border-[var(--color-border-subtle)]">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-[14px] bg-[var(--color-primary-soft)] text-[var(--color-primary-main)] flex items-center justify-center">
                <HandCoins className="w-5 h-5" />
              </div>
              <div>
                <h2 className="text-[19px] font-bold text-[var(--color-text-main)]">Add Lent or Borrowed</h2>
                <p className="text-[12px] text-[var(--color-text-muted)]">Track money given to or taken from someone</p>
              </div>
            </div>
            <button
              onClick={onClose}
              className="w-8 h-8 rounded-full bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] flex items-center justify-center text-[var(--color-text-muted)] hover:text-[var(--color-text-main)] transition-colors"
            >
              <X className="w-4 h-4" />
            </button>
          </div>

          <form onSubmit={handleSubmit} className="mt-6 space-y-4">
            {/* Type Selector Toggle */}
            <div className="grid grid-cols-2 gap-2 p-1.5 rounded-[16px] bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)]">
              <button
                type="button"
                onClick={() => setType("LENT")}
                className={`py-2.5 px-4 rounded-[12px] text-[13px] font-semibold transition-all flex items-center justify-center gap-2 ${
                  type === "LENT"
                    ? "bg-[var(--color-primary-main)] text-white shadow-md"
                    : "text-[var(--color-text-muted)] hover:text-[var(--color-text-main)]"
                }`}
              >
                <ArrowUpRight className="w-4 h-4" />
                <span>I Lent (You'll Get)</span>
              </button>

              <button
                type="button"
                onClick={() => setType("BORROWED")}
                className={`py-2.5 px-4 rounded-[12px] text-[13px] font-semibold transition-all flex items-center justify-center gap-2 ${
                  type === "BORROWED"
                    ? "bg-[var(--color-secondary-main)] text-white shadow-md"
                    : "text-[var(--color-text-muted)] hover:text-[var(--color-text-main)]"
                }`}
              >
                <ArrowDownLeft className="w-4 h-4" />
                <span>I Borrowed (You'll Give)</span>
              </button>
            </div>

            {/* Person Name */}
            <div>
              <label className="block text-[12px] font-semibold text-[var(--color-text-muted)] uppercase tracking-wider mb-1.5">
                Person Name *
              </label>
              <div className="relative">
                <User className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-[var(--color-text-muted)]" />
                <input
                  type="text"
                  required
                  value={personName}
                  onChange={(e) => setPersonName(e.target.value)}
                  placeholder="e.g. Rahul Sharma"
                  className="w-full pl-10 pr-4 py-3 bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] rounded-[14px] text-[14px] text-[var(--color-text-main)] placeholder-[var(--color-text-muted)] focus:outline-none focus:border-[var(--color-primary-main)] transition-colors"
                />
              </div>
            </div>

            {/* Amount */}
            <div>
              <label className="block text-[12px] font-semibold text-[var(--color-text-muted)] uppercase tracking-wider mb-1.5">
                Amount (₹) *
              </label>
              <div className="relative">
                <span className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-[var(--color-text-muted)] font-bold flex items-center justify-center">
                  ₹
                </span>
                <input
                  type="number"
                  step="any"
                  min="0.01"
                  required
                  value={amount}
                  onChange={(e) => setAmount(e.target.value)}
                  placeholder="0.00"
                  className="w-full pl-10 pr-4 py-3 bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] rounded-[14px] text-[15px] font-bold text-[var(--color-text-main)] placeholder-[var(--color-text-muted)] focus:outline-none focus:border-[var(--color-primary-main)] transition-colors"
                />
              </div>

              {/* Quick Amount Chips */}
              <div className="flex flex-wrap gap-2 mt-2">
                {[100, 200, 500, 1000, 2000, 5000].map((quick) => (
                  <button
                    key={quick}
                    type="button"
                    onClick={() => {
                      const cur = parseFloat(amount) || 0;
                      setAmount((cur + quick).toString());
                    }}
                    className="px-2.5 py-1 text-[11px] font-medium rounded-lg bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] text-[var(--color-text-muted)] hover:text-[var(--color-text-main)] hover:border-[var(--color-primary-main)] transition-colors"
                  >
                    +₹{quick.toLocaleString("en-IN")}
                  </button>
                ))}
              </div>
            </div>

            {/* Phone Number (Optional) */}
            <div>
              <label className="block text-[12px] font-semibold text-[var(--color-text-muted)] uppercase tracking-wider mb-1.5">
                Phone Number (Optional)
              </label>
              <div className="relative">
                <Phone className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-[var(--color-text-muted)]" />
                <input
                  type="tel"
                  value={phoneNumber}
                  onChange={(e) => setPhoneNumber(e.target.value)}
                  placeholder="+91 98765 43210"
                  className="w-full pl-10 pr-4 py-3 bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] rounded-[14px] text-[14px] text-[var(--color-text-main)] placeholder-[var(--color-text-muted)] focus:outline-none focus:border-[var(--color-primary-main)] transition-colors"
                />
              </div>
            </div>

            {/* Note / Reason */}
            <div>
              <label className="block text-[12px] font-semibold text-[var(--color-text-muted)] uppercase tracking-wider mb-1.5">
                Reason / Note (Optional)
              </label>
              <div className="relative">
                <FileText className="w-4 h-4 absolute left-3.5 top-3.5 text-[var(--color-text-muted)]" />
                <input
                  type="text"
                  value={note}
                  onChange={(e) => setNote(e.target.value)}
                  placeholder="e.g. Lunch split, Project contribution, Canteen"
                  className="w-full pl-10 pr-4 py-3 bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] rounded-[14px] text-[14px] text-[var(--color-text-main)] placeholder-[var(--color-text-muted)] focus:outline-none focus:border-[var(--color-primary-main)] transition-colors"
                />
              </div>
            </div>

            {/* Submit Button */}
            <div className="pt-2">
              <button
                type="submit"
                disabled={isSubmitting || !personName.trim() || !amount}
                className="w-full py-3.5 rounded-[16px] bg-[var(--color-primary-main)] hover:opacity-90 disabled:opacity-50 text-white font-semibold text-[15px] shadow-lg shadow-[var(--color-primary-soft)] transition-all flex items-center justify-center gap-2"
              >
                {isSubmitting ? (
                  <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                ) : (
                  <>Save to Lent & Borrowed</>
                )}
              </button>
            </div>
          </form>
        </motion.div>
      </div>
    </AnimatePresence>
  );
}
