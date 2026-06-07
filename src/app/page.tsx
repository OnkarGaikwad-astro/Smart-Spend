import Link from "next/link";
import { ArrowRight, BarChart3, Brain, PiggyBank, ShieldCheck, Sparkles } from "lucide-react";

export default function Home() {
  return (
    <main className="flex-1 flex flex-col items-center p-6 md:p-24 relative overflow-hidden bg-[var(--color-bg-body)] min-h-screen">
      {/* Premium Background Blurs */}
      <div className="absolute top-[-20%] left-[-10%] w-[50%] h-[50%] bg-[var(--color-primary-soft)] rounded-full mix-blend-multiply filter blur-[120px] opacity-70 animate-blob pointer-events-none" />
      <div className="absolute top-[20%] right-[-10%] w-[50%] h-[50%] bg-[var(--color-purple-soft)] rounded-full mix-blend-multiply filter blur-[120px] opacity-70 animate-blob animation-delay-2000 pointer-events-none" />
      <div className="absolute bottom-[-20%] left-[20%] w-[50%] h-[50%] bg-[var(--color-secondary-soft)] rounded-full mix-blend-multiply filter blur-[120px] opacity-70 animate-blob animation-delay-4000 pointer-events-none" />

      {/* Hero Section */}
      <div className="max-w-5xl w-full text-center space-y-8 z-10 mt-12 md:mt-24 flex flex-col items-center">
        <div className="inline-flex items-center rounded-full border border-[var(--color-border-subtle)] bg-[var(--color-surface)] shadow-sm px-4 py-1.5 text-[13px] font-medium text-[var(--color-text-main)] transition-all hover:shadow-md">
          <Sparkles className="w-4 h-4 text-[var(--color-primary-main)] mr-2" />
          SmartSpend AI — The Future of Student Finance
        </div>
        
        <h1 className="text-5xl md:text-7xl font-extrabold tracking-tight text-[var(--color-text-main)] leading-[1.1]">
          Master your money, <br className="hidden md:block" />
          <span className="text-transparent bg-clip-text bg-gradient-to-r from-[var(--color-primary-main)] to-[var(--color-purple-main)]">
            without the spreadsheet.
          </span>
        </h1>
        
        <p className="text-lg md:text-xl text-[var(--color-text-muted)] max-w-2xl mx-auto leading-relaxed">
          The most beautiful, intelligent personal finance tracker designed exclusively for college students. Track expenses, crush budgets, and let AI analyze your spending habits.
        </p>
        
        <div className="flex flex-col sm:flex-row items-center justify-center gap-4 pt-8">
          <Link 
            href="/dashboard"
            className="group relative inline-flex h-14 items-center justify-center overflow-hidden rounded-[16px] bg-[var(--color-primary-main)] px-8 font-medium text-white transition-all hover:bg-blue-600 hover:scale-105 shadow-xl shadow-[var(--color-primary-soft)]"
          >
            <span className="text-[16px]">Get Started Now</span>
            <ArrowRight className="ml-2 h-5 w-5 transition-transform group-hover:translate-x-1" />
          </Link>
        </div>
      </div>

      {/* Features Grid */}
      <div className="mt-32 md:mt-48 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 max-w-6xl w-full z-10 pb-24">
        <FeatureCard 
          icon={<Brain className="h-6 w-6 text-[var(--color-purple-main)]" />}
          iconBg="bg-[var(--color-purple-soft)]"
          title="AI Assistant"
          description="Talk to your finances. Ask questions like 'How much did I spend on food this month?' and get instant answers."
        />
        <FeatureCard 
          icon={<PiggyBank className="h-6 w-6 text-[var(--color-secondary-main)]" />}
          iconBg="bg-[var(--color-secondary-soft)]"
          title="Student Budgets"
          description="Set category budgets for groceries, textbooks, and entertainment. Get alerted before you overspend."
        />
        <FeatureCard 
          icon={<BarChart3 className="h-6 w-6 text-[var(--color-primary-main)]" />}
          iconBg="bg-[var(--color-primary-soft)]"
          title="Rich Analytics"
          description="Visualize your habits with beautiful, interactive charts that actually make sense of your data."
        />
        <FeatureCard 
          icon={<ShieldCheck className="h-6 w-6 text-emerald-600" />}
          iconBg="bg-emerald-100"
          title="Bank-Level Security"
          description="Your data is locked down with enterprise-grade Row Level Security and isolated user profiles."
        />
      </div>
    </main>
  );
}

function FeatureCard({ icon, iconBg, title, description }: { icon: React.ReactNode, iconBg: string, title: string, description: string }) {
  return (
    <div className="flex flex-col items-start p-8 rounded-[24px] bg-[var(--color-surface)] border border-[var(--color-border-subtle)] shadow-lg hover:shadow-xl transition-all hover:-translate-y-1 relative overflow-hidden group">
      <div className={`p-3.5 rounded-[16px] ${iconBg} mb-5 transition-transform group-hover:scale-110`}>
        {icon}
      </div>
      <h3 className="text-[18px] font-bold text-[var(--color-text-main)] mb-2">{title}</h3>
      <p className="text-[14px] text-[var(--color-text-muted)] leading-relaxed">{description}</p>
    </div>
  );
}
