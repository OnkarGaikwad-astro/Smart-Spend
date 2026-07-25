<div align="center">

<img src="public/icon-512x512.png" alt="SmartSpend AI Logo" width="120" />

# SmartSpend AI

### AI-powered personal finance tracking built for students.

Track expenses, manage budgets, build savings goals, scan receipts and understand your spending with AI.

<br/>

### 🌐 [Launch SmartSpend →](https://smartspend.astronkar.in)

[![GitHub Repo](https://img.shields.io/badge/GitHub-Repository-181717?style=for-the-badge&logo=github)](https://github.com/OnkarGaikwad-astro/Smart-Spend)
[![Live](https://img.shields.io/badge/Live-smartspend.astronkar.in-22c55e?style=for-the-badge)](https://smartspend.astronkar.in)
[![PWA](https://img.shields.io/badge/PWA-Installable-5A0FC8?style=for-the-badge&logo=pwa)](https://smartspend.astronkar.in)

<br/>

**Next.js 16 · React 19 · TypeScript · Supabase · PostgreSQL · Gemini · Zustand · Tailwind CSS**

</div>

---

## 💡 What is SmartSpend?

Keeping track of money sounds simple until dozens of small expenses start adding up.

SmartSpend is a personal finance application designed around that problem, particularly for students managing monthly allowances, everyday UPI payments, subscriptions, food expenses and savings goals.

Instead of being only a place to record transactions, SmartSpend connects your financial data across:

```text
Transactions → Budgets → Analytics → Goals → AI Insights
```

It also uses **Google Gemini** to reduce one of the most annoying parts of expense tracking: manual entry.

Upload a receipt or payment screenshot and SmartSpend can extract the transaction information for you.

---

## ✨ Highlights

### 📊 One Dashboard for Your Finances

Get a quick overview of your current balance, income, expenses, recent transactions and spending activity without digging through multiple pages.

### 🤖 AI Financial Assistant

Ask questions about your finances using natural language.

```text
"Where did I spend the most this month?"

"How much have I spent on food?"

"How can I reduce my expenses?"
```

SmartSpend combines your financial context with Gemini to provide more useful and personalised answers.

### 📸 AI Receipt & Payment Scanner

Upload receipts, bills or payment screenshots from services such as UPI apps.

SmartSpend uses Gemini to extract useful transaction information such as:

```text
Receipt / Screenshot
        │
        ▼
   Gemini Analysis
        │
        ▼
 ┌───────────────┐
 │ Amount        │
 │ Merchant      │
 │ Date          │
 │ Category      │
 └───────┬───────┘
         │
         ▼
   Transaction
```

This significantly reduces repetitive manual transaction entry.

### 💸 Smart Budget Tracking

Create monthly budgets for categories such as food, travel or entertainment.

Budget utilisation is calculated from your actual transactions instead of maintaining a separate manually entered "spent" value.

### 🎯 Savings Goals

Create goals for things you are saving towards and track your progress over time.

### 📈 Financial Analytics

Explore spending using interactive visualisations including category breakdowns and timeline-based expense trends.

### 📱 Installable PWA

SmartSpend is built as a Progressive Web App, giving it an app-like experience without requiring a separate mobile application.

Install it directly from a supported browser and access cached application resources even with limited connectivity.

### 🔐 Private by Design

Authentication is powered by Supabase, while PostgreSQL **Row Level Security (RLS)** protects user-owned financial records.

A user's transactions, budgets and goals are associated with their authenticated identity and database policies enforce ownership.

---

## 🧭 Explore SmartSpend

| Section | Purpose |
| --- | --- |
| 🏠 **Dashboard** | Overall financial health and recent activity |
| 💳 **Transactions** | Add and manage income and expenses |
| 💸 **Budgets** | Set category-wise monthly spending limits |
| 📈 **Analytics** | Explore spending patterns and trends |
| 🎯 **Goals** | Track savings targets |
| 🤖 **AI Assistant** | Ask questions about your financial data |
| 📸 **Scanner** | Extract transactions from receipts and screenshots |

---

## 🏗️ Architecture

```text
                         ┌─────────────────┐
                         │      User       │
                         └────────┬────────┘
                                  │
                                  ▼
                    ┌─────────────────────────┐
                    │      SmartSpend PWA     │
                    │                         │
                    │ Next.js + React + TS    │
                    └────────────┬────────────┘
                                 │
               ┌─────────────────┼─────────────────┐
               │                 │                 │
               ▼                 ▼                 ▼
       ┌──────────────┐   ┌──────────────┐  ┌──────────────┐
       │   Zustand    │   │   Supabase   │  │    Gemini    │
       │              │   │              │  │              │
       │ Client State │   │ Auth + DB    │  │ AI Features  │
       └──────────────┘   └──────┬───────┘  └──────────────┘
                                 │
                                 ▼
                         ┌───────────────┐
                         │  PostgreSQL   │
                         │     + RLS     │
                         └───────┬───────┘
                                 │
                    ┌────────────┼────────────┐
                    ▼            ▼            ▼
              Transactions    Budgets       Goals
```

### Design principle

> **Structured data for truth. Deterministic code for calculations. AI for interpretation.**

Gemini handles tasks where AI is useful, such as understanding receipts and natural-language questions.

Financial records, ownership, balances and budget calculations remain structured and deterministic.

---

## 🛠️ Tech Stack

| Category | Technology |
| --- | --- |
| **Framework** | Next.js 16 |
| **Frontend** | React 19 + TypeScript |
| **Styling** | Tailwind CSS 4 |
| **Database** | PostgreSQL |
| **Backend** | Supabase |
| **Authentication** | Supabase Auth + Google OAuth |
| **AI** | Google Gemini |
| **State Management** | Zustand |
| **Charts** | Recharts |
| **Animations** | Framer Motion |
| **Icons** | Lucide React |
| **PWA** | next-pwa |
| **Deployment** | Vercel |

---

## 🔐 Authentication & Data Security

SmartSpend was designed as a multi-user application rather than a shared financial dashboard.

```text
                  User
                   │
                   ▼
          Supabase Authentication
                   │
                   ▼
           Authenticated Session
                   │
                   ▼
             SmartSpend
                   │
                   ▼
          PostgreSQL + RLS
                   │
                   ▼
       Only user-owned records
```

Every private financial record is associated with its owner.

PostgreSQL Row Level Security adds protection at the database level instead of relying only on frontend filtering.

Conceptually:

```sql
auth.uid() = user_id
```

This protects transactions, budgets and goals from being accessed by another authenticated user.

---

## 🚀 Getting Started

### Prerequisites

Make sure you have installed:

- Node.js 20+
- npm
- A Supabase project
- A Google Gemini API key

---

### 1. Clone the repository

```bash
git clone https://github.com/OnkarGaikwad-astro/Smart-Spend.git
cd Smart-Spend
```

### 2. Install dependencies

```bash
npm install
```

### 3. Configure environment variables

Create a `.env.local` file in the project root:

```env
NEXT_PUBLIC_SUPABASE_URL=your_supabase_project_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key

GEMINI_API_KEY=your_gemini_api_key
```

> [!IMPORTANT]
> Use the Supabase **project base URL**, for example:
>
> ```text
> https://your-project.supabase.co
> ```
>
> Do not append `/rest/v1/` when using the Supabase JavaScript client.

### 4. Configure the database

The repository contains the SQL required to initialise the Supabase database.

Run the relevant SQL setup scripts from the repository using:

**Supabase Dashboard → SQL Editor**

This creates the required tables and security policies.

### 5. Start the development server

```bash
npm run dev
```

Then open:

```text
http://localhost:3000
```

---

## 🔑 Google Authentication

SmartSpend supports Google OAuth through Supabase.

To enable it locally:

1. Create a Google OAuth application in Google Cloud.
2. Configure the authorised redirect URI.
3. Enable the Google provider in Supabase Authentication.
4. Add the Google Client ID and Client Secret to the Supabase provider configuration.
5. Add your local and production URLs to the allowed redirect URLs.

The authentication flow is:

```text
SmartSpend
    │
    ▼
Supabase Auth
    │
    ▼
Google OAuth
    │
    ▼
Auth Callback
    │
    ▼
SmartSpend Session
```

---

## 📱 Install SmartSpend

You can use SmartSpend directly from your browser or install it as a PWA.

### Android / Chrome

1. Open **https://smartspend.astronkar.in**
2. Open the browser menu.
3. Select **Install app** or **Add to Home Screen**.
4. Launch SmartSpend from your home screen.

### iPhone / Safari

1. Open the live application in Safari.
2. Tap **Share**.
3. Select **Add to Home Screen**.
4. Confirm the installation.

> [!NOTE]
> Features that require the backend or Gemini still require a network connection. Cached application resources can remain available offline depending on what has previously been loaded.

---

## 📂 Project Structure

```text
Smart-Spend/
│
├── public/
│   ├── icons/
│   └── ...
│
├── src/
│   ├── app/
│   │   ├── api/
│   │   │   └── ...
│   │   │
│   │   ├── auth/
│   │   │   └── callback/
│   │   │
│   │   ├── dashboard/
│   │   │   ├── analytics/
│   │   │   ├── budget/
│   │   │   ├── goals/
│   │   │   └── transactions/
│   │   │
│   │   ├── login/
│   │   └── ...
│   │
│   ├── components/
│   │
│   └── lib/
│       ├── supabase/
│       └── store.ts
│
├── supabase-schema.sql
├── WRITEUP.md
├── package.json
└── README.md
```

---

## 🧪 Development Journey

SmartSpend wasn't built as a finished architecture from day one.

It evolved through several stages:

```text
Static UI
    ↓
Mock financial data
    ↓
Real transaction state
    ↓
Supabase persistence
    ↓
Authentication
    ↓
Per-user RLS security
    ↓
Dynamic budgets & analytics
    ↓
Gemini assistant
    ↓
Receipt / screenshot extraction
    ↓
PWA + production deployment
```

That progression exposed several real engineering problems, including authentication and OAuth configuration, Next.js/PWA compatibility, Supabase environment configuration, user-data isolation and deriving budgets from transaction data.

For the detailed engineering decisions, challenges and lessons from building the project:

### 📖 [Read the Technical Write-up →](./WRITEUP.md)

---

## 🗺️ What's Next?

Some directions I would like to explore further:

- [ ] Automatic transaction import
- [ ] AI extraction confidence scores
- [ ] Better receipt/screenshot evaluation dataset
- [ ] Proactive spending insights
- [ ] Budget threshold notifications
- [ ] Recurring payment detection
- [ ] Improved offline transaction synchronisation
- [ ] Comprehensive unit and end-to-end testing
- [ ] More advanced monthly financial reports

---

## 🤝 Contributing

Contributions, bug reports and suggestions are welcome.

If you want to contribute:

```bash
# Fork the repository

git checkout -b feature/your-feature

# Make your changes

git commit -m "feat: add your feature"

git push origin feature/your-feature
```

Then open a Pull Request describing what you changed and why.

---

## 📄 Technical Documentation

Want to know why SmartSpend uses PostgreSQL RLS, how budgets are calculated from transactions, what broke during development, or why AI isn't used for financial calculations?

### → [Read `WRITEUP.md`](./WRITEUP.md)

---

<div align="center">

## 💸 SmartSpend AI

### Know where your money goes before wondering where it went.

<br/>

### **[🌐 Launch SmartSpend](https://smartspend.astronkar.in)**

[GitHub](https://github.com/OnkarGaikwad-astro/Smart-Spend) •
[Technical Write-up](./WRITEUP.md)

<br/>

Built by **Onkar Gaikwad**

</div>