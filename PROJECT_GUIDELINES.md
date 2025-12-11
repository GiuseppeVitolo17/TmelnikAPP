# TmelnikAPP - Development Guidelines

## 📋 Overview

This document outlines the development guidelines for TmelnikAPP, a Flutter app for youth exchange management. Follow these to keep code consistent and avoid breaking existing features.

---

## 🎨 Theme System

### Structure
The app theme is centralized in `lib/theme/app_theme.dart`.

### Usage
**✅ ALWAYS use theme constants instead of hardcoded values:**

```dart
import '../theme/app_theme.dart';

// ✅ CORRETTO
Container(
  color: AppColors.backgroundGrey,
  decoration: BoxDecoration(
    borderRadius: AppRadius.large,
    boxShadow: AppShadows.soft,
  ),
)

// ❌ WRONG
Container(
  color: const Color(0xFFF5F6FA),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(20),
  ),
)
```

### Available Constants

**AppColors:**
- `primaryBlue` - Color(0xFF0066FF)
- `secondaryYellow` - Color(0xFFFFC107)
- `backgroundGrey` - Color(0xFFF5F6FA)
- `textPrimary` - Colors.black
- `textSecondary` - Colors.grey
- `cardBackground` - Colors.white

**AppRadius:**
- `large` - BorderRadius.circular(20)
- `medium` - BorderRadius.circular(12)

**AppShadows:**
- `soft` - BoxShadow con opacity 0.08, blur 10, offset (0, 4)

**buildAppTheme():**
- Returns the complete ThemeData for the app
- Used in `main.dart` as the base theme

---

## 🧩 Reusable UI Components

### ProjectCard Widget

**Location:** `lib/widgets/project_card.dart`

**Usage:**
```dart
ProjectCard(
  title: 'Project Berlin',
  dates: '14 July / 19 July',
  imagePathOrUrl: 'assets/images/berlin.jpg', // o URL HTTP
  onApply: () {
    // Handle Apply click
  },
  onInfo: () {
    // Handle Infopack click
  },
)
```

**Features:**
- Pure UI widget, no business logic
- Supports local (`assets/`) and remote (HTTP) images
- Built-in loading and error handling
- Uses centralized theme system

**⚠️ IMPORTANT:**
- Do not add HTTP/Firestore logic here
- Keep the widget stateless and purely UI

---

## ⚠️ PROTECTED AREAS - DO NOT MODIFY

### 🔥 Firebase & Authentication

**Files that must NOT be changed without explicit approval:**
- `lib/firebase_options.dart`
- `lib/screens/auth_screen.dart`
- `lib/screens/auth_screen_firebase.dart`
- `lib/screens/auth_wrapper.dart`
- `lib/services/firebase_*_service.dart`

**Do NOT:**
- ❌ Rimuovere inizializzazione Firebase da `main.dart`
- ❌ Modificare il flusso di autenticazione
- ❌ Cambiare la struttura di AuthWrapper
- ❌ Rimuovere import di Firebase o Auth

**You MAY:**
- ✅ Use Firebase via existing services
- ✅ Use existing auth methods
- ✅ Add features without touching core infrastructure

### 🧭 Navigazione

**Protected files:**
- `lib/main.dart` - struttura MaterialApp e AuthWrapper
- `lib/screens/main_navigation_screen.dart` - navigazione principale

**Do NOT:**
- ❌ Modificare la struttura di navigazione esistente
- ❌ Rimuovere route o screen già configurati
- ❌ Cambiare il BottomNavigationBar structure

### 📦 Services and Models

**Do not remove:**
- Classi di modelli in `lib/models/`
- Servizi esistenti in `lib/services/`
- Logica di progetto/admin esistente

---

## 🏗️ Project Structure

```
lib/
├── theme/
│   └── app_theme.dart          # Centralized theme system
├── widgets/
│   └── project_card.dart       # Reusable project card widget
├── screens/
│   ├── project_offers_screen.dart  # Projects screen (uses ProjectCard)
│   ├── auth_screen.dart           # ⚠️ PROTETTO
│   └── ...
├── services/
│   ├── pexels_service.dart        # Pexels images service
│   └── ...                         # ⚠️ Do not modify Firebase services
├── models/                        # Data models
└── main.dart                      # ⚠️ Only theme edits allowed
```

---

## ✅ Best practices

### 1. Theme usage
- **ALWAYS** import `app_theme.dart` for new widgets
- **ALWAYS** use `AppColors`, `AppRadius`, `AppShadows` instead of hardcoded values
- Keep visual consistency across the app

### 2. New Widgets
- Create reusable widgets in `lib/widgets/`
- Keep widgets stateless when possible
- Separate UI from business logic
- Do not call HTTP/Firestore directly in widgets

### 3. Tests
- Add minimal tests for new widgets in `test/`
- Do not initialize Firebase in tests
- Use a `MaterialApp` wrapper for widget tests

### 4. Images
- Use `Image.network()` for HTTP URLs
- Use `Image.asset()` for local images
- Always handle loading and error states
- Use appropriate placeholders

### 5. Error handling
- Use try-catch for async operations
- Provide proper UI fallbacks
- Log errors with `debugPrint` (not `print`)

---

## 🧪 Testing

### Test structure
- Widget tests in `test/` directory
- Do not initialize Firebase in tests
- Use `MaterialApp` wrapper
- Minimal but meaningful tests

**Esempio:**
```dart
testWidgets('Widget displays content', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MyWidget(...),
    ),
  );
  
  expect(find.text('Expected Text'), findsOneWidget);
});
```

---

## 📝 Code conventions

### Naming
- **Files:** `snake_case.dart`
- **Classes:** `PascalCase`
- **Variables/Functions:** `camelCase`
- **Constants:** `PascalCase` for classes, `camelCase` for static constants

### Code organization
1. Imports (dart:, package:, relative)
2. Class definition
3. Fields
4. Constructor
5. Build method
6. Private methods
7. Public methods

### Comments
- Explain "why", not "what"
- Document public widgets with DartDoc
- Add comments for complex logic

---

## 🚀 Development workflow

### When adding new features:

1. **Controlla il sistema di theme** - usa costanti esistenti
2. **Crea widget riutilizzabili** - in `lib/widgets/` se appropriato
3. **Non toccare Firebase/Auth** - usa solo servizi esistenti
4. **Aggiungi test minimi** - per nuovi widget
5. **Verifica che nulla sia rotto** - testa navigazione e auth

### When modifying existing UI:

1. **Aggiorna per usare theme** - sostituisci valori hardcoded
2. **Mantieni comportamento esistente** - non rompere funzionalità
3. **Verifica tutte le schermate** - assicurati che tutto funzioni

---

## 📦 Important dependencies

### Core UI
- `cached_network_image` - remote image caching
- `http` - API calls (used in PexelsService)

### Firebase (⚠️ Do not change configuration)
- `firebase_core`
- `firebase_auth`
- `cloud_firestore`

---

## 🔍 Pre-commit checklist

Before committing, verify:

- [ ] No hardcoded values (use theme)
- [ ] No changes to Firebase/Auth without approval
- [ ] Navigation works correctly
- [ ] New widgets are tested
- [ ] Code compiles without errors (`flutter analyze`)
- [ ] Tests pass (`flutter test`)

---

## 📞 Quick references

**Theme System:** `lib/theme/app_theme.dart`  
**ProjectCard Widget:** `lib/widgets/project_card.dart`  
**Projects Screen:** `lib/screens/project_offers_screen.dart`  
**Main Entry:** `lib/main.dart`  

---

## 🎯 Quality target

Target: **~80% standard professionale**

- ✅ Codice modulare e riutilizzabile
- ✅ Theme centralizzato
- ✅ Widget testati
- ✅ Gestione errori robusta
- ✅ No breaking changes to Firebase/Auth

---

**Last update:** 2025-10-29  
**Version:** 1.0

