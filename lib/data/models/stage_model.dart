/// Stage data model — matches the remote stage pack JSON schema.
class StageModel {
  final int id;
  final DateTime unlockDate;
  final String difficulty;
  final bool isSpecial;
  final List<List<int>> regionGrid; // square, size 3..10, values 0..n-1
  final int starterBunnyRow;
  final int starterBunnyCol; // -1 / -1 means "no locked starter"
  final List<String> solution; // authoritative "row,col" bunny positions

  StageModel({
    required this.id,
    required this.unlockDate,
    required this.difficulty,
    required this.isSpecial,
    required this.regionGrid,
    required this.starterBunnyRow,
    required this.starterBunnyCol,
    this.solution = const [],
  });

  factory StageModel.fromJson(Map<String, dynamic> json) {
    final grid = (json['regionGrid'] as List)
        .map((row) => List<int>.from(row as List))
        .toList();

    final rawSolution = json['solution'];
    final solution = rawSolution is List
        ? rawSolution.map((e) => e.toString()).toList()
        : <String>[];

    return StageModel(
      id: json['id'] as int,
      unlockDate: DateTime.parse(json['unlockDate'] as String),
      difficulty: json['difficulty'].toString(),
      isSpecial: json['isSpecial'] as bool? ?? false,
      regionGrid: grid,
      starterBunnyRow: (json['starterBunnyRow'] as int?) ?? -1,
      starterBunnyCol: (json['starterBunnyCol'] as int?) ?? -1,
      solution: solution,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'unlockDate': unlockDate.toIso8601String(),
        'difficulty': difficulty,
        'isSpecial': isSpecial,
        'regionGrid': regionGrid,
        'starterBunnyRow': starterBunnyRow,
        'starterBunnyCol': starterBunnyCol,
        'solution': solution,
      };

  /// Number of distinct regions (colors) on this board.
  int get regionCount => regionGrid.expand((row) => row).toSet().length;

  /// Whether this stage ships a locked starter bunny.
  bool get hasStarter => starterBunnyRow >= 0 && starterBunnyCol >= 0;

  /// Checks if this is a special stage (every 10th).
  bool get isSpecialStage => id % 10 == 0;
}
