import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'config/app_router.dart';
import 'data/storage/local_storage.dart';
import 'data/repositories/stage_repository.dart';
import 'data/repositories/booster_repository.dart';
import 'data/repositories/user_repository.dart';
import 'core/network/stage_api.dart';
import 'core/storage/stage_cache.dart';
import 'presentation/providers/stage_provider.dart';
import 'presentation/providers/game_provider.dart';
import 'presentation/providers/ad_provider.dart';
import 'presentation/providers/booster_provider.dart';
import 'presentation/providers/iap_provider.dart';
import 'presentation/screens/splash_screen.dart';
import 'utils/rules_engine.dart';
import 'domain/usecases/unlock_next_stage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Mobile Ads (AdMob) only on mobile platforms.
  // The google_mobile_ads plugin has no Linux/Windows/macOS desktop implementation.
  if (Platform.isAndroid || Platform.isIOS) {
    await MobileAds.instance.initialize();
  }

  // Initialize local storage (shared_preferences)
  await LocalStorage.init();

  // Setup dependencies
  final stageApi = StageApi();
  final remoteConfig = RemoteConfigService();
  final stageCache = StageCache();
  final stageRepo = StageRepository(
    api: stageApi,
    remoteConfig: remoteConfig,
    cache: stageCache,
  );
  final boosterRepo = BoosterRepository();
  final userRepo = UserRepository();
  final rulesEngine = RulesEngine(gridSize: 10, regionGrid: []);

  runApp(RabitDokuApp(
    stageRepo: stageRepo,
    boosterRepo: boosterRepo,
    userRepo: userRepo,
    rulesEngine: rulesEngine,
  ));
}

class RabitDokuApp extends StatelessWidget {
  final StageRepository stageRepo;
  final BoosterRepository boosterRepo;
  final UserRepository userRepo;
  final RulesEngine rulesEngine;

  const RabitDokuApp({
    super.key,
    required this.stageRepo,
    required this.boosterRepo,
    required this.userRepo,
    required this.rulesEngine,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(
          create: (_) => userRepo,
        ),
        ChangeNotifierProvider(
          create: (_) => StageProvider(
            repository: stageRepo,
            unlockUseCase: UnlockNextStageUseCase(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => GameProvider(
            boosterRepo: boosterRepo,
            userRepo: userRepo,
            rulesEngine: rulesEngine,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AdProvider(userRepo),
        ),
        ChangeNotifierProvider(
          create: (context) => BoosterProvider(
            boosterRepo: boosterRepo,
            adProvider: context.read<AdProvider>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => IAPProvider(userRepo: userRepo)..init(),
        ),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF8B5CF6),
            brightness: Brightness.light,
          ),
        ),
        onGenerateRoute: AppRouter.generateRoute,
        home: const SplashScreen(),
      ),
    );
  }
}
