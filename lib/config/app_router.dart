import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/stage_entity.dart';
import '../../domain/usecases/unlock_next_stage.dart';

import '../../data/repositories/user_repository.dart';
import '../../presentation/providers/booster_provider.dart';
import '../../presentation/providers/stage_provider.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/map_screen.dart';
import '../../presentation/screens/game_screen.dart';
import '../../presentation/screens/booster_shop_screen.dart';
import '../../presentation/screens/purchase_screen.dart';

/// Route definitions for Rabit_doku.
class AppRouter {
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/map':
        return MaterialPageRoute(builder: (_) => const MapScreen());
      case '/game':
        final stage = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => GameScreen(),
          settings: RouteSettings(name: settings.name ?? '/', arguments: stage),
        );
      case '/shop':
        return MaterialPageRoute(
          builder: (context) {
            final boosterProvider = context.read<BoosterProvider>();
            final userRepo = context.read<UserRepository>();
            final stageProvider = context.read<StageProvider>();
            final balance = stageProvider.getTotalScore();

            return BoosterShopScreen(
              boosters: boosterProvider.boosters,
              onBuyBooster: (id, withAd) async {
                if (withAd) {
                  await boosterProvider.buyBoosterWithAd(id);
                } else {
                  await boosterProvider.buyBooster(id);
                }
              },
              onBuyRemoveAds: () {
                Navigator.pushNamed(context, '/purchase');
              },
              isAdsRemoved: userRepo.getCurrentUser()?.isAdsRemoved ?? false,
              coinBalance: balance,
              onBuyWithCoins: (id) async {
                if (balance >= 100) {
                  await boosterProvider.addQuantity(id, 3);
                }
              },
            );
          },
        );
      case '/purchase':
        return MaterialPageRoute(
          builder: (context) => PurchaseScreen(
            productId: '',
            productName: '',
            price: 0,
            onConfirm: () {},
            onCancel: () {},
          ),
        );
      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}
