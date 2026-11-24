import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../models/debt_model.dart';

class AppUtils {
  static String currentCurrencySymbol = '₹';
  static bool hideBalances = false;

  static final NumberFormat _formatter = NumberFormat('#,##,##0', 'en_IN');
  static final NumberFormat _decimalFormatter = NumberFormat('#,##,##0.00', 'en_IN');

  static String formatCurrency(num amount, {bool showDecimals = false}) {
    if (hideBalances) return '••••••';
    final sign = amount < 0 ? '-' : '';
    final absAmount = amount.abs();
    final formatted = showDecimals && (absAmount % 1 != 0)
        ? _decimalFormatter.format(absAmount)
        : _formatter.format(absAmount);
    return '$sign$currentCurrencySymbol$formatted';
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
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

  /// Generate CSV data export for transactions and debts
  static String generateCsvExport({
    required List<TransactionModel> transactions,
    required List<DebtModel> debts,
  }) {
    final buffer = StringBuffer();
    // 1. Transactions Header
    buffer.writeln('--- SMART_SPEND TRANSACTIONS EXPORT ---');
    buffer.writeln('Date,Type,Title,Category,Amount ($currentCurrencySymbol),Notes');
    for (final t in transactions) {
      final date = DateFormat('yyyy-MM-dd HH:mm').format(t.date);
      final type = t.type;
      final title = '"${t.title.replaceAll('"', '""')}"';
      final category = '"${t.category.replaceAll('"', '""')}"';
      final amount = t.amount.toStringAsFixed(2);
      buffer.writeln('$date,$type,$title,$category,$amount');
    }

    buffer.writeln('');
    // 2. Debts / Khata Header
    buffer.writeln('--- KHATA & DEBTS EXPORT ---');
    buffer.writeln('Person,Direction,Net Balance ($currentCurrencySymbol),Status,Phone');
    for (final d in debts) {
      final person = '"${d.personName.replaceAll('"', '""')}"';
      final dir = d.type;
      final net = d.totalOwed.toStringAsFixed(2);
      final status = d.isSettled ? 'Settled' : 'Pending';
      final phone = d.phoneNumber ?? '';
      buffer.writeln('$person,$dir,$net,$status,$phone');
    }

    return buffer.toString();
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

      // Income Categories
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
