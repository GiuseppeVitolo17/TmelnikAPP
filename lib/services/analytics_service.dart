import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Service for Firebase Analytics tracking
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  FirebaseAnalytics? _analytics;
  bool _initialized = false;

  /// Initialize Analytics (can be called multiple times safely)
  Future<void> initialize() async {
    if (_initialized && _analytics != null) return;
    
    try {
      _analytics = FirebaseAnalytics.instance;
      _initialized = true;
      
      if (kDebugMode) {
        debugPrint('✅ [ANALYTICS] Initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [ANALYTICS] Initialization error: $e');
      }
    }
  }

  /// Get Firebase Analytics instance
  FirebaseAnalytics? get analytics => _analytics;

  /// Log a screen view
  Future<void> logScreenView(String screenName) async {
    if (!_initialized || _analytics == null) return;
    
    try {
      await _analytics!.logScreenView(screenName: screenName);
      if (kDebugMode) {
        debugPrint('📊 [ANALYTICS] Screen view: $screenName');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [ANALYTICS] Error logging screen view: $e');
      }
    }
  }

  /// Log a custom event
  Future<void> logEvent(String eventName, {Map<String, dynamic>? parameters}) async {
    if (!_initialized || _analytics == null) return;
    
    try {
      // Convert Map<String, dynamic>? to Map<String, Object>?
      Map<String, Object>? convertedParams;
      if (parameters != null) {
        convertedParams = parameters.map((key, value) => MapEntry(key, value as Object));
      }
      
      await _analytics!.logEvent(
        name: eventName,
        parameters: convertedParams,
      );
      if (kDebugMode) {
        debugPrint('📊 [ANALYTICS] Event: $eventName ${parameters != null ? "($parameters)" : ""}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [ANALYTICS] Error logging event: $e');
      }
    }
  }

  /// Log user login
  Future<void> logLogin({String? loginMethod}) async {
    await logEvent('login', parameters: {
      if (loginMethod != null) 'method': loginMethod,
    });
  }

  /// Log user signup
  Future<void> logSignUp({String? signUpMethod}) async {
    await logEvent('sign_up', parameters: {
      if (signUpMethod != null) 'method': signUpMethod,
    });
  }

  /// Log project view
  Future<void> logProjectView(String projectId, String projectTitle) async {
    await logEvent('view_project', parameters: {
      'project_id': projectId,
      'project_title': projectTitle,
    });
  }

  /// Log project application
  Future<void> logProjectApplication(String projectId, String projectTitle, String ngoId) async {
    await logEvent('apply_to_project', parameters: {
      'project_id': projectId,
      'project_title': projectTitle,
      'ngo_id': ngoId,
    });
  }

  /// Log application status update
  Future<void> logApplicationStatusUpdate(String applicationId, String oldStatus, String newStatus) async {
    await logEvent('application_status_update', parameters: {
      'application_id': applicationId,
      'old_status': oldStatus,
      'new_status': newStatus,
    });
  }

  /// Log search
  Future<void> logSearch(String searchTerm) async {
    await logEvent('search', parameters: {
      'search_term': searchTerm,
    });
  }

  /// Log share
  Future<void> logShare(String contentType, String itemId) async {
    await logEvent('share', parameters: {
      'content_type': contentType,
      'item_id': itemId,
    });
  }

  /// Set user property
  Future<void> setUserProperty(String name, String? value) async {
    if (!_initialized || _analytics == null) return;
    
    try {
      await _analytics!.setUserProperty(name: name, value: value);
      if (kDebugMode) {
        debugPrint('📊 [ANALYTICS] User property set: $name = $value');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [ANALYTICS] Error setting user property: $e');
      }
    }
  }

  /// Set user ID
  Future<void> setUserId(String? userId) async {
    if (!_initialized || _analytics == null) return;
    
    try {
      await _analytics!.setUserId(id: userId);
      if (kDebugMode) {
        debugPrint('📊 [ANALYTICS] User ID set: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [ANALYTICS] Error setting user ID: $e');
      }
    }
  }
}

