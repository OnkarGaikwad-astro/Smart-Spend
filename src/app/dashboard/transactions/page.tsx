"use client";

import { useState, useEffect } from "react";
import { Plus, Search, Filter, Download } from "lucide-react";
import { useAppStore } from "@/lib/store";
import { motion } from "framer-motion";
import { formatDateReadable, formatDateDDMMYYYY, getIcon } from "@/lib/utils";
import { type Transaction } from "@/lib/store";

export default function TransactionsPage() {
  const { transactions, isLoading, fetchData, setAddModalOpen, userProfile } = useAppStore();
  const [searchTerm, setSearchTerm] = useState("");
  const [categoryFilter, setCategoryFilter] = useState("All categories");
  const [isExporting, setIsExporting] = useState(false);
  
  const [isExportModalOpen, setIsExportModalOpen] = useState(false);
  const [exportStartDate, setExportStartDate] = useState("");
  const [exportEndDate, setExportEndDate] = useState("");

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const filteredTxns = transactions.filter(t => {
    const matchesSearch = t.title.toLowerCase().includes(searchTerm.toLowerCase()) || t.category.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesCat = categoryFilter === "All categories" || t.category === categoryFilter;
    return matchesSearch && matchesCat;
  });

  const totalSpent = filteredTxns.filter(t => t.type === 'EXPENSE').reduce((acc, curr) => acc + Math.abs(curr.amount), 0);

  const pdfFilteredTxns = filteredTxns.filter(t => {
    if (!exportStartDate && !exportEndDate) return true;
    const tDate = new Date(t.date).getTime();
    const start = exportStartDate ? new Date(exportStartDate).getTime() : 0;
    const end = exportEndDate ? new Date(exportEndDate).setHours(23, 59, 59, 999) : Infinity;
    return tDate >= start && tDate <= end;
  });

  const pdfTotalSpent = pdfFilteredTxns.filter(t => t.type === 'EXPENSE').reduce((acc, curr) => acc + Math.abs(curr.amount), 0);

  const handleExportClick = () => {
    setIsExportModalOpen(true);
  };

  const exportPDF = () => {
    setIsExportModalOpen(false);
    setIsExporting(true);
    // Allow state to update and render the hidden container
    setTimeout(() => {
      const element = document.getElementById('pdf-export-container');
      if (!element) {
        setIsExporting(false);
        return;
      }
      
      import('html-to-image').then((htmlToImage) => {
        htmlToImage.toPng(element, { backgroundColor: '#ffffff', pixelRatio: 2 })
          .then((dataUrl) => {
            import('jspdf').then(({ default: jsPDF }) => {
              const pdfWidth = 210; // A4 width in mm
              
              const img = new Image();
              img.src = dataUrl;
              img.onload = () => {
                const pdfHeight = (img.height * pdfWidth) / img.width;
                const pdf = new jsPDF({
                  orientation: 'p',
                  unit: 'mm',
                  format: [pdfWidth, pdfHeight]
                });
                pdf.addImage(dataUrl, 'PNG', 0, 0, pdfWidth, pdfHeight);
                pdf.save("SmartSpend_Transactions.pdf");
                setIsExporting(false);
              };
            });
          })
          .catch((err) => {
            console.error("Failed to generate PDF", err);
            setIsExporting(false);
          });
      });
    }, 150);
  };

  const containerVariants = {
    hidden: { opacity: 0 },
    show: { opacity: 1, transition: { staggerChildren: 0.05 } }
  };

  const uniqueCategories = Array.from(new Set(transactions.map(t => t.category))).sort();

  const itemVariants = {
    hidden: { opacity: 0, x: -10 },
    show: { opacity: 1, x: 0, transition: { type: "spring" as any, stiffness: 300, damping: 24 } }
  };

  return (
    <motion.div 
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      className="space-y-4"
    >
      <div className="flex flex-col sm:flex-row gap-2.5 mb-2 sm:items-center">
        <input 
          type="text" 
          placeholder="Search transactions..." 
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="flex-1 min-w-[180px] px-3.5 py-2.5 border border-[var(--color-border-subtle)] rounded-[10px] bg-[var(--color-surface)] text-[var(--color-text-main)] text-[13px] focus:outline-none focus:border-[var(--color-primary-main)] transition-colors placeholder:text-[var(--color-text-muted)]"
        />
        <div className="flex gap-2.5 w-full sm:w-auto">
          <select 
            value={categoryFilter}
            onChange={(e) => setCategoryFilter(e.target.value)}
            className="flex-1 sm:flex-none px-3.5 py-2.5 border border-[var(--color-border-subtle)] rounded-[10px] bg-[var(--color-surface)] text-[var(--color-text-main)] text-[13px] focus:outline-none focus:border-[var(--color-primary-main)] transition-colors appearance-none cursor-pointer"
          >
            <option>All categories</option>
            {uniqueCategories.map(cat => (
              <option key={cat} value={cat}>{cat}</option>
            ))}
          </select>
          <motion.button 
            whileHover={{ scale: 1.03 }}
            whileTap={{ scale: 0.97 }}
            onClick={handleExportClick}
            disabled={isExporting}
            className={`flex-1 sm:flex-none flex justify-center items-center gap-1.5 px-4 py-2.5 bg-[var(--color-surface-2)] text-[var(--color-text-main)] border border-[var(--color-border-subtle)] rounded-[10px] text-[13px] font-medium transition-colors shadow-sm ${isExporting ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer'}`}
          >
            {isExporting ? <div className="w-4 h-4 border-2 border-[var(--color-primary-main)] border-t-transparent rounded-full animate-spin" /> : <Download className="w-4 h-4" />} 
            {isExporting ? 'Exporting to PDF...' : 'Export to PDF'}
          </motion.button>
          <motion.button 
            whileHover={{ scale: 1.03 }}
            whileTap={{ scale: 0.97 }}
            onClick={() => setAddModalOpen(true)}
            className="flex-1 sm:flex-none flex justify-center items-center gap-1.5 px-4 py-2.5 bg-[var(--color-primary-main)] text-white border-none rounded-[10px] text-[13px] font-medium cursor-pointer transition-colors shadow-sm"
          >
            <Plus className="w-4 h-4" /> Add
          </motion.button>
        </div>
      </div>

      <div className="flex flex-wrap gap-1.5">
        <AiChip text="🤖 Spending this week" onClick={() => useAppStore.getState().setAIOpen(true, "How much did I spend this week?")} />
        <AiChip text="🤖 Find subscriptions" onClick={() => useAppStore.getState().setAIOpen(true, "Can you find all my recurring subscriptions?")} />
        <AiChip text="🤖 Unusual expenses" onClick={() => useAppStore.getState().setAIOpen(true, "Do I have any unusually large or weird expenses recently?")} />
      </div>

      <div className="bg-[var(--color-surface)] border border-[var(--color-border-subtle)] rounded-[14px] p-4.5 mt-2">
        <div className="flex justify-between items-center mb-3.5 border-b border-[var(--color-border-subtle)] pb-3">
          <span className="text-[14px] font-semibold text-[var(--color-text-main)]">
            {filteredTxns.length} transactions
          </span>
          <span className="text-[11px] text-[var(--color-text-muted)]">
            Total: ₹{totalSpent.toLocaleString('en-IN')} spent
          </span>
        </div>

        <div className="flex flex-col min-h-[400px]">
          {isLoading ? (
            <div className="flex flex-col items-center justify-center h-[300px]">
              <div className="w-6 h-6 border-2 border-[var(--color-primary-main)] border-t-transparent rounded-full animate-spin" />
              <p className="text-[var(--color-text-muted)] mt-4 text-[12px]">Loading transactions...</p>
            </div>
          ) : (
            <motion.div 
              variants={containerVariants}
              initial="hidden"
              animate="show"
            >
              {filteredTxns.map((txn) => (
                <motion.div variants={itemVariants} key={txn.id}>
                  <TransactionItem txn={txn} />
                </motion.div>
              ))}
              
              {!isLoading && filteredTxns.length === 0 && (
                <motion.div 
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  className="flex flex-col items-center justify-center h-[300px] text-center"
                >
                  <div className="w-16 h-16 mb-4 bg-[var(--color-surface-2)] rounded-full flex items-center justify-center border border-[var(--color-border-subtle)]">
                    <Search className="w-6 h-6 text-[var(--color-text-muted)]" />
                  </div>
                  <h3 className="text-[15px] font-semibold text-[var(--color-text-main)] mb-1">No transactions found</h3>
                  <p className="text-[13px] text-[var(--color-text-muted)] max-w-xs">
                    {searchTerm || categoryFilter !== "All categories" ? "Try adjusting your search or filters." : "You haven't recorded any transactions yet."}
                  </p>
                </motion.div>
              )}
            </motion.div>
          )}
        </div>
      </div>
      <PDFExportView transactions={pdfFilteredTxns} totalSpent={pdfTotalSpent} userName={userProfile?.full_name || ''} isExporting={isExporting} startDate={exportStartDate} endDate={exportEndDate} />

      {/* Export Modal */}
      {isExportModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
          <motion.div 
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            className="w-full max-w-md bg-[var(--color-surface)] border border-[var(--color-border-subtle)] rounded-[20px] shadow-2xl overflow-hidden"
          >
            <div className="p-6">
              <h2 className="text-lg font-bold text-[var(--color-text-main)] mb-4">Export to PDF</h2>
              <p className="text-sm text-[var(--color-text-muted)] mb-6">Select a date range to filter the transactions in your PDF report. Leave blank to include all.</p>
              
              <div className="space-y-4">
                <div>
                  <label className="block text-[13px] font-medium text-[var(--color-text-muted)] mb-1">From Date</label>
                  <input 
                    type="date" 
                    value={exportStartDate}
                    onChange={(e) => setExportStartDate(e.target.value)}
                    className="w-full px-3 py-2 border border-[var(--color-border-subtle)] rounded-lg bg-[var(--color-surface-2)] text-[var(--color-text-main)] text-sm focus:outline-none focus:border-[var(--color-primary-main)]"
                  />
                </div>
                <div>
                  <label className="block text-[13px] font-medium text-[var(--color-text-muted)] mb-1">To Date</label>
                  <input 
                    type="date" 
                    value={exportEndDate}
                    onChange={(e) => setExportEndDate(e.target.value)}
                    className="w-full px-3 py-2 border border-[var(--color-border-subtle)] rounded-lg bg-[var(--color-surface-2)] text-[var(--color-text-main)] text-sm focus:outline-none focus:border-[var(--color-primary-main)]"
                  />
                </div>
              </div>

              <div className="mt-8 flex gap-3">
                <button 
                  onClick={() => setIsExportModalOpen(false)}
                  className="flex-1 py-2.5 px-4 rounded-xl text-[14px] font-medium text-[var(--color-text-main)] bg-[var(--color-surface-2)] hover:bg-[var(--color-border-subtle)] transition-colors"
                >
                  Cancel
                </button>
                <button 
                  onClick={exportPDF}
                  className="flex-1 py-2.5 px-4 rounded-xl text-[14px] font-medium text-white bg-[var(--color-primary-main)] hover:bg-blue-600 shadow-lg shadow-blue-500/20 transition-all"
                >
                  Generate PDF
                </button>
              </div>
            </div>
          </motion.div>
        </div>
      )}
    </motion.div>
  );
}

// Hidden PDF Container Component (Rendered only during export)
function PDFExportView({ transactions, totalSpent, userName, isExporting, startDate, endDate }: { transactions: Transaction[], totalSpent: number, userName: string, isExporting: boolean, startDate: string, endDate: string }) {
  if (!isExporting) return null;

  return (
    <div className="absolute top-0 left-0 w-full z-[9999] flex justify-center bg-white pointer-events-none" style={{ minHeight: '100vh' }}>
      <div id="pdf-export-container" className="w-[800px] bg-white p-10 font-sans text-[#1a202c]">
      <div className="flex items-center justify-between border-b-2 border-[#e2e8f0] pb-6 mb-6">
        <div>
          <h1 className="text-3xl font-extrabold text-[#2d3748] tracking-tight flex items-center gap-2">
            <span className="w-10 h-10 rounded-[12px] bg-gradient-to-br from-[#447A9C] to-[#7DA2C8] flex items-center justify-center text-white text-xl shadow-md">
              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M21 12V7H5a2 2 0 0 1 0-4h14v4"/><path d="M3 5v14a2 2 0 0 0 2 2h16v-5"/><path d="M18 12a2 2 0 0 0 0 4h4v-4Z"/></svg>
            </span>
            SmartSpend
          </h1>
          <p className="text-[#718096] mt-2 text-sm font-medium">Financial Transactions Report</p>
        </div>
        <div className="text-right">
          <p className="text-sm text-[#718096]">Generated on</p>
          <p className="text-md font-bold text-[#2d3748]">{formatDateDDMMYYYY(new Date())}</p>
          {userName && <p className="text-sm text-[#718096] mt-1">For: <span className="font-semibold text-[#4a5568]">{userName}</span></p>}
          {(startDate || endDate) && (
            <p className="text-sm text-[#718096] mt-1 bg-[#edf2f7] px-2 py-1 rounded-md inline-block">
              Period: <span className="font-semibold text-[#4a5568]">{startDate ? formatDateDDMMYYYY(startDate) : 'Start'} to {endDate ? formatDateDDMMYYYY(endDate) : 'End'}</span>
            </p>
          )}
        </div>
      </div>

      <div className="flex gap-4 mb-8">
        <div className="flex-1 bg-[#f7fafc] rounded-[16px] p-5 border border-[#e2e8f0]">
          <p className="text-sm text-[#718096] font-medium mb-1">Total Records</p>
          <p className="text-2xl font-bold text-[#2d3748]">{transactions.length}</p>
        </div>
        <div className="flex-1 bg-[#fff5f5] rounded-[16px] p-5 border border-[#fed7d7]">
          <p className="text-sm text-[#e53e3e] font-medium mb-1">Total Filtered Spent</p>
          <p className="text-2xl font-bold text-[#c53030]">₹{totalSpent.toLocaleString('en-IN')}</p>
        </div>
      </div>

      <div className="space-y-3">
        {transactions.map((txn, idx) => (
          <div key={txn.id} className="flex items-center justify-between p-4 bg-white border border-[#e2e8f0] rounded-[12px] shadow-sm">
            <div className="flex items-center gap-4">
              <div className="w-10 h-10 rounded-[10px] bg-[#edf2f7] flex items-center justify-center text-[20px]">
                {getIcon(txn.icon === 'receipt' ? txn.category : (txn.icon || txn.category), txn.type)}
              </div>
              <div>
                <p className="text-[15px] font-bold text-[#2d3748]">{txn.title}</p>
                <div className="flex items-center gap-2 mt-0.5">
                  <span className="text-[12px] font-medium text-[#447A9C] bg-[#ebf8ff] px-2 py-0.5 rounded-full">{txn.category}</span>
                  <span className="text-[12px] text-[#a0aec0]">• {formatDateReadable(txn.date)}</span>
                </div>
              </div>
            </div>
            <div className={`text-[16px] font-bold ${txn.type === 'INCOME' ? 'text-[#38a169]' : 'text-[#e53e3e]'}`}>
              {txn.type === 'INCOME' ? '+' : '-'}₹{Math.abs(txn.amount).toLocaleString('en-IN')}
            </div>
          </div>
        ))}
      </div>
      
      <div className="mt-10 text-center text-[#a0aec0] text-xs font-medium">
        Generated securely by SmartSpend AI • {transactions.length} records processed
      </div>
    </div>
    </div>
  );
}

function AiChip({ text, onClick }: { text: string; onClick?: () => void }) {
  return (
    <motion.button 
      onClick={onClick}
      whileHover={{ scale: 1.05 }}
      whileTap={{ scale: 0.95 }}
      className="px-3 py-1.5 bg-[var(--color-primary-soft)] text-[var(--color-primary-main)] border border-[rgba(79,70,229,0.25)] rounded-[20px] text-[12px] cursor-pointer"
    >
      {text}
    </motion.button>
  );
}

function TransactionItem({ txn }: { txn: Transaction }) {
  const { setAddModalOpen } = useAppStore();
  const positive = txn.type === 'INCOME';
  const amount = `${positive ? '+' : '−'}₹${Math.abs(txn.amount).toLocaleString('en-IN')}`;

  return (
    <div 
      onClick={() => setAddModalOpen(true, txn)}
      className="flex items-center gap-3 py-2.5 border-b border-[var(--color-border-subtle)] last:border-b-0 hover:bg-[var(--color-surface-2)] -mx-2 px-2 rounded-lg transition-colors cursor-pointer"
    >
      <div className="w-9 h-9 rounded-[10px] flex items-center justify-center text-[18px] shrink-0 bg-[var(--color-primary-soft)] text-[var(--color-primary-main)] shadow-sm">
        {getIcon(txn.icon === 'receipt' ? txn.category : (txn.icon || txn.category), txn.type)}
      </div>
      <div className="flex-1">
        <div className="text-[13px] font-medium text-[var(--color-text-main)]">{txn.title}</div>
        <div className="text-[11px] text-[var(--color-text-muted)] mt-0.5">{txn.category} · {formatDateReadable(txn.date)}</div>
      </div>
      <div className={`font-mono text-[13px] font-bold ${positive ? 'text-emerald-500' : 'text-[var(--color-danger-main)]'}`}>
        {amount}
      </div>
    </div>
  );
}
