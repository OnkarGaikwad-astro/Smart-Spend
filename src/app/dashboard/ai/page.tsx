"use client";

import { useState, useRef, useEffect } from "react";
import { motion } from "framer-motion";
import { Send, Bot, Sparkles, User, Loader2 } from "lucide-react";
import { useAppStore } from "@/lib/store";

interface Message {
  id: string | number;
  type: "system" | "user";
  text: string;
}

export default function AIPage() {
  const { transactions, goals } = useAppStore();
  const [messages, setMessages] = useState<Message[]>([
    {
      id: "welcome",
      type: "system",
      text: "Hello! I'm Aurex, your AI financial advisor. Ask me anything about your spending, budgets, savings goals, or financial tips!"
    }
  ]);
  const [input, setInput] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages, isLoading]);

  const handleSend = async () => {
    if (!input.trim() || isLoading) return;

    const userText = input.trim();
    const userMsg: Message = { id: Date.now(), type: "user", text: userText };
    const nextMessages = [...messages, userMsg];

    setMessages(nextMessages);
    setInput("");
    setIsLoading(true);

    try {
      const totalIncome = transactions
        .filter(t => t.type === 'INCOME')
        .reduce((acc, curr) => acc + curr.amount, 0);
      const totalExpense = transactions
        .filter(t => t.type === 'EXPENSE')
        .reduce((acc, curr) => acc + Math.abs(curr.amount), 0);

      const response = await fetch('/api/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          messages: nextMessages.map(m => ({
            role: m.type === 'user' ? 'user' : 'model',
            content: m.text,
          })),
          context: {
            totalBalance: totalIncome - totalExpense,
            totalIncome,
            totalExpense,
            transactions,
            goals,
          },
        }),
      });

      const data = await response.json();

      if (response.ok && data.content) {
        setMessages(prev => [
          ...prev,
          { id: Date.now() + 1, type: "system", text: data.content }
        ]);
      } else {
        setMessages(prev => [
          ...prev,
          {
            id: Date.now() + 1,
            type: "system",
            text: `Error: ${data.error || 'Failed to generate response.'}`
          }
        ]);
      }
    } catch {
      setMessages(prev => [
        ...prev,
        {
          id: Date.now() + 1,
          type: "system",
          text: "I encountered a network error connecting to Aurex AI. Please try again."
        }
      ]);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="flex flex-col h-[calc(100vh-140px)]">
      <div className="mb-4">
        <h1 className="text-[18px] font-bold text-[var(--color-text-main)] flex items-center gap-2">
          <Sparkles className="w-5 h-5 text-[var(--color-primary-main)]" />
          Aurex AI Assistant
        </h1>
        <p className="text-[13px] text-[var(--color-text-muted)]">
          Real-time financial intelligence powered by Gemini. Ask about your spending, trends, and budget health.
        </p>
      </div>

      <div className="flex-1 bg-[var(--color-surface)] border border-[var(--color-border-subtle)] rounded-[14px] flex flex-col overflow-hidden relative shadow-sm">

        {/* Messages Area */}
        <div className="flex-1 overflow-y-auto p-4 space-y-4">
          {messages.map(msg => (
            <motion.div
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              key={msg.id}
              className={`flex gap-3 max-w-[85%] ${msg.type === "user" ? "ml-auto flex-row-reverse" : ""}`}
            >
              <div className={`w-8 h-8 rounded-full flex items-center justify-center shrink-0 ${msg.type === "system"
                ? "bg-gradient-to-br from-[var(--color-primary-main)] to-[var(--color-purple-main)] text-white"
                : "bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] text-[var(--color-text-main)]"
                }`}>
                {msg.type === "system" ? <Bot className="w-4 h-4" /> : <User className="w-4 h-4" />}
              </div>
              <div className={`p-3 rounded-[12px] text-[13px] leading-relaxed whitespace-pre-wrap ${msg.type === "user"
                ? "bg-[var(--color-primary-main)] text-white rounded-tr-none"
                : "bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] text-[var(--color-text-main)] rounded-tl-none"
                }`}>
                {msg.text}
              </div>
            </motion.div>
          ))}
          {isLoading && (
            <motion.div
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              className="flex gap-3 max-w-[85%]"
            >
              <div className="w-8 h-8 rounded-full flex items-center justify-center shrink-0 bg-gradient-to-br from-[var(--color-primary-main)] to-[var(--color-purple-main)] text-white">
                <Bot className="w-4 h-4" />
              </div>
              <div className="p-3 rounded-[12px] text-[13px] bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] text-[var(--color-text-main)] rounded-tl-none flex items-center gap-2">
                <Loader2 className="w-4 h-4 animate-spin text-[var(--color-primary-main)]" />
                Thinking...
              </div>
            </motion.div>
          )}
          <div ref={messagesEndRef} />
        </div>

        {/* Input Area */}
        <div className="p-3 border-t border-[var(--color-border-subtle)] bg-[var(--color-surface)]">
          <div className="relative flex items-center">
            <input
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleSend()}
              placeholder="Ask about your budget, monthly expenses, or advice..."
              disabled={isLoading}
              className="w-full pl-4 pr-12 py-3 bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] rounded-full text-[var(--color-text-main)] text-[13px] focus:outline-none focus:border-[var(--color-primary-main)] transition-colors disabled:opacity-60"
            />
            <button
              onClick={handleSend}
              disabled={isLoading || !input.trim()}
              className="absolute right-2 w-8 h-8 flex items-center justify-center rounded-full bg-[var(--color-primary-main)] text-white hover:bg-[var(--color-purple-main)] transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
            >
              <Send className="w-4 h-4 ml-0.5" />
            </button>
          </div>
        </div>

      </div>
    </div>
  );
}
