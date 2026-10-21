/// Stage data model — matches the remote stage pack JSON schema.
class StageModel {
  final int id;
  final DateTime unlockDate;
  final String difficulty;
  final bool isSpecial;
  final List<List<int>> regionGrid; // square, size 3..10, values 0..n-1
  final int starterRabbitRow;
  final int starterRabbitCol; // -1 / -1 means "no locked starter"
  final List<String> solution; // authoritative "row,col" rabbit positions

  StageModel({
    required this.id,
    required this.unlockDate,
    required this.difficulty,
    required this.isSpecial,
    required this.regionGrid,
    required this.starterRabbitRow,
    required this.starterRabbitCol,
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
      starterRabbitRow: (json['starterRabbitRow'] as int?) ?? -1,
      starterRabbitCol: (json['starterRabbitCol'] as int?) ?? -1,
      solution: solution,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'unlockDate': unlockDate.toIso8601String(),
        'difficulty': difficulty,
        'isSpecial': isSpecial,
        'regionGrid': regionGrid,
        'starterRabbitRow': starterRabbitRow,
        'starterRabbitCol': starterRabbitCol,
        'solution': solution,
      };

  /// Number of distinct regions (colors) on this board.
  int get regionCount => regionGrid.expand((row) => row).toSet().length;

  /// Whether this stage ships a locked starter rabbit.
  bool get hasStarter => starterRabbitRow >= 0 && starterRabbitCol >= 0;

  /// Checks if this is a special stage (every 10th).
  bool get isSpecialStage => id % 10 == 0;
}
