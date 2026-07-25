import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../providers/finance_provider.dart';
import '../models/account_model.dart';
import '../models/installment_model.dart';

class PdfService {
  static Future<void> generateAndPrintReport(
    FinanceProvider provider,
    DateTime start,
    DateTime end,
    String rangeLabel,
  ) async {
    final pdf = pw.Document();

    final totalIncome = provider.totalIncomeInRange(start, end);
    final totalExpense = provider.expenseByCategory(start, end).values.fold(0.0, (a, b) => a + b);
    final netSavings = totalIncome - totalExpense;

    final accounts = provider.accounts;
    final totalBalance = provider.totalBalance;

    final installments = provider.installments;

    final formatter = NumberFormat.currency(symbol: provider.currencySymbol, decimalDigits: 2);
    final dateFormat = DateFormat('MMM dd, yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('FINANCIAL REPORT', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                  pw.SizedBox(height: 4),
                  pw.Text(provider.userName.isNotEmpty ? 'Prepared for: ${provider.userName}' : 'Personal Finance Tracker', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(rangeLabel, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
                  pw.Text('${dateFormat.format(start)} - ${dateFormat.format(end)}', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 30),

          // Summary Section
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Total Income', formatter.format(totalIncome), PdfColors.green700),
                _buildSummaryItem('Total Expense', formatter.format(totalExpense), PdfColors.red700),
                _buildSummaryItem('Net Savings', formatter.format(netSavings), PdfColors.blue700),
              ],
            ),
          ),
          pw.SizedBox(height: 30),

          // Accounts Section
          pw.Text('Account Balances', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellAlignment: pw.Alignment.centerLeft,
            data: [
              ['Account Name', 'Type', 'Balance'],
              ...accounts.map((a) => [a.name, a.type.name.toUpperCase(), formatter.format(provider.accountBalance(a.id))]),
              ['TOTAL BALANCE', '', formatter.format(totalBalance)],
            ],
          ),
          pw.SizedBox(height: 30),

          // Loans & Installments Section
          if (installments.isNotEmpty) ...[
            pw.Text('Loans & Installments', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellAlignment: pw.Alignment.centerLeft,
              data: [
                ['Item', 'Total Amount', 'Paid Amount', 'Remaining Amount'],
                ...installments.map((i) {
                  final paidAmount = (i.totalAmount / i.months) * i.paidMonths;
                  final remaining = i.totalAmount - paidAmount;
                  return [
                    '${i.item} (${i.shop})',
                    formatter.format(i.totalAmount),
                    formatter.format(paidAmount),
                    formatter.format(remaining),
                  ];
                }),
              ],
            ),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Financial_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _buildSummaryItem(String title, String amount, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(title, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
        pw.SizedBox(height: 4),
        pw.Text(amount, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }
}
