class Penalty {
  final String category;
  final String reason;
  final int pointsDeducted;

  Penalty({
    required this.category,
    required this.reason,
    required this.pointsDeducted,
  });

  factory Penalty.fromJson(Map<String, dynamic> json) {
    return Penalty(
      category: json['category'] ?? '',
      reason: json['reason'] ?? '',
      pointsDeducted: json['points_deducted'] ?? 0,
    );
  }
}

class FairnessScore {
  final int score;
  final String tier;
  final List<Penalty> penalties;

  FairnessScore({
    required this.score,
    required this.tier,
    required this.penalties,
  });

  factory FairnessScore.fromJson(Map<String, dynamic> json) {
    var penaltiesList = json['penalties'] as List? ?? [];
    List<Penalty> penalties = penaltiesList
        .map((i) => Penalty.fromJson(i))
        .toList();

    return FairnessScore(
      score: json['score'] ?? 0,
      tier: json['tier'] ?? 'Unknown',
      penalties: penalties,
    );
  }
}
