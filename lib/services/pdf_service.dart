import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../providers/finance_provider.dart';

class PdfService {
  // --- Color Palette ---
  static const _primary = PdfColor.fromInt(0xFF4C3AE3); // Deep Blue/Purple
  static const _textDark = PdfColor.fromInt(0xFF1E1E1E);
  static const _textGrey = PdfColor.fromInt(0xFF6B7280);
  static const _green = PdfColor.fromInt(0xFF10B981);
  static const _red = PdfColor.fromInt(0xFFEF4444);
  static const _orange = PdfColor.fromInt(0xFFF59E0B);
  static const _border = PdfColor.fromInt(0xFFE5E7EB);
  static const _tableHeader = PdfColor.fromInt(0xFF6C47FF); // Bright Purple
  static const _tableRowAlt = PdfColor.fromInt(0xFFF9F8FF); // Very light purple
  static const _cardBg = PdfColors.white;

  static Future<void> generateAndPrintReport(
    FinanceProvider provider,
    DateTime start,
    DateTime end,
    String rangeLabel,
  ) async {
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
        italic: pw.Font.helveticaOblique(),
      ),
    );

    final txns = provider.transactionsInRange(start, end)..sort((a, b) => a.date.compareTo(b.date));
    final totalIncome = provider.totalIncomeInRange(start, end);
    final totalExpense = provider.expenseByCategory(start, end).values.fold(0.0, (a, b) => a + b);
    final netSavings = totalIncome - totalExpense;
    final savingsRate = totalIncome > 0 ? (netSavings / totalIncome) * 100 : 0.0;
    
    final accounts = provider.accounts;
    final installments = provider.installments;

    // Calculate Opening Balance
    double runningBalance = accounts.fold(0.0, (s, a) => s + a.openingBalance);
    for (final t in provider.transactions) {
      if (t.date.isBefore(start) && !t.isTransfer) {
        runningBalance += t.type.name == 'income' ? t.amount : -t.amount;
      }
    }
    final openingBalance = runningBalance;
    final closingBalance = openingBalance + netSavings;

    final fmt = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);
    final dateFmt = DateFormat('MMM dd, yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(30),
        ),
        footer: (context) => pw.Container(
          color: _primary,
          padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          margin: const pw.EdgeInsets.only(top: 20),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(
                children: [
                  pw.Container(
                    width: 16, height: 16,
                    decoration: const pw.BoxDecoration(color: PdfColors.white, shape: pw.BoxShape.circle),
                    child: pw.Center(child: pw.Text('B', style: pw.TextStyle(color: _primary, fontSize: 10, fontWeight: pw.FontWeight.bold))),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Text('BudgetBuddy - Personal Finance Tracker', style: const pw.TextStyle(color: PdfColors.white, fontSize: 9)),
                ],
              ),
              pw.Text('Confidential - Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(color: PdfColors.white, fontSize: 9)),
            ],
          ),
        ),
        build: (context) => [
          // ═══════════════════ HEADER ═══════════════════
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Logo & App Name
              pw.Row(
                children: [
                  pw.Container(
                    width: 40, height: 40,
                    decoration: const pw.BoxDecoration(color: _primary, shape: pw.BoxShape.circle),
                    child: pw.Center(child: pw.Text('B', style: pw.TextStyle(color: PdfColors.white, fontSize: 24, fontWeight: pw.FontWeight.bold))),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('BudgetBuddy', style: pw.TextStyle(color: _primary, fontSize: 22, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Personal Finance Tracker', style: const pw.TextStyle(color: _textGrey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              // Report Details
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Row(
                    children: [
                      pw.Text('FINANCIAL ', style: pw.TextStyle(color: _primary, fontSize: 22, fontWeight: pw.FontWeight.bold)),
                      pw.Text('REPORT ', style: pw.TextStyle(color: _tableHeader, fontSize: 22, fontWeight: pw.FontWeight.bold)),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: const pw.BoxDecoration(
                          color: _primary,
                          borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                        ),
                        child: pw.Text('PDF', style: pw.TextStyle(color: PdfColors.white, fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: const pw.BoxDecoration(color: _green, borderRadius: pw.BorderRadius.all(pw.Radius.circular(10))),
                    child: pw.Text(rangeLabel.toUpperCase(), style: pw.TextStyle(color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          
          pw.SizedBox(height: 20),
          pw.Divider(color: _border),
          pw.SizedBox(height: 10),
          
          // ═══════════════════ SUB-HEADER ═══════════════════
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(
                children: [
                  pw.Container(
                    width: 30, height: 30,
                    decoration: const pw.BoxDecoration(color: _tableRowAlt, shape: pw.BoxShape.circle),
                    child: pw.Center(child: pw.Text(provider.userName.isNotEmpty ? provider.userName[0].toUpperCase() : 'U', style: pw.TextStyle(color: _primary, fontWeight: pw.FontWeight.bold))),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Prepared for:', style: const pw.TextStyle(color: _textGrey, fontSize: 9)),
                      pw.Text(provider.userName.isNotEmpty ? provider.userName : 'User', style: pw.TextStyle(color: _textDark, fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('${dateFmt.format(start)} - ${dateFmt.format(end)}', style: pw.TextStyle(color: _textDark, fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Generated: ${dateFmt.format(DateTime.now())}', style: const pw.TextStyle(color: _textGrey, fontSize: 9)),
                ],
              ),
            ],
          ),
          
          pw.SizedBox(height: 20),

          // ═══════════════════ SUMMARY CARDS ═══════════════════
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _kpiCard('TOTAL INCOME', fmt.format(totalIncome), _green, '100% of income'),
              pw.SizedBox(width: 8),
              _kpiCard('TOTAL EXPENSES', fmt.format(totalExpense), _red, '${totalIncome > 0 ? (totalExpense/totalIncome*100).toStringAsFixed(1) : 0}% of income'),
              pw.SizedBox(width: 8),
              _kpiCard('NET SAVINGS', fmt.format(netSavings), _primary, '${savingsRate.toStringAsFixed(1)}% of income'),
              pw.SizedBox(width: 8),
              _kpiCard('SAVINGS RATE', '${savingsRate.toStringAsFixed(1)}%', _tableHeader, savingsRate >= 20 ? 'Excellent' : 'Needs Work'),
              pw.SizedBox(width: 8),
              _kpiCard('CLOSING BALANCE', fmt.format(closingBalance), _orange, 'End of period'),
            ],
          ),
          
          pw.SizedBox(height: 20),

          // ═══════════════════ CASH FLOW & BALANCES ═══════════════════
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Left side: Cash Flow Summary
              pw.Expanded(
                child: _sectionContainer(
                  title: 'CASH FLOW SUMMARY',
                  child: pw.Column(
                    children: [
                      _cashFlowRow('Opening Balance', fmt.format(openingBalance), isBold: false),
                      pw.Divider(color: _border),
                      _cashFlowRow('Total Income', '+ ${fmt.format(totalIncome)}', color: _green, isBold: true),
                      pw.Divider(color: _border),
                      _cashFlowRow('Total Expenses', '- ${fmt.format(totalExpense)}', color: _red, isBold: true),
                      pw.Divider(color: _border),
                      _cashFlowRow('Net Cash Flow', '${netSavings >= 0 ? '+' : '-'} ${fmt.format(netSavings.abs())}', color: netSavings >= 0 ? _green : _red, isBold: true),
                      pw.Divider(color: _primary, thickness: 1.5),
                      _cashFlowRow('Closing Balance', fmt.format(closingBalance), color: _primary, isBold: true, size: 12),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 16),
              // Right side: Account Balances
              pw.Expanded(
                child: _sectionContainer(
                  title: 'ACCOUNT BALANCES',
                  child: pw.Column(
                    children: accounts.map((a) {
                      return pw.Column(
                        children: [
                          _cashFlowRow(a.name, fmt.format(provider.accountBalance(a.id)), isBold: false),
                          pw.Divider(color: _border),
                        ],
                      );
                    }).toList()..add(
                      pw.Column(
                        children: [
                          _cashFlowRow('Total Balance', fmt.format(provider.totalBalance), color: _primary, isBold: true, size: 12),
                        ],
                      )
                    ),
                  ),
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 20),

          // ═══════════════════ TRANSACTION HISTORY ═══════════════════
          _sectionTitle('TRANSACTION HISTORY'),
          pw.SizedBox(height: 8),
          _transactionTable(txns, openingBalance, fmt, dateFmt, provider),

          pw.SizedBox(height: 20),

          // ═══════════════════ LOANS & INSTALLMENTS ═══════════════════
          if (installments.isNotEmpty) ...[
            _sectionTitle('LOANS & INSTALLMENTS'),
            pw.SizedBox(height: 8),
            _loansTable(installments, fmt),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'Financial_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  // ─────────────────────────── HELPERS ───────────────────────────

  static pw.Widget _kpiCard(String title, String amount, PdfColor color, String subtitle) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: _cardBg,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(color: _border),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: const pw.TextStyle(fontSize: 7, color: _textGrey, letterSpacing: 0.5)),
            pw.SizedBox(height: 6),
            pw.Text(amount, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: color)),
            pw.SizedBox(height: 4),
            pw.Text(subtitle, style: const pw.TextStyle(fontSize: 7, color: _textDark)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _sectionContainer({required String title, required pw.Widget child}) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _cardBg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: _border),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const pw.BoxDecoration(
              color: _tableHeader,
              borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(7)),
            ),
            child: pw.Text(title, style: pw.TextStyle(color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(14),
            child: child,
          ),
        ],
      ),
    );
  }

  static pw.Widget _cashFlowRow(String label, String value, {PdfColor color = _textDark, bool isBold = false, double size = 9}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: size, color: _textDark, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontSize: size, color: color, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Text(title, style: pw.TextStyle(color: _primary, fontSize: 10, fontWeight: pw.FontWeight.bold, letterSpacing: 0.5));
  }

  static pw.Widget _transactionTable(List txns, double initialBalance, NumberFormat fmt, DateFormat dateFmt, FinanceProvider provider) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _cardBg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: _border),
      ),
      child: pw.ClipRRect(
        horizontalRadius: 8,
        verticalRadius: 8,
        child: pw.Column(
          children: [
            // Header
            pw.Container(
              color: _tableRowAlt,
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: pw.Row(
                children: [
                  pw.Expanded(flex: 2, child: pw.Text('DATE', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _primary))),
                  pw.Expanded(flex: 3, child: pw.Text('DESCRIPTION', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _primary))),
                  pw.Expanded(flex: 2, child: pw.Text('CATEGORY', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _primary))),
                  pw.Expanded(flex: 2, child: pw.Text('ACCOUNT', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _primary))),
                  pw.Expanded(flex: 2, child: pw.Text('AMOUNT', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _primary))),
                  pw.Expanded(flex: 2, child: pw.Text('BALANCE', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _primary))),
                ],
              ),
            ),
            pw.Divider(color: _border, height: 0),
            // Initial Balance Row
            pw.Container(
              color: PdfColors.white,
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: pw.Row(
                children: [
                  pw.Expanded(flex: 2, child: pw.Text('-', style: const pw.TextStyle(fontSize: 8, color: _textGrey))),
                  pw.Expanded(flex: 3, child: pw.Text('Opening Balance', style: const pw.TextStyle(fontSize: 8, color: _textDark))),
                  pw.Expanded(flex: 2, child: pw.Text('-', style: const pw.TextStyle(fontSize: 8, color: _textGrey))),
                  pw.Expanded(flex: 2, child: pw.Text('-', style: const pw.TextStyle(fontSize: 8, color: _textGrey))),
                  pw.Expanded(flex: 2, child: pw.Text('-', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8, color: _textGrey))),
                  pw.Expanded(flex: 2, child: pw.Text(fmt.format(initialBalance), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8, color: _textDark))),
                ],
              ),
            ),
            pw.Divider(color: _border, height: 0),
            // Transaction Rows
            ...txns.asMap().entries.map((entry) {
              final t = entry.value;
              final isAlt = entry.key % 2 == 1;
              
              // Calculate running balance
              double b = initialBalance;
              for (var i = 0; i <= entry.key; i++) {
                if (!txns[i].isTransfer) {
                  b += txns[i].type.name == 'income' ? txns[i].amount : -txns[i].amount;
                }
              }

              final isIncome = t.type.name == 'income';
              final acc = provider.accounts.firstWhere((a) => a.id == t.accountId, orElse: () => provider.accounts.first);
              
              return pw.Container(
                color: isAlt ? _tableRowAlt : PdfColors.white,
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: pw.Row(
                  children: [
                    pw.Expanded(flex: 2, child: pw.Text(dateFmt.format(t.date), style: const pw.TextStyle(fontSize: 8, color: _textGrey))),
                    pw.Expanded(flex: 3, child: pw.Text(t.title, style: const pw.TextStyle(fontSize: 8, color: _textDark))),
                    pw.Expanded(flex: 2, child: pw.Text(isIncome ? 'Income' : 'Expense', style: pw.TextStyle(fontSize: 8, color: isIncome ? _green : _red))),
                    pw.Expanded(flex: 2, child: pw.Text(acc.name, style: const pw.TextStyle(fontSize: 8, color: _textDark))),
                    pw.Expanded(flex: 2, child: pw.Text('${isIncome ? '+' : '-'} ${fmt.format(t.amount)}', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8, color: isIncome ? _green : _red))),
                    pw.Expanded(flex: 2, child: pw.Text(fmt.format(b), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8, color: _textDark))),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  static pw.Widget _loansTable(List installments, NumberFormat fmt) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _cardBg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: _border),
      ),
      child: pw.ClipRRect(
        horizontalRadius: 8,
        verticalRadius: 8,
        child: pw.Column(
          children: [
            // Header
            pw.Container(
              color: _tableRowAlt,
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: pw.Row(
                children: [
                  pw.Expanded(flex: 4, child: pw.Text('ITEM', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _primary))),
                  pw.Expanded(flex: 2, child: pw.Text('TOTAL AMOUNT', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _primary))),
                  pw.Expanded(flex: 2, child: pw.Text('PAID', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _primary))),
                  pw.Expanded(flex: 2, child: pw.Text('REMAINING', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _primary))),
                ],
              ),
            ),
            pw.Divider(color: _border, height: 0),
            // Data
            ...installments.asMap().entries.map((entry) {
              final i = entry.value;
              final paid = (i.totalAmount / i.months) * i.paidMonths;
              final rem = i.totalAmount - paid;
              final isAlt = entry.key % 2 == 1;

              return pw.Container(
                color: isAlt ? _tableRowAlt : PdfColors.white,
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: pw.Row(
                  children: [
                    pw.Expanded(flex: 4, child: pw.Text('${i.item} - ${i.shop}', style: const pw.TextStyle(fontSize: 8, color: _textDark))),
                    pw.Expanded(flex: 2, child: pw.Text(fmt.format(i.totalAmount), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8, color: _textDark))),
                    pw.Expanded(flex: 2, child: pw.Text(fmt.format(paid), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8, color: _textDark))),
                    pw.Expanded(flex: 2, child: pw.Text(fmt.format(rem), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8, color: _textDark))),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
