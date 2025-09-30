import 'package:flutter/foundation.dart';
import 'dart:js' as js;

/// Simple service to signal when Flutter app is ready
class LoadingController {
  static final LoadingController _instance = LoadingController._internal();
  factory LoadingController() => _instance;
  LoadingController._internal();

  bool _isReady = false;
  
  /// Whether Flutter app is ready to show
  bool get isReady => _isReady;

  /// Mark the Flutter app as ready
  /// This will hide the HTML loading screen immediately
  void markAsReady() {
    if (_isReady) return; // Already marked as ready
    
    _isReady = true;
    
    if (kIsWeb) {
      // Call JavaScript function to hide loading screen
      try {
        js.context.callMethod('setFlutterReady');
      } catch (e) {
        if (kDebugMode) {
          print('Error calling setFlutterReady: $e');
        }
      }
    }
    
    if (kDebugMode) {
      print('🎯 Flutter marked as ready! Loading screen will hide immediately.');
    }
  }
}

/// Global instance for easy access
final loadingController = LoadingController();
