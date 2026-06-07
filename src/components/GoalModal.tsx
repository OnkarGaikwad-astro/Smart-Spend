import React, { useState, useEffect } from "react";
import { X, Plus, Trash2 } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import { useAppStore } from "@/lib/store";

export function GoalModal({ isOpen, onClose }: { isOpen: boolean; onClose: () => void }) {
  const { addGoal, updateGoal, deleteGoal, editingGoal } = useAppStore();
  
  const [name, setName] = useState("");
  const [target, setTarget] = useState("");
  const [targetDate, setTargetDate] = useState("");
  const [color, setColor] = useState("primary");
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    if (isOpen) {
      if (editingGoal) {
        setName(editingGoal.name);
        setTarget(editingGoal.target.toString());
        setTargetDate(editingGoal.target_date);
        setColor(editingGoal.color);
      } else {
        setName("");
        setTarget("");
        setTargetDate(new Date(new Date().setFullYear(new Date().getFullYear() + 1)).toISOString().split('T')[0]);
        setColor("primary");
      }
    }
  }, [isOpen, editingGoal]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name || !target) return;

    setIsSubmitting(true);
    const parsedTarget = Math.abs(parseFloat(target));

    try {
      if (editingGoal) {
        await updateGoal(editingGoal.id, {
          name,
          target: parsedTarget,
          target_date: targetDate,
          color,
        });
      } else {
        await addGoal({
          name,
          target: parsedTarget,
          target_date: targetDate,
          color,
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
    if (!editingGoal) return;
    if (confirm("Are you sure you want to delete this goal?")) {
      setIsSubmitting(true);
      await deleteGoal(editingGoal.id);
      setIsSubmitting(false);
      onClose();
    }
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
            className="relative w-full max-w-sm bg-[var(--color-surface)] border border-[var(--color-border-subtle)] rounded-[20px] shadow-2xl overflow-hidden backdrop-blur-xl"
            onClick={e => e.stopPropagation()}
          >
            <div className="p-5 border-b border-[var(--color-border-subtle)] flex items-center justify-between bg-black/[0.02]">
              <h2 className="text-[16px] font-semibold text-[var(--color-text-main)] flex items-center gap-2">
                <div className="w-6 h-6 rounded-md bg-[var(--color-primary-soft)] text-[var(--color-primary-main)] flex items-center justify-center">
                  <Plus className="w-4 h-4" />
                </div>
                {editingGoal ? "Edit Goal" : "New Savings Goal"}
              </h2>
              <div className="flex items-center gap-2">
                {editingGoal && (
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
              <div>
                <label className="block text-[12px] font-medium text-[var(--color-text-muted)] mb-1.5">Goal Name</label>
                <input 
                  type="text" 
                  required
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="e.g. 💻 New Laptop"
                  className="w-full px-3.5 py-2.5 bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] rounded-[10px] text-[var(--color-text-main)] text-[14px] focus:outline-none focus:border-[var(--color-primary-main)] transition-colors"
                />
              </div>

              <div>
                <label className="block text-[12px] font-medium text-[var(--color-text-muted)] mb-1.5">Target Amount (₹)</label>
                <input 
                  type="number" 
                  required
                  value={target}
                  onChange={(e) => setTarget(e.target.value)}
                  placeholder="40000"
                  className="w-full px-3.5 py-2.5 bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] rounded-[10px] text-[var(--color-text-main)] text-[16px] font-mono focus:outline-none focus:border-[var(--color-primary-main)] transition-colors"
                />
              </div>

              <div>
                <label className="block text-[12px] font-medium text-[var(--color-text-muted)] mb-1.5">Target Date</label>
                <input 
                  type="date" 
                  required
                  value={targetDate}
                  onChange={(e) => setTargetDate(e.target.value)}
                  className="w-full px-3.5 py-2.5 bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] rounded-[10px] text-[var(--color-text-main)] text-[13px] focus:outline-none focus:border-[var(--color-primary-main)] transition-colors [color-scheme:dark]"
                />
              </div>

              <div>
                <label className="block text-[12px] font-medium text-[var(--color-text-muted)] mb-1.5">Color</label>
                <select 
                  value={color}
                  onChange={(e) => setColor(e.target.value)}
                  className="w-full px-3.5 py-2.5 bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] rounded-[10px] text-[var(--color-text-main)] text-[13px] focus:outline-none focus:border-[var(--color-primary-main)] transition-colors appearance-none cursor-pointer"
                >
                  <option value="primary">Ocean Blue</option>
                  <option value="secondary">Teal</option>
                  <option value="accent">Gold</option>
                </select>
              </div>

              <button 
                type="submit" 
                disabled={isSubmitting}
                className="w-full py-2.5 mt-2 bg-gradient-to-r from-[var(--color-primary-main)] to-[var(--color-purple-main)] text-white font-medium rounded-[10px] text-[14px] hover:opacity-90 transition-opacity disabled:opacity-50"
              >
                {isSubmitting ? "Saving..." : (editingGoal ? "Save Changes" : "Create Goal")}
              </button>
            </form>
          </motion.div>
        </div>
      )}
    </AnimatePresence>
  );
}
