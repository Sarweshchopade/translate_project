class FontUtils {
  /// Get the appropriate font family for different languages
  static String getFontFamily(String languageCode) {
    switch (languageCode) {
      case 'hi': // Hindi
      case 'ne': // Nepali
      case 'mr': // Marathi
        return 'Noto Sans Devanagari';
      case 'ta': // Tamil
        return 'Noto Sans Tamil';
      case 'si': // Sinhala
        return 'Noto Sans Sinhala';
      case 'en': // English
      default:
        return 'Noto Sans';
    }
  }
  
  /// Check if the language uses Devanagari script
  static bool isDevanagariScript(String languageCode) {
    return ['hi', 'ne', 'mr'].contains(languageCode);
  }
  
  /// Check if the language uses Tamil script
  static bool isTamilScript(String languageCode) {
    return languageCode == 'ta';
  }
  
  /// Check if the language uses Sinhala script
  static bool isSinhalaScript(String languageCode) {
    return languageCode == 'si';
  }
}
