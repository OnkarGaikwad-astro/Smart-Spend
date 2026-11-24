"use client";

import React, { useState, useEffect, useRef } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Bot, X, Send, Sparkles, Mic, MicOff, Volume2 } from "lucide-react";
import { useAppStore } from "@/lib/store";

export default function AIAssistantWidget() {
  const { transactions, goals, debts, isAIOpen, setAIOpen, aiInitialMsg } = useAppStore();
  const [messages, setMessages] = useState<{ role: "user" | "ai"; content: string }[]>([
    {
      role: "ai",
      content: "Hi! I am Aurex, your AI financial assistant. Ask me anything about your expenses, budgets, savings, or khata!",
    },
  ]);
  const [input, setInput] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [isListening, setIsListening] = useState(false);
  const [speechSupported, setSpeechSupported] = useState(false);
  const recognitionRef = useRef<any>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const toggleOpen = () => setAIOpen(!isAIOpen);

  // Scroll to bottom of chat
  useEffect(() => {
    if (isAIOpen) {
      messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
    }
  }, [messages, isAIOpen]);

  // Initialize Speech Recognition
  useEffect(() => {
    if (typeof window !== "undefined") {
      const SpeechRecognition =
        (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition;

      if (SpeechRecognition) {
        setSpeechSupported(true);
        const recognition = new SpeechRecognition();
        recognition.continuous = false;
        recognition.interimResults = true;
        recognition.lang = "en-IN"; // English (India) with support for Indian names and terms

        recognition.onstart = () => {
          setIsListening(true);
        };

        recognition.onresult = (event: any) => {
          const current = event.resultIndex;
          const transcript = event.results[current][0].transcript;
          setInput(transcript);
        };

        recognition.onerror = (event: any) => {
          console.warn("Speech recognition error:", event.error);
          setIsListening(false);
        };

        recognition.onend = () => {
          setIsListening(false);
        };

        recognitionRef.current = recognition;
      }
    }

    return () => {
      if (recognitionRef.current) {
        try {
          recognitionRef.current.stop();
        } catch {}
      }
    };
  }, []);

  const toggleVoiceListening = () => {
    if (!recognitionRef.current) return;

    if (isListening) {
      try {
        recognitionRef.current.stop();
      } catch {}
      setIsListening(false);
    } else {
      try {
        setInput("");
        recognitionRef.current.start();
      } catch (err) {
        console.warn("Could not start speech recognition:", err);
      }
    }
  };

  useEffect(() => {
    if (isAIOpen && aiInitialMsg) {
      handleSend(undefined, aiInitialMsg);
      setAIOpen(true, ""); // Clear initial message so it doesn't resend
    }
  }, [isAIOpen, aiInitialMsg]);

  const handleSend = async (e?: React.FormEvent, customMsg?: string) => {
    e?.preventDefault();
    const userText = customMsg || input;
    if (!userText.trim() || isLoading) return;

    if (isListening && recognitionRef.current) {
      try {
        recognitionRef.current.stop();
      } catch {}
      setIsListening(false);
    }

    const newMessages = [...messages, { role: "user" as const, content: userText.trim() }];
    setMessages(newMessages);
    setInput("");
    setIsLoading(true);

    try {
      const totalIncome = transactions
        .filter((t) => t.type === "INCOME")
        .reduce((acc, curr) => acc + curr.amount, 0);
      const totalExpense = transactions
        .filter((t) => t.type === "EXPENSE")
        .reduce((acc, curr) => acc + Math.abs(curr.amount), 0);

      const response = await fetch("/api/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          messages: newMessages,
          context: {
            totalBalance: totalIncome - totalExpense,
            totalIncome,
            totalExpense,
            transactions,
            goals,
            debts,
          },
        }),
      });

      const data = await response.json();

      if (response.ok) {
        setMessages((prev) => [...prev, { role: "ai", content: data.content }]);
      } else {
        setMessages((prev) => [
          ...prev,
          { role: "ai", content: `Error: ${data.error || "Failed to get response"}` },
        ]);
      }
    } catch (error) {
      setMessages((prev) => [
        ...prev,
        { role: "ai", content: "Sorry, I encountered a network error connecting to the AI." },
      ]);
    } finally {
      setIsLoading(false);
    }
  };

  const quickPrompts = [
    "What's my balance?",
    "Who owes me money?",
    "How much did I spend this month?",
  ];

  return (
    <>
      <AnimatePresence>
        {isAIOpen && (
          <motion.div
            initial={{ opacity: 0, scale: 0.9, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.9, y: 20 }}
            transition={{ duration: 0.2, type: "spring", bounce: 0.25 }}
            className="fixed bottom-[80px] md:bottom-24 right-4 md:right-6 w-[calc(100vw-32px)] md:w-[380px] h-[540px] max-h-[75vh] z-50 flex flex-col overflow-hidden shadow-2xl rounded-[28px] border border-[var(--color-border-subtle)] bg-[var(--color-surface)] backdrop-blur-2xl"
          >
            {/* Header */}
            <div className="flex items-center justify-between p-4 border-b border-[var(--color-border-subtle)] bg-white/[0.02]">
              <div className="flex items-center gap-2.5">
                <div className="w-9 h-9 rounded-[12px] bg-[var(--color-primary-soft)] flex items-center justify-center text-[var(--color-primary-main)] shadow-sm">
                  <Sparkles className="w-4 h-4" />
                </div>
                <div>
                  <h3 className="font-bold text-[15px] text-[var(--color-text-main)] flex items-center gap-1.5">
                    Aurex AI
                    <span className="text-[10px] font-semibold px-1.5 py-0.2 rounded-full bg-emerald-500/15 text-emerald-600 dark:text-emerald-400">
                      Voice Ready
                    </span>
                  </h3>
                  <p className="text-[11px] text-[var(--color-text-muted)]">
                    Smart Financial & Khata Assistant
                  </p>
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
            <div className="flex-1 overflow-y-auto p-4 space-y-3.5 scrollbar-thin">
              {messages.map((msg, idx) => (
                <div
                  key={idx}
                  className={`flex ${msg.role === "user" ? "justify-end" : "justify-start"}`}
                >
                  <div
                    className={`max-w-[85%] p-3.5 text-[13.5px] leading-relaxed shadow-sm whitespace-pre-wrap ${
                      msg.role === "user"
                        ? "bg-[var(--color-primary-main)] text-white rounded-[20px] rounded-tr-[4px]"
                        : "bg-[var(--color-surface-2)] text-[var(--color-text-main)] rounded-[20px] rounded-tl-[4px] border border-[var(--color-border-subtle)]"
                    }`}
                  >
                    {msg.content}
                  </div>
                </div>
              ))}

              {isLoading && (
                <div className="flex justify-start">
                  <div className="p-3 rounded-[20px] rounded-tl-[4px] bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] flex items-center gap-2 text-[12px] text-[var(--color-text-muted)]">
                    <div className="w-3.5 h-3.5 border-2 border-[var(--color-primary-main)] border-t-transparent rounded-full animate-spin" />
                    <span>Aurex is thinking...</span>
                  </div>
                </div>
              )}
              <div ref={messagesEndRef} />
            </div>

            {/* Quick Starters */}
            {messages.length <= 2 && (
              <div className="px-4 py-1.5 flex gap-1.5 overflow-x-auto hide-scrollbar border-t border-[var(--color-border-subtle)] bg-black/[0.02]">
                {quickPrompts.map((prompt, i) => (
                  <button
                    key={i}
                    onClick={() => handleSend(undefined, prompt)}
                    className="whitespace-nowrap px-2.5 py-1 text-[11px] rounded-full bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] text-[var(--color-text-muted)] hover:text-[var(--color-text-main)] hover:border-[var(--color-primary-main)] transition-colors"
                  >
                    {prompt}
                  </button>
                ))}
              </div>
            )}

            {/* Voice Status Pill */}
            {isListening && (
              <div className="px-4 py-1.5 bg-rose-500/10 border-t border-rose-500/20 flex items-center justify-between text-[12px] text-rose-500 font-semibold animate-pulse">
                <span className="flex items-center gap-1.5">
                  <span className="w-2 h-2 rounded-full bg-rose-500 animate-ping" />
                  Listening to your voice... Speak now!
                </span>
                <button
                  type="button"
                  onClick={toggleVoiceListening}
                  className="text-[11px] underline hover:opacity-80"
                >
                  Stop
                </button>
              </div>
            )}

            {/* Input Area */}
            <div className="p-3 border-t border-[var(--color-border-subtle)] bg-white/[0.02]">
              <form
                onSubmit={handleSend}
                className="flex items-center gap-1.5 p-1 pl-3.5 rounded-full bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] focus-within:border-[var(--color-primary-main)] transition-colors"
              >
                <input
                  type="text"
                  value={input}
                  onChange={(e) => setInput(e.target.value)}
                  placeholder={isListening ? "Listening..." : "Ask Aurex or speak..."}
                  className="flex-1 bg-transparent border-none outline-none text-[13.5px] text-[var(--color-text-main)] placeholder-[var(--color-text-muted)]"
                />

                {/* Voice Recognition Mic Button */}
                {speechSupported && (
                  <button
                    type="button"
                    onClick={toggleVoiceListening}
                    title={isListening ? "Stop listening" : "Speak to Aurex"}
                    className={`w-8 h-8 flex items-center justify-center rounded-full transition-all ${
                      isListening
                        ? "bg-rose-500 text-white animate-bounce shadow-md"
                        : "text-[var(--color-text-muted)] hover:text-[var(--color-primary-main)] hover:bg-black/5 dark:hover:bg-white/5"
                    }`}
                  >
                    {isListening ? <MicOff className="w-4 h-4" /> : <Mic className="w-4 h-4" />}
                  </button>
                )}

                <button
                  type="submit"
                  disabled={!input.trim() || isLoading}
                  className="w-8 h-8 flex items-center justify-center rounded-full bg-[var(--color-primary-main)] text-white disabled:opacity-40 transition-opacity shadow-sm hover:brightness-110"
                >
                  {isLoading ? (
                    <div className="w-3.5 h-3.5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                  ) : (
                    <Send className="w-3.5 h-3.5 ml-0.5" />
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
        className="fixed bottom-[80px] md:bottom-6 right-4 md:right-6 w-14 h-14 z-50 flex items-center justify-center rounded-full shadow-lg border border-[var(--color-border-subtle)] bg-[var(--color-surface)] backdrop-blur-xl text-[var(--color-primary-main)] hover:bg-[var(--color-surface-2)] transition-colors cursor-pointer"
      >
        <Bot className="w-6 h-6" />
      </motion.button>
    </>
  );
}
