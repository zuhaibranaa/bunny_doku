/// Purchase record.
class PurchaseModel {
  final String purchaseId;
  final String userId;
  final String productId;
  final String type; // 'IAP' or 'REWARDED_AD'
  final double amountUsd;
  final String currency;
  final String receiptData;
  final bool isValidated;
  final DateTime purchasedAt;

  PurchaseModel({
    required this.purchaseId,
    required this.userId,
    required this.productId,
    required this.type,
    required this.amountUsd,
    required this.currency,
    required this.receiptData,
    required this.isValidated,
    required this.purchasedAt,
  });

  Map<String, dynamic> toJson() => {
        'purchaseId': purchaseId,
        'userId': userId,
        'productId': productId,
        'type': type,
        'amountUsd': amountUsd,
        'currency': currency,
        'receiptData': receiptData,
        'isValidated': isValidated ? 1 : 0,
        'purchasedAt': purchasedAt.toIso8601String(),
      };

  factory PurchaseModel.fromJson(Map<String, dynamic> json) {
    return PurchaseModel(
      purchaseId: json['purchaseId'] as String,
      userId: json['userId'] as String,
      productId: json['productId'] as String,
      type: json['type'] as String,
      amountUsd: (json['amountUsd'] as num).toDouble(),
      currency: json['currency'] as String,
      receiptData: json['receiptData'] as String,
      isValidated: (json['isValidated'] as int? ?? 0) == 1,
      purchasedAt: DateTime.parse(
        json['purchasedAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
