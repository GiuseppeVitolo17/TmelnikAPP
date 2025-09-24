class FirebaseConfig {
  // Environment variables for Firebase configuration
  // These should be set via build-time environment variables
  
  static const String apiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: '',
  );
  
  static const String projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: '',
  );
  
  static const String messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '',
  );
  
  static const String authDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
    defaultValue: '',
  );
  
  static const String storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: '',
  );
  
  // App IDs for different platforms
  static const String webAppId = String.fromEnvironment(
    'FIREBASE_WEB_APP_ID',
    defaultValue: '',
  );
  
  static const String androidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
    defaultValue: '',
  );
  
  static const String iosAppId = String.fromEnvironment(
    'FIREBASE_IOS_APP_ID',
    defaultValue: '',
  );
  
  static const String macosAppId = String.fromEnvironment(
    'FIREBASE_MACOS_APP_ID',
    defaultValue: '',
  );
  
  // Validation method
  static bool get isConfigured => 
      apiKey.isNotEmpty && 
      projectId.isNotEmpty && 
      messagingSenderId.isNotEmpty;
}
