import 'package:intl/intl.dart';

class Formatters {
  static String currency(double amount, String symbol) {
    final format = NumberFormat.currency(symbol: symbol, decimalDigits: 2);
    return format.format(amount);
  }

  static String currencyCompact(double amount, String symbol) {
    final format = NumberFormat.compactCurrency(symbol: symbol, decimalDigits: 1);
    return format.format(amount);
  }

  static String date(DateTime d) => DateFormat('MMM d, yyyy').format(d);

  static String dateShort(DateTime d) => DateFormat('MMM d').format(d);

  static String monthYear(DateTime d) => DateFormat('MMMM yyyy').format(d);

  static String monthShort(DateTime d) => DateFormat('MMM').format(d);

  static String weekday(DateTime d) => DateFormat('EEE').format(d);
}
