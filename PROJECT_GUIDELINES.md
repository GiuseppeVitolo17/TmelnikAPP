# TmelnikAPP - Linee Guida di Sviluppo

## 📋 Panoramica

Questo documento contiene le linee guida per lo sviluppo del progetto TmelnikAPP, un'app Flutter per la gestione di scambi giovanili. Segui queste direttive per mantenere la coerenza del codice e evitare di rompere funzionalità esistenti.

---

## 🎨 Sistema di Theme

### Struttura
Il tema dell'app è centralizzato in `lib/theme/app_theme.dart`.

### Utilizzo
**✅ SEMPRE usa le costanti del tema invece di valori hardcoded:**

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

// ❌ ERRATO
Container(
  color: const Color(0xFFF5F6FA),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(20),
  ),
)
```

### Costanti Disponibili

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
- Funzione che ritorna il ThemeData completo per l'app
- Utilizzata in `main.dart` come base del tema

---

## 🧩 Componenti UI Riutilizzabili

### ProjectCard Widget

**Posizione:** `lib/widgets/project_card.dart`

**Utilizzo:**
```dart
ProjectCard(
  title: 'Project Berlin',
  dates: '14 July / 19 July',
  imagePathOrUrl: 'assets/images/berlin.jpg', // o URL HTTP
  onApply: () {
    // Gestisci click su Apply
  },
  onInfo: () {
    // Gestisci click su Infopack
  },
)
```

**Caratteristiche:**
- Widget puro UI, nessuna logica di business
- Supporta sia immagini locali (`assets/`) che remote (HTTP)
- Gestione automatica di loading ed errori
- Utilizza il sistema di theme centralizzato

**⚠️ IMPORTANTE:**
- Non aggiungere logica HTTP o Firestore dentro questo widget
- Mantieni il widget stateless e puramente UI

---

## ⚠️ ZONE PROTETTE - NON MODIFICARE

### 🔥 Firebase & Authentication

**File che NON devono essere modificati senza autorizzazione esplicita:**
- `lib/firebase_options.dart`
- `lib/screens/auth_screen.dart`
- `lib/screens/auth_screen_firebase.dart`
- `lib/screens/auth_wrapper.dart`
- `lib/services/firebase_*_service.dart`

**Cosa NON fare:**
- ❌ Rimuovere inizializzazione Firebase da `main.dart`
- ❌ Modificare il flusso di autenticazione
- ❌ Cambiare la struttura di AuthWrapper
- ❌ Rimuovere import di Firebase o Auth

**Cosa puoi fare:**
- ✅ Usare Firebase nei servizi esistenti
- ✅ Chiamare metodi di autenticazione già definiti
- ✅ Aggiungere nuove funzionalità senza toccare l'infrastruttura esistente

### 🧭 Navigazione

**File protetti:**
- `lib/main.dart` - struttura MaterialApp e AuthWrapper
- `lib/screens/main_navigation_screen.dart` - navigazione principale

**Cosa NON fare:**
- ❌ Modificare la struttura di navigazione esistente
- ❌ Rimuovere route o screen già configurati
- ❌ Cambiare il BottomNavigationBar structure

### 📦 Servizi e Modelli

**Non eliminare:**
- Classi di modelli in `lib/models/`
- Servizi esistenti in `lib/services/`
- Logica di progetto/admin esistente

---

## 🏗️ Struttura Progetto

```
lib/
├── theme/
│   └── app_theme.dart          # Sistema di theme centralizzato
├── widgets/
│   └── project_card.dart       # Widget riutilizzabile per card progetti
├── screens/
│   ├── project_offers_screen.dart  # Schermata progetti (usa ProjectCard)
│   ├── auth_screen.dart           # ⚠️ PROTETTO
│   └── ...
├── services/
│   ├── pexels_service.dart        # Service per immagini Pexels
│   └── ...                         # ⚠️ Non modificare servizi Firebase
├── models/                        # Modelli dati
└── main.dart                      # ⚠️ Solo modifiche al theme consentite
```

---

## ✅ Best Practices

### 1. Uso del Theme
- **SEMPRE** importa `app_theme.dart` per nuovi widget
- **SEMPRE** usa `AppColors`, `AppRadius`, `AppShadows` invece di valori hardcoded
- Mantieni la coerenza visiva in tutta l'app

### 2. Nuovi Widget
- Crea widget riutilizzabili in `lib/widgets/`
- Mantieni widget stateless quando possibile
- Separa logica UI da logica di business
- Non includere chiamate HTTP o Firestore direttamente nei widget

### 3. Test
- Aggiungi test minimi per nuovi widget in `test/`
- Non inizializzare Firebase nei test
- Usa `MaterialApp` wrapper per i test widget

### 4. Immagini
- Usa `Image.network()` per URL HTTP
- Usa `Image.asset()` per immagini locali
- Gestisci sempre loading e error states
- Usa placeholder appropriati

### 5. Gestione Errori
- Usa try-catch per operazioni async
- Fornisci fallback UI appropriati
- Logga errori con `debugPrint` (non `print`)

---

## 🧪 Testing

### Struttura Test
- Test widget in `test/` directory
- Non inizializzare Firebase nei test
- Usa `MaterialApp` wrapper
- Test minimi ma significativi

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

## 📝 Convenzioni Codice

### Naming
- **File:** `snake_case.dart`
- **Classi:** `PascalCase`
- **Variabili/Funzioni:** `camelCase`
- **Costanti:** `PascalCase` per classi, `camelCase` per costanti statiche

### Organizzazione Codice
1. Imports (dart:, package:, relative)
2. Class definition
3. Fields
4. Constructor
5. Build method
6. Private methods
7. Public methods

### Commenti
- Usa commenti per spiegare "perché", non "cosa"
- Documenta widget pubblici con commenti DartDoc
- Aggiungi commenti per logica complessa

---

## 🚀 Workflow di Sviluppo

### Quando aggiungi nuove funzionalità:

1. **Controlla il sistema di theme** - usa costanti esistenti
2. **Crea widget riutilizzabili** - in `lib/widgets/` se appropriato
3. **Non toccare Firebase/Auth** - usa solo servizi esistenti
4. **Aggiungi test minimi** - per nuovi widget
5. **Verifica che nulla sia rotto** - testa navigazione e auth

### Quando modifichi UI esistente:

1. **Aggiorna per usare theme** - sostituisci valori hardcoded
2. **Mantieni comportamento esistente** - non rompere funzionalità
3. **Verifica tutte le schermate** - assicurati che tutto funzioni

---

## 📦 Dipendenze Importanti

### Core UI
- `cached_network_image` - per cache immagini remote
- `http` - per chiamate API (usato in PexelsService)

### Firebase (⚠️ Non modificare configurazione)
- `firebase_core`
- `firebase_auth`
- `cloud_firestore`

---

## 🔍 Checklist Pre-Commit

Prima di fare commit, verifica:

- [ ] Nessun valore hardcoded (usa theme)
- [ ] Nessuna modifica a Firebase/Auth senza autorizzazione
- [ ] Navigazione funziona correttamente
- [ ] Widget nuovi sono testati
- [ ] Codice compila senza errori (`flutter analyze`)
- [ ] Test passano (`flutter test`)

---

## 📞 Riferimenti Rapidi

**Theme System:** `lib/theme/app_theme.dart`  
**ProjectCard Widget:** `lib/widgets/project_card.dart`  
**Progetti Screen:** `lib/screens/project_offers_screen.dart`  
**Main Entry:** `lib/main.dart`  

---

## 🎯 Obiettivo Qualità

Target: **~80% standard professionale**

- ✅ Codice modulare e riutilizzabile
- ✅ Theme centralizzato
- ✅ Widget testati
- ✅ Gestione errori robusta
- ✅ Nessuna breaking change a Firebase/Auth

---

**Ultima aggiornamento:** 2025-10-29  
**Versione:** 1.0

