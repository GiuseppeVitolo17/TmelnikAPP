#!/bin/bash

echo "🚀 Starting Tmelnik App in LOCAL mode (without Firebase)..."

# Run Flutter with local version (no Firebase)
flutter run -t lib/main_local.dart -d chrome --web-port 8080
