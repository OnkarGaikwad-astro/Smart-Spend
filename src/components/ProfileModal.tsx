"use client";

import { useState, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { X, User, Mail, Save, ShieldCheck, Camera } from "lucide-react";
import { useAppStore } from "@/lib/store";

export function ProfileModal() {
  const { isProfileModalOpen, setProfileModalOpen, userProfile, updateProfile } = useAppStore();
  const [fullName, setFullName] = useState("");
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    if (userProfile?.full_name) {
      setFullName(userProfile.full_name);
    }
  }, [userProfile, isProfileModalOpen]);

  if (!isProfileModalOpen) return null;

  const handleSave = async () => {
    setIsSaving(true);
    await updateProfile({ full_name: fullName });
    setIsSaving(false);
    setProfileModalOpen(false);
  };

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/60 backdrop-blur-md">
        <motion.div 
          initial={{ opacity: 0, scale: 0.95, y: 30 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.95, y: 30 }}
          transition={{ type: "spring", bounce: 0.3, duration: 0.4 }}
          className="bg-[var(--color-surface)] w-full max-w-md rounded-[28px] shadow-2xl overflow-hidden relative border border-[var(--color-border-subtle)]"
        >
          {/* Header Graphic Background */}
          <div className="h-32 bg-gradient-to-br from-[var(--color-primary-main)] via-[var(--color-purple-main)] to-indigo-600 relative overflow-hidden">
            <div className="absolute inset-0 bg-white/10" style={{ backgroundImage: 'radial-gradient(circle at 2px 2px, rgba(255,255,255,0.15) 1px, transparent 0)', backgroundSize: '24px 24px' }}></div>
            <button 
              onClick={() => setProfileModalOpen(false)}
              className="absolute top-4 right-4 w-8 h-8 bg-black/20 hover:bg-black/40 backdrop-blur-md rounded-full flex items-center justify-center text-white transition-colors"
            >
              <X className="w-4 h-4" />
            </button>
          </div>

          {/* Body */}
          <div className="px-8 pb-8">
            {/* Floating Avatar */}
            <div className="relative -mt-14 mb-6 flex justify-center">
              <div className="relative">
                <div className="w-28 h-28 rounded-full bg-[var(--color-surface)] p-1.5 shadow-xl">
                  <div className="w-full h-full rounded-full bg-gradient-to-br from-[var(--color-surface-2)] to-[var(--color-surface)] border border-[var(--color-border-subtle)] overflow-hidden flex items-center justify-center text-4xl font-bold text-[var(--color-primary-main)]">
                    {userProfile?.avatar_url ? (
                      <img src={userProfile.avatar_url} alt="Profile" className="w-full h-full object-cover" />
                    ) : (
                      fullName ? fullName.charAt(0).toUpperCase() : userProfile?.email?.charAt(0).toUpperCase() || 'U'
                    )}
                  </div>
                </div>
                <div className="absolute bottom-1 right-1 w-8 h-8 bg-white border border-[var(--color-border-subtle)] rounded-full shadow-md flex items-center justify-center text-[var(--color-text-muted)] hover:text-[var(--color-primary-main)] cursor-pointer transition-colors">
                  <Camera className="w-4 h-4" />
                </div>
              </div>
            </div>

            <div className="text-center mb-8">
              <h2 className="text-[22px] font-extrabold text-[var(--color-text-main)] mb-1">
                {fullName || "User Profile"}
              </h2>
              <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-500/10 text-emerald-600 text-[12px] font-medium">
                <ShieldCheck className="w-3.5 h-3.5" /> Verified Account
              </div>
            </div>

            <div className="space-y-5">
              <div>
                <label className="block text-[13px] font-semibold text-[var(--color-text-muted)] uppercase tracking-wider mb-2 flex items-center gap-2">
                  <User className="w-4 h-4" /> Full Name
                </label>
                <input 
                  type="text" 
                  value={fullName}
                  onChange={(e) => setFullName(e.target.value)}
                  className="w-full px-4 py-3.5 bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] rounded-[14px] text-[15px] font-medium text-[var(--color-text-main)] focus:outline-none focus:border-[var(--color-primary-main)] focus:ring-4 focus:ring-[var(--color-primary-soft)] transition-all"
                  placeholder="John Doe"
                />
              </div>
              
              <div>
                <label className="block text-[13px] font-semibold text-[var(--color-text-muted)] uppercase tracking-wider mb-2 flex items-center gap-2">
                  <Mail className="w-4 h-4" /> Email Address
                </label>
                <input 
                  type="email" 
                  value={userProfile?.email || ""}
                  disabled
                  className="w-full px-4 py-3.5 bg-[var(--color-surface-2)]/50 border border-[var(--color-border-subtle)] rounded-[14px] text-[15px] text-[var(--color-text-muted)] cursor-not-allowed"
                />
              </div>
            </div>

            {/* Actions */}
            <div className="mt-8 pt-6 border-t border-[var(--color-border-subtle)] flex gap-3">
              <button 
                onClick={() => setProfileModalOpen(false)}
                className="flex-1 py-3.5 text-[14px] font-bold text-[var(--color-text-muted)] hover:text-[var(--color-text-main)] bg-[var(--color-surface)] border border-[var(--color-border-subtle)] rounded-[14px] hover:bg-[var(--color-surface-2)] transition-colors"
              >
                Cancel
              </button>
              <button 
                onClick={handleSave}
                disabled={isSaving}
                className="flex-[2] py-3.5 text-[14px] font-bold text-white bg-[var(--color-primary-main)] rounded-[14px] hover:bg-blue-600 transition-colors shadow-lg shadow-[var(--color-primary-soft)] flex items-center justify-center gap-2 disabled:opacity-70"
              >
                {isSaving ? (
                  <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                ) : (
                  <><Save className="w-4 h-4" /> Save Changes</>
                )}
              </button>
            </div>
          </div>
        </motion.div>
      </div>
    </AnimatePresence>
  );
}
