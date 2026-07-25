<div align="center">

# 💸 SmartSpend AI

### Personal finance that helps students understand where their money actually goes.

**Technical Write-up · Project Submission**

[Live Application](https://smartspend.astronkar.in) •
[GitHub Repository](https://github.com/OnkarGaikwad-astro/Smart-Spend)

<br/>

**Next.js · TypeScript · Supabase · PostgreSQL · Gemini · Zustand · Recharts · PWA**

</div>

---

## 👋 About the Project

SmartSpend started from a problem that I see around me as a college student.

A lot of students receive a fixed amount of money from their parents every month. The individual expenses usually don't feel significant:

> ₹120 for food  
> ₹80 for a cab  
> ₹200 for an event  
> ₹149 for a subscription  

But by the end of the month, answering one simple question becomes surprisingly difficult:

> **Where did all my money go?**

I wanted to build something more useful than a digital expense notebook.

SmartSpend therefore combines **transaction tracking, budgets, savings goals, analytics and AI** into one mobile-first Progressive Web Application.

The idea is simple:

```text
Track → Understand → Improve
```

Instead of only recording expenses, SmartSpend tries to help users understand their financial behaviour.

---

## ✨ What SmartSpend Does

| | Feature | What it does |
| :---: | --- | --- |
| 💳 | **Transactions** | Track income and expenses with categories, dates and notes |
| 📊 | **Dashboard** | Shows balance, income, expenses and recent activity |
| 🎯 | **Budgets** | Create monthly category-wise spending limits |
| 🏦 | **Savings Goals** | Track progress towards personal financial goals |
| 📈 | **Analytics** | Visualise spending patterns and category distribution |
| 🤖 | **AI Assistant** | Ask questions about personal spending in natural language |
| 📸 | **AI Scanner** | Extract transaction information from receipts/payment screenshots |
| 🔐 | **Authentication** | Email/password and Google authentication |
| 🛡️ | **User Isolation** | PostgreSQL Row Level Security protects financial records |
| 📱 | **PWA** | Installable mobile-friendly web application |
| 🌙 | **Responsive UI** | Mobile layouts, dark mode and interactive UI |

---

# 🏗️ Architecture

SmartSpend follows a relatively simple architecture where structured financial data remains separate from the AI layer.

```text
                           ┌─────────────────┐
                           │      User       │
                           └────────┬────────┘
                                    │
                                    ▼
                    ┌───────────────────────────┐
                    │       SmartSpend PWA      │
                    │                           │
                    │   Next.js + React + TS    │
                    └─────────────┬─────────────┘
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
                           ┌──────┴──────┐
                           │ PostgreSQL  │
                           │    + RLS    │
                           └──────┬──────┘
                                  │
                  ┌───────────────┼───────────────┐
                  ▼               ▼               ▼
            Transactions       Budgets          Goals
```

### Technology Stack

| Layer | Technology |
| --- | --- |
| Framework | Next.js 16 |
| UI | React 19 + TypeScript |
| Styling | Tailwind CSS 4 |
| Database | PostgreSQL |
| Backend Platform | Supabase |
| Authentication | Supabase Auth + Google OAuth |
| AI | Google Gemini |
| State Management | Zustand |
| Charts | Recharts |
| Animations | Framer Motion |
| PWA | next-pwa / Service Worker |
| Deployment | Vercel |

---

# 🧠 Technical Decisions

## 1. Next.js instead of separate frontend and backend projects

I wanted SmartSpend to remain easy to develop and deploy while still supporting server-side functionality.

Using Next.js allowed the UI, authentication callbacks and API routes to stay in the same project.

This became particularly useful after introducing Gemini because AI requests containing secrets should not simply be made directly from the browser.

Instead of maintaining:

```text
React frontend
      +
Separate backend API
      +
Deployment for both
```

I could keep the application architecture closer to:

```text
              Next.js

       ┌────────┴────────┐
       │                 │
   React UI          API Routes
```

This reduced infrastructure complexity while still keeping sensitive operations server-side.

---

## 2. PostgreSQL + Supabase

Finance data is naturally relational.

A SmartSpend user owns several related types of information:

```text
User
 │
 ├── Transactions
 │
 ├── Budgets
 │
 ├── Savings Goals
 │
 └── Profile
```

PostgreSQL was therefore a natural fit.

I chose Supabase because it provided PostgreSQL together with authentication, Row Level Security and a JavaScript SDK that integrates well with Next.js.

---

## 3. Security at the database level

One of the biggest architectural changes during development happened when SmartSpend moved from a single-user prototype to an actual multi-user application.

Initially it was tempting to think that filtering data in the frontend would be enough:

```ts
transactions.filter(
  transaction => transaction.userId === currentUser.id
);
```

But this only changes what the interface displays.

It does **not** provide a strong security boundary.

Financial data should not depend on the browser behaving correctly.

So every private record is associated with a user and PostgreSQL **Row Level Security (RLS)** is used to enforce ownership.

Conceptually:

```sql
auth.uid() = user_id
```

This means authentication and authorisation are treated as two separate questions:

```text
Authentication
     │
     └── Who is this user?

Authorisation / RLS
     │
     └── Which records may this user access?
```

Even if someone bypasses the frontend and attempts a direct request, the database still evaluates whether that authenticated user owns the requested rows.

For a finance application, this was one of the most important technical decisions in the project.

---

# 🤖 How I Used AI

I did not want SmartSpend to become an application where every feature was unnecessarily routed through an LLM.

Instead, I use AI mainly when the input or question is **unstructured**.

My basic rule became:

> **Database for truth. Code for calculations. AI for interpretation.**

---

## AI Financial Assistant

A normal analytics dashboard requires the user to find the correct chart, filter it and interpret the result.

SmartSpend also allows users to ask questions directly.

For example:

```text
"How much did I spend on food?"

"Where am I spending the most?"

"How much did I save this month?"

"How can I reduce my expenses?"
```

The assistant receives relevant financial context and can turn the underlying transaction information into a natural-language explanation.

The database still remains the source of truth.

---

## 📸 Receipt & Payment Screenshot Scanner

Manual transaction entry is one of the biggest friction points in expense trackers.

So I experimented with allowing users to provide a receipt or payment screenshot.

The pipeline is roughly:

```text
          Receipt / Payment Screenshot
                      │
                      ▼
               Gemini Analysis
                      │
                      ▼
            Structured Information
                      │
            ┌─────────┼─────────┐
            ▼         ▼         ▼
          Amount   Merchant    Date
                      │
                      ▼
                  Category
                      │
                      ▼
               User confirmation
                      │
                      ▼
                 Transaction
```

Instead of expecting AI output to become financial truth immediately, the extracted information can be converted into the structured transaction model used by the rest of SmartSpend.

This keeps AI at the edge of the system rather than at its foundation.

---

# 🧩 State Management

I chose **Zustand** for shared client-side state.

The application needs several pieces of information across different pages:

```text
transactions
budgets
goals
user/session
loading state
error state
```

I did not feel that this required a larger state-management architecture.

Zustand gave me a small central store without adding much boilerplate.

Where appropriate, the UI can also update optimistically.

```text
             Add Transaction
                    │
              ┌─────┴─────┐
              │           │
              ▼           ▼
       Update UI       Save to DB
       immediately         │
                           ▼
                      success/error
```

The result is that normal actions feel immediate rather than forcing the user to wait for every network round trip.

---

# 📊 Budgets and Analytics

One surprisingly important change happened in the budget system.

An early approach effectively treated this:

```text
Food Budget: ₹5,000
Spent:       ₹3,200
```

as two values.

But `₹3,200` should not need to be entered independently.

The transactions already contain the truth.

I changed the system so budget utilisation is derived from the user's actual transactions for the corresponding category and month.

```text
             FOOD TRANSACTIONS

              ₹280
              ₹120
              ₹450
              ₹200
                │
                ▼
             SUM(...)
                │
                ▼
           ₹1,050 spent
                │
                ▼
       Food Budget Progress
```

Now adding another Food transaction automatically changes the relevant budget utilisation.

I followed the same principle for analytics.

Instead of displaying a predetermined spending curve, transaction dates and amounts are used to generate the timeline.

This reinforced a useful database principle for me:

> **If something can reliably be calculated from your source data, avoid maintaining another manually editable copy of it.**

---

# 📱 Why a PWA?

SmartSpend is intended to be used when spending actually happens.

That usually means:

**on a phone.**

Building independent Android, iOS and web clients would have increased the scope considerably, so I chose a Progressive Web Application.

This gives SmartSpend an installable, app-like experience while retaining a single web codebase.

```text
              SmartSpend
                   │
         ┌─────────┼─────────┐
         ▼         ▼         ▼
       Desktop    Mobile   Installed PWA
```

Cached application resources can remain available when connectivity is poor, while features that fundamentally require the internet, such as cloud synchronisation or Gemini requests, can degrade gracefully.

---

# 🎨 UI / UX Decisions

Finance dashboards can become visually exhausting very quickly.

There are balances, percentages, transactions, categories, charts, budgets, goals and alerts competing for attention.

I therefore tried to give every section a clear job.

```text
Dashboard
   │
   └── "What is happening?"

Transactions
   │
   └── "Where did the money go?"

Budgets
   │
   └── "Am I spending too much?"

Analytics
   │
   └── "What patterns exist?"

Goals
   │
   └── "What am I saving towards?"

AI
   │
   └── "Explain my finances to me."
```

The interface uses cards, restrained glassmorphism, responsive layouts and small Framer Motion interactions.

I tried to keep animation functional rather than decorative. Button presses and transitions should make the interface feel responsive, not make users wait for the interface to finish performing.

---

# 🐛 Challenges & Things That Actually Broke

SmartSpend definitely did not go from:

```bash
npm install
```

to production without resistance.

Some of the most useful learning happened because things broke.

---

## 01 · Next.js + Windows + PWA

One of the earliest major problems happened before the application logic was even finished.

The development server started throwing:

```text
Attempted to load @next/swc-win32-x64-msvc

next-swc.win32-x64-msvc.node
is not a valid Win32 application.
```

At the same time:

```text
Failed to load next.config.ts

ReferenceError: require is not defined
```

Initially this looked like one problem.

It was actually several.

### Root causes

- the Windows SWC installation had become corrupted;
- the PWA configuration was mixing module styles;
- Next.js 16 was using Turbopack while the PWA configuration behaved better with Webpack.

### What I changed

I reinstalled the affected Next.js packages, corrected the module import in the Next.js configuration and explicitly used Webpack where required.

The useful lesson was that tooling errors often cascade.

The first visible error is not necessarily the root cause.

---

## 02 · From Mock Data to a Real Application

The first dashboard looked good because the data was predictable.

There was one problem:

**it wasn't the user's data.**

A mock dashboard can happily display:

```text
Income       ₹18,500
Expenses     ₹12,840
Savings      ₹5,660
```

even for someone who created their account ten seconds ago.

That made SmartSpend look more complete while actually making it less real.

I eventually removed the dependence on hard-coded financial data and moved the application towards real Supabase-backed state.

This also forced me to design proper empty states.

```text
┌──────────────────────────────────┐
│                                  │
│        No transactions yet       │
│                                  │
│  Add your first transaction to   │
│  start building your dashboard.  │
│                                  │
│       [ + Add Transaction ]      │
│                                  │
└──────────────────────────────────┘
```

A blank account now has a reason to be blank.

That sounds obvious in retrospect, but it was an important transition from **demo UI** to **actual product behaviour**.

---

## 03 · Supabase Configuration

I also spent time debugging what looked like a database connection issue.

Part of the problem was surprisingly simple.

The credentials had initially ended up in:

```text
.env.example
```

instead of:

```text
.env.local
```

I had also used a Supabase URL containing:

```text
/rest/v1/
```

The JavaScript client expects the project base URL instead:

```text
https://<project>.supabase.co
```

because the SDK constructs the required endpoint paths itself.

After correcting the environment file and URL, the development server also needed to be restarted because Next.js reads those variables when starting.

This was one of those bugs where almost all of the application code was correct while a few characters in configuration stopped everything underneath it.

---

## 04 · Securing Data Per User

Authentication introduced another problem.

A login page alone doesn't make data private.

I needed to guarantee that:

```text
Student A ──X──> Student B's transactions
Student B ──X──> Student A's budgets
```

The schema was therefore changed so private records belong to an authenticated `user_id`.

RLS policies then enforce ownership.

Protected dashboard routes add another layer by redirecting unauthenticated visitors before they reach private application pages.

This required more work than simply adding login/signup, but it gave SmartSpend a much stronger foundation.

---

## 05 · Google OAuth

Google Sign-In looked simple from the UI:

```text
┌──────────────────────────┐
│  G   Continue with Google │
└──────────────────────────┘
```

The system behind that button was less simple.

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
Authorised Redirect URI
    │
    ▼
SmartSpend Callback
    │
    ▼
Token Exchange
    │
    ▼
Authenticated Session
```

The Google Cloud configuration, Supabase provider settings, callback URL and application redirect behaviour all needed to agree.

At one stage, the OAuth flow appeared to proceed while the user was not being stored/returned as expected.

Working through that problem gave me a much better understanding of OAuth than simply copying a sign-in component would have.

I later added profile handling so authenticated users could also have application-specific profile data and personalised dashboard information.

---

## 06 · Budget Calculations Were Initially Wrong Architecturally

Initially, budget spending was too disconnected from actual transaction history.

That would eventually create situations where:

```text
Transactions say: ₹3,750 spent on Food

Budget says:      ₹3,200 spent on Food
```

Both cannot be the source of truth.

So I changed the budget logic to calculate spending directly from matching transactions for the current period.

Now:

```text
Transaction added
      │
      ├──► Dashboard updates
      │
      ├──► Analytics updates
      │
      └──► Budget usage updates
```

One event affects every view that derives information from that transaction.

---

## 07 · A Very Small but Very Visible Bug

Not every bug involved architecture.

Transaction icons provided a much smaller example.

Some stored icon identifiers were strings such as:

```text
briefcase
pizza
music
```

Unfortunately, the UI placed them inside tiny icon containers.

The result was essentially:

```text
┌──────┐
│ brie │fcase
└──────┘
```

The identifier escaped the icon like it had somewhere important to be.

I added a mapping layer that converts those stored identifiers into appropriate visual icons/emoji before rendering them.

Tiny bug.

Very visible bug.

Also a useful reminder that polish is mostly the accumulation of fixing small things.

---

# 🔐 Security Model

The final security flow can be thought of as:

```text
                    User
                     │
                     ▼
            ┌─────────────────┐
            │ Supabase Auth   │
            └────────┬────────┘
                     │
                     ▼
             Authenticated User
                     │
                     ▼
            ┌─────────────────┐
            │ Protected Route │
            └────────┬────────┘
                     │
                     ▼
              Supabase Client
                     │
                     ▼
            ┌─────────────────┐
            │ PostgreSQL RLS  │
            └────────┬────────┘
                     │
                     ▼
           Rows owned by that user
```

This gives the application multiple boundaries instead of relying entirely on UI checks.

---

# 🚀 What I Would Do With More Time

SmartSpend has reached the point where the core product works, but there are several directions I would explore next.

---

## 1. Reduce manual transaction entry further

The receipt scanner reduces friction, but the ideal expense tracker requires even less manual work.

I would explore secure ways of importing transactions from supported financial-data sources, statements or notification information.

The ideal flow would become:

```text
Payment
   │
   ▼
Transaction detected/imported
   │
   ▼
Category suggested
   │
   ▼
User confirms if necessary
   │
   ▼
SmartSpend
   │
   ├──► Budget
   ├──► Analytics
   └──► Insights
```

---

## 2. Confidence-aware AI extraction

An AI model should not be treated as equally certain about every field.

Instead of:

```text
Amount:   ₹430
Merchant: Swiggy
Date:     24 July
```

I would eventually like the scanner to behave more like:

```text
┌────────────────────────────────────┐
│ AI Extraction                     │
├────────────────────────────────────┤
│ Amount       ₹430           99% ✓  │
│ Merchant     Swiggy         96% ✓  │
│ Category     Food           91% ✓  │
│ Date         24 July        71% ⚠  │
└────────────────────────────────────┘

          [ Review & Add ]
```

Low-confidence fields could be highlighted before saving.

---

## 3. Build a real evaluation set for receipt scanning

Testing five screenshots manually tells me whether the feature *seems* to work.

It doesn't tell me how well it works.

I would create an evaluation dataset containing:

- UPI payment screenshots
- restaurant receipts
- shopping receipts
- blurry images
- low-light photographs
- cropped screenshots
- different date formats
- receipts containing multiple totals

Then I could measure extraction accuracy field-by-field.

```text
Amount Accuracy       97%
Merchant Accuracy     91%
Date Accuracy         88%
Category Accuracy     90%
```

That would turn AI improvement from guesswork into something measurable.

---

## 4. Proactive financial intelligence

Currently the AI assistant mainly responds when the user asks something.

I would like SmartSpend to eventually identify useful information itself.

For example:

> ⚠️ **Food spending is unusually high**  
> You've spent 32% more on food this week than your recent average.

or:

> 📈 **Budget forecast**  
> At your current spending rate, your Entertainment budget may run out six days before the end of the month.

That would move SmartSpend from an expense tracker toward a lightweight financial assistant.

---

## 5. Better notifications

Budget information becomes much more useful when it arrives at the right time.

Examples:

```text
⚠️ Food budget is 80% used

🚨 Entertainment budget is 95% used

🎯 Laptop savings goal reached 75%

📊 Your monthly report is ready
```

---

## 6. Stronger automated testing

If I continued developing SmartSpend, testing would be one of my highest priorities.

I would add automated coverage for:

```text
Authentication
      │
      ├── Email login
      ├── Google OAuth
      └── Session handling

Database
      │
      ├── RLS isolation
      ├── Transaction CRUD
      ├── Budgets
      └── Goals

Finance Logic
      │
      ├── Totals
      ├── Budget utilisation
      └── Analytics

AI
      │
      ├── Response validation
      └── Receipt extraction

End-to-End
      │
      └── Complete mobile user flow
```

For financial software especially, correctness matters more than a dashboard merely looking correct.

---

# 💡 What I Learned

SmartSpend started as a fairly simple idea:

> *Build an expense tracker for college students.*

The interesting problems appeared once I tried to make it behave like a real application.

I ended up learning much more about:

- authentication vs authorisation,
- PostgreSQL Row Level Security,
- OAuth redirects and callbacks,
- relational financial data,
- derived vs stored values,
- state synchronisation,
- optimistic UI,
- Next.js server/client boundaries,
- PWA compatibility,
- AI structured output,
- responsive financial dashboards,
- and production deployment.

Most importantly, the project changed how I think about adding AI to software.

It is tempting to put the model in the centre:

```text
Everything
    │
    ▼
   AI
    │
    ▼
Result
```

SmartSpend ended up closer to:

```text
                    SmartSpend

        ┌──────────────┼──────────────┐
        │              │              │
        ▼              ▼              ▼
   PostgreSQL     Application       Gemini
      Truth          Logic       Interpretation
        │              │              │
        └──────────────┼──────────────┘
                       ▼
                     User
```

That separation makes the application easier to reason about.

---

# 🎯 Final Takeaway

If I had to summarise the architecture of SmartSpend in one line, it would be:

> ### **Structured data for truth. Deterministic code for calculations. AI for interpretation.**

A language model is useful for understanding a messy receipt.

It is useful for translating transaction history into a natural explanation.

It can help identify patterns that would otherwise be tedious to find.

But the user's balance, transaction ownership and budget calculations should remain deterministic and verifiable.

That distinction became the most important technical lesson I took away from building SmartSpend.

---

## ✅ Current Project Status

```text
Authentication          ████████████████████  DONE
Transaction CRUD        ████████████████████  DONE
Per-user data security  ████████████████████  DONE
Budget tracking         ████████████████████  DONE
Savings goals           ████████████████████  DONE
Analytics               ████████████████████  DONE
AI assistant            ████████████████████  DONE
AI receipt scanner      ████████████████████  DONE
PWA                     ████████████████████  DONE
Responsive UI           ████████████████████  DONE
```

---

<div align="center">

## 💸 SmartSpend AI

### *Know where your money goes before wondering where it went.*

<br/>

**[🌐 Try SmartSpend](https://smartspend.astronkar.in)**  
**[💻 Explore the Source Code](https://github.com/OnkarGaikwad-astro/Smart-Spend)**

<br/>

Built by **Onkar Gaikwad**

</div>