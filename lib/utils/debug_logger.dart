import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class DebugLogger {
  static const String _logFileName = 'tmelnik_debug.log';
  static DebugLogger? _instance;
  static DebugLogger get instance => _instance ??= DebugLogger._();
  
  DebugLogger._();

  /// Clear and recreate log file on app startup
  Future<void> initializeLog() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logFile = File('${directory.path}/$_logFileName');
      
      // Delete existing log file
      if (await logFile.exists()) {
        await logFile.delete();
        await _writeLog('🔄 Log file cleared and recreated');
      } else {
        await _writeLog('🆕 New log file created');
      }
      
      await _writeLog('🚀 Tmelnik App started - ${DateTime.now()}');
      await _writeLog('📱 Platform: ${Platform.operatingSystem}');
    } catch (e) {
      print('❌ Error initializing log: $e');
    }
  }

  /// Write a log message with timestamp
  Future<void> log(String message, {String level = 'INFO'}) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      final logMessage = '[$timestamp] [$level] $message';
      
      await _writeLog(logMessage);
      print('📝 $logMessage'); // Also print to console
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

  /// Get the log file path
  Future<String?> getLogFilePath() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logFile = File('${directory.path}/$_logFileName');
      return logFile.existsSync() ? logFile.path : null;
    } catch (e) {
      print('❌ Error getting log file path: $e');
      return null;
    }
  }

  /// Read all log content
  Future<String> readLogs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logFile = File('${directory.path}/$_logFileName');
      
      if (await logFile.exists()) {
        return await logFile.readAsString();
      } else {
        return 'No log file found';
      }
    } catch (e) {
      return 'Error reading logs: $e';
    }
  }

  /// Write to log file
  Future<void> _writeLog(String message) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logFile = File('${directory.path}/$_logFileName');
      
      // Create directory if it doesn't exist
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      // Append to log file
      await logFile.writeAsString('$message\n', mode: FileMode.append);
    } catch (e) {
      print('❌ Error writing to log file: $e');
    }
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
