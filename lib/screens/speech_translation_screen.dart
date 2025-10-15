import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/translation_service.dart';
import '../models/translation_result.dart';

class SpeechTranslationScreen extends StatefulWidget {
  const SpeechTranslationScreen({super.key});

  @override
  State<SpeechTranslationScreen> createState() => _SpeechTranslationScreenState();
}

class _SpeechTranslationScreenState extends State<SpeechTranslationScreen>
    with TickerProviderStateMixin {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _speechEnabled = false;
  String _recognizedText = '';
  String _translatedText = '';
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;

  final List<Map<String, String>> _languages = [
    {'code': 'ne', 'name': 'Nepali', 'flag': '🇳🇵'},
    {'code': 'si', 'name': 'Sinhalese', 'flag': '🇱🇰'},
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'hi', 'name': 'Hindi', 'flag': '🇮🇳'},
    {'code': 'ta', 'name': 'Tamil', 'flag': '🇮🇳'},
    {'code': 'mr', 'name': 'Marathi', 'flag': '🇮🇳'},
  ];
  
  String _sourceLanguage = 'en';
  String _targetLanguage = 'ne';

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
    _initAnimations();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initSpeech() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      _showErrorSnackBar('Microphone permission is required');
      return;
    }

    _speechEnabled = await _speechToText.initialize(
      onStatus: (status) {
        setState(() {
          _isListening = status == 'listening';
          if (_isListening) {
            _pulseController.repeat(reverse: true);
          } else {
            _pulseController.stop();
          }
        });
      },
      onError: (error) {
        setState(() {
          _isListening = false;
          _pulseController.stop();
        });
        _showErrorSnackBar('Speech recognition error: ${error.errorMsg}');
      },
    );
    
    if (!_speechEnabled) {
      _showErrorSnackBar('Speech recognition not available');
    }
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage(_targetLanguage);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _startListening() async {
    if (!_speechEnabled) {
      _showErrorSnackBar('Speech recognition not available');
      return;
    }

    setState(() {
      _recognizedText = '';
      _translatedText = '';
    });

    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          _recognizedText = result.recognizedWords;
        });
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: _getLocaleId(_sourceLanguage),
      onSoundLevelChange: (level) {
        // Handle sound level changes for visual feedback
      },
    );
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    if (_recognizedText.isNotEmpty) {
      await _translateAndSpeak();
    }
  }

  Future<void> _translateAndSpeak() async {
    if (_recognizedText.isEmpty) return;

    try {
      setState(() => _isSpeaking = true);
      
      final translated = await TranslationService.translateText(
        _recognizedText,
        _sourceLanguage,
        _targetLanguage,
      );
      
      setState(() => _translatedText = translated);
      
      // Save translation result
      final result = TranslationResult(
        originalText: _recognizedText,
        translatedText: translated,
        sourceLanguage: _sourceLanguage,
        targetLanguage: _targetLanguage,
        timestamp: DateTime.now(),
        mode: 'speech',
      );
      
      // Save to local storage
      await _saveTranslationResult(result);
      
      // Speak the translated text
      await _speakText(translated);
      
    } catch (e) {
      _showErrorSnackBar('Translation failed: ${e.toString()}');
    } finally {
      setState(() => _isSpeaking = false);
    }
  }

  Future<void> _speakText(String text) async {
    await _flutterTts.setLanguage(_targetLanguage);
    await _flutterTts.speak(text);
  }

  Future<void> _saveTranslationResult(TranslationResult result) async {
    // Save to local storage
    // Implementation will be added with storage service
  }

  String _getLocaleId(String languageCode) {
    final localeMap = {
      'en': 'en_US',
      'hi': 'hi_IN',
      'ne': 'ne_NP',
      'si': 'si_LK',
      'ta': 'ta_IN',
      'mr': 'mr_IN',
    };
    return localeMap[languageCode] ?? 'en_US';
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _swapLanguages() {
    setState(() {
      final temp = _sourceLanguage;
      _sourceLanguage = _targetLanguage;
      _targetLanguage = temp;
    });
    _initTts(); // Reinitialize TTS with new language
  }

  String _getLanguageName(String code) {
    return _languages.firstWhere((lang) => lang['code'] == code)['name'] ?? code;
  }

  String _getLanguageFlag(String code) {
    return _languages.firstWhere((lang) => lang['code'] == code)['flag'] ?? '🌐';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _speechToText.cancel();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Speech Translation',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildLanguageSelector(),
          _buildSpeechInterface(),
          _buildTranslationDisplay(),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildLanguageDropdown(_sourceLanguage, true),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: _swapLanguages,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667eea),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.swap_horiz,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildLanguageDropdown(_targetLanguage, false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageDropdown(String selectedCode, bool isSource) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isSource ? 'Speak in' : 'Translate to',
          style: GoogleFonts.poppins(
            color: Colors.grey[400],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2F4A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[700]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedCode,
              isExpanded: true,
              dropdownColor: const Color(0xFF2A2F4A),
              style: GoogleFonts.poppins(color: Colors.white),
              items: _languages.map((language) {
                return DropdownMenuItem<String>(
                  value: language['code'],
                  child: Row(
                    children: [
                      Text(language['flag']!, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Text(
                        language['name']!,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    if (isSource) {
                      _sourceLanguage = value;
                    } else {
                      _targetLanguage = value;
                    }
                  });
                  if (!isSource) {
                    _initTts(); // Reinitialize TTS with new language
                  }
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeechInterface() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMicrophoneButton(),
            const SizedBox(height: 32),
            _buildStatusText(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildMicrophoneButton() {
    return GestureDetector(
      onTapDown: (_) => _startListening(),
      onTapUp: (_) => _stopListening(),
      onTapCancel: () => _stopListening(),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isListening ? _pulseAnimation.value : 1.0,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: _isListening
                      ? [const Color(0xFF667eea), const Color(0xFF764ba2)]
                      : [const Color(0xFF2A2F4A), const Color(0xFF1A1F3A)],
                ),
                boxShadow: _isListening
                    ? [
                        BoxShadow(
                          color: const Color(0xFF667eea).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                size: 48,
                color: _isListening ? Colors.white : Colors.grey[400],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusText() {
    String statusText;
    Color statusColor;
    
    if (_isListening) {
      statusText = 'Listening... Speak now';
      statusColor = const Color(0xFF667eea);
    } else if (_isSpeaking) {
      statusText = 'Speaking translation...';
      statusColor = const Color(0xFF764ba2);
    } else if (_recognizedText.isNotEmpty && _translatedText.isNotEmpty) {
      statusText = 'Translation complete';
      statusColor = Colors.green[400]!;
    } else {
      statusText = 'Hold and speak to translate';
      statusColor = Colors.grey[400]!;
    }
    
    return Text(
      statusText,
      style: GoogleFonts.poppins(
        color: statusColor,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (_translatedText.isNotEmpty)
          _buildActionButton(
            icon: Icons.volume_up,
            label: 'Speak Again',
            onTap: () => _speakText(_translatedText),
            color: const Color(0xFF764ba2),
          ),
        if (_recognizedText.isNotEmpty)
          _buildActionButton(
            icon: Icons.refresh,
            label: 'Retry',
            onTap: () {
              setState(() {
                _recognizedText = '';
                _translatedText = '';
              });
            },
            color: const Color(0xFF667eea),
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranslationDisplay() {
    if (_recognizedText.isEmpty && _translatedText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recognizedText.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  _getLanguageFlag(_sourceLanguage),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  'Recognized (${_getLanguageName(_sourceLanguage)})',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _recognizedText,
              style: GoogleFonts.poppins(
                color: Colors.grey[300],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_translatedText.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  _getLanguageFlag(_targetLanguage),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  'Translated (${_getLanguageName(_targetLanguage)})',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _translatedText,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
