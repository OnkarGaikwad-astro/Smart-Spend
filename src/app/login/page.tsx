"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { motion } from "framer-motion";
import { Wallet, LogIn, UserPlus, AlertCircle, Sparkles } from "lucide-react";

export default function LoginPage() {
  const router = useRouter();
  const supabase = createClient();
  const [isLogin, setIsLogin] = useState(true);
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError(null);
    setSuccessMsg(null);

    try {
      if (isLogin) {
        const { error } = await supabase.auth.signInWithPassword({
          email,
          password,
        });
        if (error) throw error;
        router.push("/dashboard");
      } else {
        const { data, error } = await supabase.auth.signUp({
          email,
          password,
          options: {
            data: {
              full_name: name,
            }
          }
        });
        if (error) throw error;
        
        if (data?.session) {
          router.push("/dashboard");
        } else {
          setSuccessMsg("Account created! Please check your email for a confirmation link to log in.");
        }
      }
    } catch (err: any) {
      setError(err.message);
    } finally {
      setIsLoading(false);
    }
  };

  const handleGoogleSignIn = async () => {
    try {
      const { error } = await supabase.auth.signInWithOAuth({
        provider: 'google',
        options: {
          redirectTo: `${window.location.origin}/auth/callback`
        }
      });
      if (error) throw error;
    } catch (err: any) {
      setError(err.message);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-[var(--color-bg-body)] p-4 relative overflow-hidden">
      {/* Decorative background blur */}
      <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-[var(--color-primary-soft)] rounded-full mix-blend-multiply filter blur-3xl opacity-50 animate-blob"></div>
      <div className="absolute top-1/3 right-1/4 w-96 h-96 bg-[var(--color-purple-soft)] rounded-full mix-blend-multiply filter blur-3xl opacity-50 animate-blob animation-delay-2000"></div>

      <motion.div 
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="w-full max-w-md bg-[var(--color-surface)] border border-[var(--color-border-subtle)] rounded-[24px] shadow-2xl p-8 relative z-10 backdrop-blur-xl"
      >
        <div className="flex flex-col items-center mb-8">
          <div className="w-14 h-14 rounded-[16px] bg-gradient-to-br from-[var(--color-primary-main)] to-[var(--color-purple-main)] flex items-center justify-center mb-4 shadow-lg shadow-[var(--color-primary-soft)]">
            <Wallet className="w-7 h-7 text-white" />
          </div>
          <h1 className="text-[24px] font-bold text-[var(--color-text-main)] mb-1">SmartSpend</h1>
          <p className="text-[14px] text-[var(--color-text-muted)] flex items-center gap-1.5">
            <Sparkles className="w-3.5 h-3.5" /> 
            AI-Powered Financial Assistant
          </p>
        </div>

        {error && (
          <motion.div 
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            className="mb-6 p-3.5 bg-[var(--color-danger-soft)] border border-[var(--color-danger-main)] rounded-[12px] flex items-start gap-2.5"
          >
            <AlertCircle className="w-5 h-5 text-[var(--color-danger-main)] shrink-0 mt-0.5" />
            <p className="text-[13px] text-[var(--color-danger-main)] leading-relaxed">{error}</p>
          </motion.div>
        )}

        {successMsg && (
          <motion.div 
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            className="mb-6 p-3.5 bg-emerald-500/10 border border-emerald-500/50 rounded-[12px] flex items-start gap-2.5"
          >
            <Sparkles className="w-5 h-5 text-emerald-500 shrink-0 mt-0.5" />
            <p className="text-[13px] text-emerald-500 leading-relaxed font-medium">{successMsg}</p>
          </motion.div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          {!isLogin && (
            <motion.div 
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              className="overflow-hidden"
            >
              <label className="block text-[13px] font-medium text-[var(--color-text-main)] mb-1.5 mt-1">Full Name</label>
              <input 
                type="text" 
                required={!isLogin}
                value={name}
                onChange={(e) => setName(e.target.value)}
                className="w-full px-4 py-3 bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] rounded-[12px] text-[14px] text-[var(--color-text-main)] focus:outline-none focus:border-[var(--color-primary-main)] transition-colors mb-4"
                placeholder="John Doe"
              />
            </motion.div>
          )}

          <div>
            <label className="block text-[13px] font-medium text-[var(--color-text-main)] mb-1.5">Email Address</label>
            <input 
              type="email" 
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full px-4 py-3 bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] rounded-[12px] text-[14px] text-[var(--color-text-main)] focus:outline-none focus:border-[var(--color-primary-main)] transition-colors"
              placeholder="you@example.com"
            />
          </div>
          
          <div>
            <label className="block text-[13px] font-medium text-[var(--color-text-main)] mb-1.5">Password</label>
            <input 
              type="password" 
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full px-4 py-3 bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] rounded-[12px] text-[14px] text-[var(--color-text-main)] focus:outline-none focus:border-[var(--color-primary-main)] transition-colors"
              placeholder="••••••••"
            />
          </div>

          <button 
            type="submit"
            disabled={isLoading}
            className="w-full py-3.5 mt-2 bg-[var(--color-primary-main)] text-white font-medium rounded-[12px] text-[15px] hover:bg-blue-600 transition-colors shadow-lg shadow-[var(--color-primary-soft)] flex items-center justify-center gap-2 disabled:opacity-50"
          >
            {isLoading ? (
              <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
            ) : isLogin ? (
              <><LogIn className="w-4 h-4" /> Sign In</>
            ) : (
              <><UserPlus className="w-4 h-4" /> Create Account</>
            )}
          </button>
        </form>

        <div className="mt-6">
          <div className="relative">
            <div className="absolute inset-0 flex items-center">
              <div className="w-full border-t border-[var(--color-border-subtle)]"></div>
            </div>
            <div className="relative flex justify-center text-[12px]">
              <span className="bg-[var(--color-surface)] px-2 text-[var(--color-text-muted)]">Or continue with</span>
            </div>
          </div>

          <button 
            type="button"
            onClick={handleGoogleSignIn}
            className="w-full mt-4 py-3 bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] text-[var(--color-text-main)] font-medium rounded-[12px] text-[14px] hover:bg-[var(--color-surface-3)] transition-colors flex items-center justify-center gap-2"
          >
            <svg viewBox="0 0 24 24" className="w-5 h-5">
              <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
              <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
              <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/>
              <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
            </svg>
            Google
          </button>
        </div>

        <div className="mt-6 text-center">
          <button 
            type="button"
            onClick={() => {
              setIsLogin(!isLogin);
              setError(null);
              setSuccessMsg(null);
              setName("");
            }}
            className="text-[13px] text-[var(--color-text-muted)] hover:text-[var(--color-primary-main)] transition-colors font-medium"
          >
            {isLogin ? "Don't have an account? Sign up" : "Already have an account? Sign in"}
          </button>
        </div>
      </motion.div>
    </div>
  );
}
