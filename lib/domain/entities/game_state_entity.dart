/// Domain entity for the current game state during a stage.
class GameStateEntity {
  final int stageId;
  final int heartsRemaining;
  final int livesStart;
  final bool isSpecial;
  final Set<({int row, int col})> placedBunnies;
  final Set<({int row, int col})> xMarks;
  final DateTime startedAt;
  int? hintsUsed;
  int? boostersUsed;

  GameStateEntity({
    required this.stageId,
    required this.heartsRemaining,
    required this.livesStart,
    required this.isSpecial,
    required this.placedBunnies,
    required this.xMarks,
    required this.startedAt,
  });

  int get heartsUsed => livesStart - heartsRemaining;
  bool get isGameOver => heartsRemaining <= 0;
}
