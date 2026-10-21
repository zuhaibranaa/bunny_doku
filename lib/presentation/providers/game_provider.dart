import 'package:flutter/foundation.dart';

import '../../data/repositories/booster_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../utils/rules_engine.dart';

class GameProvider extends ChangeNotifier {
  final BoosterRepository _boosterRepo;
  final UserRepository _userRepo;
  RulesEngine _rulesEngine;

  Map<String, dynamic>? _gameState;
  List<List<int>> _regionGrid = [];
  int _starterRow = 0;
  int _starterCol = 0;
  bool _isLoading = true;
  String? _error;

  GameProvider({
    required BoosterRepository boosterRepo,
    required UserRepository userRepo,
    required RulesEngine rulesEngine,
  })  : _boosterRepo = boosterRepo,
        _userRepo = userRepo,
        _rulesEngine = rulesEngine;

  Map<String, dynamic>? get gameState => _gameState;
  List<List<int>> get regionGrid => _regionGrid;
  int get starterRow => _starterRow;
  int get starterCol => _starterCol;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isGameOver => _gameState == null ? false : _gameState!['heartsRemaining'] <= 0;

  /// Initializes a new game for [stageId].
  Future<void> initGame({
    required int stageId,
    required List<List<int>> regionGrid,
    required int starterRow,
    required int starterCol,
    required bool isSpecial,
  }) async {
    _isLoading = true;
    _error = null;
    _regionGrid = regionGrid;
    _starterRow = starterRow;
    _starterCol = starterCol;
    // The engine must match this stage's board size (3x3 .. 10x10).
    _rulesEngine = RulesEngine(
      gridSize: regionGrid.isEmpty ? 0 : regionGrid.length,
      regionGrid: regionGrid,
    );
    notifyListeners();

    try {
      // In-stage hearts: 3 on normal stages, 1 on special (every 10th) stages.
      const lives = 3;
      final stageHearts = isSpecial ? 1 : lives;

      _gameState = {
        'stageId': stageId,
        'heartsRemaining': stageHearts,
        'livesStart': stageHearts,
        'isSpecial': isSpecial,
        'placedRabbits': <String>[],
        'xMarks': <String>[],
        'startedAt': DateTime.now(),
      };

      // Add the starter rabbit only when the stage defines one (-1 = none).
      final size = regionGrid.isEmpty ? 0 : regionGrid.length;
      final hasStarter = _starterRow >= 0 &&
          _starterCol >= 0 &&
          _starterRow < size &&
          _starterCol < size;
      if (hasStarter) {
        _gameState = {
          ..._gameState!,
          'placedRabbits': <String>[
            RulesEngine.key(_starterRow, _starterCol)
          ],
        };
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Places or removes a rabbit at [row],[col].
  /// Returns 'placed', 'removed', 'starter' (locked) or 'ignored'.
  /// The caller is responsible for legality checks ([RulesEngine.isLegalPlacement])
  /// and for heart loss on illegal attempts.
  Future<String> toggleRabbit(int row, int col) async {
    if (_gameState == null) return 'ignored';

    try {
      // Defensive type casting - elements might not be Strings
      final rawPlacements = _gameState!['placedRabbits'] as List? ?? <dynamic>[];
      final placements = Set<String>.from(rawPlacements.whereType<String>());
      final key = RulesEngine.key(row, col);
      final isStarter = row == _starterRow && col == _starterCol;

      // Cannot remove starter rabbit
      if (placements.contains(key) && isStarter) {
        return 'starter';
      }

      String result;
      if (placements.contains(key)) {
        // Remove rabbit
        placements.remove(key);
        result = 'removed';
      } else {
        placements.add(key);
        result = 'placed';
      }

      _gameState = {
        ..._gameState!,
        'placedRabbits': placements.toList(),
      };
      notifyListeners();
      return result;
    } catch (_) {
      // Silently ignore errors during toggle
      return 'ignored';
    }
  }

  /// Places or removes an X mark at [row],[col].
  void toggleXMark(int row, int col) {
    if (_gameState == null) return;
    try {
      final marks = Set<String>.from(_gameState!['xMarks'] ?? <String>[]);
      final key = RulesEngine.key(row, col);

      if (marks.contains(key)) {
        marks.remove(key);
      } else {
        // Don't allow X on cells with rabbits
        final placed = Set<String>.from(_gameState!['placedRabbits'] ?? <String>[]);
        if (!placed.contains(key)) {
          marks.add(key);
        }
      }

      _gameState = {
        ..._gameState!,
        'xMarks': marks.toList(),
      };
      notifyListeners();
    } catch (_) {
      // Silently ignore errors during toggle
    }
  }

  /// Consumes a booster of [type]. Returns true if successful.
  Future<bool> useBooster(String type) async {
    try {
      await _boosterRepo.consumeBooster(type);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Decrease the in-stage heart counter by one (wrong placement).
  /// Returns the remaining hearts.
  int loseStageHeart() {
    if (_gameState == null) return 0;
    final remaining =
        (_gameState!['heartsRemaining'] as int? ?? 0) - 1;
    _gameState = {
      ..._gameState!,
      'heartsRemaining': remaining.clamp(0, 100),
    };
    notifyListeners();
    return remaining.clamp(0, 100);
  }

  /// Restore [hearts] in-stage hearts (rewarded-ad revive / booster).
  void revive(int hearts) {
    if (_gameState == null) return;
    _gameState = {
      ..._gameState!,
      'heartsRemaining': hearts,
    };
    notifyListeners();
  }

  /// Called when in-stage hearts hit 0: tries to consume an extra life to
  /// refill the stage hearts. Returns false if no extra lives remain (game over).
  bool loseLife() {
    if (_gameState == null) return false;

    // Refill extra lives based on time
    _userRepo.refillLives();

    if (_userRepo.consumeExtraLife()) {
      // Refill stage hearts for a new attempt
      final lives = _gameState!['isSpecial'] == true ? 1 : 3;
      _gameState = {
        ..._gameState!,
        'heartsRemaining': lives,
      };
      notifyListeners();
      return true; // Continue playing
    }

    // No extra lives left - game over
    return false;
  }

  /// Returns blocked cells for a potential placement (for UI highlighting).
  Set<String> getBlockedCells(int row, int col) {
    if (_gameState == null) return {};
    if (_regionGrid.isEmpty) return {};
    final rawPlacements = _gameState!['placedRabbits'] as List? ?? [];
    final placements = Set<String>.from(rawPlacements.whereType<String>());
    return _rulesEngine.getBlockedCells(row, col, placements);
  }

  void disposeGame() {
    _gameState = null;
    _regionGrid = [];
    _isLoading = true;
    notifyListeners();
  }
}
