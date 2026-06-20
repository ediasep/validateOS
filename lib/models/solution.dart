class Solution {
  final String id;
  final String userId;
  final String problemId;
  final String statement;
  final int feasibilityScore;
  final int excitementScore;
  final bool isChosen;
  final String status;
  final String? notes;
  final String createdAt;

  Solution({
    required this.id,
    required this.userId,
    required this.problemId,
    required this.statement,
    required this.feasibilityScore,
    required this.excitementScore,
    required this.isChosen,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  factory Solution.fromJson(Map<String, dynamic> json) {
    return Solution(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      problemId: json['problem_id'] as String,
      statement: json['statement'] as String,
      feasibilityScore: json['feasibility_score'] as int,
      excitementScore: json['excitement_score'] as int,
      isChosen: json['is_chosen'] as bool,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'problem_id': problemId,
      'statement': statement,
      'feasibility_score': feasibilityScore,
      'excitement_score': excitementScore,
      'is_chosen': isChosen,
      'status': status,
      'notes': notes,
    };
  }

  int get combinedScore => feasibilityScore * excitementScore;
}
