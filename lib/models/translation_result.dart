class TranslationResult {
  final String originalText;
  final String translatedText;
  final String sourceLanguage;
  final String targetLanguage;
  final DateTime timestamp;
  final String mode; // 'text', 'speech', 'image'
  final String? imagePath; // For image translations

  TranslationResult({
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.timestamp,
    required this.mode,
    this.imagePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'originalText': originalText,
      'translatedText': translatedText,
      'sourceLanguage': sourceLanguage,
      'targetLanguage': targetLanguage,
      'timestamp': timestamp.toIso8601String(),
      'mode': mode,
      'imagePath': imagePath,
    };
  }

  factory TranslationResult.fromJson(Map<String, dynamic> json) {
    return TranslationResult(
      originalText: json['originalText'],
      translatedText: json['translatedText'],
      sourceLanguage: json['sourceLanguage'],
      targetLanguage: json['targetLanguage'],
      timestamp: DateTime.parse(json['timestamp']),
      mode: json['mode'],
      imagePath: json['imagePath'],
    );
  }

  TranslationResult copyWith({
    String? originalText,
    String? translatedText,
    String? sourceLanguage,
    String? targetLanguage,
    DateTime? timestamp,
    String? mode,
    String? imagePath,
  }) {
    return TranslationResult(
      originalText: originalText ?? this.originalText,
      translatedText: translatedText ?? this.translatedText,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      timestamp: timestamp ?? this.timestamp,
      mode: mode ?? this.mode,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  @override
  String toString() {
    return 'TranslationResult(originalText: $originalText, translatedText: $translatedText, sourceLanguage: $sourceLanguage, targetLanguage: $targetLanguage, timestamp: $timestamp, mode: $mode, imagePath: $imagePath)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TranslationResult &&
        other.originalText == originalText &&
        other.translatedText == translatedText &&
        other.sourceLanguage == sourceLanguage &&
        other.targetLanguage == targetLanguage &&
        other.timestamp == timestamp &&
        other.mode == mode &&
        other.imagePath == imagePath;
  }

  @override
  int get hashCode {
    return originalText.hashCode ^
        translatedText.hashCode ^
        sourceLanguage.hashCode ^
        targetLanguage.hashCode ^
        timestamp.hashCode ^
        mode.hashCode ^
        imagePath.hashCode;
  }
}
