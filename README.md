# SmartSpend AI

**AI-powered personal finance tracking built for students.**

SmartSpend is a full-stack Progressive Web App for tracking expenses, managing budgets, setting savings goals, and understanding spending patterns with AI-assisted insights.

🌐 **[Live Demo](https://smartspend.astronkar.in)**  
💻 **[GitHub](https://github.com/OnkarGaikwad-astro/Smart-Spend)**

**Next.js 16 · React 19 · TypeScript · Supabase · PostgreSQL · Gemini · Zustand · PWA**

---

## Overview

Managing everyday expenses can become difficult when transactions are spread across food, travel, subscriptions, UPI payments, and other small purchases.

SmartSpend brings these workflows into one application:

```text
Transactions
     ↓
Budgets & Goals
     ↓
Financial Analytics
     ↓
AI-assisted Insights
```

The application combines **deterministic financial logic** with AI where language understanding is useful. Financial records, balances, budgets, and ownership remain structured and database-backed rather than being calculated by an LLM.

---

## Key Features

### 💳 Expense & Income Tracking

- Record income and expenses
- Categorize transactions
- Track current balance
- View recent financial activity
- Manage transactions through a unified dashboard

### 💰 Budget Management

- Create category-based monthly budgets
- Track budget utilisation from actual transactions
- Compare spending against configured limits

### 🎯 Savings Goals

- Create savings targets
- Track progress toward individual goals
- Connect financial activity with long-term targets

### 📊 Financial Analytics

- Category-based spending breakdowns
- Timeline-based expense trends
- Income and expense summaries
- Visual analysis of spending behaviour

### 🤖 Gemini-Powered AI Features

SmartSpend integrates Google Gemini for tasks where natural-language understanding is useful.

Examples include:

- AI-assisted spending analysis
- Financial questions using natural language
- Budgeting recommendations
- Transaction insights
- Receipt and payment screenshot extraction

Example queries:

```text
"Where did I spend the most this month?"

"How much have I spent on food?"

"How can I reduce my expenses?"
```

### 📸 Receipt & Payment Scanner

Users can upload receipts, bills, or payment screenshots.

```text
Receipt / Screenshot
        ↓
   Gemini Analysis
        ↓
 ┌─────────────────┐
 │ Amount          │
 │ Merchant        │
 │ Date            │
 │ Category        │
 └────────┬────────┘
          ↓
     Transaction
```

This reduces repetitive manual transaction entry.

### 📱 Progressive Web App

SmartSpend is installable as a PWA and provides an app-like experience directly from a browser.

The application uses cached resources to remain accessible during limited connectivity. Features requiring Supabase or Gemini still require a network connection.

---

## Architecture

```text
                         ┌──────────────┐
                         │     User     │
                         └──────┬───────┘
                                │
                                ▼
                    ┌─────────────────────┐
                    │   SmartSpend PWA    │
                    │ Next.js + React + TS│
                    └──────────┬──────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
              ▼                ▼                ▼
       ┌────────────┐   ┌────────────┐   ┌────────────┐
       │  Zustand   │   │  Supabase  │   │   Gemini   │
       │    State   │   │ Auth + API │   │     AI     │
       └────────────┘   └──────┬─────┘   └────────────┘
                               │
                               ▼
                       ┌──────────────┐
                       │  PostgreSQL  │
                       │     + RLS    │
                       └──────┬───────┘
                              │
                  ┌───────────┼───────────┐
                  ▼           ▼           ▼
             Transactions  Budgets      Goals
```

### Design principle

> **Structured data for truth. Deterministic code for calculations. AI for interpretation.**

This separation keeps financial calculations predictable while allowing Gemini to handle tasks such as natural-language analysis and information extraction.

---

## Authentication & Data Security

Authentication is handled through **Supabase Auth**.

Financial records are protected using **PostgreSQL Row-Level Security (RLS)**.

```text
User
 │
 ▼
Supabase Auth
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
User-owned records
```

Database policies enforce ownership at the database layer rather than relying only on frontend filtering.

Conceptually:

```text
auth.uid() = user_id
```

This applies to user-owned financial data such as transactions, budgets, and savings goals.

---

## Tech Stack

| Category | Technologies |
|---|---|
| Framework | Next.js 16 |
| Frontend | React 19, TypeScript |
| Styling | Tailwind CSS |
| Database | PostgreSQL |
| Backend | Supabase |
| Authentication | Supabase Auth, Google OAuth |
| AI | Google Gemini |
| State Management | Zustand |
| Charts | Recharts |
| Animations | Framer Motion |
| PWA | next-pwa |
| Deployment | Vercel |

---

## Project Structure

```text
Smart-Spend/
├── public/
│   └── icons/
│
├── src/
│   ├── app/
│   │   ├── api/
│   │   ├── auth/
│   │   ├── dashboard/
│   │   │   ├── analytics/
│   │   │   ├── budget/
│   │   │   ├── goals/
│   │   │   └── transactions/
│   │   └── login/
│   │
│   ├── components/
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

## Getting Started

### Prerequisites

- Node.js 20+
- npm
- Supabase project
- Google Gemini API key

### 1. Clone

```bash
git clone https://github.com/OnkarGaikwad-astro/Smart-Spend.git
cd Smart-Spend
```

### 2. Install dependencies

```bash
npm install
```

### 3. Configure environment variables

Create `.env.local`:

```env
NEXT_PUBLIC_SUPABASE_URL=your_supabase_project_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
GEMINI_API_KEY=your_gemini_api_key
```

Do not commit real credentials to the repository.

### 4. Configure Supabase

Run the SQL setup scripts from the repository through:

**Supabase Dashboard → SQL Editor**

This creates the required database structures and security policies.

### 5. Start development server

```bash
npm run dev
```

Open:

```text
http://localhost:3000
```

---

## Development Journey

SmartSpend evolved incrementally rather than starting with the final architecture.

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
Per-user RLS
   ↓
Budgets & analytics
   ↓
Gemini integration
   ↓
Receipt / screenshot extraction
   ↓
PWA deployment
```

Some of the main engineering challenges involved:

- Authentication and OAuth configuration
- Supabase environment configuration
- Per-user database security
- Keeping financial calculations deterministic
- PWA behaviour and cached resources
- Connecting AI-generated information to structured application data

---

## Engineering Approach

A core design decision was to avoid using an LLM for calculations that should be deterministic.

For example:

```text
Financial records
      ↓
PostgreSQL
      ↓
Application logic
      ↓
Exact calculations
```

while:

```text
User question / receipt
        ↓
      Gemini
        ↓
Interpretation / extraction
        ↓
Structured application data
```

This keeps the AI layer useful without making it the source of truth for financial state.

---

## Future Improvements

- Automatic transaction import
- AI extraction confidence scores
- Improved receipt/screenshot evaluation
- Proactive spending insights
- Budget threshold notifications
- Recurring payment detection
- Improved offline transaction synchronisation
- More comprehensive automated testing
- Advanced monthly financial reports

---

## Documentation

For a deeper look at the architecture, engineering decisions, and development challenges:

**[Read the Technical Write-up](WRITEUP.md)**

---

## License

This project is licensed under the MIT License.

---

## Author

**Onkar Gaikwad**

[GitHub](https://github.com/OnkarGaikwad-astro) · [Portfolio](https://portfolio.astronkar.in)