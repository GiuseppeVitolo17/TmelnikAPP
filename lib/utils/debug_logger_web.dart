import 'package:flutter/foundation.dart';

/// Web-compatible logger that only uses print statements
/// On web, file system access is not available, so we only log to console
class DebugLogger {
  static const String _logFileName = 'tmelnik_debug.log';
  static DebugLogger? _instance;
  static DebugLogger get instance => _instance ??= DebugLogger._();
  
  DebugLogger._();

  /// Clear and recreate log file on app startup
  Future<void> initializeLog() async {
    try {
      print('🆕 Log system initialized (Web mode - console only)');
      print('🚀 Tmelnik App started - ${DateTime.now()}');
      print('📱 Platform: Web');
    } catch (e) {
      print('❌ Error initializing log: $e');
    }
  }

  /// Write a log message with timestamp
  Future<void> log(String message, {String level = 'INFO'}) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      final logMessage = '📝 [$timestamp] [$level] $message';
      print(logMessage);
    } catch (e) {
      print('❌ Error writing log: $e');
    }
  }

  /// Write error message
  Future<void> error(String message, [dynamic error, StackTrace? stackTrace]) async {
    await log('❌ ERROR: $message', level: 'ERROR');
    if (error != null) {
      await log('🔍 Error details: $error', level: 'ERROR');
    }
    if (stackTrace != null) {
      await log('📍 Stack trace: ${stackTrace.toString().split('\n').take(5).join('\n')}', level: 'ERROR');
    }
  }

  /// Write warning message
  Future<void> warning(String message) async {
    await log('⚠️ WARNING: $message', level: 'WARN');
  }

  /// Write success message
  Future<void> success(String message) async {
    await log('✅ SUCCESS: $message', level: 'SUCCESS');
  }

  /// Write Firebase specific logs
  Future<void> firebase(String message) async {
    await log('🔥 FIREBASE: $message', level: 'FIREBASE');
  }

  /// Write authentication specific logs
  Future<void> auth(String message) async {
    await log('🔐 AUTH: $message', level: 'AUTH');
  }

  /// Write UI specific logs
  Future<void> ui(String message) async {
    await log('🎨 UI: $message', level: 'UI');
  }

  /// Write navigation specific logs
  Future<void> navigation(String message) async {
    await log('🧭 NAV: $message', level: 'NAV');
  }

  /// Get the log file path (not available on web)
  Future<String?> getLogFilePath() async {
    if (kDebugMode) {
      print('⚠️ Log file access not available on web platform');
    }
    return null;
  }

  /// Read all log content (not available on web)
  Future<String> readLogs() async {
    return 'Log file reading not available on web platform. Check browser console for logs.';
  }

  /// Log app lifecycle events
  Future<void> logAppLifecycle(String event) async {
    await log('📱 App Lifecycle: $event', level: 'LIFECYCLE');
  }

  /// Log widget build events
  Future<void> logWidgetBuild(String widgetName) async {
    await log('🏗️ Widget Built: $widgetName', level: 'WIDGET');
  }

  /// Log Firebase initialization steps
  Future<void> logFirebaseInit(String step) async {
    await firebase('Initialization: $step');
  }

  /// Log authentication steps
  Future<void> logAuthStep(String step) async {
    await auth('Step: $step');
  }
}

/// Global logger instance for easy access
final debugLogger = DebugLogger.instance;

