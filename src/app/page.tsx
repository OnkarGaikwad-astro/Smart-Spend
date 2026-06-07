import Link from "next/link";
import { ArrowRight, BarChart3, Brain, PiggyBank, WifiOff } from "lucide-react";

export default function Home() {
  return (
    <main className="flex-1 flex flex-col items-center justify-center p-6 md:p-24 relative overflow-hidden">
      {/* Background Gradients */}
      <div className="absolute top-[-10%] left-[-10%] w-[40%] h-[40%] bg-indigo-500/20 rounded-full blur-[120px] pointer-events-none" />
      <div className="absolute bottom-[-10%] right-[-10%] w-[40%] h-[40%] bg-emerald-500/20 rounded-full blur-[120px] pointer-events-none" />

      {/* Hero Section */}
      <div className="max-w-4xl w-full text-center space-y-8 z-10">
        <div className="inline-flex items-center rounded-full border border-indigo-500/30 bg-indigo-500/10 px-3 py-1 text-sm font-medium text-indigo-300">
          <span className="flex h-2 w-2 rounded-full bg-indigo-500 mr-2"></span>
          SmartSpend AI v1.0
        </div>
        
        <h1 className="text-5xl md:text-7xl font-extrabold tracking-tight text-transparent bg-clip-text bg-gradient-to-r from-indigo-400 via-emerald-400 to-amber-400">
          Know where your money disappears.
        </h1>
        
        <p className="text-lg md:text-xl text-slate-400 max-w-2xl mx-auto">
          The intelligent personal finance tracker designed for college students. Track expenses, manage budgets, and get AI-powered insights.
        </p>
        
        <div className="flex flex-col sm:flex-row items-center justify-center gap-4 pt-4">
          <Link 
            href="/dashboard"
            className="group relative inline-flex h-12 items-center justify-center overflow-hidden rounded-full bg-indigo-600 px-8 font-medium text-white transition-all hover:bg-indigo-700 hover:scale-105"
          >
            <span>Get Started</span>
            <ArrowRight className="ml-2 h-4 w-4 transition-transform group-hover:translate-x-1" />
          </Link>
          
          <Link 
            href="/auth/login"
            className="inline-flex h-12 items-center justify-center rounded-full border border-slate-700 bg-slate-800/50 px-8 font-medium text-slate-300 transition-colors hover:bg-slate-800 hover:text-white"
          >
            Login
          </Link>
        </div>
      </div>

      {/* Features Grid */}
      <div className="mt-32 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 max-w-6xl w-full z-10">
        <FeatureCard 
          icon={<Brain className="h-6 w-6 text-indigo-400" />}
          title="AI Insights"
          description="Automatic transaction categorization and natural language financial assistant."
        />
        <FeatureCard 
          icon={<PiggyBank className="h-6 w-6 text-emerald-400" />}
          title="Budget Planning"
          description="Set category-wise budgets and get alerts before you overspend."
        />
        <FeatureCard 
          icon={<BarChart3 className="h-6 w-6 text-amber-400" />}
          title="Spending Analytics"
          description="Visualize your habits with beautiful, interactive charts and monthly reports."
        />
        <FeatureCard 
          icon={<WifiOff className="h-6 w-6 text-slate-400" />}
          title="Offline Access"
          description="Log expenses anytime, anywhere. Auto-syncs when you're back online."
        />
      </div>
    </main>
  );
}

function FeatureCard({ icon, title, description }: { icon: React.ReactNode, title: string, description: string }) {
  return (
    <div className="flex flex-col items-start p-6 rounded-2xl bg-slate-800/40 border border-slate-700/50 backdrop-blur-sm transition-all hover:bg-slate-800/80 hover:-translate-y-1">
      <div className="p-3 rounded-lg bg-slate-900/50 mb-4">
        {icon}
      </div>
      <h3 className="text-xl font-semibold text-slate-100 mb-2">{title}</h3>
      <p className="text-slate-400 leading-relaxed">{description}</p>
    </div>
  );
}
