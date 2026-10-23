/// Domain entity for a stage (pure Dart, no Flutter/Hive dependencies).
class StageEntity {
  final int id;
  final DateTime unlockDate;
  final String difficulty;
  final bool isSpecial;
  final List<List<int>> regionGrid; // square, size 3..10
  final int starterBunnyRow;
  final int starterBunnyCol; // -1 / -1 means "no locked starter"
  final List<String> solution; // authoritative "row,col" bunny positions

  StageEntity({
    required this.id,
    required this.unlockDate,
    required this.difficulty,
    required this.isSpecial,
    required this.regionGrid,
    required this.starterBunnyRow,
    required this.starterBunnyCol,
    this.solution = const [],
  });

  bool get isSpecialStage => id % 10 == 0;

  bool get hasStarter => starterBunnyRow >= 0 && starterBunnyCol >= 0;
}
