#!/bin/bash

# Smart Translate - Deployment Script
# For Smart India Hackathon 2024

set -e

echo "🚀 Starting Smart Translate Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are installed
check_dependencies() {
    print_status "Checking dependencies..."
    
    # Check Flutter
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter is not installed. Please install Flutter first."
        exit 1
    fi
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is not installed. Please install Python 3 first."
        exit 1
    fi
    
    # Check pip
    if ! command -v pip3 &> /dev/null; then
        print_error "pip3 is not installed. Please install pip3 first."
        exit 1
    fi
    
    print_success "All dependencies are installed."
}

# Setup Flutter environment
setup_flutter() {
    print_status "Setting up Flutter environment..."
    
    # Get Flutter dependencies
    flutter pub get
    
    # Check Flutter doctor
    flutter doctor
    
    print_success "Flutter environment setup complete."
}

# Setup Python backend
setup_backend() {
    print_status "Setting up Python backend..."
    
    cd backend
    
    # Create virtual environment
    if [ ! -d "venv" ]; then
        python3 -m venv venv
    fi
    
    # Activate virtual environment
    source venv/bin/activate
    
    # Install dependencies
    pip install -r requirements.txt
    
    # Create necessary directories
    mkdir -p models/translation
    mkdir -p models/ocr
    mkdir -p models/asr
    mkdir -p data
    mkdir -p logs
    
    cd ..
    
    print_success "Python backend setup complete."
}

# Build Flutter app
build_flutter() {
    print_status "Building Flutter app..."
    
    # Build for Android
    print_status "Building Android APK..."
    flutter build apk --release
    
    # Build for iOS (if on macOS)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        print_status "Building iOS app..."
        flutter build ios --release
    fi
    
    # Build for Web
    print_status "Building Web app..."
    flutter build web --release
    
    print_success "Flutter app build complete."
}

# Setup models
setup_models() {
    print_status "Setting up AI models..."
    
    cd backend
    
    # Activate virtual environment
    source venv/bin/activate
    
    # Create sample data
    print_status "Creating sample training data..."
    python collect_data.py --create_sample_data --output_dir data
    
    # Download and optimize models
    print_status "Downloading and optimizing models..."
    python optimize_models.py --optimize_translation --optimize_ocr --optimize_asr --create_bundle
    
    cd ..
    
    print_success "AI models setup complete."
}

# Start backend server
start_backend() {
    print_status "Starting backend server..."
    
    cd backend
    source venv/bin/activate
    
    # Start the server in background
    nohup python main.py > ../logs/backend.log 2>&1 &
    BACKEND_PID=$!
    
    # Save PID for later cleanup
    echo $BACKEND_PID > ../logs/backend.pid
    
    cd ..
    
    # Wait for server to start
    sleep 5
    
    # Check if server is running
    if curl -s http://localhost:8000/health > /dev/null; then
        print_success "Backend server started successfully."
    else
        print_error "Failed to start backend server."
        exit 1
    fi
}

# Run tests
run_tests() {
    print_status "Running tests..."
    
    # Flutter tests
    print_status "Running Flutter tests..."
    flutter test
    
    # Python tests
    print_status "Running Python tests..."
    cd backend
    source venv/bin/activate
    python -m pytest tests/ -v
    cd ..
    
    print_success "All tests passed."
}

# Create deployment package
create_deployment_package() {
    print_status "Creating deployment package..."
    
    # Create deployment directory
    DEPLOY_DIR="smart_translate_deployment"
    rm -rf $DEPLOY_DIR
    mkdir -p $DEPLOY_DIR
    
    # Copy Flutter build outputs
    mkdir -p $DEPLOY_DIR/flutter
    cp -r build/web $DEPLOY_DIR/flutter/
    cp build/app/outputs/flutter-apk/app-release.apk $DEPLOY_DIR/flutter/smart_translate.apk
    
    # Copy backend
    mkdir -p $DEPLOY_DIR/backend
    cp -r backend $DEPLOY_DIR/
    rm -rf $DEPLOY_DIR/backend/venv
    rm -rf $DEPLOY_DIR/backend/__pycache__
    rm -rf $DEPLOY_DIR/backend/*.pyc
    
    # Copy documentation
    cp README.md $DEPLOY_DIR/
    cp LICENSE $DEPLOY_DIR/ 2>/dev/null || echo "No LICENSE file found"
    
    # Create deployment script
    cat > $DEPLOY_DIR/deploy.sh << 'EOF'
#!/bin/bash
echo "Deploying Smart Translate..."

# Install Python dependencies
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Start backend server
python main.py &
BACKEND_PID=$!

# Serve Flutter web app
cd ../flutter/web
python3 -m http.server 8080 &
WEB_PID=$!

echo "Backend running on http://localhost:8000"
echo "Web app running on http://localhost:8080"
echo "Press Ctrl+C to stop"

# Wait for interrupt
trap "kill $BACKEND_PID $WEB_PID; exit" INT
wait
EOF
    
    chmod +x $DEPLOY_DIR/deploy.sh
    
    # Create zip file
    zip -r smart_translate_deployment.zip $DEPLOY_DIR/
    
    print_success "Deployment package created: smart_translate_deployment.zip"
}

# Cleanup function
cleanup() {
    print_status "Cleaning up..."
    
    # Stop backend server if running
    if [ -f logs/backend.pid ]; then
        BACKEND_PID=$(cat logs/backend.pid)
        if kill -0 $BACKEND_PID 2>/dev/null; then
            kill $BACKEND_PID
            print_status "Backend server stopped."
        fi
        rm logs/backend.pid
    fi
    
    print_success "Cleanup complete."
}

# Main deployment function
main() {
    print_status "Starting Smart Translate deployment process..."
    
    # Create logs directory
    mkdir -p logs
    
    # Set trap for cleanup on exit
    trap cleanup EXIT
    
    # Run deployment steps
    check_dependencies
    setup_flutter
    setup_backend
    setup_models
    build_flutter
    start_backend
    run_tests
    create_deployment_package
    
    print_success "🎉 Smart Translate deployment completed successfully!"
    print_status "Deployment package: smart_translate_deployment.zip"
    print_status "Backend API: http://localhost:8000"
    print_status "Web App: http://localhost:8080"
    print_status "Android APK: smart_translate_deployment/flutter/smart_translate.apk"
}

# Handle command line arguments
case "${1:-}" in
    "backend")
        check_dependencies
        setup_backend
        start_backend
        ;;
    "frontend")
        check_dependencies
        setup_flutter
        build_flutter
        ;;
    "models")
        check_dependencies
        setup_backend
        setup_models
        ;;
    "test")
        check_dependencies
        setup_flutter
        setup_backend
        run_tests
        ;;
    "clean")
        cleanup
        ;;
    *)
        main
        ;;
esac
