#!/bin/bash

# Quick Deploy Script for Email Functions
# Run this after completing firebase login

set -e

echo "🚀 Tmelnik Email Functions - Quick Deploy"
echo "=========================================="
echo ""

# Check if logged in
if ! firebase projects:list &> /dev/null; then
    echo "❌ Not logged in to Firebase"
    echo ""
    echo "Please run: firebase login"
    echo "This will open a browser for authentication."
    exit 1
fi

echo "✅ Firebase authentication verified"
echo ""

# Set project
echo "📋 Setting project to tmelnikapp..."
firebase use tmelnikapp
echo ""

# Check if email is configured
echo "📧 Checking email configuration..."
CONFIG=$(firebase functions:config:get 2>/dev/null || echo "")

if [[ -z "$CONFIG" ]] || [[ "$CONFIG" == *"email"* ]]; then
    echo "✅ Email configuration found"
else
    echo "⚠️  Email not configured yet"
    echo ""
    echo "To configure email, run:"
    echo "  firebase functions:config:set email.user=\"your-email@gmail.com\""
    echo "  firebase functions:config:set email.pass=\"your-app-password\""
    echo "  firebase functions:config:set email.from=\"noreply@tmelnikapp.com\""
    echo "  firebase functions:config:set email.service=\"gmail\""
    echo ""
    read -p "Do you want to configure email now? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter your email: " EMAIL_USER
        read -sp "Enter app password: " EMAIL_PASS
        echo ""
        read -p "Enter sender email (default: noreply@tmelnikapp.com): " EMAIL_FROM
        EMAIL_FROM=${EMAIL_FROM:-noreply@tmelnikapp.com}
        
        firebase functions:config:set \
          email.user="$EMAIL_USER" \
          email.pass="$EMAIL_PASS" \
          email.from="$EMAIL_FROM" \
          email.service="gmail"
        
        echo "✅ Email configured!"
    fi
fi

echo ""
echo "📦 Deploying functions..."
firebase deploy --only functions

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 View logs with: firebase functions:log"
echo "🧪 Test by creating an application in the app"

