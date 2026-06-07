"use client";

import { FileText, Download, FileBarChart, CalendarDays } from "lucide-react";
import { motion } from "framer-motion";

export default function ReportsPage() {
  const containerVariants = {
    hidden: { opacity: 0 },
    show: { opacity: 1, transition: { staggerChildren: 0.1 } }
  };

  const itemVariants = {
    hidden: { opacity: 0, y: 10 },
    show: { opacity: 1, y: 0, transition: { type: "spring", stiffness: 300, damping: 24 } }
  };

  const mockReports = [
    { id: 1, title: "May 2026 Monthly Summary", date: "Jun 1, 2026", type: "PDF", size: "1.2 MB" },
    { id: 2, title: "April 2026 Monthly Summary", date: "May 1, 2026", type: "PDF", size: "1.1 MB" },
    { id: 3, title: "Q1 2026 Tax Export", date: "Apr 5, 2026", type: "CSV", size: "45 KB" },
  ];

  return (
    <motion.div 
      initial="hidden"
      animate="show"
      variants={containerVariants}
      className="space-y-4"
    >
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2 mb-2">
        <motion.div variants={itemVariants}>
          <h1 className="text-[18px] font-bold text-[var(--color-text-main)] flex items-center gap-2">
            <FileBarChart className="w-5 h-5 text-[var(--color-primary-main)]" />
            Financial Reports
          </h1>
          <p className="text-[13px] text-[var(--color-text-muted)]">Generate, view, and export your spending reports.</p>
        </motion.div>
        
        <motion.button 
          variants={itemVariants}
          whileHover={{ scale: 1.03 }}
          whileTap={{ scale: 0.97 }}
          className="flex items-center gap-1.5 px-4 py-2.5 bg-[var(--color-primary-main)] text-white rounded-[10px] text-[13px] font-medium shadow-sm"
        >
          <FileText className="w-4 h-4" /> Generate New Report
        </motion.button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-[1fr_250px] gap-3.5">
        
        {/* Reports List */}
        <motion.div variants={itemVariants} className="bg-[var(--color-surface)] border border-[var(--color-border-subtle)] rounded-[14px] p-4.5">
          <h2 className="text-[14px] font-semibold text-[var(--color-text-main)] mb-3.5 border-b border-[var(--color-border-subtle)] pb-3">Available Reports</h2>
          
          <div className="flex flex-col gap-2">
            {mockReports.map((report) => (
              <div key={report.id} className="flex items-center justify-between p-3 rounded-[12px] hover:bg-[var(--color-surface-2)] border border-transparent hover:border-[var(--color-border-subtle)] transition-colors cursor-pointer group">
                <div className="flex items-center gap-3">
                  <div className={`w-9 h-9 rounded-[10px] flex items-center justify-center shrink-0 ${report.type === 'PDF' ? 'bg-[var(--color-danger-soft)] text-[var(--color-danger-main)]' : 'bg-[var(--color-secondary-soft)] text-[var(--color-secondary-main)]'}`}>
                    <FileText className="w-4 h-4" />
                  </div>
                  <div>
                    <h3 className="text-[13px] font-medium text-[var(--color-text-main)]">{report.title}</h3>
                    <p className="text-[11px] text-[var(--color-text-muted)] mt-0.5">{report.date} · {report.type} · {report.size}</p>
                  </div>
                </div>
                <button className="p-2 text-[var(--color-text-muted)] hover:text-[var(--color-primary-main)] bg-[var(--color-surface-2)] rounded-[8px] opacity-0 group-hover:opacity-100 transition-all border border-[var(--color-border-subtle)]">
                  <Download className="w-4 h-4" />
                </button>
              </div>
            ))}
          </div>
        </motion.div>

        {/* Quick Exports Panel */}
        <motion.div variants={itemVariants} className="bg-[var(--color-surface)] border border-[var(--color-border-subtle)] rounded-[14px] p-4.5 h-fit">
          <h2 className="text-[14px] font-semibold text-[var(--color-text-main)] mb-3.5 border-b border-[var(--color-border-subtle)] pb-3">Quick Export</h2>
          
          <div className="space-y-2.5">
            <button className="w-full flex items-center gap-2.5 p-3 rounded-[10px] bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] text-[12px] font-medium text-[var(--color-text-main)] hover:text-[var(--color-primary-main)] hover:border-[var(--color-primary-soft)] transition-colors">
              <CalendarDays className="w-4 h-4 text-[var(--color-text-muted)]" />
              Export This Month (CSV)
            </button>
            <button className="w-full flex items-center gap-2.5 p-3 rounded-[10px] bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] text-[12px] font-medium text-[var(--color-text-main)] hover:text-[var(--color-primary-main)] hover:border-[var(--color-primary-soft)] transition-colors">
              <CalendarDays className="w-4 h-4 text-[var(--color-text-muted)]" />
              Export Last Month (CSV)
            </button>
            <button className="w-full flex items-center gap-2.5 p-3 rounded-[10px] bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] text-[12px] font-medium text-[var(--color-text-main)] hover:text-[var(--color-primary-main)] hover:border-[var(--color-primary-soft)] transition-colors">
              <CalendarDays className="w-4 h-4 text-[var(--color-text-muted)]" />
              Export Full Year (CSV)
            </button>
          </div>
        </motion.div>

      </div>
    </motion.div>
  );
}
