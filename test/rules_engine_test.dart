import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:bunny_doku/config/difficulty_config.dart';
import 'package:bunny_doku/utils/rules_engine.dart';

/// Counts rule-legal solutions of [grid], stopping once [cap] are found.
/// A unique solution means every rule-legal move is the authored move.
int countSolutions(List<List<int>> grid, {int cap = 2}) {
  final n = grid.length;
  final colsUsed = List<bool>.filled(n, false);
  final regionsUsed = List<bool>.filled(n, false);
  final placed = List<int>.filled(n, 0);
  var found = 0;

  void backtrack(int row) {
    if (found >= cap) return;
    if (row == n) {
      found++;
      return;
    }
    for (var col = 0; col < n; col++) {
      if (colsUsed[col] || regionsUsed[grid[row][col]]) continue;
      if (row > 0 && (col - placed[row - 1]).abs() <= 1) continue;
      colsUsed[col] = true;
      regionsUsed[grid[row][col]] = true;
      placed[row] = col;
      backtrack(row + 1);
      colsUsed[col] = false;
      regionsUsed[grid[row][col]] = false;
    }
  }

  backtrack(0);
  return found;
}

/// True when every cell of [region] is reachable from every other by
/// edge-adjacent steps — i.e. the colour is one blob, not two.
bool regionIsContiguous(List<List<int>> grid, int region) {
  final n = grid.length;
  int? startRow;
  int? startCol;
  var total = 0;
  for (var r = 0; r < n; r++) {
    for (var c = 0; c < n; c++) {
      if (grid[r][c] == region) {
        total++;
        startRow ??= r;
        startCol ??= c;
      }
    }
  }
  if (total == 0) return false;

  final seen = <String>{RulesEngine.key(startRow!, startCol!)};
  final queue = <List<int>>[
    [startRow, startCol],
  ];
  while (queue.isNotEmpty) {
    final cell = queue.removeAt(0);
    const deltas = [
      [-1, 0],
      [1, 0],
      [0, -1],
      [0, 1],
    ];
    for (final d in deltas) {
      final nr = cell[0] + d[0];
      final nc = cell[1] + d[1];
      if (nr < 0 || nr >= n || nc < 0 || nc >= n) continue;
      if (grid[nr][nc] != region) continue;
      if (!seen.add(RulesEngine.key(nr, nc))) continue;
      queue.add([nr, nc]);
    }
  }
  return seen.length == total;
}

void main() {
  final pack = jsonDecode(
    File('assets/stages/stage_pack_v1.json').readAsStringSync(),
  ) as List;

  List<List<int>> gridOf(Map<String, dynamic> stage) =>
      (stage['regionGrid'] as List)
          .map((r) => List<int>.from(r as List))
          .toList();

  group('key / parse', () {
    test('round trips', () {
      final k = RulesEngine.key(3, 7);
      expect(k, '3,7');
      final p = RulesEngine.parse(k);
      expect(p.row, 3);
      expect(p.col, 7);
    });
  });

  group('stage pack', () {
    test('contains 1000 stages numbered 1..1000', () {
      expect(pack.length, DifficultyConfig.stageCount);
      for (var i = 0; i < pack.length; i++) {
        expect((pack[i] as Map)['id'], i + 1);
      }
    });

    test('every stage is a square board between 5x5 and 10x10', () {
      for (final stage in pack) {
        final id = stage['id'];
        final grid = gridOf(stage);
        expect(
            grid.length,
            inInclusiveRange(
                DifficultyConfig.minBoardSize, DifficultyConfig.maxBoardSize),
            reason: 'stage $id');
        for (final row in grid) {
          expect(row.length, grid.length, reason: 'stage $id must be square');
        }
      }
    });

    test('no stage uses a board smaller than 5x5', () {
      for (final stage in pack) {
        expect(gridOf(stage).length, greaterThanOrEqualTo(5),
            reason: 'stage ${stage['id']} is too small to be a fair puzzle');
      }
    });

    test('region count equals the board size (one colour per rabbit)', () {
      for (final stage in pack) {
        final id = stage['id'];
        final grid = gridOf(stage);
        final ids = grid.expand((r) => r).toSet();
        expect(ids.length, grid.length, reason: 'stage $id');
      }
    });

    test('region ids are contiguous 0..regionCount-1 and each region is used',
        () {
      for (final stage in pack) {
        final id = stage['id'];
        final grid = gridOf(stage);
        final ids = grid.expand((r) => r).toSet();
        expect(ids, equals({for (var i = 0; i < ids.length; i++) i}),
            reason: 'stage $id region ids must be 0..${ids.length - 1}');
      }
    });

    test('every region is contiguous — a colour never splits into two blobs',
        () {
      for (final stage in pack) {
        final id = stage['id'];
        final grid = gridOf(stage);
        for (final region in grid.expand((r) => r).toSet()) {
          expect(regionIsContiguous(grid, region), isTrue,
              reason: 'stage $id region $region is disconnected');
        }
      }
    });

    test('board sizes stay inside their difficulty band', () {
      // Sizes are random inside a band, so a stage may be smaller than the
      // previous one — what must hold is that every stage honours its band
      // and that the bands themselves ramp upwards.
      for (final stage in pack) {
        final id = stage['id'] as int;
        final size = gridOf(stage).length;
        expect(
            size,
            inInclusiveRange(
                DifficultyConfig.minGridSizeForStage(id),
                DifficultyConfig.maxGridSizeForStage(id)),
            reason: 'stage $id outside its size band');
        expect(
            size,
            inInclusiveRange(
                DifficultyConfig.minBoardSize, DifficultyConfig.maxBoardSize),
            reason: 'stage $id');
      }

      var previousMax = 0;
      for (final (last, lo, hi) in DifficultyConfig.sizeBands) {
        expect(lo, lessThanOrEqualTo(hi), reason: 'band ending at $last');
        expect(hi, greaterThanOrEqualTo(previousMax),
            reason: 'band ending at $last must not shrink the ramp');
        expect(last, lessThanOrEqualTo(DifficultyConfig.stageCount));
        previousMax = hi;
      }
      expect(DifficultyConfig.sizeBands.last.$1, DifficultyConfig.stageCount);
      expect(DifficultyConfig.sizeBands.last.$3, 10);
    });

    test('every stage ships a valid bundled solution', () {
      for (final stage in pack) {
        final id = stage['id'];
        final grid = gridOf(stage);
        final engine = RulesEngine(gridSize: grid.length, regionGrid: grid);
        final bundled = (stage['solution'] as List).cast<String>();

        expect(bundled.length, engine.rabbitCount,
            reason: 'stage $id must hold one rabbit per region');
        expect(engine.isSolved(bundled.toSet()), isTrue,
            reason: 'stage $id bundled solution invalid');
      }
    });

    test('the bundled solution is the only rule-legal solution', () {
      for (final stage in pack) {
        final id = stage['id'];
        final grid = gridOf(stage);
        expect(countSolutions(grid), 1,
            reason: 'stage $id admits more than one solution');
      }
    });

    // Running the generic backtracking solver over all 1000 stages is too
    // slow for CI, so sample a spread across the whole pack (every band, plus
    // first/last) — the full-pack guarantees are covered by the bundled
    // solution / uniqueness tests, which do not need to search.
    test('sampled stages are solvable with their starter (or from scratch)',
        () {
      final indices = <int>{
        0, 1, 2, 3, 4,
        99, 299, 549, 799, 998, 999,
        for (var i = 0; i < pack.length; i += 97) i,
      }.where((i) => i >= 0 && i < pack.length).toList()
        ..sort();

      for (final i in indices) {
        final stage = pack[i];
        final id = stage['id'];
        final grid = gridOf(stage);
        final engine = RulesEngine(gridSize: grid.length, regionGrid: grid);

        final row = stage['starterRabbitRow'] as int;
        final col = stage['starterRabbitCol'] as int;
        final starterKey =
            (row >= 0 && col >= 0) ? RulesEngine.key(row, col) : null;

        final solution = engine.solve(starterKey: starterKey);
        expect(solution, isNotNull,
            reason: 'stage $id must be solvable (starter $starterKey)');
        expect(solution!.length, engine.rabbitCount, reason: 'stage $id');
        expect(engine.isSolved(solution.toSet()), isTrue,
            reason: 'stage $id solved state must validate');
        if (starterKey != null) {
          expect(solution, contains(starterKey),
              reason: 'stage $id solution must keep the locked starter');
        }
      }
    });

    test('starter (when present) is part of the bundled solution', () {
      for (final stage in pack) {
        final row = stage['starterRabbitRow'] as int;
        final col = stage['starterRabbitCol'] as int;
        final bundled = (stage['solution'] as List).cast<String>();
        if (row < 0 || col < 0) {
          expect(row, -1, reason: 'stage ${stage['id']}');
          expect(col, -1, reason: 'stage ${stage['id']}');
        } else {
          expect(bundled, contains(RulesEngine.key(row, col)),
              reason: 'stage ${stage['id']} starter must be in the solution');
        }
      }
    });

    test('some stages ship a starter and some do not', () {
      final withStarter =
          pack.where((s) => (s['starterRabbitRow'] as int) >= 0).length;
      expect(withStarter, greaterThan(0));
      expect(withStarter, lessThan(pack.length));
    });

    test('special stages are every 10th', () {
      for (final stage in pack) {
        final id = stage['id'] as int;
        expect(stage['isSpecial'], id % 10 == 0, reason: 'stage $id');
      }
    });

    test('every stage is a distinct level (layout + solution pattern)', () {
      final seen = <String>{};
      for (final stage in pack) {
        final id = stage['id'];
        final fingerprint =
            '${stage['solution']}|${(stage['regionGrid'] as List)}';
        expect(seen.add(fingerprint), isTrue,
            reason: 'stage $id must not repeat an earlier level');
      }
    });

    test('first stages are the gentlest boards (5x5)', () {
      for (final stage in pack.take(100)) {
        expect(gridOf(stage).length, inInclusiveRange(5, 6),
            reason: 'stage ${stage['id']} should open on the gentlest band');
      }
    });
  });

  group('isLegalPlacement', () {
    // A 10x10 board with 10 row-major regions keeps these checks unambiguous.
    late RulesEngine engine;

    setUp(() {
      final grid = List.generate(10, (r) => List.generate(10, (c) => r));
      engine = RulesEngine(gridSize: 10, regionGrid: grid);
    });

    test('empty board accepts any cell', () {
      expect(engine.isLegalPlacement(0, 0, {}), isTrue);
      expect(engine.isLegalPlacement(9, 9, {}), isTrue);
    });

    test('rejects same row', () {
      expect(engine.isLegalPlacement(0, 5, {'0,0'}), isFalse);
    });

    test('rejects same column', () {
      expect(engine.isLegalPlacement(5, 0, {'0,0'}), isFalse);
    });

    test('rejects diagonal touch', () {
      expect(engine.isLegalPlacement(1, 1, {'0,0'}), isFalse);
      expect(engine.isLegalPlacement(1, 0, {'0,0'}), isFalse); // same column
      expect(engine.isLegalPlacement(0, 1, {'0,0'}), isFalse); // same row
    });

    test('rejects same region only', () {
      // Quadrant regions: (0,0) and (3,4) are in the same top-left region,
      // on different rows/columns and not diagonal-adjacent.
      final grid = List.generate(
          10, (r) => List.generate(10, (c) => (r ~/ 5) * 2 + (c ~/ 5)));
      final quad = RulesEngine(gridSize: 10, regionGrid: grid);
      expect(quad.isLegalPlacement(3, 4, {'0,0'}), isFalse,
          reason: 'same-region placement must be rejected');
      expect(quad.isLegalPlacement(6, 6, {'0,0'}), isTrue,
          reason: 'different region, row and column is legal');
    });

    test('accepts a legal far placement', () {
      expect(engine.isLegalPlacement(4, 4, {'0,0'}), isTrue);
    });
  });

  group('solve / isSolved', () {
    test('solves a full 4x4 board to one rabbit per region', () {
      final grid = [
        [0, 0, 1, 1],
        [0, 0, 1, 1],
        [2, 2, 3, 3],
        [2, 2, 3, 3],
      ];
      final engine = RulesEngine(gridSize: 4, regionGrid: grid);
      expect(engine.regionCount, 4);

      final solution = engine.solve();
      expect(solution, isNotNull);
      expect(solution!.length, 4);
      expect(engine.isSolved(solution.toSet()), isTrue);
    });

    test('solves a small 3x3 board with two regions', () {
      final grid = [
        [0, 1, 1],
        [0, 1, 1],
        [0, 1, 1],
      ];
      final engine = RulesEngine(gridSize: 3, regionGrid: grid);
      expect(engine.regionCount, 2);

      final solution = engine.solve();
      expect(solution, isNotNull);
      expect(solution!.length, 2);
      expect(engine.isSolved(solution.toSet()), isTrue);
    });
  });
}
