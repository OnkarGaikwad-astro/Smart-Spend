"use client";

import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Bot, X, Send, Sparkles } from 'lucide-react';

import { useAppStore } from '@/lib/store';

export default function AIAssistantWidget() {
  const { transactions, goals, isAIOpen, setAIOpen, aiInitialMsg } = useAppStore();
  const [messages, setMessages] = useState<{role: 'user' | 'ai', content: string}[]>([
    { role: 'ai', content: 'Hi there! I am Aurex, your AI financial assistant. How can I help you today?' }
  ]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const toggleOpen = () => setAIOpen(!isAIOpen);

  useEffect(() => {
    if (isAIOpen && aiInitialMsg) {
      handleSend(undefined, aiInitialMsg);
      setAIOpen(true, ''); // Clear initial message so it doesn't resend
    }
  }, [isAIOpen, aiInitialMsg]);

  const handleSend = async (e?: React.FormEvent, customMsg?: string) => {
    e?.preventDefault();
    const userText = customMsg || input;
    if (!userText.trim() || isLoading) return;

    const newMessages = [...messages, { role: 'user' as const, content: userText }];
    setMessages(newMessages);
    setInput('');
    setIsLoading(true);

    try {
      const totalIncome = transactions.filter(t => t.type === 'INCOME').reduce((acc, curr) => acc + curr.amount, 0);
      const totalExpense = transactions.filter(t => t.type === 'EXPENSE').reduce((acc, curr) => acc + Math.abs(curr.amount), 0);
      
      const response = await fetch('/api/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          messages: newMessages,
          context: {
            totalBalance: totalIncome - totalExpense,
            totalIncome,
            totalExpense,
            transactions,
            goals
          }
        }),
      });

      const data = await response.json();
      
      if (response.ok) {
        setMessages(prev => [...prev, { role: 'ai', content: data.content }]);
      } else {
        setMessages(prev => [...prev, { role: 'ai', content: `Error: ${data.error}` }]);
      }
    } catch (error) {
      setMessages(prev => [...prev, { role: 'ai', content: 'Sorry, I encountered a network error connecting to the AI.' }]);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <>
      <AnimatePresence>
        {isAIOpen && (
          <motion.div
            initial={{ opacity: 0, scale: 0.9, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.9, y: 20 }}
            transition={{ duration: 0.2, type: 'spring', bounce: 0.25 }}
            className="fixed bottom-[80px] md:bottom-24 right-4 md:right-6 w-[calc(100vw-32px)] md:w-[350px] h-[500px] max-h-[70vh] z-50 flex flex-col overflow-hidden shadow-2xl rounded-[24px] border border-[var(--color-border-subtle)] bg-[var(--color-surface)] backdrop-blur-2xl"
          >
            {/* Header */}
            <div className="flex items-center justify-between p-4 border-b border-[var(--color-border-subtle)] bg-white/[0.02]">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-full bg-[var(--color-primary-soft)] flex items-center justify-center text-[var(--color-primary-main)]">
                  <Sparkles className="w-4 h-4" />
                </div>
                <div>
                  <h3 className="font-semibold text-[15px] text-[var(--color-text-main)]">Smart AI</h3>
                  <p className="text-[12px] text-[var(--color-text-muted)]">Always here to help</p>
                </div>
              </div>
              <button 
                onClick={toggleOpen}
                className="w-8 h-8 flex items-center justify-center rounded-full text-[var(--color-text-muted)] hover:text-[var(--color-text-main)] hover:bg-[var(--color-surface-2)] transition-colors"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            {/* Chat Area */}
            <div className="flex-1 overflow-y-auto p-4 space-y-4 scrollbar-thin">
              {messages.map((msg, idx) => (
                <div 
                  key={idx} 
                  className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}
                >
                  <div 
                    className={`max-w-[85%] p-3 text-[14px] leading-relaxed shadow-sm ${
                      msg.role === 'user' 
                        ? 'bg-[var(--color-primary-main)] text-white rounded-[20px] rounded-tr-[4px]' 
                        : 'bg-[var(--color-surface-2)] text-[var(--color-text-main)] rounded-[20px] rounded-tl-[4px] border border-[var(--color-border-subtle)]'
                    }`}
                  >
                    {msg.content}
                  </div>
                </div>
              ))}
            </div>

            {/* Input Area */}
            <div className="p-3 border-t border-[var(--color-border-subtle)] bg-white/[0.02]">
              <form 
                onSubmit={handleSend}
                className="flex items-center gap-2 p-1 pl-4 rounded-full bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)]"
              >
                <input 
                  type="text" 
                  value={input}
                  onChange={(e) => setInput(e.target.value)}
                  placeholder="Ask anything..."
                  className="flex-1 bg-transparent border-none outline-none text-[14px] text-[var(--color-text-main)] placeholder-[var(--color-text-muted)]"
                />
                <button 
                  type="submit"
                  disabled={!input.trim() || isLoading}
                  className="w-8 h-8 flex items-center justify-center rounded-full bg-[var(--color-primary-main)] text-white disabled:opacity-50 transition-opacity"
                >
                  {isLoading ? (
                    <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                  ) : (
                    <Send className="w-4 h-4 ml-0.5" />
                  )}
                </button>
              </form>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Floating Action Button */}
      <motion.button
        whileHover={{ scale: 1.05 }}
        whileTap={{ scale: 0.95 }}
        onClick={toggleOpen}
        className="fixed bottom-[80px] md:bottom-6 right-4 md:right-6 w-14 h-14 z-50 flex items-center justify-center rounded-full shadow-lg border border-[var(--color-border-subtle)] bg-[var(--color-surface)] backdrop-blur-xl text-[var(--color-primary-main)] hover:bg-[var(--color-surface-2)] transition-colors"
      >
        <Bot className="w-6 h-6" />
      </motion.button>
    </>
  );
}
