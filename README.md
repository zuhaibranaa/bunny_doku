# 🐰 Bunny Doku

A rabbit-themed logic puzzle game for Android and iOS — a Sudoku-variant where you place rabbits on a coloured grid, one puzzle region at a time.

Built with **Flutter** using a clean, layered architecture, and shipped with **1000 hand-verified puzzle stages**.

---

## 🎯 The Game

Each stage is a square board divided into coloured regions. Place one rabbit in every region such that:

| Rule | Description |
|------|-------------|
| 🐇 One per row | No two rabbits share a row |
| 🐇 One per column | No two rabbits share a column |
| 🐇 No diagonal touch | Rabbits may not sit diagonally adjacent |
| 🐇 One per region | Every coloured region holds exactly one rabbit |

A rabbit is a "queen" — it attacks along rows, columns and diagonals — but each colour region is a cage that admits exactly one rabbit.

---

## ✨ Features

- **1,000 bundled stages**, difficulty ramping from 5×5 to 10×10 boards
- **Candy-Crush-style stage map** with scrollable path, locked/unlocked/completed nodes
- **Unique-solution guarantee** — every authored solution is provably the *only* rule-legal answer, so a move you can justify by the rules is never marked wrong
- **Hearts & lives system** — 3 hearts per stage (1 on special stages every 10th), plus a 5-life entry pool that refills on a timer
- **Boosters** — Hint, Undo, Extra Life, Reveal Cell; earned via rewarded ads or in-app purchase
- **Monetisation** — AdMob rewarded / interstitial / banner ads, in-app purchases, tenure-based ad cooldown
- **Remote daily stages** — new content delivered via remote config, no app update required
- **Offline-first** — bundled stage pack with a local cache and versioned reload

---

## 🏗️ Architecture

Clean architecture with a strict dependency direction (`presentation → domain → data/core`):

```
lib/
├── config/         App config, release config, booster & ad configuration
├── core/           Constants, errors, network (stage API, remote config), storage
├── data/           Models, repositories, local storage & stage cache
├── domain/         Entities and use cases (validate placement, compute stars, unlock stage…)
├── presentation/   Screens, widgets, providers (ChangeNotifier / Provider)
└── utils/          Rules engine, ad helpers, date helpers, receipt validation
```

**State management:** [`provider`](https://pub.dev/packages/provider) — separate `ChangeNotifier`s for stage, game, ads, boosters and IAP.

**Key module — `lib/utils/rules_engine.dart`:**
Pure-Dart, side-effect-free rule engine. Given a board's region grid and the current placements it answers:
- `isLegalPlacement(row, col, placements)` — would this rabbit break a rule?
- `isSolved(placements)` — is the board complete and valid?
- `solve({starterKey})` — backtracking solver used by tests and the hint booster
- `getBlockedCells(row, col, placements)` — which cells a rabbit would attack

---

## 🧪 Testing

```bash
flutter test
```

`test/rules_engine_test.dart` validates the **entire bundled stage pack**, not just a sample:

- every board is square and between 5×5 and 10×10
- region count equals board size (one colour per rabbit)
- every region is **contiguous** — a colour never splits into two separate blobs
- region ids are contiguous and every region is used
- board sizes stay inside their difficulty band
- the bundled solution is valid, and is the **only** rule-legal solution
- sampled stages are solvable from scratch and with their starter rabbit
- starter rabbits (where present) are part of the bundled solution
- special stages occur exactly every 10th stage
- every stage is a distinct level
- the first stages use the gentlest 5×5 boards

---

## 🛠️ Building

**Prerequisites:** Flutter SDK ≥ 3.13.5, Dart ≥ 3.13.5

```bash
# Install dependencies
flutter pub get

# Run on a device
flutter run

# Run tests
flutter test

# Static analysis
flutter analyze
```

**Regenerating the stage pack** (optional — the pack is committed):

```bash
python3 tool/generate_ramp.py
```

`tool/generate_ramp.py` generates the 1,000 stages solution-first and validates each one:

1. Pick a random non-attacking rabbit placement — that placement *is* the solution, and every rabbit seeds one region.
2. Grow each region as a bounded random walk over unclaimed cells, while guaranteeing every rabbit keeps at least one orthogonally adjacent cell owned by another region (this stops a region from swallowing the board and making the puzzle ambiguous).
3. Absorb leftover cells into neighbouring regions, cascading so connectivity is preserved.
4. **Reject the board unless the solution is unique** — otherwise retry.

Difficulty ramp:

| Stages | Board size |
|--------|-----------|
| 1 – 100 | 5×5 → 6×6 |
| 101 – 300 | 6×6 → 7×7 |
| 301 – 550 | 7×7 → 8×8 |
| 551 – 800 | 8×8 → 9×9 |
| 801 – 1000 | 9×9 → 10×10 |

The board size is picked at random *inside* each band, so no two consecutive stages feel the same.

---

## 📦 Tech stack

| Concern | Choice |
|---------|--------|
| Framework | Flutter / Dart 3.13+ |
| State management | `provider` |
| Local storage | `shared_preferences` + `hive` |
| Remote content | `http` + Firebase Remote Config (with custom JSON endpoint fallback) |
| Ads | `google_mobile_ads` (AdMob) |
| In-app purchases | `in_app_purchase` |
| SVG assets | `flutter_svg` |
| Dates | `intl` |

---

## 📄 License

MIT — free to use for learning, portfolio and commercial use.
