# 🚀 SmartSpend AI

![SmartSpend AI Hero Banner](public/icon-512x512.png)

> **Live Deployment:** [https://smart-spend-ten-blue.vercel.app](https://smart-spend-ten-blue.vercel.app)

**SmartSpend AI** is an intelligent, modern personal finance tracker built specifically for college students. It helps you manage your money, track your goals, and gain financial insights through an integrated AI assistant powered by Google Gemini.

## ✨ Key Features

- **📊 Comprehensive Dashboard:** View your complete financial overview, total balance, income vs. expenses, and recent transactions at a glance.
- **🤖 AI Financial Assistant:** Integrated Google Gemini AI to analyze your spending habits, answer financial questions, and suggest personalized budgeting strategies.
- **📱 Installable PWA:** Fully installable on iOS and Android devices with offline caching support. Your dashboard and transaction logs load instantly, even without an internet connection.
- **💸 Budget & Goal Tracking:** Set monthly budgets by category and create long-term savings goals with progress tracking.
- **📈 Advanced Analytics:** Visualize your spending patterns with interactive charts. Compare this month's spending against last month's.
- **🌙 Beautiful UI/UX:** A stunning, highly-responsive interface with dark mode support, fluid micro-animations, and glassmorphic elements.
- **🔒 Secure Authentication:** Powered by Supabase Auth for robust user security.

## 🛠 Tech Stack

- **Framework:** [Next.js 16](https://nextjs.org/) (App Router)
- **Styling:** [Tailwind CSS v4](https://tailwindcss.com/)
- **State Management:** [Zustand](https://zustand-demo.pmnd.rs/) (with persistent local storage)
- **Database & Auth:** [Supabase](https://supabase.com/) (PostgreSQL)
- **AI Integration:** [Google Gemini API](https://deepmind.google/technologies/gemini/)
- **PWA Configuration:** `next-pwa`
- **Icons:** [Lucide React](https://lucide.dev/)

## 🚀 Getting Started

### Prerequisites
Make sure you have [Node.js](https://nodejs.org/) installed on your machine.

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/smart-spend.git
   cd smart-spend
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Set up Environment Variables:**
   Create a `.env.local` file in the root directory and add your keys:
   ```env
   NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
   NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
   GEMINI_API_KEY=your_gemini_api_key
   ```

4. **Run the development server:**
   ```bash
   npm run dev
   ```

5. **Open the App:**
   Open [http://localhost:3000](http://localhost:3000) with your browser to see the result.

## 📱 Installing the PWA (Progressive Web App)

SmartSpend AI acts as a native app on your mobile device! 

1. Navigate to the **Live Deployment URL** (https://smart-spend-ten-blue.vercel.app) on your Android or iOS browser (Chrome/Safari).
2. Open the browser menu and select **"Add to Home Screen"**.
3. The app will install and function fully offline for viewing your cached dashboard and transaction logs!

