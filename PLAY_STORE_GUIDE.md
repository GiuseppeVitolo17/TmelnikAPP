# 📱 Complete Guide: Publish TmelnikAPP to Google Play Store

This guide walks you step-by-step to publish your Flutter app on Google Play Store.

---

## 📋 Prerequisites

1. ✅ Account Google Developer (costo una tantum: $25)
2. ✅ App Flutter funzionante
3. ✅ Firebase configurato (già fatto ✅)
4. ✅ Google-services.json già presente in `android/app/`

---

## 🔧 Step 1: Configure Android for Release

### 1.1 Update build.gradle

Verifica che `android/app/build.gradle.kts` abbia:

```kotlin
android {
    namespace = "com.example.tmelnik_app"  // Replace with your package name
    compileSdk = 34
    
    defaultConfig {
        applicationId = "com.example.tmelnik_app"  // Must be unique!
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

### 1.2 Verify google-services.json

Assicurati che `android/app/google-services.json` sia presente e corretto.

---

## 🔐 Step 2: Create Keystore to Sign the App

### 2.1 Generate the Keystore

Apri il terminale e esegui:

```bash
cd android
keytool -genkey -v -keystore tmelnik-upload-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**IMPORTANT**: 
- Store the keystore password securely
- The keystore MUST be stored safely and never committed to Git
- Without this keystore you CANNOT update the app later

### 2.2 Create key.properties

Crea il file `android/key.properties`:

```properties
storePassword=LA_TUA_PASSWORD_DEL_KEYSTORE
keyPassword=LA_TUA_PASSWORD_DELLA_CHIAVE
keyAlias=upload
storeFile=/percorso/completo/tmelnik-upload-key.jks
```

**⚠️ WARNING**: Add `key.properties` to `.gitignore` to avoid committing it!

### 2.3 Configure build.gradle signing

Modifica `android/app/build.gradle.kts`:

```kotlin
// Add at top of file
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ... other configurations
    
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

## 🎨 Step 3: Customize the App

### 3.1 App Icon

Aggiungi `flutter_launcher_icons` a `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/images/app_icon.png"
```

Then run:
```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

### 3.2 App Name and Package Name

Modifica `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.tmelnik.app">  <!-- Change to your package name -->
    
    <application
        android:label="TmelnikAPP"  <!-- App name -->
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        ...
    </application>
</manifest>
```

### 3.3 Required Permissions

Verifica che `AndroidManifest.xml` includa:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>  <!-- For notifications -->
```

---

## 📦 Step 4: Build App Bundle (AAB)

### 4.1 Build Release

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

The `.aab` file will be generated at:
`build/app/outputs/bundle/release/app-release.aab`

### 4.2 Testare l'APK Locale (Opzionale)

To test before publishing:

```bash
flutter build apk --release
```

The `.apk` will be at:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 🏪 Step 5: Publish in Google Play Console

### 5.1 Creare Account Developer

1. Vai su [Google Play Console](https://play.google.com/console)
2. Clicca "Create account" o accedi
3. Paga la quota di $25 (una tantum)

### 5.2 Create the App

1. Clicca "Create app"
2. Compila:
   - **App name**: TmelnikAPP
   - **Default language**: English (or Italian)
   - **App or game**: App
   - **Free or paid**: Free (o Paid)
   - Accetta i termini

### 5.3 Configure App Details

Nella sezione **"Store listing"** completa:

#### Basic information:
- **App name**: TmelnikAPP
- **Short description**: (max 80 characters)
  ```
  Join youth exchange projects across Europe. Discover opportunities, apply, and connect.
  ```
- **Full description**: (max 4000 characters)
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

#### Graphics:
- **App icon**: 512x512px PNG (no transparency)
- **Feature graphic**: 1024x500px PNG
- **Screenshots**: 
  - At least 2 phone screenshots (min 320px, max 3840px)
  - Recommended: 1080x1920px or 1440x2560px
- **Phone screenshots**: 2-8 images
- **Tablet screenshots**: Optional

#### Category and Contact:
- **App category**: Social / Education / Travel
- **Privacy policy URL**: (if needed)
- **Website**: (opzionale)
- **Email support**: your email address

### 5.4 Configure App Content

- **Content rating**: Complete the questionnaire
- **Target audience**: Select the appropriate age
- **Data safety**: Fill in privacy details

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

### 5.6 Review and Publish

1. Controlla tutti i campi obbligatori
2. Verifica che tutte le sezioni siano complete
3. Clicca **"Send for review"**
4. Attendi l'approvazione (solitamente 1-3 giorni)

---

## 🔔 Step 6: Configure Push Notifications (Firebase Cloud Messaging)

### 6.1 Firebase Console

1. Vai su [Firebase Console](https://console.firebase.google.com/)
2. Seleziona il progetto "tmelnikapp"
3. Vai a **Cloud Messaging**

### 6.2 Send a Test Notification

1. Clicca **"Send your first message"**
2. Compila:
   - **Notification title**: "New Project Available!"
   - **Notification text**: "Check out the latest opportunities"
   - **Target**: Select your Android app
3. Clicca **"Review"** → **"Publish"**

### 6.3 Send Notifications from Code

Notifications are sent automatically when a new project is added via `NotificationService`.

---

## 📊 Step 7: Monitor and Operate

### 7.1 Google Play Console Dashboard

- **Statistics**: View downloads, active users, crashes
- **User feedback**: Read and reply to reviews
- **Crashes & ANRs**: Monitor issues

### 7.2 Update the App

1. Modifica `version` in `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2  # +2 incrementa versionCode
   ```
2. Build new AAB:
   ```bash
   flutter build appbundle --release
   ```
3. Carica nuovo bundle in Play Console → **"Create new release"**

---

## ⚠️ Final Checklist Before Publishing

- [ ] App tested on real devices
- [ ] Keystore stored safely (backup!)
- [ ] Unique and final package name
- [ ] Icon and screenshots ready
- [ ] Privacy policy ready (if required)
- [ ] All permissions justified
- [ ] App bundle (.aab) built correctly
- [ ] All Play Console sections complete
- [ ] Tested with beta users (optional but recommended)

---

## 🎉 Congratulations!

Once approved, your app will be available on Google Play Store for millions of users!

---

## 📞 Support

- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)

---

**Happy publishing! 🚀**

