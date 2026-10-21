# Rabit_doku - AI Agent Instructions

## Project Overview
Rabit_doku is a Flutter mobile puzzle game inspired by Meowdoku (rabbit theme).
- Grid: starts at 4×4 (stages 1-8) and grows with difficulty up to 10×10 across 100 bundled stages — region count always equals grid size (1 region color per N rabbits). Board size is random inside each difficulty band, so the authoritative size is the stage's own `regionGrid`
- Rules: 1 rabbit/row | 1 rabbit/column | no diagonal adjacency | 1 rabbit/region
- Starter locked rabbit is **optional** (some stages ship one, some start empty)
- Lives: 5 extra lives (max 5, refill 1 every 5 minutes with countdown) — **map-level entry pool only**: starting a stage consumes 1; at 0 lives no stage can be started
- In-stage hearts: 3 (1 on special stages); wrong placement −1 heart and a persistent red X on the cell; at 0 hearts → game over (rewarded-ad revive restores stage-start hearts). The 5-life pool is never consumed mid-stage
- Stage selection: Candy Crush Saga-style scrollable map
- Daily stages via remote config (no app update for content)
- Boosters: buy with real money (IAP) OR watch rewarded ad
- Ads: AdMob rewarded/interstitial/banner with tenure-based cadence

## Tech Stack
- Flutter (Dart SDK ^3.13.5)
- State management: `provider`
- Local storage: `shared_preferences` + `hive`
- Remote config: `http` + Firebase Remote Config (or custom JSON endpoint)
- Ads: `google_mobile_ads`
- IAP: `in_app_purchase`
- Dates: `intl`
- SVG: `flutter_svg`

## Folder Structure (DO NOT deviate without updating this file)
```
lib/
  main.dart
  config/             app_config.dart, release_config.dart, booster_config.dart, ad_config.dart
  core/
    constants/        app_constants.dart, grid_constants.dart
    errors/           app_exception.dart
    network/          stage_api.dart, remote_config_service.dart
    storage/          local_storage.dart, stage_cache.dart
  data/
    models/           stage_model.dart, booster_model.dart, user_model.dart, purchase_model.dart
    repositories/     stage_repository.dart, booster_repository.dart, user_repository.dart
  domain/
    entities/         stage_entity.dart, booster_entity.dart, game_state_entity.dart, user_entity.dart
    usecases/         load_stages.dart, validate_placement.dart, compute_stars.dart,
                      purchase_booster.dart, watch_ad_for_booster.dart, unlock_next_stage.dart
  presentation/
    screens/          splash_screen.dart, map_screen.dart, stage_popup.dart, game_screen.dart,
                      booster_shop_screen.dart, purchase_screen.dart
    widgets/          stage_node.dart, map_path_painter.dart, grid_cell.dart, heart_counter.dart,
                      booster_button.dart, ad_banner_widget.dart
    providers/        stage_provider.dart, game_provider.dart, ad_provider.dart,
                      booster_provider.dart, iap_provider.dart
  utils/              rules_engine.dart, ad_helpers.dart, date_helpers.dart, receipt_validator.dart
assets/
  stages/             stage_packs JSON
  images/             rabbits, regions, map nodes, stars
  fonts/
```

## Invariants — Never Break These
1. Board size is driven by difficulty: stages 1-8 = 4×4, then grows per `difficulty_config.dart` (`sizeBands`) up to 10×10 over 100 stages, with the size picked at random inside each band. The bundled pack is regenerated with `tool/generate_ramp.py` (solution-first, guaranteed solvable & unique) — never hand-edit `assets/stages/stage_pack_v1.json`. A 3×3 board must NOT be used (it can only hold 2 rabbits, breaking the 4-rabbit rule design).
2. Every region must be **contiguous**: a colour is one edge-connected blob, never two separate islands of the same colour.
3. Region count always equals board size (one colour per rabbit), and the bundled `solution` must be the **only** rule-legal solution — otherwise a move the player can justify by the rules would be marked wrong.
4. Rules Engine enforces: 1 rabbit/row, 1 rabbit/column, no diagonal touch, 1 rabbit/region. At runtime the player may only place a rabbit on a cell of the stage's bundled `solution` (strict pattern — wrong boxes shake + red X + −1 heart).
5. Locked starter rabbit cannot be removed by player.
6. Special stage every 10th stage (10, 20, 30…) forces 1 life instead of 3.
7. Daily stages load from remote config/cache; NEVER require app update for new content.
8. Ad cadence by tenure: Days 0-2 = 120s, Days 2-7 = 100s, Day 7+ = 90s interstitial cooldown.
9. Boosters can be bought via IAP (real money) OR rewarded ad.

## How to Add Daily Stages (No App Update)
1. Publish new stage JSON to remote endpoint / Firebase Remote Config.
2. JSON: stageId, unlockDate, regionGrid (contiguous color ids, one region per row/rabbit), starterRabbit pos, difficulty, isSpecial, solution.
3. App fetches on launch, caches locally, unlocks stages where unlockDate <= today AND previous stage completed.
4. Bump `contentVersion` in `release_config.dart` only; do NOT bump `pubspec.yaml` version. (Also bump `assets/stages/version.json` to match when the bundled pack changes — installed clients reload bundled stages only when the stored version is older.)

## Booster System
Types: HINT, EXTRA_LIFE, UNDO, REVEAL_CELL
- Purchase path 1: IAP via `in_app_purchase` (Google Play Billing / Apple App Store)
- Purchase path 2: Rewarded Ad via `google_mobile_ads`
- Inventory stored in Hive + synced to shared_preferences
- Receipt validation optional (local or server)

## Ad Strategy
- Rewarded video: revive after fail, extra booster — from stage 1
- Interstitial: between levels (win or lose) — from stage 10
- Banner: bottom of map — from stage 10
- Tenure-based interstitial cooldown segmentation

## Testing Requirements
- Unit tests: `rules_engine.dart` (placement validation) and `test/rules_engine_test.dart` must validate the bundled stage pack (contiguity, uniqueness, size ramp, bundled solution)
- Widget tests: `stage_node.dart` (locked/available/completed states)
- Golden tests: map screen layout
- Integration test: map → popup → game → win/lose → stars saved

## PR Rules
- New stage pack → update `assets/stages/` + `contentVersion` + tests
- UI change → `flutter analyze` + `flutter test` + screenshot test
- Ad/IAP change → update config + `DECISIONS.md` if strategy changes
- Rule change → `rules_engine.dart` + all existing level solutions must still validate
