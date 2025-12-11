# Configurazione Notifiche Push per iOS

## ✅ Cosa è già implementato

Il codice Dart è già pronto per iOS:
- ✅ `NotificationService` supporta iOS con `DarwinInitializationSettings`
- ✅ Richiesta permessi notifiche per iOS
- ✅ Gestione notifiche in foreground e background
- ✅ Supporto per FCM (Firebase Cloud Messaging)

## ⚠️ Configurazioni necessarie per iOS

### 1. AppDelegate.swift ✅ (AGGIORNATO)
L'`AppDelegate.swift` è stato aggiornato per supportare FCM.

### 2. GoogleService-Info.plist
Devi aggiungere il file `GoogleService-Info.plist` nella cartella `ios/Runner/`:

1. Vai su [Firebase Console](https://console.firebase.google.com/)
2. Seleziona il progetto `tmelnikapp`
3. Vai su **Project Settings** → **Your apps**
4. Se non c'è un'app iOS, clicca su **Add app** → **iOS**
5. Inserisci il **Bundle ID** (es: `com.example.tmelnikApp`)
6. Scarica il file `GoogleService-Info.plist`
7. Copialo in `ios/Runner/GoogleService-Info.plist`
8. Aggiungilo al progetto Xcode (drag & drop in Xcode)

### 3. Aggiornare firebase_options.dart
Dopo aver aggiunto l'app iOS su Firebase Console, aggiorna `lib/firebase_options.dart`:

```dart
static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'YOUR_IOS_API_KEY',
  appId: 'YOUR_IOS_APP_ID',  // Es: '1:950924265668:ios:abc123...'
  messagingSenderId: '950924265668',
  projectId: 'tmelnikapp',
  storageBucket: 'tmelnikapp.firebasestorage.app',
  iosBundleId: 'com.example.tmelnikApp',  // Il tuo Bundle ID
);
```

**Oppure** usa FlutterFire CLI per rigenerare automaticamente:
```bash
flutterfire configure --platforms=ios
```

### 4. Configurare Xcode Project

Apri `ios/Runner.xcworkspace` in Xcode e configura:

#### a) Push Notifications Capability
1. Seleziona il target **Runner**
2. Vai su **Signing & Capabilities**
3. Clicca **+ Capability**
4. Aggiungi **Push Notifications**

#### b) Background Modes
1. Nella stessa sezione **Signing & Capabilities**
2. Aggiungi **Background Modes** (se non presente)
3. Abilita:
   - ✅ Remote notifications

#### c) Bundle Identifier
Assicurati che il **Bundle Identifier** corrisponda a quello configurato su Firebase Console.

### 5. Installare Pods
Dopo aver aggiunto le dipendenze, installa i CocoaPods:

```bash
cd ios
pod install
cd ..
```

### 6. APNs Certificate/Key (per produzione)
Per le notifiche push su dispositivi reali, devi configurare APNs:

1. Vai su [Apple Developer Portal](https://developer.apple.com/)
2. Crea un **Key** per APNs (o usa un certificato)
3. Carica la chiave su Firebase Console:
   - Firebase Console → Project Settings → Cloud Messaging → **Apple app configuration**
   - Carica il file `.p8` (APNs Auth Key) o il certificato

**Nota**: Per il testing in sviluppo, puoi usare il certificato di sviluppo automatico.

## 🧪 Test delle Notifiche

### Test locale (senza FCM)
Le notifiche locali funzioneranno subito dopo la configurazione base.

### Test con FCM
1. Assicurati che l'app sia registrata su Firebase Console
2. Verifica che il token FCM venga generato (controlla i log)
3. Usa Firebase Console → Cloud Messaging per inviare una notifica di test

## 📱 Verifica Funzionamento

Dopo la configurazione, verifica che:

1. ✅ L'app richiede i permessi notifiche al primo avvio
2. ✅ Il token FCM viene generato (controlla i log: `🔔 FCM token: ...`)
3. ✅ L'app si iscrive al topic `projects` (log: `✅ Subscribed to FCM topic: projects`)
4. ✅ Le notifiche locali funzionano quando viene creato un nuovo progetto

## 🔍 Troubleshooting

### "Failed to register for remote notifications"
- Verifica che Push Notifications capability sia abilitata in Xcode
- Controlla che il Bundle ID corrisponda su Firebase e Xcode

### "No APNs token"
- Assicurati di aver configurato APNs su Firebase Console
- Per sviluppo, usa il certificato di sviluppo automatico

### Notifiche non arrivano
- Verifica i permessi: Settings → App → Notifications
- Controlla che il token FCM sia generato
- Verifica che l'app sia iscritta al topic `projects`

## 📚 Riferimenti

- [Firebase Cloud Messaging iOS Setup](https://firebase.google.com/docs/cloud-messaging/ios/client)
- [FlutterFire Messaging](https://firebase.flutter.dev/docs/messaging/overview)
- [APNs Configuration](https://developer.apple.com/documentation/usernotifications)


