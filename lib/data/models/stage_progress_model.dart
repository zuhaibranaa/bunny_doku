/// Stage progress model — tracks completion and stars.
class StageProgressModel {
  final String id; // "userId_stageId"
  final int stageId;
  int starsEarned; // 0-3
  bool isCompleted;
  int bestTimeSeconds;
  int bestHeartsRemaining;
  DateTime completedAt;

  StageProgressModel({
    required this.id,
    required this.stageId,
    this.starsEarned = 0,
    this.isCompleted = false,
    this.bestTimeSeconds = 0,
    this.bestHeartsRemaining = 0,
    DateTime? completedAt,
  }) : completedAt = completedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'stageId': stageId,
        'starsEarned': starsEarned,
        'isCompleted': isCompleted ? 1 : 0,
        'bestTimeSeconds': bestTimeSeconds,
        'bestHeartsRemaining': bestHeartsRemaining,
        'completedAt': completedAt.toIso8601String(),
      };

  factory StageProgressModel.fromJson(Map<String, dynamic> json) {
    return StageProgressModel(
      id: json['id'] as String,
      stageId: json['stageId'] as int,
      starsEarned: json['starsEarned'] as int? ?? 0,
      isCompleted: (json['isCompleted'] as int? ?? 0) == 1,
      bestTimeSeconds: json['bestTimeSeconds'] as int? ?? 0,
      bestHeartsRemaining: json['bestHeartsRemaining'] as int? ?? 0,
      completedAt: DateTime.parse(
        json['completedAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
