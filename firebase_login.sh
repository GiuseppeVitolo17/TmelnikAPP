#!/bin/bash

# Firebase Login Script
# This script will help you login to Firebase

echo "🔐 Firebase Login"
echo "=================="
echo ""
echo "This will open a browser for authentication."
echo "Please complete the login process in your browser."
echo ""
read -p "Press Enter to continue..." 

firebase login

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Login successful!"
    echo ""
    echo "Verifying connection..."
    firebase projects:list
    echo ""
    echo "Setting project to tmelnikapp..."
    firebase use tmelnikapp
    echo ""
    echo "✅ Ready to deploy!"
else
    echo ""
    echo "❌ Login failed. Please try again."
    exit 1
fi

