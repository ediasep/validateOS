class ProblemEvidence {
  final String id;
  final String userId;
  final String problemId;
  final String platform;
  final String quote;
  final String? url;
  final String foundVia;
  final String createdAt;

  ProblemEvidence({
    required this.id,
    required this.userId,
    required this.problemId,
    required this.platform,
    required this.quote,
    this.url,
    required this.foundVia,
    required this.createdAt,
  });

  factory ProblemEvidence.fromJson(Map<String, dynamic> json) {
    return ProblemEvidence(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      problemId: json['problem_id'] as String,
      platform: json['platform'] as String,
      quote: json['quote'] as String,
      url: json['url'] as String?,
      foundVia: json['found_via'] as String,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'problem_id': problemId,
      'platform': platform,
      'quote': quote,
      'url': url,
      'found_via': foundVia,
    };
  }
}
