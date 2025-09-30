/// Configuration for the loading screen duration and behavior
class LoadingConfig {
  /// Minimum duration the loading screen should be visible (in milliseconds)
  /// This ensures users see the loading screen for a reasonable time
  static const int minimumDuration = 3000; // 3 seconds
  
  /// Maximum duration before forcing the loading screen to hide (in milliseconds)
  /// This is a fallback in case Flutter takes too long to initialize
  static const int maximumDuration = 8000; // 8 seconds
  
  /// Duration of the fade-out animation (in milliseconds)
  static const int fadeOutDuration = 800; // 0.8 seconds
  
  /// Whether to show debug information in console
  static const bool debugMode = true;
  
  /// Get the configuration as a JavaScript object string
  static String getJavaScriptConfig() {
    return '''
    window.loadingScreenConfig = {
      minimumDuration: $minimumDuration,
      maximumDuration: $maximumDuration,
      fadeOutDuration: $fadeOutDuration,
      debugMode: $debugMode
    };
    ''';
  }
  
  /// Log configuration values
  static void logConfig() {
    if (debugMode) {
      print('🔧 Loading Screen Configuration:');
      print('   • Minimum Duration: ${minimumDuration}ms (${minimumDuration/1000}s)');
      print('   • Maximum Duration: ${maximumDuration}ms (${maximumDuration/1000}s)');
      print('   • Fade Out Duration: ${fadeOutDuration}ms (${fadeOutDuration/1000}s)');
      print('   • Debug Mode: $debugMode');
    }
  }
}
