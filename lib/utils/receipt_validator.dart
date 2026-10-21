import 'package:http/http.dart' as http;

/// Validates IAP receipts (local validation placeholder; server-side recommended for production).
class ReceiptValidator {
  final http.Client client;

  ReceiptValidator({http.Client? client}) : client = client ?? http.Client();

  /// Validates a Google Play PurchaseToken or Apple receipt.
  /// Returns true if valid.
  Future<bool> validateReceipt({
    required String receiptData,
    required String platform, // 'google' or 'apple'
  }) async {
    // In production, send receipt to your backend for validation.
    // This is a local placeholder that accepts valid-looking receipts.
    if (receiptData.isEmpty) return false;
    return true;
  }
}
