# Firebase Setup Guide

## 🔒 Security Options

This project offers multiple security approaches for Firebase configuration:

### **Option 1: Environment Variables (Recommended for Development)**
- Uses `.env` file for local development
- No secrets in repository
- Requires manual setup

### **Option 2: Public Repository with "Safe" Keys (Recommended for Small Teams)**
- Firebase API keys are NOT actually secret
- Security comes from Firebase Rules, not API keys
- Simpler setup, works out of the box

### **Option 3: GitHub Secrets (Recommended for CI/CD)**
- Uses GitHub Actions secrets
- Perfect for automated deployments
- Requires GitHub repository

### **Option 4: Private Repository**
- Keep repository private
- Include actual keys
- Only authorized team members can access

## 📋 Setup Instructions

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project: `tmelnikapp`
3. Enable Authentication (Email/Password + Google)
4. Create Firestore Database
5. Get your configuration values

### 2. Configure Environment Variables

#### Option A: Using .env file (Recommended for development)
1. Create a `.env` file in the project root:
```bash
# Copy and paste your Firebase config values
FIREBASE_API_KEY=your_actual_api_key_here
FIREBASE_PROJECT_ID=tmelnikapp
FIREBASE_MESSAGING_SENDER_ID=your_sender_id_here
FIREBASE_AUTH_DOMAIN=tmelnikapp.firebaseapp.com
FIREBASE_STORAGE_BUCKET=tmelnikapp.firebasestorage.app
FIREBASE_WEB_APP_ID=your_web_app_id_here
```

#### Option B: Using build arguments (Recommended for production)
```bash
flutter run --dart-define=FIREBASE_API_KEY=your_api_key_here \
             --dart-define=FIREBASE_PROJECT_ID=tmelnikapp \
             --dart-define=FIREBASE_MESSAGING_SENDER_ID=your_sender_id_here \
             --dart-define=FIREBASE_AUTH_DOMAIN=tmelnikapp.firebaseapp.com \
             --dart-define=FIREBASE_STORAGE_BUCKET=tmelnikapp.firebasestorage.app \
             --dart-define=FIREBASE_WEB_APP_ID=your_web_app_id_here
```

### 3. Enable Authentication Methods

In Firebase Console → Authentication → Sign-in method:
- ✅ Enable Email/Password
- ✅ Enable Google (for Google Sign-In)

### 4. Configure Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Public read access for offers, news, info
    match /{collection}/{document} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

## 🚀 Running the App

### Development
```bash
# Make sure .env file exists with your Firebase config
flutter run -d linux
```

### Production
```bash
# Use build arguments for production
flutter run --dart-define=FIREBASE_API_KEY=... [other defines]
```

## 🔐 Security Best Practices

1. ✅ Never commit `.env` files
2. ✅ Use environment variables for all secrets
3. ✅ Rotate API keys regularly
4. ✅ Use Firebase Security Rules
5. ✅ Enable App Check for production

## 📱 Features Included

- ✅ Firebase Authentication (Email + Google)
- ✅ Firestore Database
- ✅ Firebase Storage
- ✅ Real-time data sync
- ✅ Offline support
- ✅ User roles (admin/member)
- ✅ Secure configuration

## 🆘 Troubleshooting

### "Firebase not initialized" error
- Check that all environment variables are set
- Verify Firebase project configuration
- Ensure Authentication is enabled

### Google Sign-In not working
- Enable Google Sign-In in Firebase Console
- Check OAuth consent screen configuration
- Verify web client ID

### Build errors
- Run `flutter clean && flutter pub get`
- Check environment variable syntax
- Verify all required variables are set
