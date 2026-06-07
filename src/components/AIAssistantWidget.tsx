"use client";

import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Bot, X, Send, Sparkles } from 'lucide-react';

export default function AIAssistantWidget() {
  const [isOpen, setIsOpen] = useState(false);
  const [messages, setMessages] = useState<{role: 'user' | 'ai', content: string}[]>([
    { role: 'ai', content: 'Hi there! I am your AI financial assistant. How can I help you today?' }
  ]);
  const [input, setInput] = useState('');

  const toggleOpen = () => setIsOpen(!isOpen);

  const handleSend = (e?: React.FormEvent) => {
    e?.preventDefault();
    if (!input.trim()) return;

    // Add user message
    const newMessages = [...messages, { role: 'user' as const, content: input }];
    setMessages(newMessages);
    setInput('');

    // Mock AI Response (for now)
    setTimeout(() => {
      setMessages(prev => [...prev, { 
        role: 'ai', 
        content: "I'm still learning! Soon I'll be able to analyze your spending and answer financial questions using Gemini AI." 
      }]);
    }, 1000);
  };

  return (
    <>
      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ opacity: 0, scale: 0.9, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.9, y: 20 }}
            transition={{ duration: 0.2, type: 'spring', bounce: 0.25 }}
            className="fixed bottom-24 right-6 w-[350px] h-[500px] z-50 flex flex-col overflow-hidden shadow-2xl rounded-[24px] border border-[var(--color-border-subtle)] bg-[var(--color-surface)] backdrop-blur-2xl"
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
                  disabled={!input.trim()}
                  className="w-8 h-8 flex items-center justify-center rounded-full bg-[var(--color-primary-main)] text-white disabled:opacity-50 transition-opacity"
                >
                  <Send className="w-4 h-4 ml-0.5" />
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
        className="fixed bottom-6 right-6 w-14 h-14 z-50 flex items-center justify-center rounded-full shadow-lg border border-[var(--color-border-subtle)] bg-[var(--color-surface)] backdrop-blur-xl text-[var(--color-primary-main)] hover:bg-[var(--color-surface-2)] transition-colors"
      >
        <Bot className="w-6 h-6" />
      </motion.button>
    </>
  );
}
