#!/bin/bash

echo "🚀 Starting Tmelnik App on Port 5000..."
echo "📝 This will open in your main Chrome browser on http://localhost:5000"
echo "🔧 Fixed port for consistent Google Sign-In configuration"

# Run the Flutter app on Chrome with fixed port 5000
flutter run -d chrome --web-port 5000

echo "🔍 App should be available at: http://localhost:5000"
echo "📋 Google Sign-In domains configured for port 5000"
