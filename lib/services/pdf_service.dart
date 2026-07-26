import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../providers/finance_provider.dart';
import '../models/category_model.dart';

class PdfService {
  // --- Color Palette ---
  static const _primary = PdfColor.fromInt(0xFF0F766E); // Deep Teal
  static const _textDark = PdfColor.fromInt(0xFF0F172A);
  static const _textGrey = PdfColor.fromInt(0xFF64748B);
  static const _green = PdfColor.fromInt(0xFF10B981);
  static const _red = PdfColor.fromInt(0xFFF43F5E);
  static const _orange = PdfColor.fromInt(0xFFF59E0B);
  static const _border = PdfColor.fromInt(0xFFE2E8F0);
  static const _tableHeader = PdfColor.fromInt(0xFF14B8A6); // Light Teal
  static const _tableRowAlt = PdfColor.fromInt(0xFFF8FAFC); // Very light greyish blue
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
    final categories = provider.categories;
    final installments = provider.installments;

    // Income by Category
    final Map<String, double> incomeByCategory = {};
    for (final t in txns) {
      if (!t.isTransfer && t.type == CategoryType.income) {
        final cat = categories.firstWhere(
          (c) => c.id == t.categoryId,
          orElse: () => CategoryModel(id: '', name: 'Other Income', iconKey: '', colorValue: 0, type: CategoryType.income),
        );
        incomeByCategory[cat.name] = (incomeByCategory[cat.name] ?? 0) + t.amount;
      }
    }

    // Expense by Category
    final Map<String, double> expenseByCategory = {};
    for (final t in txns) {
      if (!t.isTransfer && t.type == CategoryType.expense) {
        final cat = categories.firstWhere(
          (c) => c.id == t.categoryId,
          orElse: () => CategoryModel(id: '', name: 'Other Expense', iconKey: '', colorValue: 0, type: CategoryType.expense),
        );
        expenseByCategory[cat.name] = (expenseByCategory[cat.name] ?? 0) + t.amount;
      }
    }

    const incomeColors = [
      PdfColor.fromInt(0xFF10B981),
      PdfColor.fromInt(0xFF3B82F6),
      PdfColor.fromInt(0xFF8B5CF6),
      PdfColor.fromInt(0xFFF59E0B),
      PdfColor.fromInt(0xFF06B6D4),
    ];

    const expenseColors = [
      PdfColor.fromInt(0xFFF43F5E),
      PdfColor.fromInt(0xFFF97316),
      PdfColor.fromInt(0xFFEC4899),
      PdfColor.fromInt(0xFF6366F1),
      PdfColor.fromInt(0xFF14B8A6),
    ];

    // Calculate Opening Balance
    double runningBalance = accounts.fold(0.0, (s, a) => s + a.openingBalance);
    for (final t in provider.transactions) {
      if (t.date.isBefore(start) && !t.isTransfer) {
        runningBalance += t.type == CategoryType.income ? t.amount : -t.amount;
      }
    }
    final openingBalance = runningBalance;
    final closingBalance = openingBalance + netSavings;

    final fmt = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);
    final dateFmt = DateFormat('MMM dd, yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(30),
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

          // ═══════════════════ BREAKDOWNS ═══════════════════
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _breakdownCard(
                  title: 'INCOME BREAKDOWN',
                  total: totalIncome,
                  categoryData: incomeByCategory,
                  palette: incomeColors,
                  fmt: fmt,
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: _breakdownCard(
                  title: 'EXPENSE BREAKDOWN',
                  total: totalExpense,
                  categoryData: expenseByCategory,
                  palette: expenseColors,
                  fmt: fmt,
                ),
              ),
            ],
          ),

          pw.NewPage(),

          // ═══════════════════ TRANSACTION HISTORY ═══════════════════
          ..._transactionTable(txns, openingBalance, fmt, dateFmt, provider),

          // ═══════════════════ LOANS & INSTALLMENTS ═══════════════════
          if (installments.isNotEmpty) ..._loansTable(installments, fmt),
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

  static pw.Widget _sectionContainer({
    required String title,
    required pw.Widget child,
    pw.EdgeInsets padding = const pw.EdgeInsets.all(14),
  }) {
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
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const pw.BoxDecoration(
                color: _tableHeader,
              ),
              child: pw.Text(title, style: pw.TextStyle(color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: padding,
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _breakdownCard({
    required String title,
    required double total,
    required Map<String, double> categoryData,
    required List<PdfColor> palette,
    required NumberFormat fmt,
  }) {
    if (categoryData.isEmpty) {
      return _sectionContainer(
        title: title,
        child: pw.Container(
          height: 100,
          child: pw.Center(
            child: pw.Text('No data recorded for this period', style: const pw.TextStyle(color: _textGrey, fontSize: 9)),
          ),
        ),
      );
    }

    final entries = categoryData.entries.toList();

    return _sectionContainer(
      title: title,
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total', style: const pw.TextStyle(fontSize: 9, color: _textGrey)),
              pw.Text(fmt.format(total), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _textDark)),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Divider(color: _border, height: 1),
          pw.SizedBox(height: 8),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Pie Chart
              pw.Container(
                width: 75,
                height: 75,
                child: pw.Chart(
                  grid: pw.PieGrid(),
                  datasets: entries.asMap().entries.map((e) {
                    final idx = e.key;
                    final val = e.value.value;
                    final color = palette[idx % palette.length];
                    return pw.PieDataSet(
                      value: val,
                      color: color,
                    );
                  }).toList(),
                ),
              ),
              pw.SizedBox(width: 10),
              // Legend
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: entries.asMap().entries.map((e) {
                    final idx = e.key;
                    final name = e.value.key;
                    final val = e.value.value;
                    final pct = total > 0 ? (val / total * 100).toStringAsFixed(1) : '0';
                    final color = palette[idx % palette.length];

                    return pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 2),
                      child: pw.Row(
                        children: [
                          pw.Container(width: 6, height: 6, decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle)),
                          pw.SizedBox(width: 4),
                          pw.Expanded(
                            child: pw.Text(name, style: const pw.TextStyle(fontSize: 8, color: _textDark), maxLines: 1),
                          ),
                          pw.Text('$pct%', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _textDark)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }





  static pw.Widget _th(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(text, textAlign: align, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
    );
  }

  static pw.Widget _td(String text, {pw.TextAlign align = pw.TextAlign.left, PdfColor color = _textDark, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(text, textAlign: align, style: pw.TextStyle(fontSize: 8, color: color, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
    );
  }

  static List<pw.Widget> _transactionTable(List txns, double initialBalance, NumberFormat fmt, DateFormat dateFmt, FinanceProvider provider) {
    return [
      pw.Header(
        level: 1,
        decoration: const pw.BoxDecoration(),
        margin: const pw.EdgeInsets.only(bottom: 10, top: 10),
        child: pw.Text('TRANSACTION HISTORY', style: pw.TextStyle(color: _primary, fontSize: 12, fontWeight: pw.FontWeight.bold)),
      ),
      pw.Table(
        border: pw.TableBorder.all(color: _border, width: 0.5),
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(3),
          2: const pw.FlexColumnWidth(2),
          3: const pw.FlexColumnWidth(2),
          4: const pw.FlexColumnWidth(2),
          5: const pw.FlexColumnWidth(2),
        },
        children: [
          pw.TableRow(
            repeat: true,
            decoration: const pw.BoxDecoration(color: _tableHeader),
            children: [
              _th('DATE'),
              _th('DESCRIPTION'),
              _th('CATEGORY'),
              _th('ACCOUNT'),
              _th('AMOUNT', align: pw.TextAlign.right),
              _th('BALANCE', align: pw.TextAlign.right),
            ],
          ),
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.white),
            children: [
              _td('-', color: _textGrey),
              _td('Opening Balance'),
              _td('-', color: _textGrey),
              _td('-', color: _textGrey),
              _td('-', align: pw.TextAlign.right, color: _textGrey),
              _td(fmt.format(initialBalance), align: pw.TextAlign.right, isBold: true),
            ],
          ),
          ...txns.asMap().entries.map((entry) {
            final t = entry.value;
            final isAlt = entry.key % 2 == 1;

            double b = initialBalance;
            for (var i = 0; i <= entry.key; i++) {
              if (!txns[i].isTransfer) {
                b += txns[i].type == CategoryType.income ? txns[i].amount : -txns[i].amount;
              }
            }

            final isIncome = t.type == CategoryType.income;
            final acc = provider.accounts.firstWhere((a) => a.id == t.accountId, orElse: () => provider.accounts.first);
            final cat = provider.categories.firstWhere((c) => c.id == t.categoryId, orElse: () => CategoryModel(id: '', name: isIncome ? 'Income' : 'Expense', iconKey: '', colorValue: 0, type: t.type));

            return pw.TableRow(
              decoration: pw.BoxDecoration(color: isAlt ? _tableRowAlt : PdfColors.white),
              children: [
                _td(dateFmt.format(t.date), color: _textGrey),
                _td(t.title),
                _td(cat.name, color: isIncome ? _green : _red),
                _td(acc.name),
                _td('${isIncome ? '+' : '-'} ${fmt.format(t.amount)}', align: pw.TextAlign.right, color: isIncome ? _green : _red),
                _td(fmt.format(b), align: pw.TextAlign.right),
              ],
            );
          }),
        ],
      ),
    ];
  }

  static List<pw.Widget> _loansTable(List installments, NumberFormat fmt) {
    return [
      pw.Header(
        level: 1,
        decoration: const pw.BoxDecoration(),
        margin: const pw.EdgeInsets.only(bottom: 10, top: 20),
        child: pw.Text('LOANS & INSTALLMENTS', style: pw.TextStyle(color: _primary, fontSize: 12, fontWeight: pw.FontWeight.bold)),
      ),
      pw.Table(
        border: pw.TableBorder.all(color: _border, width: 0.5),
        columnWidths: {
          0: const pw.FlexColumnWidth(4),
          1: const pw.FlexColumnWidth(2),
          2: const pw.FlexColumnWidth(2),
          3: const pw.FlexColumnWidth(2),
        },
        children: [
          pw.TableRow(
            repeat: true,
            decoration: const pw.BoxDecoration(color: _tableHeader),
            children: [
              _th('ITEM'),
              _th('TOTAL AMOUNT', align: pw.TextAlign.right),
              _th('PAID', align: pw.TextAlign.right),
              _th('REMAINING', align: pw.TextAlign.right),
            ],
          ),
          ...installments.asMap().entries.map((entry) {
            final i = entry.value;
            final paid = (i.totalAmount / i.months) * i.paidMonths;
            final rem = i.totalAmount - paid;
            final isAlt = entry.key % 2 == 1;

            return pw.TableRow(
              decoration: pw.BoxDecoration(color: isAlt ? _tableRowAlt : PdfColors.white),
              children: [
                _td('${i.item} - ${i.shop}'),
                _td(fmt.format(i.totalAmount), align: pw.TextAlign.right),
                _td(fmt.format(paid), align: pw.TextAlign.right),
                _td(fmt.format(rem), align: pw.TextAlign.right),
              ],
            );
          }),
        ],
      ),
    ];
  }
}
