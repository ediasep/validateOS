class Validation {
  final String id;
  final String userId;
  final String solutionId;
  final String method;
  final String hypothesis;
  final String successSignal;
  final String result;
  final String? evidence;
  final String? dateRun;
  final String createdAt;

  Validation({
    required this.id,
    required this.userId,
    required this.solutionId,
    required this.method,
    required this.hypothesis,
    required this.successSignal,
    required this.result,
    this.evidence,
    this.dateRun,
    required this.createdAt,
  });

  factory Validation.fromJson(Map<String, dynamic> json) {
    return Validation(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      solutionId: json['solution_id'] as String,
      method: json['method'] as String,
      hypothesis: json['hypothesis'] as String,
      successSignal: json['success_signal'] as String,
      result: json['result'] as String,
      evidence: json['evidence'] as String?,
      dateRun: json['date_run'] as String?,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'solution_id': solutionId,
      'method': method,
      'hypothesis': hypothesis,
      'success_signal': successSignal,
      'result': result,
      'evidence': evidence,
      'date_run': dateRun,
    };
  }
}
