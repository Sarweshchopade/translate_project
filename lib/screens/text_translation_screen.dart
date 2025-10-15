import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../services/translation_service.dart';
import '../models/translation_result.dart';
import '../utils/font_utils.dart';

class TextTranslationScreen extends StatefulWidget {
  const TextTranslationScreen({super.key});

  @override
  State<TextTranslationScreen> createState() => _TextTranslationScreenState();
}

class _TextTranslationScreenState extends State<TextTranslationScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<TranslationResult> _translationHistory = [];
  bool _isTranslating = false;
  
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
    _loadTranslationHistory();
  }

  Future<void> _loadTranslationHistory() async {
    // Load from local storage
    // Implementation will be added with storage service
  }

  Future<void> _translateText() async {
    if (_inputController.text.trim().isEmpty) return;
    
    setState(() => _isTranslating = true);
    
    try {
      final result = await TranslationService.translateText(
        _inputController.text.trim(),
        _sourceLanguage,
        _targetLanguage,
      );
      
      final translationResult = TranslationResult(
        originalText: _inputController.text.trim(),
        translatedText: result,
        sourceLanguage: _sourceLanguage,
        targetLanguage: _targetLanguage,
        timestamp: DateTime.now(),
        mode: 'text',
      );
      
      setState(() {
        _translationHistory.insert(0, translationResult);
        _inputController.clear();
      });
      
      // Save to local storage
      await _saveTranslationHistory();
      
    } catch (e) {
      _showErrorSnackBar('Translation failed: ${e.toString()}');
    } finally {
      setState(() => _isTranslating = false);
    }
  }

  Future<void> _saveTranslationHistory() async {
    // Save to local storage
    // Implementation will be added with storage service
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
  }

  String _getLanguageName(String code) {
    return _languages.firstWhere((lang) => lang['code'] == code)['name'] ?? code;
  }

  String _getLanguageFlag(String code) {
    return _languages.firstWhere((lang) => lang['code'] == code)['flag'] ?? '🌐';
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
          'Text Translation',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () => _showHistoryDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildLanguageSelector(),
          _buildInputSection(),
          _buildTranslationHistory(),
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
          isSource ? 'From' : 'To',
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
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F3A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: TextField(
              controller: _inputController,
              maxLines: 4,
              style: TextStyle(
                color: Colors.white, 
                fontSize: 16,
                fontFamily: FontUtils.getFontFamily(_sourceLanguage),
              ),
              decoration: InputDecoration(
                hintText: 'Enter text to translate...',
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontFamily: FontUtils.getFontFamily(_sourceLanguage),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(20),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isTranslating ? null : _translateText,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isTranslating
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.translate, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Translate',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationHistory() {
    if (_translationHistory.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.translate,
                size: 64,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 16),
              Text(
                'No translations yet',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start typing to translate text',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Translations',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _translationHistory.length,
                itemBuilder: (context, index) {
                  final result = _translationHistory[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 400),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: _buildTranslationCard(result),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranslationCard(TranslationResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _getLanguageFlag(result.sourceLanguage),
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Text(
                _getLanguageName(result.sourceLanguage),
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, color: Colors.grey, size: 16),
              const SizedBox(width: 8),
              Text(
                _getLanguageFlag(result.targetLanguage),
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Text(
                _getLanguageName(result.targetLanguage),
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                _formatTime(result.timestamp),
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            result.originalText,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 14,
              fontFamily: FontUtils.getFontFamily(result.sourceLanguage),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            result.translatedText,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: FontUtils.getFontFamily(result.targetLanguage),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: Text(
          'Translation History',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: _translationHistory.length,
            itemBuilder: (context, index) {
              final result = _translationHistory[index];
              return ListTile(
                title: Text(
                  result.originalText,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                ),
                subtitle: Text(
                  result.translatedText,
                  style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12),
                ),
                trailing: Text(
                  _formatTime(result.timestamp),
                  style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 10),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(color: const Color(0xFF667eea)),
            ),
          ),
        ],
      ),
    );
  }
}
