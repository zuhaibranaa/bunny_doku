/// Pure validation engine for Rabit_doku placement rules.
/// No Flutter dependencies. Fully testable in isolation.
class RulesEngine {
  final int gridSize;
  final List<List<int>> regionGrid; // region id per cell (0-9)

  RulesEngine({
    required this.gridSize,
    required this.regionGrid,
  });

  /// Returns a string key for a cell position.
  static String key(int row, int col) => '$row,$col';

  /// Number of distinct colored regions on the board. A solved board holds
  /// exactly one rabbit per region, so this is also the rabbit target count.
  int get regionCount => regionGrid.expand((row) => row).toSet().length;

  /// Expected rabbit count for a solved board.
  int get rabbitCount => regionCount;

  /// Parses a position key back to row and col.
  static ({int row, int col}) parse(String keyStr) {
    final parts = keyStr.split(',');
    return (row: int.parse(parts[0]), col: int.parse(parts[1]));
  }

  /// Returns true if placing a rabbit at [row],[col] is legal given
  /// existing [placements] (Set of position keys).
  bool isLegalPlacement(int row, int col, Set<String> placements) {
    // Rule 1: one rabbit per row
    if (placements.any((k) => parse(k).row == row)) return false;

    // Rule 2: one rabbit per column
    if (placements.any((k) => parse(k).col == col)) return false;

    // Rule 3: no diagonal adjacency (8 surrounding cells)
    for (final k in placements) {
      final p = parse(k);
      final dr = (p.row - row).abs();
      final dc = (p.col - col).abs();
      if (dr <= 1 && dc <= 1 && !(dr == 0 && dc == 0)) return false;
    }

    // Rule 4: one rabbit per region (color)
    final regionId = regionGrid[row][col];
    if (placements.any((k) => regionGrid[parse(k).row][parse(k).col] == regionId)) {
      return false;
    }

    return true;
  }

  /// Returns true if the board is fully solved:
  /// every region has exactly one rabbit and all rules hold.
  bool isSolved(Set<String> placements) {
    if (placements.length != rabbitCount) return false;

    final regionsWithRabbit = <int>{};
    for (final k in placements) {
      final p = parse(k);
      regionsWithRabbit.add(regionGrid[p.row][p.col]);
    }
    if (regionsWithRabbit.length != rabbitCount) return false;

    final list = placements.toList();
    for (int i = 0; i < list.length; i++) {
      for (int j = i + 1; j < list.length; j++) {
        final pj = parse(list[j]);
        if (!isLegalPlacement(pj.row, pj.col, {key(parse(list[i]).row, parse(list[i]).col)})) {
          return false;
        }
      }
    }
    return true;
  }

  /// Finds one complete legal placement of rabbits (one per row, column,
  /// region, no diagonal touch). Used by Hint / Reveal-Cell boosters and as
  /// a fallback when a stage ships without a bundled solution.
  /// [starterKey] is placed first and never moved. Returns null if unsolvable.
  List<String>? solve({String? starterKey}) {
    final placed = <String>{};
    if (starterKey != null &&
        !starterKey.startsWith('-') &&
        _isInside(starterKey)) {
      placed.add(starterKey);
    }

    final total = gridSize * gridSize;
    final target = rabbitCount;

    bool backtrack(int index) {
      if (placed.length == target) return true;
      if (index >= total) return false;
      // Not enough cells left to reach the target.
      if (placed.length + (total - index) < target) return false;

      final r = index ~/ gridSize;
      final c = index % gridSize;

      if (isLegalPlacement(r, c, placed)) {
        placed.add(key(r, c));
        if (backtrack(index + 1)) return true;
        placed.remove(key(r, c));
      }
      return backtrack(index + 1);
    }

    return backtrack(0) ? placed.toList() : null;
  }

  bool _isInside(String k) {
    final parts = k.split(',');
    if (parts.length != 2) return false;
    final r = int.tryParse(parts[0]);
    final c = int.tryParse(parts[1]);
    if (r == null || c == null) return false;
    return r >= 0 && r < gridSize && c >= 0 && c < gridSize;
  }

  /// Returns all cells blocked by placing a rabbit at [row],[col]
  /// (same row, same column, 8 neighbors, same region).
  Set<String> getBlockedCells(int row, int col, Set<String> placements) {
    final blocked = <String>{};

    // Same row and column
    for (int r = 0; r < gridSize; r++) {
      blocked.add(key(r, col));
    }
    for (int c = 0; c < gridSize; c++) {
      blocked.add(key(row, c));
    }

    // 8 neighbors
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        final nr = row + dr;
        final nc = col + dc;
        if (nr >= 0 && nr < gridSize && nc >= 0 && nc < gridSize) {
          blocked.add(key(nr, nc));
        }
      }
    }

    // Same region
    final regionId = regionGrid[row][col];
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (regionGrid[r][c] == regionId) {
          blocked.add(key(r, c));
        }
      }
    }

    return blocked;
  }
}
