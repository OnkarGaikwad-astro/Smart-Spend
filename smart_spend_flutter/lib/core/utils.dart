import 'package:intl/intl.dart';

class AppUtils {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat _decimalCurrencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static String formatCurrency(num amount, {bool showDecimals = false}) {
    if (showDecimals && (amount % 1 != 0)) {
      return _decimalCurrencyFormat.format(amount);
    }
    return _currencyFormat.format(amount);
  }

  static String formatDateDDMMYYYY(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatDateReadable(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    final time = DateFormat('h:mm a').format(date);

    if (checkDate == today) {
      return 'Today, $time';
    } else if (checkDate == yesterday) {
      return 'Yesterday, $time';
    } else {
      return '${DateFormat('dd/MM/yyyy').format(date)} $time';
    }
  }

  static String getCategoryIcon(String category, {String? type}) {
    switch (category.toLowerCase().trim()) {
      // Expense Categories
      case 'food':
      case 'pizza':
      case 'food delivery':
        return '🍔';
      case 'transport':
      case 'car':
      case 'uber':
        return '🚗';
      case 'subscriptions':
      case 'music':
      case 'spotify':
        return '🎵';
      case 'entertainment':
      case 'movies':
        return '🎬';
      case 'shopping':
      case 'clothes':
        return '🛍️';
      case 'bills':
      case 'utilities':
        return '💡';
      case 'savings':
        return '🐷';

      // Income Categories (Student Focus)
      case 'scholarship':
        return '🎓';
      case 'parents':
        return '👨‍👩‍👧‍👦';
      case 'sister':
        return '👧';
      case 'friends':
        return '🤝';
      case 'salary':
        return '💰';
      case 'freelance':
      case 'briefcase':
        return '💼';
      case 'investment':
        return '📈';
      case 'gift':
        return '🎁';

      // Fallbacks
      case 'receipt':
        return '🧾';
      default:
        return type == 'INCOME' ? '💵' : '📄';
    }
  }
}
