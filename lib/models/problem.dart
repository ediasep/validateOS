class Problem {
  final String id;
  final String userId;
  final String statement;
  final String targetAudience;
  final int timeSpentScore;
  final int complaintFrequencyScore;
  final bool paysForAlternative;
  final int willingnessToPayScore;
  final int painScore;
  final String? evidenceSummary;
  final String status;
  final String source;
  final String? notes;
  final String createdAt;

  Problem({
    required this.id,
    required this.userId,
    required this.statement,
    required this.targetAudience,
    required this.timeSpentScore,
    required this.complaintFrequencyScore,
    required this.paysForAlternative,
    required this.willingnessToPayScore,
    required this.painScore,
    this.evidenceSummary,
    required this.status,
    required this.source,
    this.notes,
    required this.createdAt,
  });

  factory Problem.fromJson(Map<String, dynamic> json) {
    return Problem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      statement: json['statement'] as String,
      targetAudience: json['target_audience'] as String,
      timeSpentScore: json['time_spent_score'] as int,
      complaintFrequencyScore: json['complaint_frequency_score'] as int,
      paysForAlternative: json['pays_for_alternative'] as bool,
      willingnessToPayScore: json['willingness_to_pay_score'] as int,
      painScore: json['pain_score'] as int,
      evidenceSummary: json['evidence_summary'] as String?,
      status: json['status'] as String,
      source: json['source'] as String,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'statement': statement,
      'target_audience': targetAudience,
      'time_spent_score': timeSpentScore,
      'complaint_frequency_score': complaintFrequencyScore,
      'pays_for_alternative': paysForAlternative,
      'willingness_to_pay_score': willingnessToPayScore,
      'evidence_summary': evidenceSummary,
      'status': status,
      'source': source,
      'notes': notes,
    };
  }

  int get computedPainScore =>
      timeSpentScore +
      complaintFrequencyScore +
      willingnessToPayScore +
      (paysForAlternative ? 5 : 0);
}
