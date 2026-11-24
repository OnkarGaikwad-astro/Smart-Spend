import Link from "next/link";
import { 
  ArrowRight, 
  BarChart3, 
  Brain, 
  Download, 
  ExternalLink, 
  HandCoins, 
  Mic, 
  PiggyBank, 
  Smartphone, 
  Sparkles, 
  Zap 
} from "lucide-react";

const APK_DOWNLOAD_URL = "https://github.com/OnkarGaikwad-astro/SmartSpend-flutter/releases/latest/download/SmartSpend.apk";
const FLUTTER_REPO_URL = "https://github.com/OnkarGaikwad-astro/SmartSpend-flutter";
const FLUTTER_RELEASES_URL = "https://github.com/OnkarGaikwad-astro/SmartSpend-flutter/releases";

export default function Home() {
  return (
    <main className="flex-1 flex flex-col items-center p-6 md:p-24 relative overflow-hidden bg-[var(--color-bg-body)] min-h-screen">
      {/* Premium Ambient Background Blurs matching theme */}
      <div className="absolute top-[-20%] left-[-10%] w-[50%] h-[50%] bg-[var(--color-primary-soft)] rounded-full mix-blend-multiply filter blur-[120px] opacity-70 animate-blob pointer-events-none" />
      <div className="absolute top-[20%] right-[-10%] w-[50%] h-[50%] bg-[var(--color-secondary-soft)] rounded-full mix-blend-multiply filter blur-[120px] opacity-70 animate-blob animation-delay-2000 pointer-events-none" />
      <div className="absolute bottom-[-20%] left-[20%] w-[50%] h-[50%] bg-[var(--color-accent-soft)] rounded-full mix-blend-multiply filter blur-[120px] opacity-60 animate-blob animation-delay-4000 pointer-events-none" />

      {/* Structured Data for Google Site Name */}
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{
          __html: JSON.stringify({
            "@context": "https://schema.org",
            "@type": "WebSite",
            name: "SmartSpend AI",
            alternateName: "SmartSpend",
            url: "https://smartspend.astronkar.in",
          }),
        }}
      />

      {/* Hero Section */}
      <div className="max-w-5xl w-full text-center space-y-8 z-10 mt-12 md:mt-20 flex flex-col items-center">
        <div className="inline-flex items-center gap-2 rounded-full border border-[var(--color-border-subtle)] bg-[var(--color-surface)] shadow-sm px-4 py-1.5 text-[13px] font-medium text-[var(--color-text-main)] transition-all hover:shadow-md backdrop-blur-md">
          <Sparkles className="w-4 h-4 text-[var(--color-primary-main)]" />
          <span>SmartSpend AI — The Future of Personal Finance</span>
        </div>
        
        <h2 className="text-5xl md:text-7xl font-extrabold tracking-tight text-[var(--color-text-main)] leading-[1.1]">
          Master your money, <br className="hidden md:block" />
          <span className="text-transparent bg-clip-text bg-gradient-to-r from-[var(--color-primary-main)] to-[var(--color-secondary-main)]">
            without the spreadsheet.
          </span>
        </h2>
        
        <p className="text-lg md:text-xl text-[var(--color-text-muted)] max-w-2xl mx-auto leading-relaxed">
          The most beautiful, intelligent personal finance tracker designed for everyone. Track expenses, crush budgets, manage debts, and let AI analyze your spending habits.
        </p>
        
        {/* Call to Actions (Web + Android APK) */}
        <div className="flex flex-col sm:flex-row items-center justify-center gap-4 pt-4 w-full sm:w-auto">
          <Link 
            href="/dashboard"
            className="w-full sm:w-auto group relative inline-flex h-14 items-center justify-center overflow-hidden rounded-[16px] bg-[var(--color-primary-main)] px-8 font-medium text-white transition-all hover:opacity-90 hover:scale-105 shadow-xl shadow-[var(--color-primary-soft)]"
          >
            <span className="text-[16px]">Launch Web App</span>
            <ArrowRight className="ml-2 h-5 w-5 transition-transform group-hover:translate-x-1" />
          </Link>

          <a 
            href={APK_DOWNLOAD_URL}
            className="w-full sm:w-auto group relative inline-flex h-14 items-center justify-center overflow-hidden rounded-[16px] bg-[var(--color-surface)] border border-[var(--color-border-subtle)] px-7 font-medium text-[var(--color-text-main)] transition-all hover:bg-[var(--color-surface-2)] hover:scale-105 shadow-lg hover:shadow-xl backdrop-blur-md"
          >
            <div className="w-8 h-8 rounded-full bg-[var(--color-primary-soft)] flex items-center justify-center mr-3 text-[var(--color-primary-main)] group-hover:scale-110 transition-transform">
              <Smartphone className="h-4 w-4" />
            </div>
            <div className="flex flex-col text-left">
              <span className="text-[11px] text-[var(--color-text-muted)] uppercase tracking-wider font-semibold -mb-0.5">Android APK</span>
              <span className="text-[15px] font-bold flex items-center gap-1.5">
                Download App <Download className="w-4 h-4 text-[var(--color-primary-main)] group-hover:translate-y-0.5 transition-transform" />
              </span>
            </div>
          </a>
        </div>
      </div>

      {/* Android Companion App Showcase Card */}
      <div className="mt-20 max-w-4xl w-full z-10">
        <div className="relative rounded-[28px] bg-[var(--color-surface)] border border-[var(--color-border-subtle)] p-8 md:p-10 shadow-2xl backdrop-blur-xl overflow-hidden">
          <div className="absolute top-0 right-0 w-80 h-80 bg-gradient-to-br from-[var(--color-primary-soft)] to-[var(--color-secondary-soft)] rounded-full blur-3xl pointer-events-none"></div>

          <div className="flex flex-col md:flex-row items-center justify-between gap-8 relative z-10">
            <div className="space-y-4 max-w-xl text-center md:text-left">
              <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-[var(--color-primary-soft)] border border-[var(--color-border-subtle)] text-[var(--color-primary-main)] text-[12px] font-semibold">
                <Smartphone className="w-3.5 h-3.5" /> Flutter Companion App • v1.0.0
              </div>
              <h3 className="text-2xl md:text-3xl font-bold text-[var(--color-text-main)] tracking-tight">
                Get SmartSpend on Your Android Phone
              </h3>
              <p className="text-[15px] text-[var(--color-text-muted)] leading-relaxed">
                Log expenses in seconds with interactive Android Home Screen Widgets, record voice transactions with AI, manage money you lent to friends or borrowed with the built-in Debt Tracker, and sync everything offline or online with Supabase.
              </p>
              
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 pt-2 text-[13px] font-medium text-[var(--color-text-main)]">
                <div className="flex items-center gap-2 p-2.5 rounded-[12px] bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)]">
                  <Zap className="w-4 h-4 text-[var(--color-primary-main)] shrink-0" />
                  <span>Home Widgets</span>
                </div>
                <div className="flex items-center gap-2 p-2.5 rounded-[12px] bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)]">
                  <Mic className="w-4 h-4 text-[var(--color-secondary-main)] shrink-0" />
                  <span>Voice AI Assistant</span>
                </div>
                <div className="flex items-center gap-2 p-2.5 rounded-[12px] bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)]">
                  <HandCoins className="w-4 h-4 text-[var(--color-primary-main)] shrink-0" />
                  <span>Lent & Borrowed</span>
                </div>
              </div>
            </div>

            <div className="flex flex-col sm:flex-row md:flex-col gap-3 w-full md:w-auto shrink-0">
              <a
                href={APK_DOWNLOAD_URL}
                className="inline-flex items-center justify-center gap-2.5 px-6 py-4 rounded-[16px] bg-[var(--color-primary-main)] hover:opacity-90 text-white font-semibold text-[15px] shadow-lg shadow-[var(--color-primary-soft)] transition-all hover:scale-105"
              >
                <Download className="w-5 h-5" />
                <span>Download SmartSpend.apk</span>
              </a>
              <a
                href={FLUTTER_RELEASES_URL}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center justify-center gap-2 px-5 py-3 rounded-[14px] bg-[var(--color-surface)] border border-[var(--color-border-subtle)] text-[var(--color-text-main)] hover:bg-[var(--color-surface-2)] text-[13px] font-medium transition-colors"
              >
                <span>All Releases on GitHub</span>
                <ExternalLink className="w-3.5 h-3.5 text-[var(--color-text-muted)]" />
              </a>
            </div>
          </div>
        </div>
      </div>

      {/* Features Grid */}
      <div className="mt-24 md:mt-32 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 max-w-6xl w-full z-10 pb-24">
        <FeatureCard 
          icon={<Brain className="h-6 w-6 text-[var(--color-primary-main)]" />}
          iconBg="bg-[var(--color-primary-soft)]"
          title="AI Assistant"
          description="Talk to your finances. Ask questions like 'How much did I spend on food this month?' and get instant answers."
        />
        <FeatureCard 
          icon={<HandCoins className="h-6 w-6 text-[var(--color-secondary-main)]" />}
          iconBg="bg-[var(--color-secondary-soft)]"
          title="Lent & Borrowed"
          description="Never forget money you gave to friends or owe. Track repayments, due dates, and settlement progress."
        />
        <FeatureCard 
          icon={<PiggyBank className="h-6 w-6 text-[var(--color-primary-main)]" />}
          iconBg="bg-[var(--color-primary-soft)]"
          title="Budgets & Goals"
          description="Set spending limits for groceries, dining, and shopping. Build saving habits and track progress toward targets."
        />
        <FeatureCard 
          icon={<BarChart3 className="h-6 w-6 text-[var(--color-secondary-main)]" />}
          iconBg="bg-[var(--color-secondary-soft)]"
          title="Rich Analytics"
          description="Visualize your financial trajectory with intuitive charts, category breakdowns, and monthly trends."
        />
      </div>

      {/* Footer / Developer Info */}
      <footer className="w-full max-w-6xl z-10 border-t border-[var(--color-border-subtle)] pt-8 pb-12 mt-auto flex flex-col items-center justify-center text-center">
        <p className="text-[15px] font-medium text-[var(--color-text-muted)]">
          Designed and built with ❤️ by <span className="text-[var(--color-text-main)] font-bold">Onkar Gaikwad</span>.
        </p>
        <p className="text-[13px] text-[var(--color-text-muted)] mt-2 max-w-lg">
          A personal finance tracker built to help you manage your money, savings, and debts effectively using the power of AI across Web & Android.
        </p>
        <div className="flex flex-wrap justify-center gap-4 mt-4 text-[13px] font-medium">
          <a href="https://github.com/OnkarGaikwad-astro" target="_blank" rel="noopener noreferrer" className="text-[var(--color-text-muted)] hover:text-[var(--color-primary-main)] transition-colors">
            GitHub Profile
          </a>
          <span className="text-[var(--color-border-subtle)]">•</span>
          <a href={FLUTTER_REPO_URL} target="_blank" rel="noopener noreferrer" className="text-[var(--color-text-muted)] hover:text-[var(--color-primary-main)] transition-colors">
            Flutter App Repository
          </a>
          <span className="text-[var(--color-border-subtle)]">•</span>
          <a href={APK_DOWNLOAD_URL} className="text-[var(--color-primary-main)] hover:underline font-semibold transition-colors flex items-center gap-1">
            <Download className="w-3.5 h-3.5" /> Download APK (v1.0.0)
          </a>
        </div>
      </footer>
    </main>
  );
}

function FeatureCard({ icon, iconBg, title, description }: { icon: React.ReactNode, iconBg: string, title: string, description: string }) {
  return (
    <div className="flex flex-col items-start p-8 rounded-[24px] bg-[var(--color-surface)] border border-[var(--color-border-subtle)] shadow-lg hover:shadow-xl transition-all hover:-translate-y-1 relative overflow-hidden group backdrop-blur-md">
      <div className={`p-3.5 rounded-[16px] ${iconBg} mb-5 transition-transform group-hover:scale-110`}>
        {icon}
      </div>
      <h3 className="text-[18px] font-bold text-[var(--color-text-main)] mb-2">{title}</h3>
      <p className="text-[14px] text-[var(--color-text-muted)] leading-relaxed">{description}</p>
    </div>
  );
}
