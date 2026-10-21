"""Generates assets/stages/stage_pack_v1.json — the first 1000 stages.

Every stage obeys the game invariants (all enforced by `validate`):
  * Square board, size 5..10 (smaller boards can only hold too few rabbits —
    3x3 holds 2 and 4x4 offers almost no variety once puzzles must be unique).
  * Exactly one region (colour) per rabbit: regionCount == boardSize.
  * Regions are CONTIGUOUS — a colour is always a single edge-connected
    shape, never two separate blobs (this is what "same colour must touch"
    means in the level design).
  * One rabbit per row, per column, per region, and no diagonal touch.
  * The authored solution is the ONLY rule-legal solution, so any move the
    player can justify by the rules is the authored move.

Difficulty ramps by board size, with randomness inside each band:

    stages    1-100   5x5..6x6
    stages  101-300   6x6..7x7
    stages  301-550   7x7..8x8
    stages  551-800   8x8..9x9
    stages  801-1000  9x9..10x10

Region painting (the part that makes a puzzle unique):
  1. Pick a random non-attacking placement of rabbits (one per row/column,
     no diagonal touch). That placement is the authored solution and every
     rabbit seeds one region.
  2. Grow each region as a bounded random walk over unclaimed cells while
     keeping the "no boxed rabbit" invariant: every rabbit must keep at
     least one orthogonally adjacent cell that belongs to another region.
     This is what stops a region from swallowing the board and leaving the
     puzzle ambiguous.
  3. Absorb every leftover cell into a neighbouring region (cascading, so
     regions stay connected).
  4. Reject the board unless the solution is unique; otherwise retry.

Output format matches the in-app StageModel (bare JSON list):
  id, unlockDate, difficulty, isSpecial, regionGrid,
  starterRabbitRow, starterRabbitCol (-1 = no starter), solution
"""

import json
import random
import sys
from collections import deque

OUT = "/home/zuhaib/Desktop/Flutter Projects/rabit_doku/assets/stages/stage_pack_v1.json"

MIN_SIZE = 5
MAX_SIZE = 10
STAGE_COUNT = 1000

# Cells a single region may hold at most (3 * board size) — keeps one colour
# from covering half the board while still leaving room for unique puzzles.
MAX_REGION_FACTOR = 3

# (last stage id, (min size, max size)) — size is picked at random in band.
BANDS = [
    (100, (5, 6)),
    (300, (6, 7)),
    (550, (7, 8)),
    (800, (8, 9)),
    (1000, (9, 10)),
]

# Stages that ship a locked starter rabbit (the first few, as a tutorial).
STARTER_STAGES = {1, 2, 3, 4, 5}

CARDINALS = ((-1, 0), (0, 1), (1, 0), (0, -1))


def key(r, c):
    return f"{r},{c}"


def size_for(stage_id, rng):
    for last, (lo, hi) in BANDS:
        if stage_id <= last:
            return rng.randint(lo, hi)
    return MAX_SIZE


def random_solution(n, rng):
    """Random placement of n rabbits: one per row/column, no diagonal touch."""
    for _ in range(4000):
        cols = list(range(n))
        rng.shuffle(cols)
        if all(abs(cols[i] - cols[i + 1]) > 1 for i in range(n - 1)):
            return [(r, cols[r]) for r in range(n)]
    return backtrack_solution(n, rng)


def backtrack_solution(n, rng):
    used = [False] * n
    cols = [0] * n

    def place(r):
        if r == n:
            return True
        order = list(range(n))
        rng.shuffle(order)
        for c in order:
            if used[c] or (r > 0 and abs(c - cols[r - 1]) <= 1):
                continue
            used[c] = True
            cols[r] = c
            if place(r + 1):
                return True
            used[c] = False
        return False

    if not place(0):
        raise RuntimeError(f"no solution for size {n}")
    return [(r, cols[r]) for r in range(n)]


def inside(n, r, c):
    return 0 <= r < n and 0 <= c < n


def no_boxed_rabbit(grid, n, solution):
    """True while every rabbit keeps an orthogonal neighbour in another region.

    A board where a rabbit is walled in by its own colour can never be
    extended into an unambiguous puzzle, so painting stops/refuses such a move.
    """
    for qr, qc in solution:
        own = grid[qr][qc]
        escape = False
        for dr, dc in CARDINALS:
            nr, nc = qr + dr, qc + dc
            if not inside(n, nr, nc):
                continue
            v = grid[nr][nc]
            if v is not None and v != own:
                escape = True
                break
        if not escape:
            return False
    return True


def can_paint(grid, n, solution, r, c, region):
    """Painting (r, c) with [region] must not box any rabbit in."""
    if not inside(n, r, c) or grid[r][c] is not None:
        return False
    grid[r][c] = region
    ok = no_boxed_rabbit(grid, n, solution)
    grid[r][c] = None
    return ok


def paint_regions(n, solution, rng):
    """Grows one contiguous region out of every solution cell.

    Both the order regions grow in and the scan order used to absorb the
    leftover cells are randomised: they change the shape of every colour
    without changing any rule, which is what gives each stage its own look.
    """
    grid = [[None] * n for _ in range(n)]
    for rid, (r, c) in enumerate(solution):
        grid[r][c] = rid

    budget = max(2, (n * n - (n - 1) * 2) // 2)
    order = list(range(n))
    rng.shuffle(order)
    for rid in order:
        qr, qc = solution[rid]
        limit = rng.randint(2, max(2, budget))
        pos = (qr, qc)
        marked = 1
        while marked < limit:
            options = [
                (pos[0] + dr, pos[1] + dc)
                for dr, dc in CARDINALS
                if can_paint(grid, n, solution, pos[0] + dr, pos[1] + dc, rid)
            ]
            if not options:
                break
            pos = rng.choice(options)
            grid[pos[0]][pos[1]] = rid
            marked += 1

    absorb_leftovers(grid, n, rng)
    return grid


def absorb_leftovers(grid, n, rng):
    """Every unclaimed cell joins a neighbouring region (cascading scan)."""
    rows = list(range(n))
    cols = list(range(n))
    if rng.random() < 0.5:
        rows.reverse()
    if rng.random() < 0.5:
        cols.reverse()

    while True:
        unclaimed = False
        for r in rows:
            for c in cols:
                if grid[r][c] is not None:
                    continue
                unclaimed = True
                neighbours = list(CARDINALS)
                rng.shuffle(neighbours)
                adopted = None
                for dr, dc in neighbours:
                    nr, nc = r + dr, c + dc
                    if inside(n, nr, nc) and grid[nr][nc] is not None:
                        adopted = grid[nr][nc]
                if adopted is not None:
                    grid[r][c] = adopted
        if not unclaimed:
            return grid


def relabel(grid):
    """Renumber region ids by first appearance (row-major) -> 0..n-1."""
    n = len(grid)
    mapping = {}
    out = [[0] * n for _ in range(n)]
    nxt = 0
    for r in range(n):
        for c in range(n):
            v = grid[r][c]
            if v not in mapping:
                mapping[v] = nxt
                nxt += 1
            out[r][c] = mapping[v]
    assert nxt == n, "region count must equal board size"
    return out


def regions_contiguous(grid):
    """Every region must be one edge-connected blob."""
    n = len(grid)
    cells = {}
    for r in range(n):
        for c in range(n):
            cells.setdefault(grid[r][c], []).append((r, c))

    for rid, group in cells.items():
        seen = {group[0]}
        queue = deque([group[0]])
        while queue:
            r, c = queue.popleft()
            for dr, dc in CARDINALS:
                nr, nc = r + dr, c + dc
                if inside(n, nr, nc) and grid[nr][nc] == rid:
                    if (nr, nc) not in seen:
                        seen.add((nr, nc))
                        queue.append((nr, nc))
        if len(seen) != len(group):
            return False
    return True


def count_solutions(grid, cap=2):
    """Counts rule-legal solutions, stopping at [cap]."""
    n = len(grid)
    cols_used = [False] * n
    regions_used = [False] * n
    placed = [0] * n
    found = [0]

    def backtrack(r):
        if found[0] >= cap:
            return
        if r == n:
            found[0] += 1
            return
        for c in range(n):
            if cols_used[c] or regions_used[grid[r][c]]:
                continue
            if r > 0 and abs(c - placed[r - 1]) <= 1:
                continue
            cols_used[c] = True
            regions_used[grid[r][c]] = True
            placed[r] = c
            backtrack(r + 1)
            cols_used[c] = False
            regions_used[grid[r][c]] = False

    backtrack(0)
    return found[0]


def region_sizes(grid):
    counts = {}
    for row in grid:
        for v in row:
            counts[v] = counts.get(v, 0) + 1
    return sorted(counts.values())


def difficulty_for(n):
    if n <= 5:
        return "easy"
    if n <= 7:
        return "medium"
    return "hard"


def fingerprint(stage):
    return (tuple(stage["solution"]), tuple(tuple(r) for r in stage["regionGrid"]))


def make_stage(stage_id, rng, seen, attempts=6000):
    n = size_for(stage_id, rng)
    for attempt in range(attempts):
        # Prefer boards with few single-cell regions (they feel like free
        # hints) but relax the preference if the size makes that rare, so
        # generation always finishes.
        if attempt < attempts // 2:
            singleton_cap = 1
        elif attempt < (3 * attempts) // 4:
            singleton_cap = 2
        else:
            singleton_cap = n

        solution = random_solution(n, rng)
        grid = paint_regions(n, solution, rng)
        if not regions_contiguous(grid):
            continue
        sizes = region_sizes(grid)
        if max(sizes) > MAX_REGION_FACTOR * n:
            continue
        if sum(1 for s in sizes if s == 1) > singleton_cap:
            continue
        if count_solutions(grid, cap=2) != 1:
            continue

        grid = relabel(grid)
        cells = [key(r, c) for r, c in solution]
        if stage_id in STARTER_STAGES:
            sr, sc = solution[stage_id % n]
        else:
            sr, sc = -1, -1

        stage = {
            "id": stage_id,
            "unlockDate": "2026-01-01T00:00:00Z",
            "difficulty": difficulty_for(n),
            "isSpecial": stage_id % 10 == 0,
            "regionGrid": grid,
            "starterRabbitRow": sr,
            "starterRabbitCol": sc,
            "solution": cells,
        }
        if fingerprint(stage) in seen:
            continue
        return stage
    raise RuntimeError(f"could not build stage {stage_id} (size {n})")


def validate(stage):
    grid = stage["regionGrid"]
    n = len(grid)
    sol = [(int(k.split(",")[0]), int(k.split(",")[1])) for k in stage["solution"]]

    assert MIN_SIZE <= n <= MAX_SIZE, f"size {n} out of range"
    assert all(len(row) == n for row in grid), "board must be square"

    # Regions: ids contiguous 0..n-1, one cell per rabbit, contiguous shapes.
    ids = {grid[r][c] for r in range(n) for c in range(n)}
    assert ids == set(range(n)), f"region ids must be 0..{n - 1}"
    assert regions_contiguous(grid), "every region must be contiguous"

    # Solution: one per row/column/region, no diagonal touch.
    assert len(sol) == n, "one rabbit per region"
    assert len({r for r, _ in sol}) == n, "one rabbit per row"
    assert len({c for _, c in sol}) == n, "one rabbit per column"
    assert len({grid[r][c] for r, c in sol}) == n, "one rabbit per region"
    for i in range(len(sol)):
        for j in range(i + 1, len(sol)):
            dr = abs(sol[i][0] - sol[j][0])
            dc = abs(sol[i][1] - sol[j][1])
            assert not (dr <= 1 and dc <= 1), "diagonal touch"

    # The authored solution must be the only rule-legal one.
    assert count_solutions(grid, cap=2) == 1, "solution must be unique"

    # Starter (optional) must be part of the solution.
    sr, sc = stage["starterRabbitRow"], stage["starterRabbitCol"]
    if sr >= 0:
        assert (sr, sc) in sol, "starter must be part of the solution"
    else:
        assert sr == -1 and sc == -1, "absent starter must be -1/-1"

    assert stage["isSpecial"] == (stage["id"] % 10 == 0), "special cadence"


def main():
    stages = []
    seen = set()
    for stage_id in range(1, STAGE_COUNT + 1):
        rng = random.Random(20_260_101 + stage_id)
        stage = make_stage(stage_id, rng, seen)
        validate(stage)
        seen.add(fingerprint(stage))
        stages.append(stage)

    with open(OUT, "w") as f:
        json.dump(stages, f, indent=2)

    by_size = {}
    for s in stages:
        n = len(s["regionGrid"])
        by_size[n] = by_size.get(n, 0) + 1

    print(f"wrote {OUT}")
    print(f"stages: {len(stages)}  distinct levels: {len(seen)}")
    print("size histogram: " + ", ".join(
        f"{n}x{n}={by_size.get(n, 0)}" for n in range(MIN_SIZE, MAX_SIZE + 1)))
    for s in stages[:3] + stages[8:10] + stages[-2:]:
        sizes = region_sizes(s["regionGrid"])
        print(f"  stage {s['id']:3d}: {len(s['regionGrid'])}x{len(s['regionGrid'])} "
              f"{s['difficulty']:6s} regions={len(sizes)} "
              f"cells {sizes[0]}..{sizes[-1]} "
              f"starter={s['starterRabbitRow']},{s['starterRabbitCol']}")


if __name__ == "__main__":
    sys.exit(main())
