# Decisions

Design and engineering decisions that shape the game. Keep this file in sync
whenever a rule, stage-pack rule, or economy rule changes.

## Stage generation

### D1 — Stages must have exactly one rule-legal solution
**Decision:** Any generated board whose solution set is not unique is rejected
and never shipped.

**Why:** The game gates placement strictly on the stage's bundled `solution`
(correct cell = rabbit, any other cell = shake + red X + −1 heart). If a board
admitted a second rule-legal placement, a player could make a perfectly valid
move by the rules and still be punished for it. That is unfair and impossible
to explain.

**How it is enforced:**
- `tool/generate_ramp.py` counts rule-legal solutions (cap 2) with
  row/column/region pruning plus the no-diagonal-touch constraint, and retries
  whenever the count is not exactly 1.
- `test/rules_engine_test.dart` re-counts solutions for every bundled stage and
  fails the build if any stage admits more than one.

**Consequence:** Region sizes are uneven by design (typically one small region,
median ≈ board size, one large region). Perfectly balanced regions almost never
produce unique puzzles, so balance is traded away for fairness.

### D2 — Regions must be contiguous
Every colour is one edge-connected blob, never two islands. Two separated
blobs of the same colour read as a mistake and make the region rule ambiguous.

### D3 — Region count equals board size
One colour per rabbit, so a solved board always holds exactly `boardSize`
rabbits. Board sizes run 4×4 to 10×10 across 100 stages (3×3 is never used: it
can only hold 2 rabbits).

### D4 — Booster tutorial in the first five stages
Players receive 3 of every booster for free and see a short booster
introduction when they enter one of stages 1–5. After that each booster is
bought individually with coins (Hint 50, Extra Life 80, Reveal Cell 120) or a
rewarded ad. The old "3 boosters for 100 coins" bundle dialog was removed.

### D5a — Coins are bought, boosters are not
Real money only buys coin packages (100 / 550 / 1200 coins, `coin_config.dart`).
Boosters are never sold for money directly, so pricing stays in one currency.
In debug builds a coin package tap grants the coins locally when the store
product is missing, so the flow can be tested before Play Console setup.

### D5 — Passed stages are permanent
`bestStageIndex` / `unlockedStageIndex` only move forward. A stage that has
already been earned never re-locks, even if the player loses all lives on a
later attempt. The 5-life pool gates *starting* a stage, not keeping progress.

## Currency

### D6 — Coins are the map currency
Completing a stage awards coins equal to the stars earned (1–3); special stages
award 5 coins to reflect a flawless clear. The map header shows the coin total
with a coin icon, not stars.
