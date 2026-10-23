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
      starterBunnyRow: _starter(json, 'starterBunnyRow', 'starterRabbitRow'),
      starterBunnyCol: _starter(json, 'starterBunnyCol', 'starterRabbitCol'),
      solution: solution,
    );
  }

  /// Reads a starter coordinate, accepting both the new `starterBunny*` keys
  /// and the legacy `starterRabbit*` keys used by bundled/remote packs.
  static int _starter(
    Map<String, dynamic> json,
    String key,
    String legacyKey,
  ) =>
      (json[key] as int?) ?? (json[legacyKey] as int?) ?? -1;

  Map<String, dynamic> toJson() => {
        'id': id,
        'unlockDate': unlockDate.toIso8601String(),
        'difficulty': difficulty,
        'isSpecial': isSpecial,
        'regionGrid': regionGrid,
        'starterBunnyRow': starterBunnyRow,
        'starterBunnyCol': starterBunnyCol,
        // Legacy keys keep older clients / remote packs in sync.
        'starterRabbitRow': starterBunnyRow,
        'starterRabbitCol': starterBunnyCol,
        'solution': solution,
      };

  /// Number of distinct regions (colors) on this board.
  int get regionCount => regionGrid.expand((row) => row).toSet().length;

  /// Whether this stage ships a locked starter bunny.
  bool get hasStarter => starterBunnyRow >= 0 && starterBunnyCol >= 0;

  /// Checks if this is a special stage (every 10th).
  bool get isSpecialStage => id % 10 == 0;
}
