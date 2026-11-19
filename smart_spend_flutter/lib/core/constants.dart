class AppConstants {
  static const String appName = 'SmartSpend';
  static const String appTagline = 'AI-Powered Student Finance';

  // Supabase Configuration
  static const String supabaseUrl = 'https://gyghqthvxxafjayekgxd.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd5Z2hxdGh2eHhhZmpheWVrZ3hkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA4MDcyNTEsImV4cCI6MjA5NjM4MzI1MX0.t-i1asO4donLYttyp31T-7_WmkYt46AQGMsk3mTKTcc';

  // Gemini API Configuration

  // Google OAuth / Sign In Configuration
  // Paste your Google Web Client ID from Google Cloud Console if using native one-tap sign in:
  static const String googleWebClientId =
      '252413389823-5utmjtrqemvc35dvn02fundatj7c2sus.apps.googleusercontent.com';

  // Hive Box Names
  static const String transactionsBox = 'transactions_box';
  static const String budgetsBox = 'budgets_box';
  static const String goalsBox = 'goals_box';
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
