#!/bin/bash

# Setup script for Android Studio configuration
# This helps configure Android Studio for Flutter development

echo "🔧 Android Studio Setup for Tmelnik App"
echo "========================================"
echo ""

# Check if Android Studio is installed
if [ -d "/Applications/Android Studio.app" ]; then
    echo "✅ Android Studio found"
else
    echo "⚠️  Android Studio not found in /Applications/"
    echo "   Please install Android Studio from: https://developer.android.com/studio"
    echo "   Or tell me where it's installed"
    exit 1
fi

# Check for Android SDK
SDK_PATH="$HOME/Library/Android/sdk"
if [ -d "$SDK_PATH" ]; then
    echo "✅ Android SDK found at: $SDK_PATH"
    
    # Configure Flutter to use this SDK
    flutter config --android-sdk "$SDK_PATH"
    echo "✅ Flutter configured to use Android SDK"
else
    echo "⚠️  Android SDK not found at: $SDK_PATH"
    echo ""
    echo "📝 Steps to complete setup:"
    echo ""
    echo "1. Open Android Studio"
    echo "2. Go to: Android Studio → Settings (Preferences on Mac) → Appearance & Behavior → System Settings → Android SDK"
    echo "3. Note the 'Android SDK Location' path"
    echo "4. Then run: flutter config --android-sdk <SDK_LOCATION>"
    echo ""
    echo "Or install SDK components:"
    echo "1. Open Android Studio"
    echo "2. Go through the setup wizard"
    echo "3. Install Android SDK Platform 33+ and SDK Build-Tools"
    echo ""
fi

echo ""
echo "🔍 Checking Flutter doctor..."
flutter doctor

echo ""
echo "✅ Setup check complete!"
echo ""
echo "Next steps:"
echo "1. Open Android Studio"
echo "2. Open this project: $PWD"
echo "3. Accept any license agreements if prompted"
echo "4. Install any missing SDK components"
echo "5. Run 'flutter doctor' again to verify"

