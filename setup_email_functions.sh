#!/bin/bash

# Email Functions Setup Script for Tmelnik App
# This script helps you configure and deploy email notification functions

set -e

echo "📧 Tmelnik Email Functions Setup"
echo "=================================="
echo ""

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Installing..."
    npm install -g firebase-tools
    echo "✅ Firebase CLI installed"
    echo ""
fi

# Check if logged in to Firebase
if ! firebase projects:list &> /dev/null; then
    echo "🔐 Please login to Firebase..."
    firebase login
    echo ""
fi

# Navigate to functions directory
cd functions

# Install dependencies
echo "📦 Installing dependencies..."
npm install
echo "✅ Dependencies installed"
echo ""

cd ..

# Configuration instructions
echo "📝 Configuration Steps:"
echo ""
echo "1. Configure email credentials using one of these methods:"
echo ""
echo "   Option A - Using Firebase Functions Config (Recommended):"
echo "   firebase functions:config:set email.user=\"your-email@gmail.com\""
echo "   firebase functions:config:set email.pass=\"your-app-password\""
echo "   firebase functions:config:set email.from=\"noreply@tmelnikapp.com\""
echo "   firebase functions:config:set email.service=\"gmail\""
echo ""
echo "   Option B - For Gmail (recommended for testing):"
echo "   - Enable 2-factor authentication in your Google Account"
echo "   - Generate an App Password: https://myaccount.google.com/apppasswords"
echo "   - Use the app password (not your regular password)"
echo ""
echo "   Option C - For SMTP server:"
echo "   firebase functions:config:set email.host=\"smtp.example.com\""
echo "   firebase functions:config:set email.port=\"587\""
echo "   firebase functions:config:set email.user=\"your-email@example.com\""
echo "   firebase functions:config:set email.pass=\"your-password\""
echo "   firebase functions:config:set email.secure=\"false\""
echo ""
echo "2. Deploy the functions:"
echo "   firebase deploy --only functions"
echo ""
echo "3. Test the functions:"
echo "   - Create a test application in the app"
echo "   - Check logs: firebase functions:log"
echo ""

# Ask if user wants to configure now
read -p "Do you want to configure email credentials now? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    read -p "Enter your email address: " EMAIL_USER
    read -sp "Enter your email password/app password: " EMAIL_PASS
    echo ""
    read -p "Enter sender email (default: noreply@tmelnikapp.com): " EMAIL_FROM
    EMAIL_FROM=${EMAIL_FROM:-noreply@tmelnikapp.com}
    
    echo ""
    echo "📧 Configuring Firebase Functions..."
    firebase functions:config:set email.user="$EMAIL_USER" email.pass="$EMAIL_PASS" email.from="$EMAIL_FROM" email.service="gmail"
    
    echo ""
    echo "✅ Email configuration saved!"
    echo ""
    read -p "Do you want to deploy the functions now? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "🚀 Deploying functions..."
        firebase deploy --only functions
        echo ""
        echo "✅ Functions deployed successfully!"
        echo ""
        echo "📊 To view logs: firebase functions:log"
    fi
else
    echo ""
    echo "ℹ️  You can configure email credentials later using the commands shown above."
fi

echo ""
echo "✨ Setup complete!"

