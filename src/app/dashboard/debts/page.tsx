"use client";

import React, { useState, useMemo } from "react";
import {
  HandCoins,
  ArrowUpRight,
  ArrowDownLeft,
  Search,
  Plus,
  CheckCircle,
  Phone,
  Clock,
  MoreVertical,
  Trash2,
  Calendar,
  Sparkles,
} from "lucide-react";
import {
  useAppStore,
  Debt,
  getDebtTotalOwed,
  getDebtTotalPrincipal,
  getDebtTotalRepaid,
  isDebtSettled,
} from "@/lib/store";

type FilterType = "ALL" | "LENT" | "BORROWED" | "PENDING" | "SETTLED";

export default function DebtsPage() {
  const {
    debts,
    setAddDebtModalOpen,
    setRepaymentModalOpen,
    setDebtDetailsModalOpen,
    deleteDebt,
  } = useAppStore();

  const [searchQuery, setSearchQuery] = useState("");
  const [filter, setFilter] = useState<FilterType>("ALL");

  // Aggregate Metrics
  const metrics = useMemo(() => {
    let totalLentOwed = 0;
    let totalBorrowedOwed = 0;
    let lentCount = 0;
    let borrowedCount = 0;
    let settledCount = 0;
    let pendingCount = 0;

    for (const debt of debts) {
      const owed = getDebtTotalOwed(debt);
      const settled = isDebtSettled(debt);

      if (settled) {
        settledCount++;
      } else {
        pendingCount++;
      }

      if (debt.type === "LENT") {
        totalLentOwed += owed;
        if (!settled) lentCount++;
      } else {
        totalBorrowedOwed += owed;
        if (!settled) borrowedCount++;
      }
    }

    const netPosition = totalLentOwed - totalBorrowedOwed;

    return {
      totalLentOwed,
      totalBorrowedOwed,
      netPosition,
      lentCount,
      borrowedCount,
      settledCount,
      pendingCount,
    };
  }, [debts]);

  // Filtered List
  const filteredDebts = useMemo(() => {
    return debts.filter((debt) => {
      // Search text match
      const query = searchQuery.toLowerCase().trim();
      if (query) {
        const matchesName = debt.person_name.toLowerCase().includes(query);
        const matchesPhone = debt.phone_number?.toLowerCase().includes(query);
        const matchesNote = debt.entries.some((e) =>
          e.note?.toLowerCase().includes(query)
        );
        if (!matchesName && !matchesPhone && !matchesNote) return false;
      }

      const settled = isDebtSettled(debt);

      if (filter === "LENT") return debt.type === "LENT";
      if (filter === "BORROWED") return debt.type === "BORROWED";
      if (filter === "PENDING") return !settled;
      if (filter === "SETTLED") return settled;

      return true;
    });
  }, [debts, searchQuery, filter]);

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-[26px] font-extrabold tracking-tight text-[var(--color-text-main)] flex items-center gap-2.5">
            <HandCoins className="w-7 h-7 text-[var(--color-primary-main)]" />
            Debts & Khata
          </h1>
          <p className="text-[14px] text-[var(--color-text-muted)] mt-1">
            Track money lent to friends, colleagues, and borrowed amounts with repayment logs
          </p>
        </div>

        <button
          onClick={() => setAddDebtModalOpen(true)}
          className="flex items-center justify-center gap-2 px-5 py-2.5 bg-[var(--color-primary-main)] hover:brightness-110 text-white rounded-[16px] font-semibold text-[14px] shadow-lg shadow-[var(--color-primary-main)]/20 transition-all cursor-pointer"
        >
          <Plus className="w-4 h-4" />
          <span>Add Record</span>
        </button>
      </div>

      {/* Top Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {/* You'll Get Card */}
        <div className="p-5 rounded-[22px] bg-[var(--color-surface)] border border-[var(--color-border-subtle)] relative overflow-hidden backdrop-blur-md">
          <div className="flex items-center justify-between">
            <span className="text-[12px] font-semibold uppercase tracking-wider text-[var(--color-text-muted)]">
              You'll Get (Lent)
            </span>
            <div className="w-8 h-8 rounded-full bg-[var(--color-primary-soft)] text-[var(--color-primary-main)] flex items-center justify-center">
              <ArrowUpRight className="w-4 h-4" />
            </div>
          </div>
          <div className="text-[26px] font-extrabold text-[var(--color-primary-main)] mt-2">
            ₹{metrics.totalLentOwed.toLocaleString("en-IN")}
          </div>
          <div className="text-[12px] text-[var(--color-text-muted)] mt-1">
            {metrics.lentCount === 1
              ? "Pending from 1 person"
              : `Pending from ${metrics.lentCount} people`}
          </div>
        </div>

        {/* You'll Give Card */}
        <div className="p-5 rounded-[22px] bg-[var(--color-surface)] border border-[var(--color-border-subtle)] relative overflow-hidden backdrop-blur-md">
          <div className="flex items-center justify-between">
            <span className="text-[12px] font-semibold uppercase tracking-wider text-[var(--color-text-muted)]">
              You'll Give (Borrowed)
            </span>
            <div className="w-8 h-8 rounded-full bg-[var(--color-secondary-soft)] text-[var(--color-secondary-main)] flex items-center justify-center">
              <ArrowDownLeft className="w-4 h-4" />
            </div>
          </div>
          <div className="text-[26px] font-extrabold text-[var(--color-secondary-main)] mt-2">
            ₹{metrics.totalBorrowedOwed.toLocaleString("en-IN")}
          </div>
          <div className="text-[12px] text-[var(--color-text-muted)] mt-1">
            {metrics.borrowedCount === 1
              ? "To repay 1 person"
              : `To repay ${metrics.borrowedCount} people`}
          </div>
        </div>

        {/* Net Balance Card */}
        <div className="p-5 rounded-[22px] bg-[var(--color-surface)] border border-[var(--color-border-subtle)] relative overflow-hidden backdrop-blur-md">
          <div className="flex items-center justify-between">
            <span className="text-[12px] font-semibold uppercase tracking-wider text-[var(--color-text-muted)]">
              Net Balance
            </span>
            <div
              className={`w-8 h-8 rounded-full flex items-center justify-center text-[13px] font-bold ${
                metrics.netPosition >= 0
                  ? "bg-emerald-500/15 text-emerald-600 dark:text-emerald-400"
                  : "bg-rose-500/15 text-rose-500"
              }`}
            >
              {metrics.netPosition >= 0 ? "+" : "-"}
            </div>
          </div>
          <div
            className={`text-[26px] font-extrabold mt-2 ${
              metrics.netPosition >= 0
                ? "text-emerald-600 dark:text-emerald-400"
                : "text-rose-500"
            }`}
          >
            {metrics.netPosition >= 0 ? "+" : "-"}₹
            {Math.abs(metrics.netPosition).toLocaleString("en-IN")}
          </div>
          <div className="text-[12px] text-[var(--color-text-muted)] mt-1">
            {metrics.netPosition > 0
              ? "Net amount to be received"
              : metrics.netPosition < 0
              ? "Net amount you need to pay"
              : "All even & balanced"}
          </div>
        </div>
      </div>

      {/* Toolbar: Search and Filter Chips */}
      <div className="flex flex-col sm:flex-row gap-3 items-stretch sm:items-center justify-between">
        {/* Search Input */}
        <div className="relative flex-1 max-w-md">
          <Search className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-[var(--color-text-muted)]" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search by name, note, or phone..."
            className="w-full pl-10 pr-4 py-2 bg-[var(--color-surface)] border border-[var(--color-border-subtle)] rounded-[14px] text-[13px] text-[var(--color-text-main)] placeholder-[var(--color-text-muted)] focus:outline-none focus:border-[var(--color-primary-main)] transition-colors"
          />
        </div>

        {/* Filter Chips */}
        <div className="flex items-center gap-1.5 overflow-x-auto pb-1 sm:pb-0 hide-scrollbar">
          {(
            [
              { id: "ALL", label: "All", count: debts.length },
              { id: "LENT", label: "Lent", count: debts.filter((d) => d.type === "LENT").length },
              { id: "BORROWED", label: "Borrowed", count: debts.filter((d) => d.type === "BORROWED").length },
              { id: "PENDING", label: "Pending", count: metrics.pendingCount },
              { id: "SETTLED", label: "Settled", count: metrics.settledCount },
            ] as const
          ).map((tab) => (
            <button
              key={tab.id}
              onClick={() => setFilter(tab.id)}
              className={`px-3 py-1.5 rounded-full text-[12px] font-semibold transition-all whitespace-nowrap cursor-pointer flex items-center gap-1.5 ${
                filter === tab.id
                  ? "bg-[var(--color-primary-main)] text-white shadow-sm"
                  : "bg-[var(--color-surface)] border border-[var(--color-border-subtle)] text-[var(--color-text-muted)] hover:text-[var(--color-text-main)] hover:bg-[var(--color-surface-2)]"
              }`}
            >
              <span>{tab.label}</span>
              <span
                className={`text-[10px] px-1.5 py-0.2 rounded-full ${
                  filter === tab.id
                    ? "bg-white/20 text-white"
                    : "bg-black/5 dark:bg-white/5 text-[var(--color-text-muted)]"
                }`}
              >
                {tab.count}
              </span>
            </button>
          ))}
        </div>
      </div>

      {/* Debts Grid / Cards */}
      {filteredDebts.length === 0 ? (
        <div className="p-12 text-center rounded-[24px] bg-[var(--color-surface)] border border-[var(--color-border-subtle)] flex flex-col items-center justify-center">
          <div className="w-14 h-14 rounded-[18px] bg-[var(--color-surface-2)] text-[var(--color-text-muted)] flex items-center justify-center mb-3">
            <HandCoins className="w-7 h-7" />
          </div>
          <h3 className="text-[17px] font-bold text-[var(--color-text-main)]">
            {searchQuery || filter !== "ALL"
              ? "No records match your filter"
              : "No Lent or Borrowed records yet"}
          </h3>
          <p className="text-[13px] text-[var(--color-text-muted)] max-w-sm mt-1 mb-5">
            {searchQuery || filter !== "ALL"
              ? "Try clearing your search query or switching to another filter."
              : "Keep track of who owes you and whom you owe. Add your first record now."}
          </p>
          <button
            onClick={() => setAddDebtModalOpen(true)}
            className="flex items-center gap-2 px-5 py-2.5 bg-[var(--color-primary-main)] hover:brightness-110 text-white rounded-[14px] font-semibold text-[13px] shadow-md transition-all cursor-pointer"
          >
            <Plus className="w-4 h-4" />
            <span>Add Record</span>
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {filteredDebts.map((debt) => {
            const totalOwed = getDebtTotalOwed(debt);
            const totalPrincipal = getDebtTotalPrincipal(debt);
            const totalRepaid = getDebtTotalRepaid(debt);
            const settled = isDebtSettled(debt);
            const isLent = debt.type === "LENT";
            const progressPercent =
              totalPrincipal > 0
                ? Math.min(100, Math.round((totalRepaid / totalPrincipal) * 100))
                : 0;

            const lastEntry = debt.entries[debt.entries.length - 1];

            return (
              <div
                key={debt.id}
                className="p-5 rounded-[24px] bg-[var(--color-surface)] border border-[var(--color-border-subtle)] hover:border-[var(--color-primary-main)]/60 transition-all shadow-sm hover:shadow-md flex flex-col justify-between group"
              >
                {/* Card Top: Person & Badges */}
                <div>
                  <div className="flex items-start justify-between gap-2 mb-3">
                    <div className="flex items-center gap-3">
                      <div
                        className={`w-11 h-11 rounded-[14px] flex items-center justify-center font-bold text-[16px] ${
                          isLent
                            ? "bg-[var(--color-primary-soft)] text-[var(--color-primary-main)]"
                            : "bg-[var(--color-secondary-soft)] text-[var(--color-secondary-main)]"
                        }`}
                      >
                        {debt.person_name ? debt.person_name[0].toUpperCase() : "?"}
                      </div>
                      <div>
                        <h4 className="text-[16px] font-bold text-[var(--color-text-main)] group-hover:text-[var(--color-primary-main)] transition-colors">
                          {debt.person_name}
                        </h4>
                        {debt.phone_number ? (
                          <p className="text-[11px] text-[var(--color-text-muted)] flex items-center gap-1 mt-0.5">
                            <Phone className="w-3 h-3" />
                            {debt.phone_number}
                          </p>
                        ) : (
                          <p className="text-[11px] text-[var(--color-text-muted)] mt-0.5">
                            {isLent ? "You Lent" : "You Borrowed"}
                          </p>
                        )}
                      </div>
                    </div>

                    <span
                      className={`text-[10px] font-bold px-2.5 py-0.5 rounded-full ${
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

                  {/* Balance Display */}
                  <div className="my-4 p-3.5 rounded-[16px] bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)]">
                    <div className="flex items-baseline justify-between">
                      <span className="text-[11px] font-semibold text-[var(--color-text-muted)] uppercase tracking-wider">
                        {settled ? "Total Cleared" : "Outstanding"}
                      </span>
                      <div
                        className={`text-[20px] font-extrabold ${
                          settled
                            ? "text-emerald-600 dark:text-emerald-400"
                            : isLent
                            ? "text-[var(--color-primary-main)]"
                            : "text-[var(--color-secondary-main)]"
                        }`}
                      >
                        ₹{totalOwed.toLocaleString("en-IN")}
                      </div>
                    </div>

                    {/* Mini Progress */}
                    <div className="mt-2 space-y-1">
                      <div className="w-full h-1.5 bg-black/10 dark:bg-white/10 rounded-full overflow-hidden">
                        <div
                          className="h-full bg-emerald-500 rounded-full"
                          style={{ width: `${progressPercent}%` }}
                        />
                      </div>
                      <div className="flex justify-between text-[10px] text-[var(--color-text-muted)]">
                        <span>Repaid: ₹{totalRepaid.toLocaleString("en-IN")}</span>
                        <span>{progressPercent}%</span>
                      </div>
                    </div>
                  </div>

                  {/* Last Note / Reason */}
                  {lastEntry?.note && (
                    <p className="text-[12px] text-[var(--color-text-muted)] line-clamp-1 italic mb-4">
                      "{lastEntry.note}"
                    </p>
                  )}
                </div>

                {/* Card Action Buttons */}
                <div className="pt-2 border-t border-[var(--color-border-subtle)] grid grid-cols-2 gap-2">
                  <button
                    type="button"
                    onClick={() => setRepaymentModalOpen(true, debt)}
                    className="py-2 px-3 rounded-[12px] bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-600 dark:text-emerald-400 text-[12px] font-semibold flex items-center justify-center gap-1.5 transition-colors cursor-pointer"
                  >
                    <CheckCircle className="w-3.5 h-3.5" />
                    <span>Pay / Add</span>
                  </button>

                  <button
                    type="button"
                    onClick={() => setDebtDetailsModalOpen(true, debt)}
                    className="py-2 px-3 rounded-[12px] bg-[var(--color-surface-2)] hover:border-[var(--color-primary-main)] border border-[var(--color-border-subtle)] text-[var(--color-text-main)] text-[12px] font-semibold flex items-center justify-center gap-1.5 transition-colors cursor-pointer"
                  >
                    <Clock className="w-3.5 h-3.5 text-[var(--color-text-muted)]" />
                    <span>Ledger</span>
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
