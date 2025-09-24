# 🚀 Local Development Guide

## 📱 App Versions

This project has **two versions** for different use cases:

### 1. **Full Version** (with Firebase)
- **File**: `lib/main.dart`
- **Features**: Complete Firebase integration, authentication, database
- **Use**: Production, web deployment
- **Command**: `flutter run -d chrome`

### 2. **Local Version** (without Firebase)
- **File**: `lib/main_local.dart`
- **Features**: UI only, no Firebase dependencies
- **Use**: Local development, testing, demo
- **Command**: `flutter run -t lib/main_local.dart -d chrome`

## 🔧 Quick Start

### For Local Development (Recommended):
```bash
# Easy way
./run_local.sh

# Manual way
flutter run -t lib/main_local.dart -d chrome
```

### For Production Testing:
```bash
# With Firebase (requires setup)
flutter run -d chrome
```

## 🎯 What Works in Local Version

✅ **All UI Components**
✅ **Navigation between screens**
✅ **Project Offers with Instagram sharing**
✅ **Material 3 Design**
✅ **Responsive layout**
✅ **Clipboard functionality**
✅ **URL launching**

❌ **Firebase Authentication** (not needed for UI testing)
❌ **Database operations** (not needed for UI testing)
❌ **Real-time data** (not needed for UI testing)

## 🌐 Deployment

- **Web**: Use full version (`main.dart`) - already configured
- **Local**: Use local version (`main_local.dart`) - for development

## 🐛 Troubleshooting

### Firebase Errors on Linux/Desktop:
```
PlatformException(channel-error, Unable to establish connection on channel.)
```
**Solution**: Use local version instead: `./run_local.sh`

### Chrome Connection Issues:
```
Failed to compile application
```
**Solution**: Try different port: `flutter run -d chrome --web-port 8081`

## 📋 Development Workflow

1. **UI Development**: Use local version for fast iteration
2. **Firebase Features**: Use full version for testing
3. **Deployment**: Use full version for production

## 🎨 Features Available in Local Version

- 🏠 **Main Navigation** with 4 sections
- 📋 **Project Offers** with sample data
- 💬 **Feedback Screen** (placeholder)
- ℹ️ **Information Screen** (placeholder)
- 📰 **News Screen** (placeholder)
- 🔗 **Instagram Sharing** functionality
- 📱 **Responsive Design** for all screen sizes

Perfect for demonstrating the app interface and functionality without Firebase setup!
