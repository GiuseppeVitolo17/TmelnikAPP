import 'package:flutter/foundation.dart';

/// Simple service to signal when Flutter app is ready (stub for non-web platforms)
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
    
    // On non-web platforms, this is a no-op
    if (kDebugMode) {
      print('🎯 Flutter marked as ready (non-web platform).');
    }
  }
}

/// Global instance for easy access
final loadingController = LoadingController();












