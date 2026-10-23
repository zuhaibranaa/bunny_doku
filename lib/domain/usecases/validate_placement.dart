import '../../utils/rules_engine.dart';

/// Validates a bunny placement against game rules.
class ValidatePlacementUseCase {
  final RulesEngine rulesEngine;

  ValidatePlacementUseCase({required this.rulesEngine});

  bool execute({
    required int row,
    required int col,
    required Set<String> placements,
  }) {
    return rulesEngine.isLegalPlacement(row, col, placements);
  }
}
