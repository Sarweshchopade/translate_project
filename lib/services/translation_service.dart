import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

class TranslationService {
  static const String _baseUrl = 'http://localhost:8000';
  static const Map<String, String> _languageCodes = {
    'en': 'English',
    'hi': 'Hindi',
    'ne': 'Nepali',
    'si': 'Sinhalese',
    'ta': 'Tamil',
    'mr': 'Marathi',
  };

  /// Translate text from source language to target language
  static Future<String> translateText(
    String text,
    String sourceLanguage,
    String targetLanguage,
  ) async {
    try {
      // For offline mode, use local models
      if (await _isOfflineMode()) {
        return await _translateOffline(text, sourceLanguage, targetLanguage);
      } else {
        return await _translateOnline(text, sourceLanguage, targetLanguage);
      }
    } catch (e) {
      throw Exception('Translation failed: ${e.toString()}');
    }
  }

  /// Extract text from image using OCR
  static Future<String> extractTextFromImage(
    File imageFile,
    String sourceLanguage,
  ) async {
    try {
      // For web platform, use mock OCR
      if (kIsWeb) {
        return await _simulateOCRExtraction(imageFile, sourceLanguage);
      }
      
      // For offline mode, use local OCR models
      if (await _isOfflineMode()) {
        return await _extractTextOffline(imageFile, sourceLanguage);
      } else {
        return await _extractTextOnline(imageFile, sourceLanguage);
      }
    } catch (e) {
      throw Exception('OCR extraction failed: ${e.toString()}');
    }
  }

  /// Translate speech to text and then translate the text
  static Future<String> translateSpeech(
    String audioPath,
    String sourceLanguage,
    String targetLanguage,
  ) async {
    try {
      // First convert speech to text
      final text = await _speechToText(audioPath, sourceLanguage);
      
      // Then translate the text
      return await translateText(text, sourceLanguage, targetLanguage);
    } catch (e) {
      throw Exception('Speech translation failed: ${e.toString()}');
    }
  }

  /// Check if offline mode is enabled
  static Future<bool> _isOfflineMode() async {
    // For web platform, always use online mode
    if (kIsWeb) {
      return false;
    }
    
    // Check if models are downloaded and available
    final modelsDir = await _getModelsDirectory();
    return await modelsDir.exists();
  }

  /// Get the models directory
  static Future<Directory> _getModelsDirectory() async {
    if (kIsWeb) {
      // For web, return a dummy directory
      return Directory('/tmp/models');
    }
    final appDir = await getApplicationDocumentsDirectory();
    return Directory(path.join(appDir.path, 'models'));
  }

  /// Online translation using backend API
  static Future<String> _translateOnline(
    String text,
    String sourceLanguage,
    String targetLanguage,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/translate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'source_language': sourceLanguage,
          'target_language': targetLanguage,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['translated_text'] ?? text;
      } else {
        throw Exception('Translation API error: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock translation if backend is not available
      return await _simulateTranslation(text, sourceLanguage, targetLanguage);
    }
  }

  /// Offline translation using local models
  static Future<String> _translateOffline(
    String text,
    String sourceLanguage,
    String targetLanguage,
  ) async {
    // This would use TensorFlow Lite models for offline translation
    // For now, we'll simulate with a simple mapping
    
    // Check if we have the required model
    final modelPath = await _getModelPath(sourceLanguage, targetLanguage);
    if (!await File(modelPath).exists()) {
      throw Exception('Translation model not found. Please download models first.');
    }

    // Simulate translation (replace with actual TensorFlow Lite inference)
    return await _simulateTranslation(text, sourceLanguage, targetLanguage);
  }

  /// Online OCR using backend API
  static Future<String> _extractTextOnline(
    File imageFile,
    String sourceLanguage,
  ) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('$_baseUrl/ocr'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image': base64Image,
          'language': sourceLanguage,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['extracted_text'] ?? '';
      } else {
        throw Exception('OCR API error: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to offline OCR if online fails
      return await _extractTextOffline(imageFile, sourceLanguage);
    }
  }

  /// Offline OCR using local models
  static Future<String> _extractTextOffline(
    File imageFile,
    String sourceLanguage,
  ) async {
    // This would use TensorFlow Lite models for offline OCR
    // For now, we'll simulate with a simple response
    
    // Check if we have the required OCR model
    final ocrModelPath = await _getOCRModelPath(sourceLanguage);
    if (!await File(ocrModelPath).exists()) {
      throw Exception('OCR model not found. Please download models first.');
    }

    // Simulate OCR extraction (replace with actual TensorFlow Lite inference)
    return await _simulateOCRExtraction(imageFile, sourceLanguage);
  }

  /// Speech to text conversion
  static Future<String> _speechToText(
    String audioPath,
    String sourceLanguage,
  ) async {
    try {
      final audioFile = File(audioPath);
      final bytes = await audioFile.readAsBytes();
      final base64Audio = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('$_baseUrl/speech-to-text'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'audio': base64Audio,
          'language': sourceLanguage,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['text'] ?? '';
      } else {
        throw Exception('Speech-to-text API error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Speech-to-text failed: ${e.toString()}');
    }
  }

  /// Get model path for translation
  static Future<String> _getModelPath(String sourceLanguage, String targetLanguage) async {
    final modelsDir = await _getModelsDirectory();
    return path.join(
      modelsDir.path,
      'translation',
      '${sourceLanguage}_$targetLanguage.tflite',
    );
  }

  /// Get OCR model path
  static Future<String> _getOCRModelPath(String language) async {
    final modelsDir = await _getModelsDirectory();
    return path.join(
      modelsDir.path,
      'ocr',
      '${language}_ocr.tflite',
    );
  }

  /// Simulate translation (replace with actual model inference)
  static Future<String> _simulateTranslation(
    String text,
    String sourceLanguage,
    String targetLanguage,
  ) async {
    // Simulate processing delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Enhanced translation dictionary with all language pairs
    final translations = {
      // English to Hindi
      'en_hi': {
        'hello': 'नमस्ते',
        'hi': 'नमस्ते',
        'how are you': 'आप कैसे हैं',
        'thank you': 'धन्यवाद',
        'good morning': 'सुप्रभात',
        'good evening': 'शुभ संध्या',
        'good night': 'शुभ रात्रि',
        'yes': 'हाँ',
        'no': 'नहीं',
        'please': 'कृपया',
        'sorry': 'माफ करें',
        'i am running': 'मैं दौड़ रहा हूं',
        'i am walking': 'मैं चल रहा हूं',
        'i am eating': 'मैं खा रहा हूं',
        'i am sleeping': 'मैं सो रहा हूं',
        'i am working': 'मैं काम कर रहा हूं',
        'i am studying': 'मैं पढ़ रहा हूं',
        'i am happy': 'मैं खुश हूं',
        'i am sad': 'मैं उदास हूं',
        'i am tired': 'मैं थका हुआ हूं',
        'i am hungry': 'मुझे भूख लगी है',
        'i am thirsty': 'मुझे प्यास लगी है',
        'what is your name': 'आपका नाम क्या है',
        'my name is': 'मेरा नाम है',
        'where are you from': 'आप कहां से हैं',
        'i am from': 'मैं से हूं',
        'nice to meet you': 'आपसे मिलकर खुशी हुई',
        'see you later': 'बाद में मिलते हैं',
        'goodbye': 'अलविदा',
        'bye': 'अलविदा',
      },
      // Hindi to English
      'hi_en': {
        'नमस्ते': 'Hello',
        'आप कैसे हैं': 'How are you',
        'धन्यवाद': 'Thank you',
        'सुप्रभात': 'Good morning',
        'शुभ संध्या': 'Good evening',
        'शुभ रात्रि': 'Good night',
        'हाँ': 'Yes',
        'नहीं': 'No',
        'कृपया': 'Please',
        'माफ करें': 'Sorry',
        'मैं दौड़ रहा हूं': 'I am running',
        'मैं चल रहा हूं': 'I am walking',
        'मैं खा रहा हूं': 'I am eating',
        'मैं सो रहा हूं': 'I am sleeping',
        'मैं काम कर रहा हूं': 'I am working',
        'मैं पढ़ रहा हूं': 'I am studying',
        'मैं खुश हूं': 'I am happy',
        'मैं उदास हूं': 'I am sad',
        'मैं थका हुआ हूं': 'I am tired',
        'मुझे भूख लगी है': 'I am hungry',
        'मुझे प्यास लगी है': 'I am thirsty',
        'आपका नाम क्या है': 'What is your name',
        'मेरा नाम है': 'My name is',
        'आप कहां से हैं': 'Where are you from',
        'मैं से हूं': 'I am from',
        'आपसे मिलकर खुशी हुई': 'Nice to meet you',
        'बाद में मिलते हैं': 'See you later',
        'अलविदा': 'Goodbye',
      },
      // English to Nepali
      'en_ne': {
        'hello': 'नमस्कार',
        'hi': 'नमस्कार',
        'how are you': 'तपाईं कसरी हुनुहुन्छ',
        'thank you': 'धन्यवाद',
        'good morning': 'शुभ बिहान',
        'good evening': 'शुभ साँझ',
        'good night': 'शुभ रात्रि',
        'yes': 'हो',
        'no': 'होइन',
        'please': 'कृपया',
        'sorry': 'माफ गर्नुहोस्',
        'i am running': 'म दौडिरहेको छु',
        'i am walking': 'म हिँडिरहेको छु',
        'i am eating': 'म खाइरहेको छु',
        'i am sleeping': 'म सुतिरहेको छु',
        'i am working': 'म काम गरिरहेको छु',
        'i am studying': 'म पढिरहेको छु',
        'i am happy': 'म खुसी छु',
        'i am sad': 'म दुखी छु',
        'i am tired': 'म थकित छु',
        'i am hungry': 'मलाई भोक लागेको छ',
        'i am thirsty': 'मलाई प्यास लागेको छ',
        'what is your name': 'तपाईंको नाम के हो',
        'my name is': 'मेरो नाम हो',
        'where are you from': 'तपाईं कहाँबाट हुनुहुन्छ',
        'i am from': 'म बाट हुँ',
        'nice to meet you': 'तपाईंलाई भेटेर खुसी लाग्यो',
        'see you later': 'पछि भेटौं',
        'goodbye': 'अलविदा',
        'bye': 'अलविदा',
      },
      // Nepali to English
      'ne_en': {
        'नमस्कार': 'Hello',
        'तपाईं कसरी हुनुहुन्छ': 'How are you',
        'धन्यवाद': 'Thank you',
        'शुभ बिहान': 'Good morning',
        'शुभ साँझ': 'Good evening',
        'शुभ रात्रि': 'Good night',
        'हो': 'Yes',
        'होइन': 'No',
        'कृपया': 'Please',
        'माफ गर्नुहोस्': 'Sorry',
        'म दौडिरहेको छु': 'I am running',
        'म हिँडिरहेको छु': 'I am walking',
        'म खाइरहेको छु': 'I am eating',
        'म सुतिरहेको छु': 'I am sleeping',
        'म काम गरिरहेको छु': 'I am working',
        'म पढिरहेको छु': 'I am studying',
        'म खुसी छु': 'I am happy',
        'म दुखी छु': 'I am sad',
        'म थकित छु': 'I am tired',
        'मलाई भोक लागेको छ': 'I am hungry',
        'मलाई प्यास लागेको छ': 'I am thirsty',
        'तपाईंको नाम के हो': 'What is your name',
        'मेरो नाम हो': 'My name is',
        'तपाईं कहाँबाट हुनुहुन्छ': 'Where are you from',
        'म बाट हुँ': 'I am from',
        'तपाईंलाई भेटेर खुसी लाग्यो': 'Nice to meet you',
        'पछि भेटौं': 'See you later',
        'अलविदा': 'Goodbye',
      },
      // Hindi to Nepali
      'hi_ne': {
        'नमस्ते': 'नमस्कार',
        'आप कैसे हैं': 'तपाईं कसरी हुनुहुन्छ',
        'धन्यवाद': 'धन्यवाद',
        'सुप्रभात': 'शुभ बिहान',
        'शुभ संध्या': 'शुभ साँझ',
        'शुभ रात्रि': 'शुभ रात्रि',
        'हाँ': 'हो',
        'नहीं': 'होइन',
        'कृपया': 'कृपया',
        'माफ करें': 'माफ गर्नुहोस्',
        'मैं दौड़ रहा हूं': 'म दौडिरहेको छु',
        'मैं भाग रहा हूँ': 'म दौडिरहेको छु',
        'मैं भाग रहा हूं': 'म दौडिरहेको छु',
        'मैं चल रहा हूं': 'म हिँडिरहेको छु',
        'मैं खा रहा हूं': 'म खाइरहेको छु',
        'मैं सो रहा हूं': 'म सुतिरहेको छु',
        'मैं काम कर रहा हूं': 'म काम गरिरहेको छु',
        'मैं पढ़ रहा हूं': 'म पढिरहेको छु',
        'मैं लिख रहा हूं': 'म लेखिरहेको छु',
        'मैं लिख रहा हूँ': 'म लेखिरहेको छु',
        'मैं खुश हूं': 'म खुसी छु',
        'मैं उदास हूं': 'म दुखी छु',
        'मैं थका हुआ हूं': 'म थकित छु',
        'मुझे भूख लगी है': 'मलाई भोक लागेको छ',
        'मुझे प्यास लगी है': 'मलाई प्यास लागेको छ',
        'आपका नाम क्या है': 'तपाईंको नाम के हो',
        'मेरा नाम है': 'मेरो नाम हो',
        'आप कहां से हैं': 'तपाईं कहाँबाट हुनुहुन्छ',
        'मैं से हूं': 'म बाट हुँ',
        'आपसे मिलकर खुशी हुई': 'तपाईंलाई भेटेर खुसी लाग्यो',
        'बाद में मिलते हैं': 'पछि भेटौं',
        'अलविदा': 'अलविदा',
        // Additional common phrases
        'मैं': 'म',
        'हूं': 'छु',
        'हूँ': 'छु',
        'रहा': 'रहेको',
        'रही': 'रहेकी',
        'दौड़': 'दौड',
        'भाग': 'दौड',
        'चल': 'हिँड',
        'खा': 'खा',
        'सो': 'सुत',
        'काम': 'काम',
        'पढ़': 'पढ',
        'लिख': 'लेख',
        'खुश': 'खुसी',
        'उदास': 'दुखी',
        'थका': 'थकित',
        'भूख': 'भोक',
        'प्यास': 'प्यास',
      },
      // Nepali to Hindi
      'ne_hi': {
        'नमस्कार': 'नमस्ते',
        'तपाईं कसरी हुनुहुन्छ': 'आप कैसे हैं',
        'धन्यवाद': 'धन्यवाद',
        'शुभ बिहान': 'सुप्रभात',
        'शुभ साँझ': 'शुभ संध्या',
        'शुभ रात्रि': 'शुभ रात्रि',
        'हो': 'हाँ',
        'होइन': 'नहीं',
        'कृपया': 'कृपया',
        'माफ गर्नुहोस्': 'माफ करें',
        'म दौडिरहेको छु': 'मैं दौड़ रहा हूं',
        'म हिँडिरहेको छु': 'मैं चल रहा हूं',
        'म खाइरहेको छु': 'मैं खा रहा हूं',
        'म सुतिरहेको छु': 'मैं सो रहा हूं',
        'म काम गरिरहेको छु': 'मैं काम कर रहा हूं',
        'म पढिरहेको छु': 'मैं पढ़ रहा हूं',
        'म लेखिरहेको छु': 'मैं लिख रहा हूं',
        'म खुसी छु': 'मैं खुश हूं',
        'म दुखी छु': 'मैं उदास हूं',
        'म थकित छु': 'मैं थका हुआ हूं',
        'मलाई भोक लागेको छ': 'मुझे भूख लगी है',
        'मलाई प्यास लागेको छ': 'मुझे प्यास लगी है',
        'तपाईंको नाम के हो': 'आपका नाम क्या है',
        'मेरो नाम हो': 'मेरा नाम है',
        'तपाईं कहाँबाट हुनुहुन्छ': 'आप कहां से हैं',
        'म बाट हुँ': 'मैं से हूं',
        'तपाईंलाई भेटेर खुसी लाग्यो': 'आपसे मिलकर खुशी हुई',
        'पछि भेटौं': 'बाद में मिलते हैं',
        'अलविदा': 'अलविदा',
        // Additional common words
        'म': 'मैं',
        'छु': 'हूं',
        'रहेको': 'रहा',
        'रहेकी': 'रही',
        'दौड': 'दौड़',
        'हिँड': 'चल',
        'खा': 'खा',
        'सुत': 'सो',
        'काम': 'काम',
        'पढ': 'पढ़',
        'लेख': 'लिख',
        'खुसी': 'खुश',
        'दुखी': 'उदास',
        'थकित': 'थका',
        'भोक': 'भूख',
        'प्यास': 'प्यास',
      },
      // Marathi to Nepali
      'mr_ne': {
        'नमस्कार': 'नमस्कार',
        'तुम्ही कसे आहात': 'तपाईं कसरी हुनुहुन्छ',
        'धन्यवाद': 'धन्यवाद',
        'सुप्रभात': 'शुभ बिहान',
        'शुभ संध्या': 'शुभ साँझ',
        'शुभ रात्रि': 'शुभ रात्रि',
        'होय': 'हो',
        'नाही': 'होइन',
        'कृपया': 'कृपया',
        'माफ करा': 'माफ गर्नुहोस्',
        'मी धावत आहे': 'म दौडिरहेको छु',
        'मी चालत आहे': 'म हिँडिरहेको छु',
        'मी खात आहे': 'म खाइरहेको छु',
        'मी झोपत आहे': 'म सुतिरहेको छु',
        'मी काम करत आहे': 'म काम गरिरहेको छु',
        'मी अभ्यास करत आहे': 'म पढिरहेको छु',
        'मी आनंदी आहे': 'म खुसी छु',
        'मी दुःखी आहे': 'म दुखी छु',
        'मी थकलो आहे': 'म थकित छु',
        'मला भूक लागली आहे': 'मलाई भोक लागेको छ',
        'मला तहान लागली आहे': 'मलाई प्यास लागेको छ',
        'तुमचे नाव काय आहे': 'तपाईंको नाम के हो',
        'माझे नाव आहे': 'मेरो नाम हो',
        'तुम्ही कोठून आहात': 'तपाईं कहाँबाट हुनुहुन्छ',
        'मी आहे': 'म बाट हुँ',
        'तुम्हाला भेटून आनंद झाला': 'तपाईंलाई भेटेर खुसी लाग्यो',
        'पुन्हा भेटू': 'पछि भेटौं',
        'अलविदा': 'अलविदा',
      },
      // Nepali to Marathi
      'ne_mr': {
        'नमस्कार': 'नमस्कार',
        'तपाईं कसरी हुनुहुन्छ': 'तुम्ही कसे आहात',
        'धन्यवाद': 'धन्यवाद',
        'शुभ बिहान': 'सुप्रभात',
        'शुभ साँझ': 'शुभ संध्या',
        'शुभ रात्रि': 'शुभ रात्रि',
        'हो': 'होय',
        'होइन': 'नाही',
        'कृपया': 'कृपया',
        'माफ गर्नुहोस्': 'माफ करा',
        'म दौडिरहेको छु': 'मी धावत आहे',
        'म हिँडिरहेको छु': 'मी चालत आहे',
        'म खाइरहेको छु': 'मी खात आहे',
        'म सुतिरहेको छु': 'मी झोपत आहे',
        'म काम गरिरहेको छु': 'मी काम करत आहे',
        'म पढिरहेको छु': 'मी अभ्यास करत आहे',
        'म खुसी छु': 'मी आनंदी आहे',
        'म दुखी छु': 'मी दुःखी आहे',
        'म थकित छु': 'मी थकलो आहे',
        'मलाई भोक लागेको छ': 'मला भूक लागली आहे',
        'मलाई प्यास लागेको छ': 'मला तहान लागली आहे',
        'तपाईंको नाम के हो': 'तुमचे नाव काय आहे',
        'मेरो नाम हो': 'माझे नाव आहे',
        'तपाईं कहाँबाट हुनुहुन्छ': 'तुम्ही कोठून आहात',
        'म बाट हुँ': 'मी आहे',
        'तपाईंलाई भेटेर खुसी लाग्यो': 'तुम्हाला भेटून आनंद झाला',
        'पछि भेटौं': 'पुन्हा भेटू',
        'अलविदा': 'अलविदा',
      },
      // English to Sinhalese
      'en_si': {
        'hello': 'හෙලෝ',
        'hi': 'හෙලෝ',
        'how are you': 'ඔබට කොහොමද',
        'thank you': 'ස්තුතියි',
        'good morning': 'සුභ උදෑසනක්',
        'good evening': 'සුභ සන්ධ්‍යාවක්',
        'good night': 'සුභ රාත්‍රියක්',
        'yes': 'ඔව්',
        'no': 'නැත',
        'please': 'කරුණාකර',
        'sorry': 'සමාවන්න',
        'i am running': 'මම දුවනවා',
        'i am walking': 'මම ඇවිදිනවා',
        'i am eating': 'මම කනවා',
        'i am sleeping': 'මම නිදනවා',
        'i am working': 'මම වැඩ කරනවා',
        'i am studying': 'මම ඉගෙන ගන්නවා',
        'i am happy': 'මම සතුටුයි',
        'i am sad': 'මම දුක් වෙනවා',
        'i am tired': 'මම වෙහෙසට පත්යි',
        'i am hungry': 'මට බඩගිනියි',
        'i am thirsty': 'මට පිපාසයි',
        'what is your name': 'ඔබේ නම කුමක්ද',
        'my name is': 'මගේ නම',
        'where are you from': 'ඔබ කොහෙන්ද',
        'i am from': 'මම',
        'nice to meet you': 'ඔබව හමුවීම සතුටක්',
        'see you later': 'පසුව හමුවෙමු',
        'goodbye': 'ආයුබෝවන්',
        'bye': 'ආයුබෝවන්',
      },
      // Sinhalese to English
      'si_en': {
        'හෙලෝ': 'Hello',
        'ඔබට කොහොමද': 'How are you',
        'ස්තුතියි': 'Thank you',
        'සුභ උදෑසනක්': 'Good morning',
        'සුභ සන්ධ්‍යාවක්': 'Good evening',
        'සුභ රාත්‍රියක්': 'Good night',
        'ඔව්': 'Yes',
        'නැත': 'No',
        'කරුණාකර': 'Please',
        'සමාවන්න': 'Sorry',
        'මම දුවනවා': 'I am running',
        'මම ඇවිදිනවා': 'I am walking',
        'මම කනවා': 'I am eating',
        'මම නිදනවා': 'I am sleeping',
        'මම වැඩ කරනවා': 'I am working',
        'මම ඉගෙන ගන්නවා': 'I am studying',
        'මම සතුටුයි': 'I am happy',
        'මම දුක් වෙනවා': 'I am sad',
        'මම වෙහෙසට පත්යි': 'I am tired',
        'මට බඩගිනියි': 'I am hungry',
        'මට පිපාසයි': 'I am thirsty',
        'ඔබේ නම කුමක්ද': 'What is your name',
        'මගේ නම': 'My name is',
        'ඔබ කොහෙන්ද': 'Where are you from',
        'මම': 'I am from',
        'ඔබව හමුවීම සතුටක්': 'Nice to meet you',
        'පසුව හමුවෙමු': 'See you later',
        'ආයුබෝවන්': 'Goodbye',
      },
      // Hindi to Sinhalese
      'hi_si': {
        'नमस्ते': 'හෙලෝ',
        'आप कैसे हैं': 'ඔබට කොහොමද',
        'धन्यवाद': 'ස්තුතියි',
        'सुप्रभात': 'සුභ උදෑසනක්',
        'शुभ संध्या': 'සුභ සන්ධ්‍යාවක්',
        'शुभ रात्रि': 'සුභ රාත්‍රියක්',
        'हाँ': 'ඔව්',
        'नहीं': 'නැත',
        'कृपया': 'කරුණාකර',
        'माफ करें': 'සමාවන්න',
        'मैं दौड़ रहा हूं': 'මම දුවනවා',
        'मैं चल रहा हूं': 'මම ඇවිදිනවා',
        'मैं खा रहा हूं': 'මම කනවා',
        'मैं सो रहा हूं': 'මම නිදනවා',
        'मैं काम कर रहा हूं': 'මම වැඩ කරනවා',
        'मैं पढ़ रहा हूं': 'මම ඉගෙන ගන්නවා',
        'मैं खुश हूं': 'මම සතුටුයි',
        'मैं उदास हूं': 'මම දුක් වෙනවා',
        'मैं थका हुआ हूं': 'මම වෙහෙසට පත්යි',
        'मुझे भूख लगी है': 'මට බඩගිනියි',
        'मुझे प्यास लगी है': 'මට පිපාසයි',
        'आपका नाम क्या है': 'ඔබේ නම කුමක්ද',
        'मेरा नाम है': 'මගේ නම',
        'आप कहां से हैं': 'ඔබ කොහෙන්ද',
        'मैं से हूं': 'මම',
        'आपसे मिलकर खुशी हुई': 'ඔබව හමුවීම සතුටක්',
        'बाद में मिलते हैं': 'පසුව හමුවෙමු',
        'अलविदा': 'ආයුබෝවන්',
      },
      // Sinhalese to Hindi
      'si_hi': {
        'හෙලෝ': 'नमस्ते',
        'ඔබට කොහොමද': 'आप कैसे हैं',
        'ස්තුතියි': 'धन्यवाद',
        'සුභ උදෑසනක්': 'सुप्रभात',
        'සුභ සන්ධ්‍යාවක්': 'शुभ संध्या',
        'සුභ රාත්‍රියක්': 'शुभ रात्रि',
        'ඔව්': 'हाँ',
        'නැත': 'नहीं',
        'කරුණාකර': 'कृपया',
        'සමාවන්න': 'माफ करें',
        'මම දුවනවා': 'मैं दौड़ रहा हूं',
        'මම ඇවිදිනවා': 'मैं चल रहा हूं',
        'මම කනවා': 'मैं खा रहा हूं',
        'මම නිදනවා': 'मैं सो रहा हूं',
        'මම වැඩ කරනවා': 'मैं काम कर रहा हूं',
        'මම ඉගෙන ගන්නවා': 'मैं पढ़ रहा हूं',
        'මම සතුටුයි': 'मैं खुश हूं',
        'මම දුක් වෙනවා': 'मैं उदास हूं',
        'මම වෙහෙසට පත්යි': 'मैं थका हुआ हूं',
        'මට බඩගිනියි': 'मुझे भूख लगी है',
        'මට පිපාසයි': 'मुझे प्यास लगी है',
        'ඔබේ නම කුමක්ද': 'आपका नाम क्या है',
        'මගේ නම': 'मेरा नाम है',
        'ඔබ කොහෙන්ද': 'आप कहां से हैं',
        'මම': 'मैं से हूं',
        'ඔබව හමුවීම සතුටක්': 'आपसे मिलकर खुशी हुई',
        'පසුව හමුවෙමු': 'बाद में मिलते हैं',
        'ආයුබෝවන්': 'अलविदा',
      },
      // Marathi to Sinhalese
      'mr_si': {
        'नमस्कार': 'හෙලෝ',
        'तुम्ही कसे आहात': 'ඔබට කොහොමද',
        'धन्यवाद': 'ස්තුතියි',
        'सुप्रभात': 'සුභ උදෑසනක්',
        'शुभ संध्या': 'සුභ සන්ධ්‍යාවක්',
        'शुभ रात्रि': 'සුභ රාත්‍රියක්',
        'होय': 'ඔව්',
        'नाही': 'නැත',
        'कृपया': 'කරුණාකර',
        'माफ करा': 'සමාවන්න',
        'मी धावत आहे': 'මම දුවනවා',
        'मी चालत आहे': 'මම ඇවිදිනවා',
        'मी खात आहे': 'මම කනවා',
        'मी झोपत आहे': 'මම නිදනවා',
        'मी काम करत आहे': 'මම වැඩ කරනවා',
        'मी अभ्यास करत आहे': 'මම ඉගෙන ගන්නවා',
        'मी आनंदी आहे': 'මම සතුටුයි',
        'मी दुःखी आहे': 'මම දුක් වෙනවා',
        'मी थकलो आहे': 'මම වෙහෙසට පත්යි',
        'मला भूक लागली आहे': 'මට බඩගිනියි',
        'मला तहान लागली आहे': 'මට පිපාසයි',
        'तुमचे नाव काय आहे': 'ඔබේ නම කුමක්ද',
        'माझे नाव आहे': 'මගේ නම',
        'तुम्ही कोठून आहात': 'ඔබ කොහෙන්ද',
        'मी आहे': 'මම',
        'तुम्हाला भेटून आनंद झाला': 'ඔබව හමුවීම සතුටක්',
        'पुन्हा भेटू': 'පසුව හමුවෙමු',
        'अलविदा': 'ආයුබෝවන්',
      },
      // Sinhalese to Marathi
      'si_mr': {
        'හෙලෝ': 'नमस्कार',
        'ඔබට කොහොමද': 'तुम्ही कसे आहात',
        'ස්තුතියි': 'धन्यवाद',
        'සුභ උදෑසනක්': 'सुप्रभात',
        'සුභ සන්ධ්‍යාවක්': 'शुभ संध्या',
        'සුභ රාත්‍රියක්': 'शुभ रात्रि',
        'ඔව්': 'होय',
        'නැත': 'नाही',
        'කරුණාකර': 'कृपया',
        'සමාවන්න': 'माफ करा',
        'මම දුවනවා': 'मी धावत आहे',
        'මම ඇවිදිනවා': 'मी चालत आहे',
        'මම කනවා': 'मी खात आहे',
        'මම නිදනවා': 'मी झोपत आहे',
        'මම වැඩ කරනවා': 'मी काम करत आहे',
        'මම ඉගෙන ගන්නවා': 'मी अभ्यास करत आहे',
        'මම සතුටුයි': 'मी आनंदी आहे',
        'මම දුක් වෙනවා': 'मी दुःखी आहे',
        'මම වෙහෙසට පත්යි': 'मी थकलो आहे',
        'මට බඩගිනියි': 'मला भूक लागली आहे',
        'මට පිපාසයි': 'मला तहान लागली आहे',
        'ඔබේ නම කුමක්ද': 'तुमचे नाव काय आहे',
        'මගේ නම': 'माझे नाव आहे',
        'ඔබ කොහෙන්ද': 'तुम्ही कोठून आहात',
        'මම': 'मी आहे',
        'ඔබව හමුවීම සතුටක්': 'तुम्हाला भेटून आनंद झाला',
        'පසුව හමුවෙමු': 'पुन्हा भेटू',
        'ආයුබෝවන්': 'अलविदा',
      },
    };

    final key = '${sourceLanguage}_$targetLanguage';
    final translationMap = translations[key];
    
    if (translationMap != null) {
      final lowerText = text.toLowerCase().trim();
      
      // First try exact match
      if (translationMap.containsKey(lowerText)) {
        final result = translationMap[lowerText]!;
        print('Exact match found: "$text" -> "$result"');
        return result;
      }
      
      // Then try partial match - look for words within the text
      String result = text;
      bool foundMatch = false;
      
      for (final entry in translationMap.entries) {
        final searchKey = entry.key.toLowerCase();
        if (lowerText.contains(searchKey)) {
          result = result.replaceAll(RegExp(searchKey, caseSensitive: false), entry.value);
          foundMatch = true;
          print('Partial match found: "$searchKey" -> "${entry.value}"');
        }
      }
      
      if (foundMatch) {
        return result;
      }
      
      // Try word-by-word translation for common words
      final words = lowerText.split(' ');
      final translatedWords = <String>[];
      bool hasTranslation = false;
      
      for (final word in words) {
        if (translationMap.containsKey(word)) {
          translatedWords.add(translationMap[word]!);
          hasTranslation = true;
        } else {
          // Try to find partial matches for compound words
          String translatedWord = word;
          for (final entry in translationMap.entries) {
            if (word.contains(entry.key)) {
              translatedWord = word.replaceAll(entry.key, entry.value);
              hasTranslation = true;
              break;
            }
          }
          translatedWords.add(translatedWord);
        }
      }
      
      if (hasTranslation) {
        return translatedWords.join(' ');
      }
    }
    
    // If no specific translation found, return a more helpful response
    final fallback = 'Translation not available for "$text" to ${_languageCodes[targetLanguage]}. Please try a different phrase.';
    print('No translation found for "$text", using fallback: "$fallback"');
    return fallback;
  }

  /// Simulate OCR extraction (replace with actual model inference)
  static Future<String> _simulateOCRExtraction(
    File imageFile,
    String sourceLanguage,
  ) async {
    // Simulate processing delay
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // Simulate extracted text based on language
    final simulatedTexts = {
      'en': 'Hello World\nThis is a sample text extracted from image.',
      'hi': 'नमस्ते दुनिया\nयह छवि से निकाला गया नमूना पाठ है।',
      'ne': 'नमस्कार संसार\nयो छविबाट निकालिएको नमूना पाठ हो।',
      'si': 'හෙලෝ වර්ල්ඩ්\nමෙය රූපයෙන් නිස්සාරණය කරන ලද නියැදි පෙළකි।',
      'ta': 'வணக்கம் உலகம்\nஇது படத்திலிருந்து பிரித்தெடுக்கப்பட்ட மாதிரி உரை.',
      'mr': 'हॅलो वर्ल्ड\nहे चित्रातून काढलेला नमुना मजकूर आहे.',
    };
    
    return simulatedTexts[sourceLanguage] ?? 'Text extracted from image';
  }

  /// Download translation models
  static Future<void> downloadModels() async {
    try {
      final modelsDir = await _getModelsDirectory();
      await modelsDir.create(recursive: true);

      // Download translation models
      await _downloadTranslationModels(modelsDir);
      
      // Download OCR models
      await _downloadOCRModels(modelsDir);
      
    } catch (e) {
      throw Exception('Model download failed: ${e.toString()}');
    }
  }

  /// Download translation models
  static Future<void> _downloadTranslationModels(Directory modelsDir) async {
    final translationDir = Directory(path.join(modelsDir.path, 'translation'));
    await translationDir.create(recursive: true);

    // List of language pairs to download
    final languagePairs = [
      // English pairs
      'en_hi', 'en_ne', 'en_si', 'en_ta', 'en_mr',
      // Hindi pairs
      'hi_en', 'hi_ne', 'hi_si', 'hi_ta', 'hi_mr',
      // Nepali pairs
      'ne_en', 'ne_hi', 'ne_si', 'ne_ta', 'ne_mr',
      // Sinhalese pairs
      'si_en', 'si_hi', 'si_ne', 'si_ta', 'si_mr',
      // Tamil pairs
      'ta_en', 'ta_hi', 'ta_ne', 'ta_si', 'ta_mr',
      // Marathi pairs
      'mr_en', 'mr_hi', 'mr_ne', 'mr_si', 'mr_ta',
    ];

    for (final pair in languagePairs) {
      final modelPath = path.join(translationDir.path, '$pair.tflite');
      if (!await File(modelPath).exists()) {
        // In a real implementation, download from server
        await _downloadModelFile(pair, modelPath);
      }
    }
  }

  /// Download OCR models
  static Future<void> _downloadOCRModels(Directory modelsDir) async {
    final ocrDir = Directory(path.join(modelsDir.path, 'ocr'));
    await ocrDir.create(recursive: true);

    final languages = ['en', 'hi', 'ne', 'si', 'ta', 'mr'];
    
    for (final lang in languages) {
      final modelPath = path.join(ocrDir.path, '${lang}_ocr.tflite');
      if (!await File(modelPath).exists()) {
        // In a real implementation, download from server
        await _downloadOCRModelFile(lang, modelPath);
      }
    }
  }

  /// Download a specific model file
  static Future<void> _downloadModelFile(String modelName, String savePath) async {
    try {
      // Simulate download (replace with actual download logic)
      await Future.delayed(const Duration(seconds: 2));
      
      // Create a dummy model file
      final file = File(savePath);
      await file.writeAsString('Dummy model file for $modelName');
      
    } catch (e) {
      throw Exception('Failed to download model $modelName: ${e.toString()}');
    }
  }

  /// Download a specific OCR model file
  static Future<void> _downloadOCRModelFile(String language, String savePath) async {
    try {
      // Simulate download (replace with actual download logic)
      await Future.delayed(const Duration(seconds: 1));
      
      // Create a dummy OCR model file
      final file = File(savePath);
      await file.writeAsString('Dummy OCR model file for $language');
      
    } catch (e) {
      throw Exception('Failed to download OCR model $language: ${e.toString()}');
    }
  }

  /// Get available models
  static Future<List<String>> getAvailableModels() async {
    try {
      final modelsDir = await _getModelsDirectory();
      if (!await modelsDir.exists()) {
        return [];
      }

      final List<String> models = [];
      
      // Check translation models
      final translationDir = Directory(path.join(modelsDir.path, 'translation'));
      if (await translationDir.exists()) {
        final files = await translationDir.list().toList();
        for (final file in files) {
          if (file is File && file.path.endsWith('.tflite')) {
            models.add(path.basenameWithoutExtension(file.path));
          }
        }
      }
      
      // Check OCR models
      final ocrDir = Directory(path.join(modelsDir.path, 'ocr'));
      if (await ocrDir.exists()) {
        final files = await ocrDir.list().toList();
        for (final file in files) {
          if (file is File && file.path.endsWith('.tflite')) {
            models.add('${path.basenameWithoutExtension(file.path)}_ocr');
          }
        }
      }
      
      return models;
    } catch (e) {
      return [];
    }
  }

  /// Clear all downloaded models
  static Future<void> clearModels() async {
    try {
      final modelsDir = await _getModelsDirectory();
      if (await modelsDir.exists()) {
        await modelsDir.delete(recursive: true);
      }
    } catch (e) {
      throw Exception('Failed to clear models: ${e.toString()}');
    }
  }
}
