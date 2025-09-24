#!/bin/bash

echo "🔥 Starting Tmelnik App with Firebase + Google Sign-In..."

echo ""
echo "⚠️  IMPORTANTE: Prima di procedere, assicurati di aver configurato:"
echo "1. Google Client ID in web/index.html"
echo "2. Google provider abilitato in Firebase Console"
echo "3. Nome progetto e email di supporto configurati"
echo ""

read -p "Premi ENTER per continuare o Ctrl+C per annullare..."

# Run Flutter with Firebase
flutter run -t lib/main_firebase.dart -d chrome --web-port 8080
