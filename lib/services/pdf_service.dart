import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../providers/finance_provider.dart';

class PdfService {
  // --- Color Palette ---
  static const _purple = PdfColor.fromInt(0xFF6C3CE1);
  static const _teal = PdfColor.fromInt(0xFF00BFA5);
  static const _textDark = PdfColor.fromInt(0xFF1E1B4B);
  static const _textGrey = PdfColor.fromInt(0xFF6B7280);
  static const _bgLight = PdfColor.fromInt(0xFFF9F8FF);
  static const _green = PdfColor.fromInt(0xFF10B981);
  static const _red = PdfColor.fromInt(0xFFEF4444);
  static const _border = PdfColor.fromInt(0xFFE5E7EB);
  static const _tableRowAlt = PdfColor.fromInt(0xFFFAF9FF);

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

    final totalIncome = provider.totalIncomeInRange(start, end);
    final totalExpense = provider.expenseByCategory(start, end).values.fold(0.0, (a, b) => a + b);
    final netSavings = totalIncome - totalExpense;
    final accounts = provider.accounts;
    final totalBalance = provider.totalBalance;
    final installments = provider.installments;

    // Use a basic ASCII currency symbol to avoid font rendering "squares"
    final fmt = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);
    final dateFmt = DateFormat('MMM dd, yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(0),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: _bgLight),
          ),
        ),
        header: (context) {
          if (context.pageNumber > 1) {
            return pw.Container(
              color: _purple,
              padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('FINANCIAL REPORT', style: pw.TextStyle(color: PdfColors.white, fontSize: 14, fontWeight: pw.FontWeight.bold, letterSpacing: 1)),
                  pw.Text('${dateFmt.format(start)} - ${dateFmt.format(end)}', style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
                ],
              ),
            );
          }
          return pw.SizedBox.shrink();
        },
        footer: (context) => pw.Container(
          color: _purple,
          padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 14),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('BudgetBuddy - Personal Finance Tracker', style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
              pw.Text('Confidential - Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
            ],
          ),
        ),
        build: (context) => [
          // ═══════════════════ HEADER ═══════════════════
          pw.Container(
            color: _purple,
            padding: const pw.EdgeInsets.fromLTRB(40, 45, 40, 45),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('FINANCIAL', style: pw.TextStyle(color: PdfColors.white, fontSize: 30, fontWeight: pw.FontWeight.bold, letterSpacing: 3)),
                        pw.Text('REPORT', style: pw.TextStyle(color: _teal, fontSize: 30, fontWeight: pw.FontWeight.bold, letterSpacing: 3)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: const pw.BoxDecoration(
                            color: _teal,
                            borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                          ),
                          child: pw.Text(rangeLabel.toUpperCase(), style: pw.TextStyle(color: PdfColors.white, fontSize: 11, fontWeight: pw.FontWeight.bold, letterSpacing: 1)),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text('${dateFmt.format(start)} - ${dateFmt.format(end)}', style: const pw.TextStyle(color: PdfColors.white, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Container(height: 1, color: const PdfColor(1, 1, 1, 0.3)),
                pw.SizedBox(height: 15),
                pw.Row(
                  children: [
                    pw.Container(
                      width: 4, height: 4,
                      decoration: const pw.BoxDecoration(color: _teal, shape: pw.BoxShape.circle),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      provider.userName.isNotEmpty ? 'Prepared for  ${provider.userName}' : 'Personal Finance Tracker',
                      style: const pw.TextStyle(color: PdfColors.white, fontSize: 12),
                    ),
                    pw.Spacer(),
                    pw.Text('Generated: ${dateFmt.format(DateTime.now())}', style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),

          // ═══════════════════ BODY PADDING ═══════════════════
          pw.Container(
            padding: const pw.EdgeInsets.fromLTRB(40, 35, 40, 35),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [

                // ── SUMMARY CARDS ──
                pw.Row(
                  children: [
                    _summaryCard('INCOME', fmt.format(totalIncome), _green),
                    pw.SizedBox(width: 12),
                    _summaryCard('EXPENSES', fmt.format(totalExpense), _red),
                    pw.SizedBox(width: 12),
                    _summaryCard('NET SAVINGS', fmt.format(netSavings), netSavings >= 0 ? _purple : _red),
                  ],
                ),

                pw.SizedBox(height: 35),

                // ── ACCOUNT BALANCES ──
                _sectionHeader('Account Balances'),
                pw.SizedBox(height: 14),
                _table(
                  headers: ['Account', 'Type', 'Balance'],
                  rows: accounts.map((a) => [
                    a.name,
                    _formatType(a.type.name),
                    fmt.format(provider.accountBalance(a.id)),
                  ]).toList(),
                  footerRow: ['Total Balance', '', fmt.format(totalBalance)],
                ),

                pw.SizedBox(height: 35),

                // ── LOANS & INSTALLMENTS ──
                if (installments.isNotEmpty) ...[
                  _sectionHeader('Loans & Installments'),
                  pw.SizedBox(height: 14),
                  _table(
                    headers: ['Item', 'Total', 'Paid', 'Remaining'],
                    rows: installments.map((i) {
                      final paid = (i.totalAmount / i.months) * i.paidMonths;
                      final rem = i.totalAmount - paid;
                      return ['${i.item} - ${i.shop}', fmt.format(i.totalAmount), fmt.format(paid), fmt.format(rem)];
                    }).toList(),
                  ),
                ],

              ],
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'Financial_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  // ─────────────────────────── HELPERS ───────────────────────────

  static String _formatType(String raw) {
    return raw.replaceAll('_', ' ').split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  static pw.Widget _summaryCard(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: const pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              children: [
                pw.Container(width: 18, height: 3, color: color),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Text(label, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _textGrey, letterSpacing: 1.2)),
            pw.SizedBox(height: 8),
            pw.Text(value, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _sectionHeader(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _textDark)),
        pw.SizedBox(height: 6),
        pw.Row(
          children: [
            pw.Container(width: 32, height: 3, color: _purple),
            pw.SizedBox(width: 4),
            pw.Container(width: 8, height: 3, color: _teal),
          ],
        ),
      ],
    );
  }

  static pw.Widget _table({
    required List<String> headers,
    required List<List<String>> rows,
    List<String>? footerRow,
  }) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.fromBorderSide(pw.BorderSide(color: _border)),
      ),
      child: pw.ClipRRect(
        horizontalRadius: 10,
        verticalRadius: 10,
        child: pw.Column(
          children: [
            // Header
            pw.Container(
              color: _purple,
              padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: pw.Row(
                children: headers.asMap().entries.map((e) {
                  final isLast = e.key == headers.length - 1;
                  return pw.Expanded(
                    child: pw.Text(
                      e.value.toUpperCase(),
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white, letterSpacing: 0.8),
                      textAlign: isLast ? pw.TextAlign.right : pw.TextAlign.left,
                    ),
                  );
                }).toList(),
              ),
            ),
            // Rows
            ...rows.asMap().entries.map((rowEntry) {
              final isAlt = rowEntry.key % 2 == 1;
              return pw.Container(
                color: isAlt ? _tableRowAlt : PdfColors.white,
                padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                child: pw.Row(
                  children: rowEntry.value.asMap().entries.map((e) {
                    final isLast = e.key == rowEntry.value.length - 1;
                    return pw.Expanded(
                      child: pw.Text(
                        e.value,
                        style: const pw.TextStyle(fontSize: 11, color: _textDark),
                        textAlign: isLast ? pw.TextAlign.right : pw.TextAlign.left,
                      ),
                    );
                  }).toList(),
                ),
              );
            }),
            // Footer / Total
            if (footerRow != null)
              pw.Container(
                color: const PdfColor.fromInt(0xFFEDE9FE),
                padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                child: pw.Row(
                  children: footerRow.asMap().entries.map((e) {
                    final isLast = e.key == footerRow.length - 1;
                    return pw.Expanded(
                      child: pw.Text(
                        e.value,
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: isLast ? _purple : _textDark),
                        textAlign: isLast ? pw.TextAlign.right : pw.TextAlign.left,
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
