class UserSettings {
  final String id;
  final String userId;
  final String? geminiApiKey;
  final String preferredModel;
  final String createdAt;
  final String updatedAt;

  UserSettings({
    required this.id,
    required this.userId,
    this.geminiApiKey,
    required this.preferredModel,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      geminiApiKey: json['gemini_api_key'] as String?,
      preferredModel: json['preferred_model'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toUpsertJson() {
    return {
      'gemini_api_key': geminiApiKey,
      'preferred_model': preferredModel,
    };
  }

  UserSettings copyWith({
    String? id,
    String? userId,
    String? geminiApiKey,
    String? preferredModel,
    String? createdAt,
    String? updatedAt,
  }) {
    return UserSettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      preferredModel: preferredModel ?? this.preferredModel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
