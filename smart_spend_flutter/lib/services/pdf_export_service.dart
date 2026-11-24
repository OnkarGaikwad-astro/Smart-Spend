import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/transaction_model.dart';
import '../models/user_profile_model.dart';

/// Service to generate and export professional PDF statements for transactions.
class PdfExportService {
  static Future<void> exportTransactionsPdf({
    required List<TransactionModel> transactions,
    required double totalIncome,
    required double totalExpense,
    required double netBalance,
    UserProfileModel? userProfile,
  }) async {
    final pdf = pw.Document(
      title: 'SmartSpend Transaction Statement',
      author: 'SmartSpend',
    );

    final currencyFormat = NumberFormat('#,##,##0.00', 'en_IN');
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final txDateFormat = DateFormat('dd MMM yyyy');
    final generationTime = dateFormat.format(DateTime.now());

    // Sort transactions latest first
    final sortedTx = List<TransactionModel>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    // Calculate top expense categories
    final categoryTotals = <String, double>{};
    for (final tx in transactions.where((t) => t.isExpense)) {
      categoryTotals[tx.category] = (categoryTotals[tx.category] ?? 0.0) + tx.amount;
    }
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Refined color palette matching SmartSpend
    final primaryColor = PdfColor.fromHex('#0284C7'); // Sky 600
    final darkHeader = PdfColor.fromHex('#0F172A'); // Slate 900
    final textDark = PdfColor.fromHex('#1E293B'); // Slate 800
    final textMuted = PdfColor.fromHex('#64748B'); // Slate 500
    final incomeGreen = PdfColor.fromHex('#16A34A'); // Emerald 600
    final expenseRed = PdfColor.fromHex('#DC2626'); // Red 600
    final bgLight = PdfColor.fromHex('#F8FAFC'); // Slate 50
    final borderSubtle = PdfColor.fromHex('#E2E8F0'); // Slate 200

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 26),
        header: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 10),
            margin: const pw.EdgeInsets.only(bottom: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.8),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      width: 22,
                      height: 22,
                      decoration: pw.BoxDecoration(
                        color: primaryColor,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      ),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        'S',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      'SMARTSPEND',
                      style: pw.TextStyle(
                        color: primaryColor,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  'TRANSACTION STATEMENT',
                  style: pw.TextStyle(
                    color: textMuted,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 9,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 14),
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey300, width: 0.8),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'SmartSpend Financial Statement • End-to-End Local & Cloud Encrypted',
                  style: pw.TextStyle(color: textMuted, fontSize: 7.5),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(color: textMuted, fontSize: 7.5, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // Statement Title & User Info Banner
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Personal Financial Statement',
                      style: pw.TextStyle(
                        color: darkHeader,
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      userProfile != null && (userProfile.fullName?.isNotEmpty ?? false)
                          ? 'Account: ${userProfile.fullName!} (${userProfile.email})'
                          : (userProfile?.email.isNotEmpty ?? false)
                              ? 'Account: ${userProfile!.email}'
                              : 'Account: Personal',
                      style: pw.TextStyle(color: textDark, fontSize: 9.5, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Generated: $generationTime',
                      style: pw.TextStyle(color: textMuted, fontSize: 8.5),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Total Records: ${sortedTx.length}',
                      style: pw.TextStyle(color: primaryColor, fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 16),

            // Summary Metric Cards
            pw.Row(
              children: [
                // Total Income
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F0FDF4'),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      border: pw.Border.all(color: PdfColor.fromHex('#BBF7D0'), width: 0.8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'TOTAL INCOME',
                          style: pw.TextStyle(color: incomeGreen, fontSize: 8, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Rs. ${currencyFormat.format(totalIncome)}',
                          style: pw.TextStyle(color: incomeGreen, fontSize: 13, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                // Total Expenses
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#FEF2F2'),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      border: pw.Border.all(color: PdfColor.fromHex('#FECACA'), width: 0.8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'TOTAL EXPENSES',
                          style: pw.TextStyle(color: expenseRed, fontSize: 8, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Rs. ${currencyFormat.format(totalExpense)}',
                          style: pw.TextStyle(color: expenseRed, fontSize: 13, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                // Net Balance
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F0F9FF'),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      border: pw.Border.all(color: PdfColor.fromHex('#BAE6FD'), width: 0.8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'NET BALANCE',
                          style: pw.TextStyle(color: primaryColor, fontSize: 8, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          '${netBalance >= 0 ? '' : '-'}Rs. ${currencyFormat.format(netBalance.abs())}',
                          style: pw.TextStyle(
                            color: netBalance >= 0 ? primaryColor : expenseRed,
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            if (sortedCategories.isNotEmpty) ...[
              pw.SizedBox(height: 14),
              pw.Text(
                'Top Expense Categories',
                style: pw.TextStyle(color: darkHeader, fontSize: 10.5, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              pw.Wrap(
                spacing: 6,
                runSpacing: 5,
                children: sortedCategories.take(4).map((entry) {
                  final pct = totalExpense > 0 ? (entry.value / totalExpense * 100).toStringAsFixed(1) : '0';
                  return pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: bgLight,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      border: pw.Border.all(color: borderSubtle, width: 0.8),
                    ),
                    child: pw.Text(
                      '${entry.key}: Rs. ${currencyFormat.format(entry.value)} ($pct%)',
                      style: pw.TextStyle(color: textDark, fontSize: 8, fontWeight: pw.FontWeight.bold),
                    ),
                  );
                }).toList(),
              ),
            ],

            pw.SizedBox(height: 16),
            pw.Text(
              'Transaction History (${sortedTx.length})',
              style: pw.TextStyle(color: darkHeader, fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),

            // Transactions Table
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder(
                horizontalInside: pw.BorderSide(color: borderSubtle, width: 0.5),
                bottom: pw.BorderSide(color: borderSubtle, width: 0.8),
              ),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 8.5,
              ),
              headerDecoration: pw.BoxDecoration(
                color: darkHeader,
                borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(4)),
              ),
              headerPadding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 6),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 6),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.center,
                4: pw.Alignment.centerRight,
              },
              headers: ['Date', 'Category', 'Description / Title', 'Type', 'Amount'],
              data: sortedTx.map((tx) {
                final dateStr = txDateFormat.format(tx.date);
                final isInc = tx.isIncome;
                final sign = isInc ? '+' : '-';
                final amtStr = '$sign Rs. ${currencyFormat.format(tx.amount)}';
                return [
                  dateStr,
                  tx.category,
                  tx.title.isNotEmpty ? tx.title : 'Transaction',
                  tx.type.toUpperCase(),
                  amtStr,
                ];
              }).toList(),
              rowDecoration: const pw.BoxDecoration(),
              oddRowDecoration: pw.BoxDecoration(color: bgLight),
              cellStyle: pw.TextStyle(color: textDark, fontSize: 8),
            ),
          ];
        },
      ),
    );

    // Write to temporary file and trigger native share sheet
    final bytes = await pdf.save();
    final tempDir = await getTemporaryDirectory();
    final dateTag = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'SmartSpend_Statement_$dateTag.pdf';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf', name: fileName)],
        subject: 'SmartSpend Statement $dateTag',
        text: 'SmartSpend Personal Financial Statement generated on $generationTime',
      ),
    );
  }
}
