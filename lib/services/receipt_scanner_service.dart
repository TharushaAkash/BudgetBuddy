import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class ScannedReceiptData {
  final double? amount;
  final String? merchantName;
  final DateTime? date;

  ScannedReceiptData({this.amount, this.merchantName, this.date});
}

class ReceiptScannerService {
  static final ImagePicker _picker = ImagePicker();
  static final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Opens the camera or gallery, scans the receipt, and parses data.
  static Future<ScannedReceiptData?> scanReceipt(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 90, // compressed slightly for speed while keeping readability
      );
      if (image == null) return null;

      final inputImage = InputImage.fromFilePath(image.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      String fullText = recognizedText.text;
      
      return _parseReceiptData(fullText);
    } catch (e) {
      print("Error scanning receipt: $e");
      return null;
    }
  }

  /// Extracts amount, merchant, and date using regex patterns.
  static ScannedReceiptData _parseReceiptData(String text) {
    double? amount;
    String? merchantName;
    DateTime? date;

    final lines = text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    if (lines.isNotEmpty) {
      // The first prominent line is usually the store name.
      merchantName = lines.first;
    }

    // Attempt 1: Find amount near keywords like Total, Net, Rs, LKR
    // Matches something like "Total 1,234.50" or "Rs. 1234.50"
    final amountRegex = RegExp(r'(?i)(?:total|net|amount|rs|lkr)[\s\:\.\-]*([\d\,]+\.\d{2})');
    final amountMatches = amountRegex.allMatches(text);
    if (amountMatches.isNotEmpty) {
      // Get the last occurrence as "Total" usually appears at the bottom.
      final matchStr = amountMatches.last.group(1)?.replaceAll(',', '');
      if (matchStr != null) amount = double.tryParse(matchStr);
    } 

    if (amount == null) {
      // Fallback: Find the largest valid double ending in 2 decimal places.
      final allNumbersRegex = RegExp(r'([\d\,]+\.\d{2})');
      final numberMatches = allNumbersRegex.allMatches(text);
      double maxAmount = 0.0;
      for (final match in numberMatches) {
        final valStr = match.group(1)?.replaceAll(',', '');
        if (valStr != null) {
          final val = double.tryParse(valStr);
          if (val != null && val > maxAmount) {
            maxAmount = val;
          }
        }
      }
      if (maxAmount > 0) amount = maxAmount;
    }

    // Date parsing: DD/MM/YYYY or YYYY-MM-DD
    final dateRegex = RegExp(r'(\d{2,4})[\/\-](\d{2})[\/\-](\d{2,4})');
    final dateMatches = dateRegex.allMatches(text);
    if (dateMatches.isNotEmpty) {
       for (final match in dateMatches) {
         try {
           final p1 = int.parse(match.group(1)!);
           final p2 = int.parse(match.group(2)!);
           final p3 = int.parse(match.group(3)!);

           int day = p1;
           int month = p2;
           int year = p3;

           // Determine the year part
           if (p1 >= 2000) {
             // YYYY-MM-DD
             year = p1;
             month = p2;
             day = p3;
           } else {
             // DD-MM-YY or DD-MM-YYYY
             year = p3 < 100 ? p3 + 2000 : p3;
           }

           // Ensure month is valid, swap if US format (MM-DD)
           if (month > 12 && day <= 12) {
             final temp = month;
             month = day;
             day = temp;
           }

           if (month <= 12 && day <= 31) {
             date = DateTime(year, month, day);
             break; // Found a valid date
           }
         } catch(e) {
           // Skip parse errors and try next match
         }
       }
    }

    return ScannedReceiptData(amount: amount, merchantName: merchantName, date: date);
  }

  static void dispose() {
    _textRecognizer.close();
  }
}
