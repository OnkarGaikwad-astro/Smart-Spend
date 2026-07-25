# SmartSpend AI — Technical Write-up

**Live Application:** https://smartspend.astronkar.in  
**GitHub Repository:** https://github.com/OnkarGaikwad-astro/Smart-Spend

## Overview

SmartSpend AI is an AI-powered personal finance tracker designed primarily for college students. The motivation behind the project was to make personal finance management simpler and more useful than manually maintaining spreadsheets or repeatedly entering and analysing expenses.

The application combines traditional expense tracking with AI-assisted workflows. Users can record income and expenses, create category-wise budgets, set savings goals, analyse spending patterns, and interact with an AI financial assistant. One of the key features is an AI-powered receipt and payment screenshot scanner that can extract transaction information from images and reduce the amount of manual data entry required.

The goal was not just to build another expense tracker, but to explore how AI can become a useful layer on top of structured financial data while keeping the core application fast, secure, and usable across devices.

---

## Technical Decisions

### 1. Next.js and TypeScript

I chose Next.js 16 with the App Router as the primary framework because SmartSpend requires both a responsive frontend and server-side functionality for operations such as AI API calls.

Using Next.js allowed me to keep these parts in a single codebase instead of maintaining a separate frontend and backend service.

TypeScript was used throughout the project to provide stronger type safety for financial entities such as transactions, budgets, goals, and API responses. This became especially useful when handling data coming from both Supabase and AI-generated structured responses.

The frontend uses React 19 and Tailwind CSS 4. The UI was designed to be responsive and mobile-friendly because students are more likely to record expenses from their phones than from desktop computers.

### 2. Supabase and PostgreSQL

I selected Supabase as the backend because it provides PostgreSQL, authentication, and authorization while still allowing the application to use a relational data model.

The main financial data is separated into entities such as:

- Transactions
- Budgets
- Savings goals
- User profiles

Each record is associated with an authenticated user.

An important technical decision was implementing PostgreSQL Row Level Security (RLS). Instead of depending only on frontend checks to separate user data, database policies ensure that authenticated users can only select, insert, update, or delete rows belonging to their own account.

This provides an additional security boundary at the database level, which is especially important for an application dealing with personal financial information.

### 3. AI as an Enhancement Rather Than the Database

Google Gemini is integrated into SmartSpend for two major workflows.

The first is the AI Financial Assistant. Instead of showing users only charts and totals, the application allows them to interact with their financial information using natural language. This makes questions such as:

> "How much did I spend on food this month?"

or

> "Where can I reduce my spending?"

much more intuitive.

The second workflow is AI-assisted transaction extraction. Users can upload receipts, bills, or payment screenshots such as PhonePe/GPay screenshots. Gemini analyses the image and extracts structured transaction information that can then be converted into SmartSpend transactions.

A key architectural decision was to keep Supabase as the source of truth. AI is used to interpret and analyse information, but the underlying financial records remain structured database entries. This makes calculations such as totals, budgets, analytics, and goal progress deterministic instead of relying on an LLM for basic financial calculations.

### 4. State Management and Persistence

Zustand was selected for client-side state management because the application has shared state across dashboards, transactions, budgets, goals, and other components without requiring the complexity of a larger state-management framework.

Persistent local storage is also used where appropriate. This improves responsiveness and contributes to the PWA experience while the cloud database remains responsible for authenticated persistent financial data.

### 5. Progressive Web App

SmartSpend was designed as a Progressive Web App rather than only a conventional website.

This allows users to install it on Android/iOS home screens and gives the application a more app-like experience without requiring separate native Android and iOS projects.

Offline caching was introduced for appropriate application resources and previously available information. This was particularly relevant to the target audience because an expense tracker should remain quick to open and useful on mobile devices.

### 6. Analytics and Visualisation

Raw transaction history alone is not particularly useful for understanding financial behaviour, so SmartSpend converts the stored data into visual summaries.

Recharts is used for interactive visualisations such as spending distribution and income-versus-expense trends. The application also compares spending across periods and connects transaction data with category budgets.

The design principle here was to move from:

**recording money → understanding money**

rather than treating transaction entry as the final product.

---

## Challenges Faced

### Reliable AI Output

One of the most interesting challenges was converting unstructured AI responses into information that the application could safely use.

Receipts and payment screenshots vary significantly in layout, image quality, merchant naming, date formats, and the amount of information visible. AI responses also cannot be treated with the same assumptions as normal database responses.

The extraction workflow therefore needed to convert AI interpretation into predictable transaction structures before integrating it into the rest of the application.

This reinforced an important lesson from the project: LLM output should be treated as untrusted input and validated before it affects application state.

### Authentication and Data Isolation

Moving from a prototype expense tracker to a multi-user application introduced another challenge: every financial record had to belong to exactly one authenticated user.

Simply filtering transactions in the frontend would not provide sufficient isolation.

I therefore implemented user ownership directly in the database schema and enabled Row Level Security policies for transactions, budgets, and goals. These policies cover SELECT, INSERT, UPDATE, and DELETE operations.

This required more initial setup but resulted in a much stronger architecture.

### Synchronising Application State and Cloud Data

Financial applications contain many pieces of related information. Adding or deleting a transaction can affect dashboard totals, category spending, analytics, and potentially budget progress.

Keeping the interface responsive while ensuring that the displayed information accurately represents the stored data required careful state management and clear separation between local UI state and persistent data.

### PWA and Offline Behaviour

Making the project installable was relatively straightforward, but deciding what should happen without a network connection was more difficult.

Authentication, cloud synchronisation, and AI requests inherently require connectivity, while cached interface resources and previously available information can still be useful offline.

The challenge was therefore not simply "making the app offline", but deciding which functionality could meaningfully degrade when connectivity disappeared.

### Designing for Financial Data Without Making the UI Feel Heavy

Finance dashboards can quickly become overloaded with numbers, tables, cards, charts, and controls.

A significant part of the project involved finding a balance between information density and simplicity. The dashboard provides an overview first, while detailed transaction, analytics, budget, and goal functionality is separated into dedicated experiences.

Animations and visual effects were added selectively using Framer Motion while maintaining responsiveness across desktop and mobile layouts.

---

## What I Would Do With More Time

The current project provides the foundation of an intelligent personal finance platform, but there are several directions I would explore further.

### Automatic Transaction Import

The largest improvement would be reducing manual expense entry even further.

I would explore secure integrations for importing transaction data from bank statements, email/SMS notifications, or supported financial-data providers. AI could then classify imported transactions automatically while allowing users to review uncertain classifications.

### Smarter Financial Intelligence

The current AI assistant could evolve from a question-answering interface into a proactive financial intelligence system.

For example, it could detect patterns such as:

- unusually high spending in a category,
- recurring subscriptions,
- sudden changes in monthly expenditure,
- projected budget overruns,
- opportunities to reach savings goals earlier.

Instead of requiring users to ask every question, SmartSpend could surface relevant insights automatically.

### Better AI Reliability

For production-scale use, I would introduce stricter structured-output validation around AI-generated data, confidence indicators for receipt extraction, retry/fallback mechanisms, and more comprehensive handling of ambiguous transactions.

I would also build an evaluation dataset containing different types of Indian receipts and payment screenshots to quantitatively measure extraction accuracy rather than evaluating the feature only through manual testing.

### Notifications and Budget Alerts

Another major addition would be push notifications.

Users could receive alerts when they approach a category budget, when unusual spending is detected, when a recurring payment is expected, or when they reach milestones toward savings goals.

### Testing and Observability

With additional development time, I would add a comprehensive testing pipeline covering unit tests, database operations, authentication flows, AI response parsing, and end-to-end user journeys.

I would also introduce better production observability for API errors, AI failures, database latency, and client-side exceptions.

### Scaling the Architecture

For a larger user base, I would further separate deterministic financial calculations from AI operations, introduce stronger caching where appropriate, optimise database queries and indexes, and add rate limiting around expensive AI endpoints.

This would allow the system to scale while preventing AI API usage from becoming a performance or cost bottleneck.

---

## Key Takeaway

The biggest lesson from building SmartSpend was that adding AI to an application is most useful when it removes friction rather than replacing reliable software logic.

Traditional software is still better suited for authentication, storing transactions, enforcing ownership, calculating totals, and tracking budgets. AI becomes valuable at the boundaries where traditional interfaces struggle: understanding receipts, interpreting natural-language questions, and discovering patterns in financial behaviour.

SmartSpend therefore uses a hybrid approach:

**Structured database for truth + deterministic application logic for calculations + AI for interpretation and intelligence.**

That architecture is the direction I would continue developing if I took SmartSpend beyond its current version.