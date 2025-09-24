#!/bin/bash

# Development runner script with Firebase configuration
# Make sure to set your Firebase credentials in .env file first

echo "🚀 Starting Tmelnik App in development mode..."

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "❌ .env file not found!"
    echo "Please create a .env file with your Firebase configuration."
    echo "See FIREBASE_SETUP.md for instructions."
    exit 1
fi

# Load environment variables from .env file
export $(cat .env | grep -v '^#' | xargs)

# Run Flutter with environment variables
flutter run -d linux \
    --dart-define=FIREBASE_API_KEY="$FIREBASE_API_KEY" \
    --dart-define=FIREBASE_PROJECT_ID="$FIREBASE_PROJECT_ID" \
    --dart-define=FIREBASE_MESSAGING_SENDER_ID="$FIREBASE_MESSAGING_SENDER_ID" \
    --dart-define=FIREBASE_AUTH_DOMAIN="$FIREBASE_AUTH_DOMAIN" \
    --dart-define=FIREBASE_STORAGE_BUCKET="$FIREBASE_STORAGE_BUCKET" \
    --dart-define=FIREBASE_WEB_APP_ID="$FIREBASE_WEB_APP_ID" \
    --dart-define=FIREBASE_ANDROID_APP_ID="$FIREBASE_ANDROID_APP_ID" \
    --dart-define=FIREBASE_IOS_APP_ID="$FIREBASE_IOS_APP_ID" \
    --dart-define=FIREBASE_MACOS_APP_ID="$FIREBASE_MACOS_APP_ID"
