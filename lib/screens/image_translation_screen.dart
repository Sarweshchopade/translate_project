import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import '../services/translation_service.dart';
import '../models/translation_result.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';


class ImageTranslationScreen extends StatefulWidget {
  const ImageTranslationScreen({super.key});

  @override
  State<ImageTranslationScreen> createState() => _ImageTranslationScreenState();
}

class _ImageTranslationScreenState extends State<ImageTranslationScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _webImage; // <-- Add this variable at top with _selectedImage
  File? _selectedImage;
  String _extractedText = '';
  String _translatedText = '';
  bool _isProcessing = false;
  bool _isTranslating = false;
  List<CameraDescription>? _cameras;

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
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      _showErrorSnackBar('Camera initialization failed: ${e.toString()}');
    }
  }

  Future<void> _pickImageFromGallery() async {
  try {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() {
          _webImage = bytes;
          _selectedImage = null;
          _extractedText = '';
          _translatedText = '';
        });
      } else {
        setState(() {
          _selectedImage = File(image.path);
          _webImage = null;
          _extractedText = '';
          _translatedText = '';
        });
      }
      await _processImage();
    }
  } catch (e) {
    _showErrorSnackBar('Failed to pick image: ${e.toString()}');
  }
}

  Future<void> _captureImageFromCamera() async {
  try {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.camera);
    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() {
          _webImage = bytes;
          _selectedImage = null;
        });
      } else {
        setState(() {
          _selectedImage = File(image.path);
          _webImage = null;
        });
      }
      await _processImage();
    }
  } catch (e) {
    _showErrorSnackBar('Failed to capture image: ${e.toString()}');
  }
}

  Future<void> _processImage() async {
    if (_selectedImage == null) return;

    setState(() => _isProcessing = true);

    try {
      // Extract text using OCR
      final extractedText = await TranslationService.extractTextFromImage(
        _selectedImage!,
        _sourceLanguage,
      );
      
      setState(() => _extractedText = extractedText);
      
      if (extractedText.isNotEmpty) {
        await _translateText(extractedText);
      } else {
        _showErrorSnackBar('No text found in the image');
      }
    } catch (e) {
      _showErrorSnackBar('OCR processing failed: ${e.toString()}');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _translateText(String text) async {
    if (text.isEmpty) return;

    setState(() => _isTranslating = true);

    try {
      final translated = await TranslationService.translateText(
        text,
        _sourceLanguage,
        _targetLanguage,
      );
      
      setState(() => _translatedText = translated);
      
      // Save translation result
      final result = TranslationResult(
        originalText: text,
        translatedText: translated,
        sourceLanguage: _sourceLanguage,
        targetLanguage: _targetLanguage,
        timestamp: DateTime.now(),
        mode: 'image',
        imagePath: _selectedImage?.path,
      );
      
      // Save to local storage
      await _saveTranslationResult(result);
      
    } catch (e) {
      _showErrorSnackBar('Translation failed: ${e.toString()}');
    } finally {
      setState(() => _isTranslating = false);
    }
  }

  Future<void> _saveTranslationResult(TranslationResult result) async {
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
          'Image Translation',
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
          _buildImageSection(),
          if (_extractedText.isNotEmpty || _translatedText.isNotEmpty)
            _buildTranslationSection(),
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
          isSource ? 'Text in' : 'Translate to',
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

  Widget _buildImageSection() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1F3A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: _selectedImage == null
                    ? _buildImagePlaceholder()
                    : _buildImagePreview(),
              ),
            ),
            const SizedBox(height: 16),
            _buildImageActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No image selected',
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose an image to extract and translate text',
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
  return ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Stack(
      children: [
        // Handle web and mobile separately
        kIsWeb
            ? Image.network(
                _selectedImage!.path,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              )
            : Image.file(
                _selectedImage!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
        if (_isProcessing || _isTranslating)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFF667eea),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isProcessing ? 'Extracting text...' : 'Translating...',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
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

  Widget _buildImageActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.photo_library,
            label: 'Gallery',
            onTap: _pickImageFromGallery,
            color: const Color(0xFF667eea),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.camera_alt,
            label: 'Camera',
            onTap: _captureImageFromCamera,
            color: const Color(0xFF764ba2),
          ),
        ),
        if (_selectedImage != null) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.refresh,
              label: 'Retry',
              onTap: () {
                setState(() {
                  _extractedText = '';
                  _translatedText = '';
                });
                _processImage();
              },
              color: const Color(0xFFf093fb),
            ),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
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

  Widget _buildTranslationSection() {
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
          if (_extractedText.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  _getLanguageFlag(_sourceLanguage),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  'Extracted Text (${_getLanguageName(_sourceLanguage)})',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2F4A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _extractedText,
                style: GoogleFonts.poppins(
                  color: Colors.grey[300],
                  fontSize: 14,
                ),
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
                  'Translated Text (${_getLanguageName(_targetLanguage)})',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2F4A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _translatedText,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
