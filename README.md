# 🚀 TmelnikAPP

A comprehensive mobile application designed to streamline youth exchange programs. Features include travel management, participant feedback collection, event calendar with important dates, and registration system for upcoming projects.

## 🔒 Security Notice

**This repository contains Firebase API keys which are intentionally public and safe.**

Firebase API keys are **NOT secret** - they are public identifiers that identify your Firebase project. Real security comes from Firebase Security Rules, not from hiding API keys.

**For more information, see [SECURITY_NOTICE.md](SECURITY_NOTICE.md)**

## 🚀 Features

- **🔐 User Role System**: Admin and normal user roles with different permissions
- **📋 Project Management**: Admins can add, edit, and manage work opportunities
- **👥 User Authentication**: Google Sign-In and Email/Password authentication via Firebase
- **📱 Instagram Integration**: Share project offers directly to Instagram
- **🌍 Real-time Updates**: Projects load in real-time from Firebase Firestore
- **🎨 Modern UI**: Beautiful, responsive design with Material 3
- **🔄 Loading Screen**: Custom "Tmelnik Projects" loading screen
- **Cross-Platform**: Available on iOS, Android, and Web

## 🛠️ Tech Stack

- **Framework**: Flutter
- **Language**: Dart
- **Backend**: Firebase (Authentication, Firestore)
- **State Management**: StatefulWidget with StreamBuilder
- **Platforms**: iOS, Android, Web, macOS, Linux, Windows

## 📱 Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / VS Code
- iOS Simulator / Android Emulator (for testing)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/GiuseppeVitolo17/TmelnikAPP.git
cd TmelnikAPP
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
# Run with fixed port 5000 (recommended)
./run_app_port_5000.sh

# Or manually
flutter run -d chrome --web-port 5000
```

**Features:**
- ✅ **Firebase Authentication** - Email/Password and Google Sign-In
- ✅ **Complete UI** - All 4 main sections (Offers, Feedback, Info, News)
- ✅ **Navigation** - Full bottom navigation between sections
- ✅ **Instagram Sharing** - Direct link sharing functionality
- ✅ **Responsive Design** - Works on web and mobile
- ✅ **Fixed Port 5000** - Consistent configuration for Google Sign-In

**Google Sign-In Configuration:**
- OAuth Client ID: `950924265668-m1ajd0cur7oi8uf90qqarfm1f5r3plj4.apps.googleusercontent.com`
- Authorized domains: `localhost`, `127.0.0.1`, `localhost:5000`
- App runs on fixed port 5000 for consistent configuration

**For Desktop (Linux/Windows/Mac):**
```bash
flutter run -d linux  # or windows/macos
```

**For Mobile:**
```bash
flutter run  # Will show available devices
```

### 🔥 Current Status

**Firebase Version with Google Sign-In:**
- ✅ **Complete Firebase Integration** - Authentication, Firestore, Storage
- ✅ **Google Sign-In** - One-click authentication with Google
- ✅ **Email/Password Auth** - Traditional login and registration
- ✅ **Complete UI** - All 4 main sections (Offers, Feedback, Info, News)
- ✅ **Navigation** - Full bottom navigation between sections
- ✅ **Instagram Sharing** - Direct link sharing functionality
- ✅ **Responsive Design** - Works on web and mobile

### 🚀 Quick Start

**To run the complete Firebase app:**
1. Run `./run_app_port_5000.sh` or `flutter run -t lib/main_google_fixed.dart -d chrome --web-port 5000`
2. App will open at `http://localhost:5000` in your main Chrome browser
3. Use Google Sign-In or create an account with email/password
4. Explore all 4 main sections with full functionality
5. All data is synced to Firebase

**Available versions:**
- **`lib/main_google_fixed.dart`** - Complete app with Google Sign-In (recommended)
- **`lib/main_email_only.dart`** - Email/Password authentication only
- **`lib/main_working.dart`** - Working version with logging

**Note:** Port 5000 is fixed for consistent Google Sign-In configuration.

## 👑 **Admin Setup**

The app has two types of users:
- **Normal Users**: Can view and share projects
- **Admin Users**: Can add, edit, and manage projects (+ button visible)

**To set up an admin:**
1. Login to the app with your account
2. Go to [Firebase Console](https://console.firebase.google.com/) → Firestore Database
3. Find your user in the `users` collection
4. Set `isAdmin: true`
5. Logout and login again

**For detailed instructions, see [ADMIN_SETUP.md](ADMIN_SETUP.md)**

## 🏗️ Project Structure

```
lib/
├── main.dart                 # App entry point
├── screens/                  # App screens
├── widgets/                  # Reusable widgets
├── models/                   # Data models
├── services/                 # API and business logic
└── utils/                    # Utility functions
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Giuseppe Vitolo**
- GitHub: [@GiuseppeVitolo17](https://github.com/GiuseppeVitolo17)
- Email: vitologiuseppe17@gmail.com

## 📚 Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)
