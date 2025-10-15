import 'lib/services/translation_service.dart';

void main() async {
  print('Testing translation service...');
  
  try {
    // Test English to Hindi translation
    final result1 = await TranslationService.translateText('i am running', 'en', 'hi');
    print('English to Hindi: "i am running" -> "$result1"');
    
    // Test English to Nepali translation
    final result2 = await TranslationService.translateText('hello', 'en', 'ne');
    print('English to Nepali: "hello" -> "$result2"');
    
    // Test Hindi to English translation
    final result3 = await TranslationService.translateText('नमस्ते', 'hi', 'en');
    print('Hindi to English: "नमस्ते" -> "$result3"');
    
    print('Translation tests completed successfully!');
  } catch (e) {
    print('Translation test failed: $e');
  }
}
