# 🚀 TmelnikAPP

A comprehensive mobile application designed to streamline youth exchange programs. Features include travel management, participant feedback collection, event calendar with important dates, and registration system for upcoming projects.

## 🔒 Security Notice

**This repository contains Firebase API keys which are intentionally public and safe.**

Firebase API keys are **NOT secret** - they are public identifiers that identify your Firebase project. Real security comes from Firebase Security Rules, not from hiding API keys.

**For more information, see [SECURITY_NOTICE.md](SECURITY_NOTICE.md)**

## 🚀 Features

- **Travel Management**: Organize and track youth exchange trips
- **Feedback Collection**: Gather participant feedback and evaluations
- **Event Calendar**: View important dates and upcoming events
- **Project Registration**: Register for upcoming youth exchange projects
- **Cross-Platform**: Available on iOS, Android, and Web

## 🛠️ Tech Stack

- **Framework**: Flutter
- **Language**: Dart
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

**For Web (Recommended - Firebase works best here):**
```bash
flutter run -d chrome
```

**For Desktop (Linux/Windows/Mac):**
```bash
flutter run -d linux  # or windows/macos
```

**For Mobile:**
```bash
flutter run  # Will show available devices
```

### 🔥 Current Status

**Working Version Available:**
- ✅ **Complete UI** - All 4 main sections (Offers, Feedback, Info, News)
- ✅ **Navigation** - Full bottom navigation between sections
- ✅ **Local Data** - SharedPreferences for data persistence
- ✅ **Instagram Sharing** - Direct link sharing functionality
- ✅ **Responsive Design** - Works on web and mobile

**Firebase Integration (In Development):**
- ⚠️ **Firebase Dependencies** - Currently has compilation conflicts
- 📋 **Planned Features** - Email/Password auth, Firestore, Google Sign-In
- 🔧 **Status** - Working on resolving Firebase web compatibility issues

### 🚀 Quick Demo

**To see the working app:**
1. Run `./run_local.sh` or `flutter run -t lib/main_local.dart -d chrome`
2. Explore all 4 main sections with full UI functionality
3. Test navigation, data persistence, and Instagram sharing
4. All features work without requiring Firebase setup

**Note:** The app works perfectly on Web and mobile. Firebase integration is being developed separately.

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
