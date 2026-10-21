/// Booster model.
class BoosterModel {
  final String id;
  final String name;
  final String description;
  final String icon;
  final double priceUsd;
  final bool priceAd; // can be bought by watching an ad
  final int adRewardAmount;

  BoosterModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.priceUsd,
    required this.priceAd,
    required this.adRewardAmount,
  });

  factory BoosterModel.fromConfig(Map<String, dynamic> config) {
    return BoosterModel(
      id: config['id'] as String,
      name: config['name'] as String,
      description: config['description'] as String,
      icon: config['icon'] as String,
      priceUsd: (config['priceUsd'] as num).toDouble(),
      priceAd: config['priceAd'] as bool? ?? false,
      adRewardAmount: config['adRewardAmount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'icon': icon,
        'priceUsd': priceUsd,
        'priceAd': priceAd,
        'adRewardAmount': adRewardAmount,
      };
}

/// User booster inventory entry.
class UserBoosterInventory {
  final String boosterId;
  int quantity;

  UserBoosterInventory({
    required this.boosterId,
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
        'boosterId': boosterId,
        'quantity': quantity,
      };

  factory UserBoosterInventory.fromJson(Map<String, dynamic> json) {
    return UserBoosterInventory(
      boosterId: json['boosterId'] as String,
      quantity: json['quantity'] as int,
    );
  }
}
