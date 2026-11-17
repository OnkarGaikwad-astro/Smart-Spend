# SmartSpend AI — Flutter Mobile & Desktop App

A complete, pixel-perfect, offline-first cross-platform Flutter application for **SmartSpend AI**, matching every feature, design token, color theme, and functionality of the Next.js web application.

---

## 🌟 Key Features & Capabilities

### 1. 100% Feature Parity with Web App
- **Overview Dashboard**:
  - 4 Real-time Metric Cards: **Total Balance**, **Total Income**, **Total Expenses**, and **Savings Rate %**.
  - **Spending Overview Bar Chart**: Interactive 6-month comparison of Income vs Expenses with tooltip breakdowns.
  - **Recent Transactions**: Instant feed with category emoji avatars, relative time (`Today, 2:30 PM`), and colored Rupee amounts (+/-).
- **Transactions Screen**:
  - Full search by merchant title or category name.
  - Category filter chips (All, Food, Transport, Subscriptions, Entertainment, Shopping, Bills, etc.).
  - Total spent computation for current filtered subset.
  - **Date Range CSV Export**: Export transactions to CSV and share/save anywhere using native share sheets.
  - Tap any transaction to edit or delete it.
- **Budget & Savings Goals**:
  - **Monthly Budget Card**: Shows total allocated, used, and remaining funds with Ocean gradient styling.
  - **Budget Utilization**: Color-coded progress bar (shifts from teal/cyan to amber at >75% and red at >90%).
  - **Dynamic Category Budgets**: Spent amount is dynamically calculated from actual transactions matching the category in the current month!
  - **Savings Goals**: Track target amount, saved balance, target date, and animated progress.
  - **+ Deposit Modal**: Deposit funds into goals with one tap; automatically records a deducted expense under "Savings".
  - **🧹 Auto-Sweep Leftover to Goals**: Automatically calculates leftover income, evenly divides it across all active goals, and deposits with a single click.
- **Analytics & Insights**:
  - Time range toggle: **This Month** vs. **Last Month**.
  - **Activity Heatmap**: 28-31 day calendar intensity grid showing spending distribution.
  - **Spending Trend Line Chart**: Daily expenditure timeline with curved gradients and tooltips.
  - **Category Breakdown Donut Chart**: Proportional category distribution with colored legend badges.
  - Analytics CSV export.
- **Aurex AI Financial Assistant**:
  - Floating AI assistant widget powered by **Google Gemini AI**.
  - Injects full user financial context (balance, income, expenses, transactions, goals) so Aurex can answer questions like *"How much did I spend this week?"*, *"Can I afford dinner out?"*, and give student finance tips.
- **AI Receipt & Bill Scanner**:
  - Use Camera or Gallery to scan PhonePe/GooglePay receipts, bills, and payment SMS screenshots.
  - Gemini AI extracts merchant title, positive amount, detected category, and transaction date, autofilling the form with zero manual typing.
- **User Profile & Settings**:
  - Edit full name and see avatar/initials.
  - Live Sync Queue status badge showing pending offline changes.
  - Manual sync trigger button.
  - Dark mode / Light mode toggle.
  - Secure sign out.

---

## ⚡ Offline-First Architecture & Sync Queue

SmartSpend Flutter uses a **Local-First, Cloud-Synced** architecture designed to work seamlessly with zero internet connection:

```
┌────────────────────────────────────────────────────────┐
│                   Flutter UI (Provider)                │
└───────────────────────────┬────────────────────────────┘
                            │ (Instant UI updates - 0ms latency)
                            ▼
┌────────────────────────────────────────────────────────┐
│                Hive Local Database (NoSQL)             │
│  - transactions_box   - budgets_box    - goals_box     │
│  - profile_box        - settings_box   - sync_queue    │
└───────────────────────────┬────────────────────────────┘
                            │ Enqueues CRUD operations
                            ▼
┌────────────────────────────────────────────────────────┐
│                  Sync Queue Engine                     │
│  (Monitors network via connectivity_plus)              │
│  - When Offline: Accumulates queued mutations safely   │
│  - When Online: Flushes queue sequentially to Supabase │
│  - Pulls latest remote updates and reconciles local    │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│               Supabase Cloud Database & Auth           │
│  - RLS Policies & Auth Token persistence               │
└────────────────────────────────────────────────────────┘
```

1. **Local-First Writes**: When adding, editing, or deleting transactions, budgets, or goals, the data is immediately saved to local **Hive boxes**. The UI updates instantly with zero network delay.
2. **Persistent Sync Queue**: Every mutation operation (`insert`, `update`, `delete`) is recorded in a persistent `sync_queue_box` with its table name, record ID, and payload.
3. **Automatic Online Flush**: `SyncService` monitors network status via `connectivity_plus`. When connectivity is restored, it sequentially replays the queued mutations against the Supabase REST API and removes completed operations from the queue.
4. **Offline Auth Gatekeeper**: Cached profile and auth tokens allow users to reopen and use the app fully offline without being locked out.

---

## 🎨 Ocean Coast Theme Tokens

The app accurately replicates the High Contrast Ocean Coast color system from `globals.css`:

| Token | Light Mode | Dark Mode | Usage |
|---|---|---|---|
| **Background** | `#F6F6E9` (Light Cream) | `#0B1115` | App scaffold background |
| **Primary** | `#447A9C` (Dark Ocean) | `#6CA5CA` | Primary buttons, headers, accents |
| **Secondary** | `#7DA2C8` (Steel Blue) | `#95BEE8` | Incomes, charts, badges |
| **Accent** | `#8DBEDE` (Sky Blue) | `#AED8F7` | Warning states, highlights |
| **Surface** | `#EAF1F7` | `#14232D` | Cards, bottom sheets, dialogs |
| **Surface 2** | `#D7E5F1` | `#1E3241` | Input fields, active chips |
| **Border Subtle** | `#C3D8EA` | `#325064` | Subtle card & divider borders |
| **Text Main** | `#2A4B61` | `#E2EEF8` | Primary readable typography |
| **Text Muted** | `#5C7F9B` | `#8AAEC9` | Labels, trends, timestamps |
| **Danger** | `#EF4444` | `#F87171` | Expenses, alerts, deletes |
| **Success** | `#10B981` | `#34D399` | Incomes, positive balances |

---

## 🚀 Getting Started & Running the App

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.24+ recommended)
- Dart SDK 3.5+

### Installation & Execution
```bash
# Navigate to the Flutter project folder
cd smart_spend_flutter

# Fetch dependencies
flutter pub get

# Run on an attached device, emulator, or Windows desktop
flutter run

# Or run specifically on Windows desktop
flutter run -d windows

# Or run on Chrome
flutter run -d chrome
```

---

## 📁 Project Structure

```
smart_spend_flutter/
├── assets/
│   └── icon.png                  # SmartSpend App Icon
├── lib/
│   ├── core/
│   │   ├── constants.dart        # Supabase keys, Gemini key, Box names
│   │   └── utils.dart            # Currency (₹), date formats, category icons
│   ├── theme/
│   │   └── app_theme.dart        # Ocean Coast theme tokens (Light & Dark)
│   ├── models/
│   │   ├── transaction_model.dart
│   │   ├── budget_model.dart
│   │   ├── goal_model.dart
│   │   ├── user_profile_model.dart
│   │   └── sync_queue_item.dart
│   ├── services/
│   │   ├── storage_service.dart  # Hive database CRUD operations
│   │   ├── sync_service.dart     # Offline queue engine & connectivity listener
│   │   └── gemini_service.dart   # Aurex AI chat & Receipt OCR extractor
│   ├── providers/
│   │   ├── auth_provider.dart    # Supabase auth & session management
│   │   └── app_provider.dart     # Global state matching Zustand store
│   ├── widgets/
│   │   ├── offline_banner.dart
│   │   ├── overview_card.dart
│   │   ├── transaction_item_tile.dart
│   │   ├── add_transaction_dialog.dart
│   │   ├── budget_dialog.dart
│   │   ├── goal_dialog.dart
│   │   ├── deposit_dialog.dart
│   │   ├── profile_dialog.dart
│   │   └── ai_assistant_sheet.dart
│   ├── screens/
│   │   ├── auth/
│   │   │   └── login_screen.dart
│   │   └── dashboard/
│   │       ├── dashboard_shell.dart
│   │       ├── overview_tab.dart
│   │       ├── transactions_tab.dart
│   │       ├── budget_tab.dart
│   │       └── analytics_tab.dart
│   └── main.dart                 # Root App Entrypoint & Gatekeeper
└── pubspec.yaml
```
