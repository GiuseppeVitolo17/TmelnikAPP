# 📱 Guida Completa: Pubblicare TmelnikAPP su Google Play Store

Questa guida ti accompagnerà passo dopo passo per pubblicare la tua app Flutter su Google Play Store.

---

## 📋 Prerequisiti

1. ✅ Account Google Developer (costo una tantum: $25)
2. ✅ App Flutter funzionante
3. ✅ Firebase configurato (già fatto ✅)
4. ✅ Google-services.json già presente in `android/app/`

---

## 🔧 Step 1: Configurare Android per la Release

### 1.1 Aggiornare build.gradle

Verifica che `android/app/build.gradle.kts` abbia:

```kotlin
android {
    namespace = "com.example.tmelnik_app"  // Sostituisci con il tuo package name
    compileSdk = 34
    
    defaultConfig {
        applicationId = "com.example.tmelnik_app"  // Deve essere unico!
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }
    
    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    // ... altre dipendenze
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    implementation("com.google.firebase:firebase-messaging")
}
```

### 1.2 Verificare google-services.json

Assicurati che `android/app/google-services.json` sia presente e corretto.

---

## 🔐 Step 2: Creare Keystore per Firmare l'App

### 2.1 Generare il Keystore

Apri il terminale e esegui:

```bash
cd android
keytool -genkey -v -keystore tmelnik-upload-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**IMPORTANTE**: 
- Memorizza la password del keystore (scriverla in un posto sicuro!)
- Il keystore DEVE essere salvato in un posto sicuro e mai committato su Git
- Senza questo keystore NON potrai aggiornare l'app in futuro!

### 2.2 Creare key.properties

Crea il file `android/key.properties`:

```properties
storePassword=LA_TUA_PASSWORD_DEL_KEYSTORE
keyPassword=LA_TUA_PASSWORD_DELLA_CHIAVE
keyAlias=upload
storeFile=/percorso/completo/tmelnik-upload-key.jks
```

**⚠️ ATTENZIONE**: Aggiungi `key.properties` al `.gitignore` per non committarlo!

### 2.3 Configurare build.gradle per la firma

Modifica `android/app/build.gradle.kts`:

```kotlin
// Aggiungi all'inizio del file
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ... altre configurazioni
    
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

---

## 🎨 Step 3: Personalizzare l'App

### 3.1 Icona dell'App

Aggiungi `flutter_launcher_icons` a `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/images/app_icon.png"
```

Poi esegui:
```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

### 3.2 Nome e Package Name

Modifica `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.tmelnik.app">  <!-- Cambia con il tuo package name -->
    
    <application
        android:label="TmelnikAPP"  <!-- Nome dell'app -->
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        ...
    </application>
</manifest>
```

### 3.3 Permessi Necessari

Verifica che `AndroidManifest.xml` includa:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>  <!-- Per le notifiche -->
```

---

## 📦 Step 4: Build dell'App Bundle (AAB)

### 4.1 Build Release

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

Il file `.aab` sarà generato in:
`build/app/outputs/bundle/release/app-release.aab`

### 4.2 Testare l'APK Locale (Opzionale)

Per testare prima di pubblicare:

```bash
flutter build apk --release
```

Il file `.apk` sarà in:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 🏪 Step 5: Pubblicare su Google Play Console

### 5.1 Creare Account Developer

1. Vai su [Google Play Console](https://play.google.com/console)
2. Clicca "Create account" o accedi
3. Paga la quota di $25 (una tantum)

### 5.2 Creare la Nuova App

1. Clicca "Create app"
2. Compila:
   - **App name**: TmelnikAPP
   - **Default language**: Italiano / Inglese
   - **App or game**: App
   - **Free or paid**: Free (o Paid)
   - Accetta i termini

### 5.3 Configurare Dettagli dell'App

Nella sezione **"Store listing"** completa:

#### Informazioni Base:
- **App name**: TmelnikAPP
- **Short description**: (max 80 caratteri)
  ```
  Join youth exchange projects across Europe. Discover opportunities, apply, and connect.
  ```
- **Full description**: (max 4000 caratteri)
  ```
  TmelnikAPP is your gateway to exciting youth exchange projects across Europe. 
  Browse available projects, apply for opportunities, and stay connected with 
  the community. Features include:
  
  • Browse and discover new projects
  • Apply to projects directly
  • View project details and infopacks
  • Get notified about new opportunities
  • Manage your applications
  
  Start your adventure today!
  ```

#### Grafica:
- **App icon**: 512x512px PNG (senza trasparenza)
- **Feature graphic**: 1024x500px PNG
- **Screenshots**: 
  - Almeno 2 screenshot per telefono (min 320px, max 3840px)
  - Consigliato: 1080x1920px o 1440x2560px
- **Phone screenshots**: 2-8 immagini
- **Tablet screenshots**: Opzionale

#### Categoria e Contatti:
- **App category**: Social / Education / Travel
- **Privacy policy URL**: (se necessario)
- **Website**: (opzionale)
- **Email support**: il tuo indirizzo email

### 5.4 Configurare Contenuto dell'App

- **Content rating**: Completa il questionario
- **Target audience**: Seleziona l'età appropriata
- **Data safety**: Completa le informazioni sulla privacy

### 5.5 Caricare l'App Bundle

1. Vai a **"Production"** → **"Create new release"**
2. Clicca **"Upload"** e carica `app-release.aab`
3. Compila le **Release notes**:
   ```
   Version 1.0.0
   - Initial release
   - Browse and discover projects
   - Apply to opportunities
   - Push notifications for new projects
   ```
4. Clicca **"Save"** → **"Review release"**

### 5.6 Revisione e Pubblicazione

1. Controlla tutti i campi obbligatori
2. Verifica che tutte le sezioni siano complete
3. Clicca **"Send for review"**
4. Attendi l'approvazione (solitamente 1-3 giorni)

---

## 🔔 Step 6: Configurare Notifiche Push (Firebase Cloud Messaging)

### 6.1 Firebase Console

1. Vai su [Firebase Console](https://console.firebase.google.com/)
2. Seleziona il progetto "tmelnikapp"
3. Vai a **Cloud Messaging**

### 6.2 Inviare Notifica di Test

1. Clicca **"Send your first message"**
2. Compila:
   - **Notification title**: "New Project Available!"
   - **Notification text**: "Check out the latest opportunities"
   - **Target**: Seleziona la tua app Android
3. Clicca **"Review"** → **"Publish"**

### 6.3 Inviare Notifiche da Codice

Le notifiche verranno inviate automaticamente quando viene aggiunto un nuovo progetto tramite il `NotificationService`.

---

## 📊 Step 7: Monitorare e Gestire

### 7.1 Dashboard Google Play Console

- **Statistics**: Visualizza download, utenti attivi, crash
- **User feedback**: Leggi recensioni e rispondi
- **Crashes & ANRs**: Monitora errori

### 7.2 Aggiornare l'App

1. Modifica `version` in `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2  # +2 incrementa versionCode
   ```
2. Build nuovo AAB:
   ```bash
   flutter build appbundle --release
   ```
3. Carica nuovo bundle in Play Console → **"Create new release"**

---

## ⚠️ Checklist Finale Prima della Pubblicazione

- [ ] App testata su dispositivi reali
- [ ] Keystore salvato in un posto sicuro (backup!)
- [ ] Package name unico e definitivo
- [ ] Icona e screenshots pronti
- [ ] Privacy policy pronta (se richiesta)
- [ ] Tutti i permessi giustificati
- [ ] App bundle (.aab) creato correttamente
- [ ] Tutte le sezioni di Play Console complete
- [ ] Testato con utenti beta (opzionale ma consigliato)

---

## 🎉 Congratulazioni!

Una volta approvata, la tua app sarà disponibile su Google Play Store per milioni di utenti!

---

## 📞 Supporto

- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)

---

**Buona pubblicazione! 🚀**

