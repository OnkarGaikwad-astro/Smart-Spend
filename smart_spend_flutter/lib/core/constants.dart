class AppConstants {
  static const String appName = 'SmartSpend';
  static const String appTagline = 'Smart Personal Finance & Wealth Tracker';

  // App Versioning & Release
  static const String appVersion = '1.0.0';
  static const int appBuildNumber = 1;
  static const String githubRepo = 'OnkarGaikwad-astro/SmartSpend-flutter';
  static const String githubReleasesUrl = 'https://github.com/OnkarGaikwad-astro/SmartSpend-flutter/releases/latest';
  static const String githubReleasesApiUrl = 'https://api.github.com/repos/OnkarGaikwad-astro/SmartSpend-flutter/releases/latest';

  // Supabase Configuration
  // Can be overridden at build time via: --dart-define=SUPABASE_URL=https://...
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://gyghqthvxxafjayekgxd.supabase.co',
  );

  // Can be overridden at build time via: --dart-define=SUPABASE_ANON_KEY=eyJ...
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd5Z2hxdGh2eHhhZmpheWVrZ3hkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA4MDcyNTEsImV4cCI6MjA5NjM4MzI1MX0.t-i1asO4donLYttyp31T-7_WmkYt46AQGMsk3mTKTcc',
  );

  // Gemini API Configuration
  // Pass at build time via: --dart-define=GEMINI_API_KEY=...
  // Or via untracked secrets file: --dart-define-from-file=secrets.json
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  // Google OAuth / Sign In Configuration
  // Can be overridden at build time via: --dart-define=GOOGLE_WEB_CLIENT_ID=...
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '252413389823-5utmjtrqemvc35dvn02fundatj7c2sus.apps.googleusercontent.com',
  );

  // Hive Box Names
  static const String transactionsBox = 'transactions_box';
  static const String budgetsBox = 'budgets_box';
  static const String goalsBox = 'goals_box';
  static const String debtsBox = 'debts_box';
  static const String profileBox = 'profile_box';
  static const String syncQueueBox = 'sync_queue_box';
  static const String settingsBox = 'settings_box';

  // Categories
  static const List<String> defaultExpenseCategories = [
    'Food',
    'Transport',
    'Subscriptions',
    'Entertainment',
    'Shopping',
    'Bills',
    'Savings',
    'Other',
  ];

  static const List<String> defaultIncomeCategories = [
    'Scholarship',
    'Parents',
    'Sister',
    'Friends',
    'Salary',
    'Freelance',
    'Investment',
    'Gift',
    'Other',
  ];
}
