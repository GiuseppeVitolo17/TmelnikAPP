# 🔐 Google Sign-In Setup Guide

## ⚠️ Current Issue
The app shows an error when trying to use Google Sign-In:
```
ClientID not set. Either set it on a <meta name="google-signin-client_id" content="CLIENT_ID" /> tag, or pass clientId when initializing GoogleSignIn
```

## 🛠️ How to Fix

### Step 1: Get Google Client ID
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project: `tmelnikapp`
3. Go to **APIs & Services** → **Credentials**
4. Find or create an **OAuth 2.0 Client ID** for **Web application**
5. Copy the **Client ID** (looks like: `123456789-abcdefg.apps.googleusercontent.com`)

### Step 2: Update HTML File
Replace `YOUR_GOOGLE_CLIENT_ID` in `web/index.html`:

```html
<meta name="google-signin-client_id" content="123456789-abcdefg.apps.googleusercontent.com">
```

### Step 3: Enable Google Sign-In in Firebase
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: `tmelnikapp`
3. Go to **Authentication** → **Sign-in method**
4. Enable **Google** provider
5. Add your domain to **Authorized domains**

## 🚀 Alternative: Use Email/Password Only
If you don't need Google Sign-In immediately, you can:
1. Use only Email/Password authentication
2. The Google Sign-In button will show an error, but Email/Password will work fine
3. Add Google Sign-In later when you have the Client ID

## 📱 Current Working Features
- ✅ Email/Password Registration
- ✅ Email/Password Login
- ✅ Firebase Authentication
- ✅ Firestore Database
- ✅ All app screens and navigation
- ⚠️ Google Sign-In (needs Client ID setup)

## 🔧 Quick Test
To test the app without Google Sign-In:
1. Run: `./run_firebase.sh`
2. Click "Create an account"
3. Enter email and password
4. Login and explore all features

The app works perfectly with Email/Password authentication!
