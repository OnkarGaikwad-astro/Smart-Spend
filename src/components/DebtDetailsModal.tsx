"use client";

import React, { useState } from "react";
import {
  X,
  User,
  Phone,
  Copy,
  Check,
  Trash2,
  Plus,
  ArrowUpRight,
  ArrowDownLeft,
  CheckCircle,
  Calendar,
  Clock,
  Sparkles,
} from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import {
  useAppStore,
  Debt,
  DebtEntry,
  getDebtTotalOwed,
  getDebtTotalPrincipal,
  getDebtTotalRepaid,
  isDebtSettled,
} from "@/lib/store";

export function DebtDetailsModal({
  isOpen,
  onClose,
}: {
  isOpen: boolean;
  onClose: () => void;
}) {
  const {
    debts,
    activeDebtForDetails,
    deleteDebt,
    deleteDebtEntry,
    setRepaymentModalOpen,
  } = useAppStore();

  const [copied, setCopied] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);

  // Keep debt reference reactive from store
  const debt = debts.find((d) => d.id === activeDebtForDetails?.id) || activeDebtForDetails;

  if (!isOpen || !debt) return null;

  const totalOwed = getDebtTotalOwed(debt);
  const totalPrincipal = getDebtTotalPrincipal(debt);
  const totalRepaid = getDebtTotalRepaid(debt);
  const settled = isDebtSettled(debt);
  const isLent = debt.type === "LENT";
  const progressPercent = totalPrincipal > 0 ? Math.min(100, Math.round((totalRepaid / totalPrincipal) * 100)) : 0;

  const sortedEntries = [...debt.entries].sort(
    (a, b) => new Date(b.date).getTime() - new Date(a.date).getTime()
  );

  const handleCopyReminder = () => {
    const lastNote = sortedEntries[0]?.note || (isLent ? "our recent loan" : "the borrowed amount");
    const message = isLent
      ? `Hey ${debt.person_name}, friendly reminder that ₹${totalOwed.toLocaleString(
          "en-IN"
        )} is pending for ${lastNote}. Thanks!`
      : `Hey ${debt.person_name}, just checking in regarding the ₹${totalOwed.toLocaleString(
          "en-IN"
        )} I borrowed for ${lastNote}. I will repay you soon!`;

    navigator.clipboard.writeText(message);
    setCopied(true);
    setTimeout(() => setCopied(false), 2500);
  };

  const handleDeleteDebt = async () => {
    if (confirm(`Are you sure you want to delete ${debt.person_name}'s entire record?`)) {
      setIsDeleting(true);
      await deleteDebt(debt.id);
      setIsDeleting(false);
      onClose();
    }
  };

  const handleDeleteEntry = async (entryId: string) => {
    if (confirm("Delete this entry?")) {
      await deleteDebtEntry(debt.id, entryId);
    }
  };

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
        <motion.div
          initial={{ opacity: 0, scale: 0.95, y: 20 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.95, y: 20 }}
          className="w-full max-w-xl max-h-[90vh] bg-[var(--color-surface)] border border-[var(--color-border-subtle)] rounded-[28px] shadow-2xl backdrop-blur-2xl flex flex-col overflow-hidden"
        >
          {/* Header */}
          <div className="p-6 border-b border-[var(--color-border-subtle)] flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div
                className={`w-12 h-12 rounded-[16px] flex items-center justify-center text-[18px] font-bold ${
                  isLent
                    ? "bg-[var(--color-primary-soft)] text-[var(--color-primary-main)]"
                    : "bg-[var(--color-secondary-soft)] text-[var(--color-secondary-main)]"
                }`}
              >
                {debt.person_name ? debt.person_name[0].toUpperCase() : "?"}
              </div>
              <div>
                <div className="flex items-center gap-2">
                  <h2 className="text-[19px] font-bold text-[var(--color-text-main)]">
                    {debt.person_name}
                  </h2>
                  <span
                    className={`text-[11px] font-semibold px-2.5 py-0.5 rounded-full ${
                      settled
                        ? "bg-emerald-500/15 text-emerald-600 dark:text-emerald-400"
                        : isLent
                        ? "bg-[var(--color-primary-soft)] text-[var(--color-primary-main)]"
                        : "bg-[var(--color-secondary-soft)] text-[var(--color-secondary-main)]"
                    }`}
                  >
                    {settled ? "Settled" : isLent ? "You'll Get" : "You'll Give"}
                  </span>
                </div>
                {debt.phone_number ? (
                  <p className="text-[12px] text-[var(--color-text-muted)] flex items-center gap-1.5 mt-0.5">
                    <Phone className="w-3.5 h-3.5" />
                    {debt.phone_number}
                  </p>
                ) : (
                  <p className="text-[12px] text-[var(--color-text-muted)] mt-0.5">
                    {isLent ? "Money lent to them" : "Money borrowed from them"}
                  </p>
                )}
              </div>
            </div>

            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={handleCopyReminder}
                title="Copy friendly payment reminder message"
                className="flex items-center gap-1.5 px-3 py-1.5 text-[12px] font-semibold rounded-[12px] bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] text-[var(--color-text-muted)] hover:text-[var(--color-text-main)] transition-colors"
              >
                {copied ? <Check className="w-3.5 h-3.5 text-emerald-500" /> : <Copy className="w-3.5 h-3.5" />}
                <span>{copied ? "Copied!" : "Reminder"}</span>
              </button>

              <button
                type="button"
                onClick={handleDeleteDebt}
                disabled={isDeleting}
                title="Delete person and all records"
                className="w-8 h-8 rounded-full bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] flex items-center justify-center text-rose-500 hover:bg-rose-500/10 transition-colors"
              >
                <Trash2 className="w-4 h-4" />
              </button>

              <button
                onClick={onClose}
                className="w-8 h-8 rounded-full bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] flex items-center justify-center text-[var(--color-text-muted)] hover:text-[var(--color-text-main)] transition-colors"
              >
                <X className="w-4 h-4" />
              </button>
            </div>
          </div>

          {/* Content Body: Scrollable */}
          <div className="p-6 overflow-y-auto space-y-6 flex-1">
            {/* Balance Overview Card */}
            <div className="p-5 rounded-[20px] bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] relative overflow-hidden">
              <div className="flex justify-between items-start mb-3">
                <div>
                  <span className="text-[11px] font-semibold text-[var(--color-text-muted)] uppercase tracking-wider">
                    {isLent ? "Outstanding to Receive" : "Outstanding to Pay"}
                  </span>
                  <div className="text-[28px] font-extrabold text-[var(--color-text-main)] mt-0.5">
                    ₹{totalOwed.toLocaleString("en-IN")}
                  </div>
                </div>
                {settled ? (
                  <div className="flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-500/15 text-emerald-600 dark:text-emerald-400 text-[12px] font-bold">
                    <CheckCircle className="w-4 h-4" />
                    All Cleared
                  </div>
                ) : (
                  <div
                    className={`flex items-center gap-1.5 px-3 py-1 rounded-full text-[12px] font-bold ${
                      isLent
                        ? "bg-[var(--color-primary-soft)] text-[var(--color-primary-main)]"
                        : "bg-[var(--color-secondary-soft)] text-[var(--color-secondary-main)]"
                    }`}
                  >
                    {isLent ? <ArrowUpRight className="w-4 h-4" /> : <ArrowDownLeft className="w-4 h-4" />}
                    Pending
                  </div>
                )}
              </div>

              {/* Progress bar */}
              <div className="space-y-1.5">
                <div className="flex justify-between text-[11px] font-medium text-[var(--color-text-muted)]">
                  <span>Repaid: ₹{totalRepaid.toLocaleString("en-IN")}</span>
                  <span>Total Principal: ₹{totalPrincipal.toLocaleString("en-IN")}</span>
                </div>
                <div className="w-full h-2 bg-black/10 dark:bg-white/10 rounded-full overflow-hidden">
                  <div
                    className="h-full bg-emerald-500 rounded-full transition-all duration-300"
                    style={{ width: `${progressPercent}%` }}
                  />
                </div>
              </div>
            </div>

            {/* Transaction Timeline */}
            <div>
              <div className="flex items-center justify-between mb-3">
                <h3 className="text-[14px] font-bold text-[var(--color-text-main)] flex items-center gap-1.5">
                  <Clock className="w-4 h-4 text-[var(--color-text-muted)]" />
                  Ledger History ({debt.entries.length})
                </h3>
              </div>

              {sortedEntries.length === 0 ? (
                <div className="text-center py-8 text-[var(--color-text-muted)] text-[13px]">
                  No entries found.
                </div>
              ) : (
                <div className="space-y-2.5">
                  {sortedEntries.map((entry) => {
                    const isRepayment = entry.type === "REPAID";
                    const isEntryLent = entry.type === "LENT";

                    return (
                      <div
                        key={entry.id}
                        className="flex items-center justify-between p-3.5 rounded-[16px] bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] hover:border-[var(--color-primary-main)] transition-colors group"
                      >
                        <div className="flex items-center gap-3">
                          <div
                            className={`w-9 h-9 rounded-[12px] flex items-center justify-center ${
                              isRepayment
                                ? "bg-emerald-500/15 text-emerald-600 dark:text-emerald-400"
                                : isEntryLent
                                ? "bg-[var(--color-primary-soft)] text-[var(--color-primary-main)]"
                                : "bg-[var(--color-secondary-soft)] text-[var(--color-secondary-main)]"
                            }`}
                          >
                            {isRepayment ? (
                              <CheckCircle className="w-4 h-4" />
                            ) : isEntryLent ? (
                              <ArrowUpRight className="w-4 h-4" />
                            ) : (
                              <ArrowDownLeft className="w-4 h-4" />
                            )}
                          </div>
                          <div>
                            <div className="flex items-center gap-2">
                              <span className="text-[13px] font-semibold text-[var(--color-text-main)]">
                                {entry.note || (isRepayment ? "Repayment" : "Loan")}
                              </span>
                              <span
                                className={`text-[10px] font-bold px-1.5 py-0.5 rounded ${
                                  isRepayment
                                    ? "bg-emerald-500/15 text-emerald-600 dark:text-emerald-400"
                                    : "bg-black/5 dark:bg-white/5 text-[var(--color-text-muted)]"
                                }`}
                              >
                                {entry.type}
                              </span>
                            </div>
                            <div className="text-[11px] text-[var(--color-text-muted)] mt-0.5 flex items-center gap-1">
                              <Calendar className="w-3 h-3" />
                              {new Date(entry.date).toLocaleDateString("en-IN", {
                                day: "numeric",
                                month: "short",
                                year: "numeric",
                              })}
                            </div>
                          </div>
                        </div>

                        <div className="flex items-center gap-3">
                          <span
                            className={`text-[14px] font-bold ${
                              isRepayment
                                ? "text-emerald-600 dark:text-emerald-400"
                                : isLent
                                ? "text-[var(--color-primary-main)]"
                                : "text-[var(--color-secondary-main)]"
                            }`}
                          >
                            {isRepayment ? "-" : "+"}₹{entry.amount.toLocaleString("en-IN")}
                          </span>

                          <button
                            type="button"
                            onClick={() => handleDeleteEntry(entry.id)}
                            title="Delete this entry"
                            className="opacity-0 group-hover:opacity-100 p-1 text-[var(--color-text-muted)] hover:text-rose-500 transition-opacity"
                          >
                            <Trash2 className="w-3.5 h-3.5" />
                          </button>
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          </div>

          {/* Action Footer */}
          <div className="p-4 md:p-6 border-t border-[var(--color-border-subtle)] bg-[var(--color-surface)] grid grid-cols-2 gap-3">
            <button
              type="button"
              onClick={() => {
                onClose();
                setRepaymentModalOpen(true, debt);
              }}
              className="py-3 px-4 rounded-[16px] bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] text-[var(--color-text-main)] hover:border-[var(--color-primary-main)] font-semibold text-[13px] flex items-center justify-center gap-2 transition-colors"
            >
              <Plus className="w-4 h-4 text-[var(--color-primary-main)]" />
              <span>Add / Lend More</span>
            </button>

            <button
              type="button"
              onClick={() => {
                onClose();
                setRepaymentModalOpen(true, debt);
              }}
              className="py-3 px-4 rounded-[16px] bg-emerald-600 hover:bg-emerald-700 text-white font-semibold text-[13px] flex items-center justify-center gap-2 shadow-lg shadow-emerald-600/20 transition-all"
            >
              <CheckCircle className="w-4 h-4" />
              <span>Record Repayment</span>
            </button>
          </div>
        </motion.div>
      </div>
    </AnimatePresence>
  );
}
