# Rabit_doku - Implementation Plan

## Project Overview
Rabit_doku is a Flutter mobile puzzle game inspired by Meowdoku (cat Sudoku variant) with a rabbit theme. It features:
- 10×10 grid with asymmetric colored regions (10 colors)
- Rules: 1 rabbit per row | 1 rabbit per column | no diagonal adjacency | 1 rabbit per region
- Candy Crush Saga-style stage selection map
- Daily stage releases via remote config (no app update needed for content)
- Boosters purchasable via real money (IAP) or rewarded ads
- AdMob integration with tenure-based interstitial cadence

## Phase 1: Engineering & Planning (COMPLETED)
- [x] `engineering/diagrams/use_case_diagram.mmd`
- [x] `engineering/diagrams/flow_diagram.mmd`
- [x] `engineering/diagrams/architecture_diagram.mmd`
- [x] `engineering/diagrams/er_diagram.mmd`
- [x] `AGENTS.md`
- [x] `pubspec.yaml` dependencies updated

## Phase 2: Core Configuration & Data Layer
- [ ] `lib/config/app_config.dart` - App-wide config
- [ ] `lib/config/release_config.dart` - Daily stage release config
- [ ] `lib/config/booster_config.dart` - Booster definitions & pricing
- [ ] `lib/config/ad_config.dart` - Ad unit IDs & cadence
- [ ] `lib/core/constants/app_constants.dart` - Grid size, lives, rules invariants
- [ ] `lib/core/errors/app_exception.dart` - Custom exceptions
- [ ] `lib/data/models/stage_model.dart`
- [ ] `lib/data/models/booster_model.dart`
- [ ] `lib/data/models/user_model.dart`
- [ ] `lib/data/models/purchase_model.dart`
- [ ] `lib/data/repositories/stage_repository.dart`
- [ ] `lib/data/repositories/booster_repository.dart`
- [ ] `lib/data/repositories/user_repository.dart`
- [ ] `lib/data/storage/local_storage.dart` (shared_preferences + hive)

## Phase 3: Domain Layer (Use Cases & Rules Engine)
- [ ] `lib/domain/entities/stage_entity.dart`
- [ ] `lib/domain/entities/booster_entity.dart`
- [ ] `lib/domain/entities/game_state_entity.dart`
- [ ] `lib/domain/entities/user_entity.dart`
- [ ] `lib/domain/usecases/load_stages.dart`
- [ ] `lib/domain/usecases/validate_placement.dart`
- [ ] `lib/domain/usecases/compute_stars.dart`
- [ ] `lib/domain/usecases/purchase_booster.dart`
- [ ] `lib/domain/usecases/watch_ad_for_booster.dart`
- [ ] `lib/domain/usecases/unlock_next_stage.dart`
- [ ] `lib/utils/rules_engine.dart` - Pure validation logic

## Phase 4: Presentation Layer (UI)
- [ ] `lib/presentation/screens/splash_screen.dart`
- [ ] `lib/presentation/screens/map_screen.dart` - Candy Crush map
- [ ] `lib/presentation/screens/stage_popup.dart`
- [ ] `lib/presentation/screens/game_screen.dart` - 10x10 grid
- [ ] `lib/presentation/screens/booster_shop_screen.dart`
- [ ] `lib/presentation/screens/purchase_screen.dart`
- [ ] `lib/presentation/widgets/stage_node.dart`
- [ ] `lib/presentation/widgets/map_path_painter.dart`
- [ ] `lib/presentation/widgets/grid_cell.dart`
- [ ] `lib/presentation/widgets/heart_counter.dart`
- [ ] `lib/presentation/widgets/booster_button.dart`
- [ ] `lib/presentation/widgets/ad_banner_widget.dart`
- [ ] `lib/presentation/providers/stage_provider.dart`
- [ ] `lib/presentation/providers/game_provider.dart`
- [ ] `lib/presentation/providers/ad_provider.dart`
- [ ] `lib/presentation/providers/booster_provider.dart`
- [ ] `lib/presentation/providers/iap_provider.dart`

## Phase 5: Ad & IAP Integration
- [ ] `lib/utils/ad_helpers.dart` - AdMob initialization & tenure cadence
- [ ] `lib/utils/receipt_validator.dart` - IAP receipt validation
- [ ] AdMob: rewarded (revive/booster), interstitial (stage transitions), banner (map)
- [ ] IAP: booster purchases, remove ads
- [ ] Tenure-based interstitial cooldown (Days 0-2: 120s, 2-7: 100s, 7+: 90s)

## Phase 6: Daily Stage Release System
- [ ] Remote config / HTTP endpoint for stage packs
- [ ] Local caching of stages
- [ ] Unlock by date + progression logic
- [ ] contentVersion management

## Phase 7: Testing & Polish
- [ ] Unit tests for rules_engine
- [ ] Widget tests for stage_node, map_screen
- [ ] Golden tests for map layout
- [ ] Integration test: map -> game -> win/lose -> save

## Release Policy
- **New stages**: Delivered via remote config, NO app update required
- **Security / Bug fixes**: App store update required (bump pubspec.yaml version)
