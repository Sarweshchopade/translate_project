# Smart Translate - Offline Multilingual Translation App

A comprehensive offline translation application built for the Smart India Hackathon, supporting translation between Nepali, Sinhalese, English, Hindi, Tamil, and Marathi languages.

## 🌟 Features

### Translation Modes
- **Text Translation**: Type and translate text instantly
- **Speech Translation**: Speak and get instant translation with text-to-speech
- **Image Translation**: Extract and translate text from images using OCR

### Supported Languages
- 🇳🇵 **Nepali** ↔ English
- 🇱🇰 **Sinhalese** ↔ English  
- 🇺🇸 **English** ↔ Hindi/Tamil/Marathi
- 🇮🇳 **Hindi** ↔ English
- 🇮🇳 **Tamil** ↔ English
- 🇮🇳 **Marathi** ↔ English

### Key Features
- ✅ **100% Offline**: Works without internet connection
- 🚀 **Fast Performance**: Optimized models for mobile devices
- 🎯 **High Accuracy**: Fine-tuned models for better translation quality
- 🔒 **Privacy-First**: All processing happens on-device
- 📱 **Cross-Platform**: Flutter app with Python backend
- 🎨 **Modern UI**: Beautiful, intuitive interface

## 🏗️ Architecture

### Frontend (Flutter)
```
lib/
├── screens/
│   ├── home_screen.dart           # Main dashboard
│   ├── text_translation_screen.dart
│   ├── speech_translation_screen.dart
│   ├── image_translation_screen.dart
│   └── settings_screen.dart
├── services/
│   └── translation_service.dart   # Translation logic
├── models/
│   └── translation_result.dart    # Data models
└── main.dart
```

### Backend (Python FastAPI)
```
backend/
├── main.py                    # FastAPI application
├── train_models.py           # Model training script
├── optimize_models.py        # Model optimization
├── collect_data.py           # Data collection
└── requirements.txt          # Python dependencies
```

## 🚀 Quick Start

### Prerequisites
- Flutter SDK (3.9.2+)
- Python 3.8+
- Android Studio / Xcode
- Git

### Flutter App Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd smart-translate
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Python Backend Setup

1. **Navigate to backend directory**
   ```bash
   cd backend
   ```

2. **Create virtual environment**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Run the backend server**
   ```bash
   python main.py
   ```

The API will be available at `http://localhost:8000`

## 📊 Model Training

### Data Collection
```bash
# Collect parallel corpus data
python collect_data.py --collect_parallel --output_dir data

# Collect OCR training data
python collect_data.py --collect_ocr --output_dir data

# Collect ASR training data
python collect_data.py --collect_asr --output_dir data
```

### Model Training
```bash
# Train translation models
python train_models.py --train_translation --data_path data --epochs 5

# Train OCR models
python train_models.py --train_ocr --data_path data --epochs 10

# Create sample data for testing
python train_models.py --create_sample_data --data_path data
```

### Model Optimization
```bash
# Optimize models for mobile deployment
python optimize_models.py --optimize_translation --optimize_ocr --optimize_asr

# Create mobile model bundle
python optimize_models.py --create_bundle --output_dir optimized_models
```

## 🔧 Configuration

### Flutter Configuration
Update `lib/services/translation_service.dart` to configure:
- Backend API URL
- Model download URLs
- Offline mode settings

### Backend Configuration
Update `backend/main.py` to configure:
- Model paths
- Language mappings
- API endpoints

## 📱 Usage

### Text Translation
1. Open the app
2. Select source and target languages
3. Type your text
4. Tap "Translate"
5. View the translation result

### Speech Translation
1. Go to Speech Translation mode
2. Select languages
3. Hold the microphone button and speak
4. Release to get translation
5. Tap "Speak Again" to hear the translation

### Image Translation
1. Go to Image Translation mode
2. Select languages
3. Take a photo or choose from gallery
4. Wait for OCR processing
5. View extracted and translated text

## 🛠️ Development

### Project Structure
```
smart-translate/
├── lib/                    # Flutter app source
├── backend/                # Python backend
├── assets/                 # App assets
├── android/               # Android-specific code
├── ios/                   # iOS-specific code
├── web/                   # Web-specific code
└── README.md
```

### Adding New Languages
1. Add language code to `LANGUAGE_CODES` in backend
2. Update language lists in Flutter screens
3. Add language-specific training data
4. Train new translation models
5. Update UI with new language options

### Customizing Models
1. Modify `TRANSLATION_MODELS` in `backend/main.py`
2. Add new model configurations
3. Update training scripts
4. Retrain models with new data

## 📈 Performance Optimization

### Model Optimization
- Use TensorFlow Lite for mobile deployment
- Quantize models to reduce size
- Optimize inference speed
- Implement model caching

### App Performance
- Lazy loading of models
- Background processing
- Efficient memory management
- Smooth animations

## 🧪 Testing

### Unit Tests
```bash
# Flutter tests
flutter test

# Python tests
cd backend
python -m pytest
```

### Integration Tests
```bash
# Test translation accuracy
python backend/test_translation.py

# Test OCR performance
python backend/test_ocr.py

# Test ASR performance
python backend/test_asr.py
```

## 📦 Deployment

### Android APK
```bash
flutter build apk --release
```

### iOS App
```bash
flutter build ios --release
```

### Web App
```bash
flutter build web --release
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🏆 Smart India Hackathon

This project was developed for the Smart India Hackathon 2024, focusing on:
- **Innovation**: Offline-first translation approach
- **Accessibility**: Support for regional languages
- **Technology**: AI/ML integration
- **Impact**: Bridging language barriers in India

## 📞 Support

For support and questions:
- Create an issue on GitHub
- Contact the development team
- Check the documentation

## 🙏 Acknowledgments

- Hugging Face for pre-trained models
- Flutter team for the framework
- FastAPI for the backend
- Open source community for various libraries

---

**Made with ❤️ for Smart India Hackathon 2024**