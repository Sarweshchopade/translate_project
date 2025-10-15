@echo off
REM Smart Translate - Windows Deployment Script
REM For Smart India Hackathon 2024

echo 🚀 Starting Smart Translate Deployment...

REM Create logs directory
if not exist logs mkdir logs

REM Check if Flutter is installed
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Flutter is not installed. Please install Flutter first.
    exit /b 1
)

REM Check if Python is installed
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python is not installed. Please install Python first.
    exit /b 1
)

echo [INFO] All dependencies are installed.

REM Setup Flutter environment
echo [INFO] Setting up Flutter environment...
flutter pub get
flutter doctor

REM Setup Python backend
echo [INFO] Setting up Python backend...
cd backend

REM Create virtual environment
if not exist venv python -m venv venv

REM Activate virtual environment and install dependencies
call venv\Scripts\activate.bat
pip install -r requirements.txt

REM Create necessary directories
if not exist models mkdir models
if not exist models\translation mkdir models\translation
if not exist models\ocr mkdir models\ocr
if not exist models\asr mkdir models\asr
if not exist data mkdir data

cd ..

REM Build Flutter app
echo [INFO] Building Flutter app...
flutter build apk --release
flutter build web --release

REM Setup models
echo [INFO] Setting up AI models...
cd backend
call venv\Scripts\activate.bat

REM Create sample data
python collect_data.py --create_sample_data --output_dir data

REM Download and optimize models
python optimize_models.py --optimize_translation --optimize_ocr --optimize_asr --create_bundle

cd ..

REM Create deployment package
echo [INFO] Creating deployment package...
if exist smart_translate_deployment rmdir /s /q smart_translate_deployment
mkdir smart_translate_deployment
mkdir smart_translate_deployment\flutter
mkdir smart_translate_deployment\backend

REM Copy Flutter build outputs
xcopy /E /I build\web smart_translate_deployment\flutter\web
copy build\app\outputs\flutter-apk\app-release.apk smart_translate_deployment\flutter\smart_translate.apk

REM Copy backend
xcopy /E /I backend smart_translate_deployment\backend
rmdir /s /q smart_translate_deployment\backend\venv
rmdir /s /q smart_translate_deployment\backend\__pycache__

REM Copy documentation
copy README.md smart_translate_deployment\
if exist LICENSE copy LICENSE smart_translate_deployment\

REM Create Windows deployment script
echo @echo off > smart_translate_deployment\deploy.bat
echo echo Deploying Smart Translate... >> smart_translate_deployment\deploy.bat
echo cd backend >> smart_translate_deployment\deploy.bat
echo python -m venv venv >> smart_translate_deployment\deploy.bat
echo call venv\Scripts\activate.bat >> smart_translate_deployment\deploy.bat
echo pip install -r requirements.txt >> smart_translate_deployment\deploy.bat
echo start python main.py >> smart_translate_deployment\deploy.bat
echo cd ..\flutter\web >> smart_translate_deployment\deploy.bat
echo start python -m http.server 8080 >> smart_translate_deployment\deploy.bat
echo echo Backend running on http://localhost:8000 >> smart_translate_deployment\deploy.bat
echo echo Web app running on http://localhost:8080 >> smart_translate_deployment\deploy.bat
echo pause >> smart_translate_deployment\deploy.bat

echo [SUCCESS] 🎉 Smart Translate deployment completed successfully!
echo [INFO] Deployment package: smart_translate_deployment\
echo [INFO] Backend API: http://localhost:8000
echo [INFO] Web App: http://localhost:8080
echo [INFO] Android APK: smart_translate_deployment\flutter\smart_translate.apk

pause
