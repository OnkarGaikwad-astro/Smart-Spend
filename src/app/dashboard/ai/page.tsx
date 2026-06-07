"use client";

import { useState } from "react";
import { motion } from "framer-motion";
import { Send, Bot, Sparkles, User } from "lucide-react";

export default function AIPage() {
  const [messages, setMessages] = useState([
    { id: 1, type: "system", text: "Hello! I'm your AI financial assistant. How can I help you today?" }
  ]);
  const [input, setInput] = useState("");

  const handleSend = () => {
    if (!input.trim()) return;
    
    // Add user message
    const newMsg = { id: Date.now(), type: "user", text: input };
    setMessages([...messages, newMsg]);
    setInput("");
    
    // Simulate AI response
    setTimeout(() => {
      setMessages(prev => [...prev, {
        id: Date.now() + 1,
        type: "system",
        text: "I'm a placeholder AI. In the future, I will connect to Gemini to analyze your spending!"
      }]);
    }, 1000);
  };

  return (
    <div className="flex flex-col h-[calc(100vh-140px)]">
      <div className="mb-4">
        <h1 className="text-[18px] font-bold text-[var(--color-text-main)] flex items-center gap-2">
          <Sparkles className="w-5 h-5 text-[var(--color-primary-main)]" />
          AI Assistant
        </h1>
        <p className="text-[13px] text-[var(--color-text-muted)]">Ask questions about your spending and get financial advice.</p>
      </div>

      <div className="flex-1 bg-[var(--color-surface)] border border-[var(--color-border-subtle)] rounded-[14px] flex flex-col overflow-hidden relative">
        
        {/* Messages Area */}
        <div className="flex-1 overflow-y-auto p-4 space-y-4">
          {messages.map(msg => (
            <motion.div 
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              key={msg.id} 
              className={`flex gap-3 max-w-[85%] ${msg.type === "user" ? "ml-auto flex-row-reverse" : ""}`}
            >
              <div className={`w-8 h-8 rounded-full flex items-center justify-center shrink-0 ${
                msg.type === "system" 
                  ? "bg-gradient-to-br from-[var(--color-primary-main)] to-[var(--color-purple-main)] text-white" 
                  : "bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] text-[var(--color-text-main)]"
              }`}>
                {msg.type === "system" ? <Bot className="w-4 h-4" /> : <User className="w-4 h-4" />}
              </div>
              <div className={`p-3 rounded-[12px] text-[13px] ${
                msg.type === "user"
                  ? "bg-[var(--color-primary-main)] text-white rounded-tr-none"
                  : "bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] text-[var(--color-text-main)] rounded-tl-none"
              }`}>
                {msg.text}
              </div>
            </motion.div>
          ))}
        </div>

        {/* Input Area */}
        <div className="p-3 border-t border-[var(--color-border-subtle)] bg-[var(--color-surface)]">
          <div className="relative flex items-center">
            <input 
              type="text" 
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleSend()}
              placeholder="Ask about your budget..."
              className="w-full pl-4 pr-12 py-3 bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] rounded-full text-[var(--color-text-main)] text-[13px] focus:outline-none focus:border-[var(--color-primary-main)] transition-colors"
            />
            <button 
              onClick={handleSend}
              className="absolute right-2 w-8 h-8 flex items-center justify-center rounded-full bg-[var(--color-primary-main)] text-white hover:bg-[var(--color-purple-main)] transition-colors"
            >
              <Send className="w-4 h-4 ml-0.5" />
            </button>
          </div>
        </div>

      </div>
    </div>
  );
}
