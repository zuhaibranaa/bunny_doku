import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../config/booster_config.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/storage/local_storage.dart';
import '../../presentation/providers/ad_provider.dart';
import '../../presentation/providers/booster_provider.dart';
import '../../presentation/providers/game_provider.dart';
import '../../presentation/providers/stage_provider.dart';
import '../widgets/grid_cell.dart';
import '../widgets/rabbit_icon.dart';
import '../widgets/refill_countdown.dart';
import '../widgets/x_mark.dart';
import '../../utils/rules_engine.dart';

bool get _isMobile => Platform.isAndroid || Platform.isIOS;

/// Cream / mauve theme matching the reference game.
const Color kCream = Color(0xFFFFF7F0);
const Color kMauve = Color(0xFF8B6B6B);
const Color kOrange = Color(0xFFF5A623);
const Color kGold = Color(0xFFF0C419);

/// The 10x10 Rabit_doku game board — Meowdoku-style controls & animations.
///
/// Controls (same as the reference game):
///  - Single tap on an empty cell  -> place / erase a white X mark (free)
///  - Single tap on a placed rabbit -> remove it (starter is locked)
///  - Double-tap on an empty cell  -> try to place a rabbit;
///    illegal placement = shake + red flash + one heart lost
class GameScreen extends StatefulWidget {
  static const routeName = '/game';

  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

/// Decaying-oscillation curve used for the wrong-placement shake.
class _ShakeCurve extends Curve {
  const _ShakeCurve();

  @override
  double transformInternal(double t) =>
      math.sin(t * math.pi * 6) * (1 - t);
}

class _Floater {
  _Floater({required this.text, required this.color, required this.row, required this.col});
  final String text;
  final Color color;
  final int row;
  final int col;
}

class _GameScreenState extends State<GameScreen> {
  late GameProvider _gameProvider;
  late AdProvider _adProvider;
  late BoosterProvider _boosterProvider;
  late UserRepository _userRepo;
  late StageProvider _stageProvider;

  late RulesEngine _rulesEngine;
  Map<String, dynamic>? _stage;
  List<List<int>> _regionGrid = List.generate(10, (_) => List.filled(10, 0));
  bool _hasStarter = false;
  bool _lifeConsumed = false;

  int get _gridSize => _regionGrid.isEmpty ? 10 : _regionGrid.length;
  int _starterRow = -1;
  int _starterCol = -1;
  bool _initialized = false;
  bool _disposed = false;

  // ---- Game / score state -------------------------------------------------
  int _score = 0;
  final List<Map<String, String>> _history = [];
  List<String>? _solution;

  // ---- Transient animation state ------------------------------------------
  final Map<String, int> _shakeCounts = {};
  final Map<String, int> _flashCounts = {};
  final Set<String> _hintKeys = {};
  final Set<String> _wrongCells = {}; // red X marks after wrong attempts
  final List<_Floater> _floaters = [];
  String? _praiseText;
  Color _praiseColor = Colors.white;
  int _praiseId = 0;
  Timer? _praiseTimer;
  Timer? _hintTimer;

  // ---- Swipe-to-mark state ------------------------------------------------
  final GlobalKey _gridKey = GlobalKey();
  bool _painting = false;
  Offset _dragStart = Offset.zero;
  Offset _lastDragPoint = Offset.zero;
  final Set<String> _swipedCells = {};
  /// Null until the first cell of a drag decides the swipe to be a
  /// select (true) or deselect (false) gesture.
  bool? _dragModeSelect;
  double _cellSlot = 0; // cell width + spacing, set while laying out

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    try {
      _gameProvider = context.read<GameProvider>();
      _adProvider = context.read<AdProvider>();
      _boosterProvider = context.read<BoosterProvider>();
      _userRepo = context.read<UserRepository>();
      _stageProvider = context.read<StageProvider>();

      final args = ModalRoute.of(context)!.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
        _stage = args;
        _parseGrid(args);

        final sr = args['starterRabbitRow'] as int?;
        final sc = args['starterRabbitCol'] as int?;
        _hasStarter = sr != null && sc != null && sr >= 0 && sc >= 0 &&
            sr < _gridSize && sc < _gridSize;
        _starterRow = _hasStarter ? sr! : -1;
        _starterCol = _hasStarter ? sc! : -1;

        _rulesEngine =
            RulesEngine(gridSize: _gridSize, regionGrid: _regionGrid);

        // Prefer the stage's own bundled pattern (strict, authored per game);
        // fall back to solving when a remote stage ships without one.
        final rawSolution = args['solution'];
        if (rawSolution is List && rawSolution.isNotEmpty) {
          _solution = rawSolution.map((e) => e.toString()).toList();
        } else {
          _solution = _rulesEngine.solve(
            starterKey:
                _hasStarter ? RulesEngine.key(_starterRow, _starterCol) : null,
          );
        }
        _initGame();
      } else {
        _rulesEngine =
            RulesEngine(gridSize: _gridSize, regionGrid: _regionGrid);
      }
    } catch (_) {}
  }

  void _parseGrid(Map<String, dynamic> args) {
    final grid = args['regionGrid'];
    if (grid != null && grid is List && grid.isNotEmpty) {
      try {
        final parsed = <List<int>>[];
        for (final row in grid) {
          if (row is! List) continue;
          final cells = List<int>.from(row.whereType<int>());
          if (cells.isNotEmpty) parsed.add(cells);
        }
        // Keep a square board of 3..10 cells per side.
        if (parsed.length >= 3 && parsed.length <= 10) {
          final size = parsed.length;
          final square = parsed
              .where((r) => r.length == size)
              .map((r) => r.sublist(0, size))
              .toList();
          if (square.length == size) {
            _regionGrid = square;
            return;
          }
        }
        _regionGrid = List.generate(10, (_) => List.filled(10, 0));
      } catch (_) {
        _regionGrid = List.generate(10, (_) => List.filled(10, 0));
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _praiseTimer?.cancel();
    _hintTimer?.cancel();
    super.dispose();
  }

  Future<void> _initGame() async {
    if (_stage == null) return;
    try {
      // The 5-life pool is a map-level resource: starting a stage costs
      // one life. Inside the stage only the in-stage hearts matter
      // (3 normal / 1 on special stages).
      _userRepo.refillLives();
      final entered = _userRepo.consumeExtraLife();
      if (!entered) {
        // Defer out of the build phase.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showNoLivesDialog();
        });
        return;
      }
      _lifeConsumed = true;
      await _gameProvider.initGame(
        stageId: _stage!['id'],
        regionGrid: _regionGrid,
        starterRow: _starterRow,
        starterCol: _starterCol,
        isSpecial: _stage!['isSpecial'] ?? false,
      );

      final stageId = _stage!['id'] as int? ?? 1;
      if (stageId == 1 && !LocalStorage.firstRunDone) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showTutorial();
        });
      }

      if (stageId >= 1 && stageId <= 5 && !LocalStorage.boosterTutorialGiven) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await _showBoosterIntro();
          await LocalStorage.setBoosterTutorialGiven(true);
        });
      }
    } catch (_) {}
  }

  Future<void> _showBoosterIntro() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kCream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Boosters',
          style: TextStyle(color: kMauve, fontWeight: FontWeight.bold),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You got 3 of each booster for free!', style: TextStyle(color: kMauve)),
            SizedBox(height: 6),
            Text('• Hint - reveals a correct rabbit', style: TextStyle(color: kMauve)),
            SizedBox(height: 6),
            Text('• Undo - reverses your last move', style: TextStyle(color: kMauve)),
            SizedBox(height: 6),
            Text('• Reveal Cell - shows a rabbit position', style: TextStyle(color: kMauve)),
            SizedBox(height: 6),
            Text('• Later buy 3 boosters for 100 coins of your choice', style: TextStyle(color: kMauve)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kOrange,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _showTutorial() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kCream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Tutorial',
          style: TextStyle(color: kMauve, fontWeight: FontWeight.bold),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Tap empty cell to place/remove X mark', style: TextStyle(color: kMauve)),
            SizedBox(height: 6),
            Text('• Double tap empty cell to place rabbit', style: TextStyle(color: kMauve)),
            SizedBox(height: 6),
            Text('• Tap a rabbit to remove it (starter locked)', style: TextStyle(color: kMauve)),
            SizedBox(height: 6),
            Text('• 1 rabbit per row, column, and color region', style: TextStyle(color: kMauve)),
            SizedBox(height: 6),
            Text('• No adjacent rabbits (including diagonal)', style: TextStyle(color: kMauve)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kOrange,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await LocalStorage.setFirstRunDone(true);
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  // ---- Helpers ------------------------------------------------------------

  Set<String> _placedSet() {
    final state = _gameProvider.gameState;
    if (state == null) return <String>{};
    final raw = state['placedRabbits'] as List? ?? <dynamic>[];
    return Set<String>.from(raw.whereType<String>());
  }

  Set<String> _markSet() {
    final state = _gameProvider.gameState;
    if (state == null) return <String>{};
    final raw = state['xMarks'] as List? ?? <dynamic>[];
    return Set<String>.from(raw.whereType<String>());
  }

  int _hearts() {
    final state = _gameProvider.gameState;
    return (state?['heartsRemaining'] as int?) ?? 0;
  }

  // ---- Praise / floaters --------------------------------------------------

  void _showPraise(String text, Color color) {
    if (_disposed) return;
    _praiseTimer?.cancel();
    setState(() {
      _praiseText = text;
      _praiseColor = color;
      _praiseId++;
    });
    _praiseTimer = Timer(const Duration(milliseconds: 950), () {
      if (!_disposed) setState(() => _praiseText = null);
    });
  }

  // ---- Tap controls -------------------------------------------------------

  Future<void> _onCellTap(int row, int col) async {
    try {
      final state = _gameProvider.gameState;
      if (state == null) return;
      final key = RulesEngine.key(row, col);
      final placed = _placedSet();

      if (placed.contains(key)) {
        // Every found rabbit is locked: once a rabbit from the solution is
        // placed, it can never be removed (not just the starter). Tap just
        // gives a gentle nudge.
        setState(() => _shakeCounts[key] = (_shakeCounts[key] ?? 0) + 1);
        return;
      }

      // Single tap on a red (wrong-marked) cell erases the red mark.
      if (_wrongCells.contains(key)) {
        setState(() => _wrongCells.remove(key));
        return;
      }

      // Single tap on empty cell = toggle X mark (free, no heart cost).
      final hadMark = _markSet().contains(key);
      _gameProvider.toggleXMark(row, col);
      final hasMark = _markSet().contains(key);
      setState(() {
        if (hasMark && !hadMark) {
          _history.add({'type': 'x', 'key': key});
        } else if (!hasMark && hadMark) {
          _history.removeWhere(
              (h) => h['type'] == 'x' && h['key'] == key);
        }
      });
    } catch (_) {}
  }

  void _onCellDoubleTap(int row, int col) {
    try {
      final key = RulesEngine.key(row, col);
      final placed = _placedSet();
      if (placed.contains(key)) return;

      _tryPlaceCat(row, col);
    } catch (_) {}
  }

  // ---- Swipe to mark (press and drag across cells without lifting) --------

  /// Cell under a global [global] offset, or null when outside the board.
  List<int>? _cellAt(Offset global) {
    if (_cellSlot <= 0) return null;
    final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return null;
    final local = box.globalToLocal(global);
    final size = _gridSize;
    final col = (local.dx / _cellSlot).floor();
    final row = (local.dy / _cellSlot).floor();
    if (row < 0 || row >= size || col < 0 || col >= size) return null;
    return [row, col];
  }

  /// Walks the line between [from] and [to] so fast drags never skip a cell.
  void _markCellsAlong(Offset from, Offset to) {
    final distance = (to - from).distance;
    final steps = (distance / (_cellSlot <= 0 ? 8 : _cellSlot * 0.5))
        .ceil()
        .clamp(1, 64);
    for (var i = 0; i <= steps; i++) {
      final point = Offset.lerp(from, to, i / steps)!;
      _markCellAt(point);
    }
  }

  /// Applies the drag's mode to the cell under [global].
  ///
  /// The first cell touched decides the whole swipe: if it was unmarked the
  /// drag *selects* (marks X on) every cell it crosses, and if it was already
  /// marked the drag *deselects* (erases) every cell it crosses. Rabbits and
  /// red wrong-marks are never touched.
  void _markCellAt(Offset global) {
    final cell = _cellAt(global);
    if (cell == null) return;
    final row = cell[0];
    final col = cell[1];
    final key = RulesEngine.key(row, col);

    if (_placedSet().contains(key)) return; // never cover a rabbit
    if (_wrongCells.contains(key)) return; // already red-marked
    if (_swipedCells.contains(key)) return; // already handled this drag
    _swipedCells.add(key);

    final isMarked = _markSet().contains(key);
    final shouldMark = _dragModeSelect ??= !isMarked;

    if (shouldMark && !isMarked) {
      _gameProvider.toggleXMark(row, col);
      setState(() => _history.add({'type': 'x', 'key': key}));
    } else if (!shouldMark && isMarked) {
      _gameProvider.toggleXMark(row, col);
      setState(() => _history
          .removeWhere((h) => h['type'] == 'x' && h['key'] == key));
    }
  }

  /// Double-tap placement attempt: legal -> rabbit pops in + score,
  /// illegal -> shake + red flash + one heart lost.
  Future<void> _tryPlaceCat(int row, int col) async {
    final key = RulesEngine.key(row, col);
    final placed = _placedSet();
    final sol = _solution;

    // Starter is locked; can't place again (but already placed).
    if (sol == null) {
      if (!_rulesEngine.isLegalPlacement(row, col, placed)) {
        await _wrongPlacement(row, col);
        return;
      }
    } else {
      if (!sol.contains(key)) {
        await _wrongPlacement(row, col);
        return;
      }
    }

    // Auto-clear any X the player had on this cell.
    if (_markSet().contains(key)) {
      _gameProvider.toggleXMark(row, col);
      _history.removeWhere((h) => h['type'] == 'x' && h['key'] == key);
    }

    await _placeCat(row, col);
  }

  Future<void> _placeCat(int row, int col) async {
    final result = await _gameProvider.toggleRabbit(row, col);
    if (result != 'placed') return;
    // No rabbit history entry: every rabbit that lands is part of the
    // solution and is locked, so there is nothing to undo for it.
    if (!mounted) return;

    final placed = _placedSet();
    final sol = _solution;
    final solved = sol != null && sol.isNotEmpty
        ? (placed.length == sol.length && sol.every(placed.contains))
        : _rulesEngine.isSolved(placed);

    int bonus = 0;
    String praise = 'Nice';
    Color praiseColor = Colors.white;
    if (solved) {
      bonus = 500;
      praise = 'Great!';
      praiseColor = Colors.green.shade600;
    } else if (placed.length % 3 == 0) {
      bonus = 300;
      praise = 'Clear!';
      praiseColor = kGold;
    }

    setState(() {
      _score += 100 + bonus;
      _praiseText = praise;
      _praiseColor = praiseColor;
      _praiseId++;
      _wrongCells.remove(RulesEngine.key(row, col)); // clear a red mark if one was here
      final f = _Floater(
        text: '+${100 + bonus}',
        color: kOrange,
        row: row,
        col: col,
      );
      _floaters.add(f);
      Timer(const Duration(milliseconds: 950), () {
        if (!_disposed) setState(() => _floaters.remove(f));
      });
    });
    _praiseTimer?.cancel();
    _praiseTimer = Timer(const Duration(milliseconds: 950), () {
      if (!_disposed) setState(() => _praiseText = null);
    });

    if (solved) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) _handleWin();
    }
  }

  /// Wrong placement: shake + red flash, the cell springs back into place
  /// and then keeps a persistent red X until the player erases it.
  /// In-stage hearts only — the 5-life pool is a map-level resource.
  Future<void> _wrongPlacement(int row, int col) async {
    final key = RulesEngine.key(row, col);
    setState(() {
      _shakeCounts[key] = (_shakeCounts[key] ?? 0) + 1;
      _flashCounts[key] = (_flashCounts[key] ?? 0) + 1;
    });

    // After the shake finishes the cell gets its red mark.
    Timer(const Duration(milliseconds: 380), () {
      if (!_disposed) setState(() => _wrongCells.add(key));
    });

    final remaining = _gameProvider.loseStageHeart();
    if (remaining <= 0 && mounted) {
      _showGameOverDialog();
    }
  }

  // ---- Boosters -----------------------------------------------------------

  String? _nextSolutionCell() {
    final placed = _placedSet();
    final sol = _solution;
    if (sol == null) return null;
    for (final k in sol) {
      if (!placed.contains(k)) return k;
    }
    return null;
  }

  Future<void> _useHint() async {
    final target = _nextSolutionCell();
    if (target == null) {
      _showPraise('All rabbits placed!', Colors.teal);
      return;
    }
    final ok = await _boosterProvider.consume(BoosterConfig.hint);
    if (!ok) {
      _snack('No Hint boosters — get more in the shop or watch an ad.');
      return;
    }
    setState(() => _hintKeys.add(target));
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(milliseconds: 2200), () {
      if (!_disposed) setState(() => _hintKeys.remove(target));
    });
  }

  Future<void> _useReveal() async {
    final target = _nextSolutionCell();
    if (target == null) {
      _showPraise('All rabbits placed!', Colors.teal);
      return;
    }
    final ok = await _boosterProvider.consume(BoosterConfig.revealCell);
    if (!ok) {
      _snack('No Reveal boosters — buy them in the shop.');
      return;
    }
    final p = RulesEngine.parse(target);
    await _placeCat(p.row, p.col);
  }

  Future<void> _useUndo() async {
    // Rabbits are locked once placed, so only X-mark history can be undone.
    _history.removeWhere((h) => h['type'] == 'rabbit');
    if (_history.isEmpty) {
      _snack('Nothing to undo.');
      return;
    }
    final ok = await _boosterProvider.consume(BoosterConfig.undo);
    if (!ok) {
      _snack('No Undo boosters — get more in the shop or watch an ad.');
      return;
    }
    final last = _history.removeLast();
    if (last['type'] == 'x') {
      final p = RulesEngine.parse(last['key']!);
      if (_markSet().contains(last['key']!)) {
        _gameProvider.toggleXMark(p.row, p.col);
      }
    }
    if (mounted) setState(() {});
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ));
  }

  // ---- Win / lose flow ----------------------------------------------------

  Future<void> _handleWin() async {
    final hearts = _hearts();
    final stars = hearts >= 3 ? 3 : (hearts == 2 ? 2 : 1);
    final stageId = _stage?['id'] as int? ?? 1;
    final isSpecial = _stage?['isSpecial'] == true;

    // Clearing the stage gives the entry life back.
    if (_lifeConsumed) {
      _lifeConsumed = false;
      _userRepo.refillLives();
      _userRepo.addExtraLife(1);
    }

    try {
      await _stageProvider.markStageCompleted(stageId, stars: stars);
      // Every completed stage adds to the total score shown on the map.
      _userRepo.addStars(stars);
      if (isSpecial) {
        // Special stages reward coins considering completion with 5 stars.
        _userRepo.addCoins(5);
      } else {
        _userRepo.addCoins(stars);
      }
    } catch (_) {}
    if (!mounted) return;
    _showWinDialog(stars);
  }

  int? get _nextStageId {
    final stages = _stageProvider.stages;
    final stageId = _stage?['id'] as int? ?? 1;
    final i = stages.indexWhere((s) => s.id == stageId);
    if (i < 0 || i + 1 >= stages.length) return null;
    final next = stages[i + 1];
    return _stageProvider.isStageUnlocked(next.id) ? next.id : null;
  }

  void _showWinDialog(int stars) {
    final stageId = _stage?['id'] as int? ?? 1;
    final nextId = _nextStageId;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: kCream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Stage Complete!',
          textAlign: TextAlign.center,
          style: TextStyle(color: kMauve, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final filled = i < stars;
                return TweenAnimationBuilder<double>(
                  key: ValueKey('win-star-$i-$stars'),
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 400 + i * 200),
                  curve: Curves.elasticOut,
                  builder: (_, v, __) => Transform.scale(
                    scale: v,
                    child: Icon(
                      filled ? Icons.star : Icons.star_border,
                      size: 40,
                      color: filled ? kGold : Colors.grey.shade300,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            Text(
              'Score: $_score',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: kMauve),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              nav.pop(); // close dialog
              await _adProvider.showInterstitial(stageId);
              if (mounted) nav.pop(); // back to map
            },
            child: const Text('Map'),
          ),
          if (nextId != null)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final nav = Navigator.of(context);
                nav.pop(); // close dialog
                await _adProvider.showInterstitial(stageId);
                nav.pop(); // back to map
                final stages = _stageProvider.stages;
                final next =
                    stages.firstWhere((s) => s.id == nextId);
                nav.pushNamed(GameScreen.routeName, arguments: {
                  'id': next.id,
                  'regionGrid': next.regionGrid,
                  'starterRabbitRow': next.starterRabbitRow,
                  'starterRabbitCol': next.starterRabbitCol,
                  'isSpecial': next.isSpecialStage,
                });
              },
              child: const Text('Next Stage'),
            ),
        ],
      ),
    );
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: kCream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Out of Hearts!',
          textAlign: TextAlign.center,
          style: TextStyle(color: kMauve, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Wrong placements cost hearts. Want to keep going?',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Give Up'),
          ),
          if (_isMobile)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final stageHearts =
                    (_gameProvider.gameState?['livesStart'] as int?) ?? 3;
                final ok = await _adProvider.showRewardedAd((_, __) {
                  _gameProvider.revive(stageHearts);
                });
                if (!ok) _snack('Ad not ready — try again in a moment.');
                if (mounted) Navigator.pop(context);
                if (mounted) setState(() {});
              },
              child: const Text('Watch Ad to Revive'),
            ),
        ],
      ),
    );
  }

  void _showNoLivesDialog() {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: kCream,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'No Lives Available',
            textAlign: TextAlign.center,
            style: TextStyle(color: kMauve, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'You have 0 extra lives.\nLives refill every 5 minutes.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              RefillCountdown(userRepo: _userRepo),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kOrange,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/shop');
              },
              child: const Text('Get Lives'),
            ),
          ],
        ),
      );
    } catch (_) {}
  }

  // ---- Build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    try {
      if (_stage == null) {
        return const Scaffold(
          backgroundColor: kCream,
          body: Center(child: CircularProgressIndicator()),
        );
      }

      final placed = _placedSet();
      final marks = _markSet();
      final hearts = _hearts();
      final isSpecial = _stage!['isSpecial'] ?? false;

      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              backgroundColor: kCream,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Exit game?',
                style: TextStyle(
                  color: kMauve,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: const Text(
                'Do you want to exit this stage? Your progress will be lost.',
                style: TextStyle(color: kMauve),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: kMauve),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kOrange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Exit'),
                ),
              ],
            ),
          );
          if (shouldExit == true && mounted) {
            // `this.context` is the State's own context, which `mounted`
            // guards; the shadowing `build` parameter is not.
            Navigator.of(this.context).pop();
          }
        },
        child: Scaffold(
          backgroundColor: kCream,
          body: SafeArea(
            child: Column(
              children: [
                _buildTopBar(isSpecial),
                _buildLivesRow(hearts, isSpecial),
                _buildRulesPanel(),
                _buildProgressStrip(placed),
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final size = _gridSize;
                          _cellSlot = (constraints.maxWidth + 2) / size;
                          final cellSize = constraints.maxWidth / size;
                          return Stack(
                            children: [
                              Positioned.fill(
                                child: Listener(
                                  key: _gridKey,
                                  behavior: HitTestBehavior.opaque,
                                  onPointerDown: (e) {
                                    _dragStart = e.position;
                                    _lastDragPoint = e.position;
                                    _painting = false;
                                    _swipedCells.clear();
                                    _dragModeSelect = null;
                                  },
                                  onPointerMove: (e) {
                                    if (!_painting) {
                                      if ((e.position - _dragStart).distance < 8) {
                                        return;
                                      }
                                      _painting = true;
                                      // Seed the mode from the cell the drag
                                      // actually started on.
                                      _markCellAt(_dragStart);
                                      _lastDragPoint = _dragStart;
                                    }
                                    // Interpolate so quick swipes never skip cells.
                                    _markCellsAlong(_lastDragPoint, e.position);
                                    _lastDragPoint = e.position;
                                  },
                                  onPointerUp: (_) {
                                    _painting = false;
                                    _swipedCells.clear();
                                    _dragModeSelect = null;
                                  },
                                  onPointerCancel: (_) {
                                    _painting = false;
                                    _swipedCells.clear();
                                    _dragModeSelect = null;
                                  },
                                  child: _buildGrid(placed, marks),
                                ),
                              ),
                              ..._buildFloaters(cellSize),
                              if (_praiseText != null) _buildPraiseOverlay(),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
                _buildBoosterBar(),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      );
    } catch (_) {
      return const Scaffold(
        backgroundColor: kCream,
        body: Center(child: Text('Error loading game')),
      );
    }
  }

  Widget _buildTopBar(bool isSpecial) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: kMauve),
            onPressed: () async {
              final shouldExit = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  backgroundColor: kCream,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    'Exit game?',
                    style: TextStyle(
                      color: kMauve,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: const Text(
                    'Do you want to exit this stage? Your progress will be lost.',
                    style: TextStyle(color: kMauve),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: kMauve),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kOrange,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: const Text('Exit'),
                    ),
                  ],
                ),
              );
              if (shouldExit == true && mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Stage ${_stage!['id']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kMauve,
                    ),
                  ),
                  if (isSpecial) ...[
                    const SizedBox(width: 6),
                    _flameBadge(),
                  ],
                ],
              ),
              Text(
                'Score',
                style: TextStyle(fontSize: 11, color: kMauve.withValues(alpha: 0.7)),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.stars, color: kGold, size: 20),
          const SizedBox(width: 4),
          AnimatedCount(count: _score),
          IconButton(
            icon: const Icon(Icons.shop, color: kMauve),
            onPressed: () => Navigator.pushNamed(context, '/shop'),
          ),
        ],
      ),
    );
  }

  Widget _flameBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF8D6E63),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, size: 12, color: Colors.orangeAccent),
          SizedBox(width: 2),
          Text(
            'Hard',
            style: TextStyle(
                fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildLivesRow(int hearts, bool isSpecial) {
    final maxHearts = isSpecial ? 1 : 3;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // In-stage hearts as golden rabbits (3 normal / 1 special).
          // These are the ONLY lives inside a stage — the 5-life pool
          // lives on the map and is spent when a stage starts.
          TweenAnimationBuilder<double>(
            key: ValueKey('hearts-$hearts'),
            tween: Tween(begin: 1.35, end: 1),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Row(
              children: List.generate(hearts.clamp(0, maxHearts), (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: RabbitIcon(
                    size: 48,
                    bodyColor: kGold,
                    outlineColor: const Color(0xFFB8860B),
                    innerEarColor: const Color(0xFFFFE082),
                    eyeColor: const Color(0xFF5D4037),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        children: [
          _ruleChip(const RabbitIcon(size: 30), '1 rabbit per color'),
          _ruleChip(
              const Icon(Icons.swap_horiz, size: 22, color: kMauve),
              '1 per row & col'),
          _ruleChip(
              const BoldX(size: 22, color: kMauve, strokeWidthRatio: 0.22),
              'no touching'),
        ],
      ),
    );
  }

  Widget _ruleChip(Widget icon, String label) {
    return Expanded(
      child: Container(
        height: 42,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: kMauve.withValues(alpha: 0.08),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 30,
              width: 30,
              child: Center(child: icon),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: const TextStyle(fontSize: 10, color: kMauve),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Fixed-height row of rabbit slots — one per region, always visible.
  ///
  /// A slot starts as a faint outline and fills with a golden rabbit once the
  /// matching region's rabbit is found, so the row never changes height.
  Widget _buildProgressStrip(Set<String> placed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: SizedBox(
        height: 34,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_rulesEngine.regionCount, (regionId) {
            bool cleared = false;
            for (final k in placed) {
              final p = RulesEngine.parse(k);
              if (_regionGrid[p.row][p.col] == regionId) {
                cleared = true;
                break;
              }
            }
            return SizedBox(
              width: 34,
              height: 34,
              child: Center(
                child: TweenAnimationBuilder<double>(
                  key: ValueKey('strip-$regionId-$cleared'),
                  tween: Tween(begin: 0, end: cleared ? 1 : 0),
                  duration: const Duration(milliseconds: 350),
                  curve: cleared ? Curves.elasticOut : Curves.linear,
                  builder: (_, v, __) => Transform.scale(
                    scale: cleared ? v : 1,
                    child: cleared
                        ? const RabbitIcon(
                            size: 30,
                            bodyColor: kGold,
                            outlineColor: Color(0xFFB8860B),
                            innerEarColor: Color(0xFFFFE082),
                            eyeColor: Color(0xFF5D4037),
                          )
                        : RabbitIcon(
                            size: 24,
                            bodyColor: kMauve.withValues(alpha: 0.12),
                            outlineColor: kMauve.withValues(alpha: 0.22),
                            innerEarColor: kMauve.withValues(alpha: 0.15),
                            eyeColor: kMauve.withValues(alpha: 0.25),
                          ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildGrid(Set<String> placed, Set<String> marks) {
    final size = _gridSize;
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: size,
        childAspectRatio: 1,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: size * size,
      itemBuilder: (context, index) {
        try {
          final row = index ~/ size;
          final col = index % size;

          if (row >= _regionGrid.length || col >= _regionGrid[row].length) {
            return const SizedBox();
          }

          final regionId = _regionGrid[row][col];
          final cellKey = RulesEngine.key(row, col);
          final hasRabbit = placed.contains(cellKey);
          final hasXMark = marks.contains(cellKey);
          final isStarter =
              _hasStarter && row == _starterRow && col == _starterCol;
          final shakeCount = _shakeCounts[cellKey] ?? 0;
          final flashCount = _flashCounts[cellKey] ?? 0;
          final hinted = _hintKeys.contains(cellKey);

          Widget cell = GridCell(
            row: row,
            col: col,
            regionId: regionId,
            hasRabbit: hasRabbit,
            isStarter: isStarter,
            hasXMark: hasRabbit ? false : hasXMark,
            isWrongMarked: !hasRabbit && _wrongCells.contains(cellKey),
            regionColor: AppConfig.regionColors[
                regionId.clamp(0, AppConfig.regionColors.length - 1)],
            isHinted: hinted,
            onTap: () => _onCellTap(row, col),
            onDoubleTap: () => _onCellDoubleTap(row, col),
          );

          // Red flash on wrong placement (drawn over the cell).
          if (flashCount > 0) {
            cell = TweenAnimationBuilder<double>(
              key: ValueKey('flash-$cellKey-$flashCount'),
              tween: Tween(begin: 1, end: 0),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOut,
              builder: (_, v, child) => Container(
                foregroundDecoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.55 * v),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: child,
              ),
              child: cell,
            );
          }

          // Denied wobble on wrong placement / starter nudge. Rotates in
          // place so the cell never drifts out of its exact grid slot.
          if (shakeCount > 0) {
            cell = TweenAnimationBuilder<double>(
              key: ValueKey('shake-$cellKey-$shakeCount'),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 340),
              curve: const _ShakeCurve(),
              builder: (_, v, child) => Transform.rotate(
                angle: v * 0.055,
                child: child,
              ),
              child: cell,
            );
          }

          return cell;
        } catch (_) {
          return const SizedBox();
        }
      },
    );
  }

  List<Widget> _buildFloaters(double cellSize) {
    return _floaters.map((f) {
      return Positioned(
        left: (f.col * cellSize) + cellSize / 2 - 26,
        top: f.row * cellSize,
        child: IgnorePointer(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOut,
            builder: (_, v, __) => Opacity(
              opacity: (1 - v).clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, -70 * v),
                child: Text(
                  f.text,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: f.color,
                    shadows: [
                      Shadow(
                        color: Colors.white.withValues(alpha: 0.9),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildPraiseOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: TweenAnimationBuilder<double>(
            key: ValueKey('praise-$_praiseId'),
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 950),
            builder: (_, v, __) {
              final scale = v < 0.35
                  ? 0.4 + (v / 0.35) * 0.8 // 0.4 -> 1.2
                  : 1.2 - ((v - 0.35) / 0.65) * 0.2; // 1.2 -> 1.0
              final opacity = v < 0.7 ? 1.0 : (1 - (v - 0.7) / 0.3).clamp(0.0, 1.0);
              return Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Text(
                    _praiseText ?? '',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: _praiseColor,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBoosterBar() {
    final hintCount = _boosterProvider.getQuantity(BoosterConfig.hint);
    final undoCount = _boosterProvider.getQuantity(BoosterConfig.undo);
    final revealCount = _boosterProvider.getQuantity(BoosterConfig.revealCell);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _boosterButton(
            icon: Icons.lightbulb,
            color: kOrange,
            count: hintCount,
            onTap: _useHint,
          ),
          _boosterButton(
            icon: Icons.undo,
            color: Colors.blueGrey,
            count: undoCount,
            onTap: _useUndo,
          ),
          _boosterButton(
            icon: Icons.visibility,
            color: Colors.teal,
            count: revealCount,
            onTap: _useReveal,
          ),
          _boosterButton(
            icon: Icons.store,
            color: kMauve,
            count: -1, // no badge
            onTap: () => Navigator.pushNamed(context, '/shop'),
          ),
        ],
      ),
    );
  }

  Widget _boosterButton({
    required IconData icon,
    required Color color,
    required int count,
    required VoidCallback onTap,
  }) {
    final disabled = count == 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: disabled ? Colors.grey.shade200 : Colors.white,
              shape: const CircleBorder(),
              elevation: 2,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    icon,
                    size: 26,
                    color: disabled ? Colors.grey.shade400 : color,
                  ),
                ),
              ),
            ),
            if (count >= 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: count > 0 ? color : Colors.red.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Animated score counter (counts up smoothly toward [count]).
class AnimatedCount extends ImplicitlyAnimatedWidget {
  const AnimatedCount({
    super.key,
    required this.count,
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeOut,
  }) : super(duration: duration, curve: curve);

  final int count;

  @override
  AnimatedCountState createState() => AnimatedCountState();
}

class AnimatedCountState extends AnimatedWidgetBaseState<AnimatedCount> {
  IntTween _count = IntTween(begin: 0);

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _count = visitor(
      _count,
      widget.count,
      (dynamic value) => IntTween(begin: value as int),
    ) as IntTween;
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '${_count.evaluate(animation)}',
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: kMauve,
      ),
    );
  }
}
