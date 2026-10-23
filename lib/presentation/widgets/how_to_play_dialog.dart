import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'rabbit_icon.dart';
import 'x_mark.dart';

/// Cream / mauve theme shared with the game screen.
const Color tCream = Color(0xFF1A1F2E);
const Color tMauve = Color(0xFF6366F1);
const Color tOrange = Color(0xFF22D3EE);
const Color tGold = Color(0xFFA78BFA);

/// What a tutorial mini-grid cell displays.
enum _CellContent { empty, bunny, badBunny, xMark }

/// One cell of a tutorial mini-grid.
class _Cell {
  const _Cell(this.region, [this.content = _CellContent.empty]);

  final int region;
  final _CellContent content;
}

/// A single "How to Play" step: a mini-grid illustration plus copy.
class _Step {
  const _Step({
    required this.title,
    required this.caption,
    required this.grid,
    required this.badge,
  });

  final String title;
  final String caption;
  final List<List<_Cell>> grid;
  final String badge;
}

/// Animated "How to Play" popup.
///
/// Replaces the static instruction chips that used to sit above the board with
/// a step-by-step tutorial that explains every rule with a live mini-grid
/// animation, plus the touch controls.
class HowToPlayDialog extends StatefulWidget {
  const HowToPlayDialog({super.key, this.onFinished});

  /// Called when the player dismisses the tutorial (last step or Skip).
  final VoidCallback? onFinished;

  /// Shows the tutorial as a dialog.
  static Future<void> show(
    BuildContext context, {
    VoidCallback? onFinished,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => HowToPlayDialog(onFinished: onFinished),
    );
  }

  @override
  State<HowToPlayDialog> createState() => _HowToPlayDialogState();
}

class _HowToPlayDialogState extends State<HowToPlayDialog>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _anim;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _anim.dispose();
    super.dispose();
  }

  void _close() {
    Navigator.of(context).pop();
    widget.onFinished?.call();
  }

  void _next() {
    if (_page >= _steps.length - 1) {
      _close();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _prev() {
    if (_page == 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  /// Height of the swipeable step area, scaled to the available screen height
  /// so the dialog never overflows on short devices.
  double _pageHeight(BuildContext context) {
    final screen = MediaQuery.of(context).size.height;
    return (screen * 0.46).clamp(280.0, 380.0);
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _steps.length - 1;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: const Color(0xFF1B2E1B),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ---- Header: title + skip --------------------------------
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 10, 0),
                child: Row(
                  children: [
                    const Icon(Icons.help_outline, color: tOrange, size: 24),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'How to Play',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: tMauve,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _close,
                      child: const Text(
                        'Skip',
                        style: TextStyle(color: tMauve),
                      ),
                    ),
                  ],
                ),
              ),
              // ---- Swipeable steps (mini-grid + copy) --------------------
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                child: SizedBox(
                  height: _pageHeight(context),
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemCount: _steps.length,
                    itemBuilder: (context, index) {
                      final s = _steps[index];
                      return AnimatedBuilder(
                        animation: _anim,
                        builder: (context, _) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 178,
                              child: Center(
                                child: _MiniGrid(
                                  cells: s.grid,
                                  animation: _anim,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: tOrange.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                s.badge,
                                style: const TextStyle(
                                  color: tOrange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              s.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: tMauve,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Flexible(
                              child: Text(
                                s.caption,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  height: 1.35,
                                  color: tMauve.withValues(alpha: 0.85),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              // ---- Page dots ---------------------------------------------
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_steps.length, (i) {
                    final active = i == _page;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 20 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: active ? tOrange : tMauve.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
              // ---- Navigation --------------------------------------------
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Row(
                  children: [
                    if (_page > 0)
                      TextButton.icon(
                        onPressed: _prev,
                        icon: const Icon(Icons.chevron_left, color: tMauve),
                        label: const Text('Back',
                            style: TextStyle(color: tMauve)),
                      )
                    else
                      const SizedBox(width: 8),
                    const Spacer(),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tOrange,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _next,
                      icon: Icon(
                        isLast ? Icons.play_arrow : Icons.chevron_right,
                        size: 20,
                      ),
                      label: Text(isLast ? "Let's Play" : 'Next'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small animated board used to demonstrate a single rule.
class _MiniGrid extends StatelessWidget {
  const _MiniGrid({required this.cells, required this.animation});

  final List<List<_Cell>> cells;
  final Animation<double> animation;

  static const _palette = [
    Color(0xFFE23A3A),
    Color(0xFF3B82F6),
    Color(0xFFF2B705),
    Color(0xFF16A34A),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
  ];

  @override
  Widget build(BuildContext context) {
    final rows = cells.length;
    final cols = cells.isEmpty ? 0 : cells.first.length;

    return Center(
      child: AspectRatio(
        aspectRatio: cols / rows,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cellSize = constraints.maxWidth / cols;
            return Stack(
              children: [
                for (var r = 0; r < rows; r++)
                  for (var c = 0; c < cols; c++)
                    _buildCell(context, r, c, cellSize),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCell(
      BuildContext context, int row, int col, double cellSize) {
    final cell = cells[row][col];
    final color = _palette[cell.region % _palette.length];

    // Stagger the reveal so the board fills in like a live puzzle.
    final index = row * cells.first.length + col;
    final start = (index * 0.08).clamp(0.0, 0.6);
    final t = ((animation.value - start) / 0.4).clamp(0.0, 1.0);
    final eased = Curves.easeOutBack.transform(t);

    return Positioned(
      left: col * cellSize,
      top: row * cellSize,
      width: cellSize,
      height: cellSize,
      child: Padding(
        padding: EdgeInsets.all(cellSize * 0.03),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(cellSize * 0.16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.75),
              width: 1.5,
            ),
          ),
          child: Center(
            child: _content(cell, cellSize, eased, t),
          ),
        ),
      ),
    );
  }

  Widget _content(_Cell cell, double size, double eased, double t) {
    switch (cell.content) {
      case _CellContent.bunny:
        return Transform.scale(
          scale: 0.4 + 0.6 * eased,
          child: Opacity(
            opacity: t,
            child: RabbitIcon(size: size * 0.62),
          ),
        );
      case _CellContent.badBunny:
        // Offending bunny: tinted red and gently shaking.
        return Transform.scale(
          scale: 0.4 + 0.6 * eased,
          child: Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(
                math.sin(animation.value * math.pi * 6) * size * 0.04,
                0,
              ),
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Color(0xFFE53935),
                  BlendMode.srcATop,
                ),
                child: RabbitIcon(size: size * 0.62),
              ),
            ),
          ),
        );
      case _CellContent.xMark:
        return Transform.scale(
          scale: 0.4 + 0.6 * eased,
          child: Opacity(
            opacity: t,
            child: const BoldX(size: 40, color: Colors.white, strokeWidthRatio: 0.2),
          ),
        );
      case _CellContent.empty:
        return const SizedBox.shrink();
    }
  }

  double get animationValue => animation.value;
}

/// The tutorial steps.
final List<_Step> _steps = [
  _Step(
    badge: 'RULE 1',
    title: 'One bunny per colour region',
    caption:
        'Every coloured region holds exactly one bunny. Place a second bunny in the same region and it\'ll be marked wrong.',
    grid: const [
      [_Cell(0, _CellContent.bunny), _Cell(0), _Cell(1), _Cell(1)],
      [_Cell(0, _CellContent.badBunny), _Cell(0), _Cell(1), _Cell(1)],
      [_Cell(2), _Cell(2), _Cell(3), _Cell(3)],
      [_Cell(2), _Cell(2), _Cell(3), _Cell(3)],
    ],
  ),
  _Step(
    badge: 'RULE 2',
    title: 'One bunny per row',
    caption:
        'No two bunnies may share a row. Watch as placing a second bunny in the same row triggers a red error.',
    grid: const [
      [_Cell(0, _CellContent.bunny), _Cell(0), _Cell(1), _Cell(1)],
      [_Cell(0, _CellContent.badBunny), _Cell(2), _Cell(1), _Cell(1)],
      [_Cell(3), _Cell(3), _Cell(1), _Cell(1)],
      [_Cell(3), _Cell(3), _Cell(2), _Cell(2)],
    ],
  ),
  _Step(
    badge: 'RULE 3',
    title: 'One bunny per column',
    caption:
        'No two bunnies may share a column. Placing a second bunny in the same column causes an error.',
    grid: const [
      [_Cell(0, _CellContent.bunny), _Cell(1), _Cell(2), _Cell(2)],
      [_Cell(3), _Cell(1), _Cell(2), _Cell(2)],
      [_Cell(0, _CellContent.badBunny), _Cell(4), _Cell(2), _Cell(2)],
      [_Cell(5), _Cell(5), _Cell(5), _Cell(5)],
    ],
  ),
  _Step(
    badge: 'RULE 4',
    title: 'No touching bunnies',
    caption:
        'Bunnies may not sit side by side or diagonally. Even a corner touch is illegal and shows as an error.',
    grid: const [
      [_Cell(0), _Cell(1), _Cell(2), _Cell(3)],
      [_Cell(0), _Cell(1, _CellContent.bunny), _Cell(2), _Cell(3)],
      [_Cell(4), _Cell(4), _Cell(5, _CellContent.badBunny), _Cell(5)],
      [_Cell(4), _Cell(4), _Cell(5), _Cell(5)],
    ],
  ),
  _Step(
    badge: 'CONTROLS',
    title: 'How to place and mark',
    caption:
        'Double-tap a cell to place a bunny. Tap or swipe across cells to mark them with an X, and tap the X again to clear it. A placed or starter) bunny is locked in place.',
    grid: const [
      [_Cell(0, _CellContent.bunny), _Cell(1), _Cell(2, _CellContent.xMark), _Cell(3)],
      [_Cell(0), _Cell(1), _Cell(2), _Cell(3)],
      [_Cell(4), _Cell(4, _CellContent.bunny), _Cell(5), _Cell(5)],
      [_Cell(4), _Cell(4), _Cell(5), _Cell(5)],
    ],
  ),
];
