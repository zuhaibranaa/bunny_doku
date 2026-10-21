/// Domain entity for a stage (pure Dart, no Flutter/Hive dependencies).
class StageEntity {
  final int id;
  final DateTime unlockDate;
  final String difficulty;
  final bool isSpecial;
  final List<List<int>> regionGrid; // square, size 3..10
  final int starterRabbitRow;
  final int starterRabbitCol; // -1 / -1 means "no locked starter"
  final List<String> solution; // authoritative "row,col" rabbit positions

  StageEntity({
    required this.id,
    required this.unlockDate,
    required this.difficulty,
    required this.isSpecial,
    required this.regionGrid,
    required this.starterRabbitRow,
    required this.starterRabbitCol,
    this.solution = const [],
  });

  bool get isSpecialStage => id % 10 == 0;

  bool get hasStarter => starterRabbitRow >= 0 && starterRabbitCol >= 0;
}
