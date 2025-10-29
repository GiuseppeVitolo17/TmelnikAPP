import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service for displaying push notifications when new projects appear
/// Works on Android and iOS only (not web)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final Random _random = Random();
  FlutterLocalNotificationsPlugin? _localNotifications;
  bool _initialized = false;

  /// 5 fun notification messages templates
  static final List<String> _notificationTemplates = [
    '🌟 New adventure awaits! Join {project} in {city} on {date}',
    '✨ Exciting opportunity! Join {project} in {city} starting {date}',
    '🎯 Don\'t miss out! Join {project} in {city} on {date}',
    '🚀 Adventure calling! Join {project} in {city} beginning {date}',
    '🎉 Fresh project alert! Join {project} in {city} starting {date}',
  ];

  /// Initialize notification service (call this on app startup)
  Future<void> initialize() async {
    if (kIsWeb) {
      // Web doesn't support push notifications
      return;
    }

    if (_initialized) return;

    try {
      // Initialize Firebase Messaging
      final messaging = FirebaseMessaging.instance;

      // Request permission (iOS)
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        debugPrint('🔔 Notification permission status: ${settings.authorizationStatus}');
      }

      // Initialize local notifications
      _localNotifications = FlutterLocalNotificationsPlugin();

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications!.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          // Handle notification tap
          debugPrint('🔔 Notification tapped: ${details.id}');
        },
      );

      _initialized = true;
      debugPrint('✅ Notification service initialized');
    } catch (e) {
      debugPrint('❌ Error initializing notifications: $e');
    }
  }

  /// Get a random notification message
  static String _getRandomMessage(String projectName, String cityName, String departureDate) {
    final template = _notificationTemplates[_random.nextInt(_notificationTemplates.length)];
    return template
        .replaceAll('{project}', projectName)
        .replaceAll('{city}', cityName)
        .replaceAll('{date}', departureDate);
  }

  // Make this accessible from ProjectOffersScreen for SnackBar display
  static String getRandomMessage(String projectName, String cityName, String departureDate) {
    return _getRandomMessage(projectName, cityName, departureDate);
  }

  /// Show a push notification for a new project
  /// Works on Android and iOS only
  Future<void> showNewProjectNotification({
    required String projectName,
    required String cityName,
    required String departureDate,
  }) async {
    if (kIsWeb) {
      // Web: just log to console
      debugPrint('🔔 ${_getRandomMessage(projectName, cityName, departureDate)}');
      return;
    }

    // Ensure initialized
    if (!_initialized) {
      await initialize();
    }

    if (_localNotifications == null) return;

    final message = _getRandomMessage(projectName, cityName, departureDate);

    try {
      const androidDetails = AndroidNotificationDetails(
        'new_projects_channel',
        'New Projects',
        channelDescription: 'Notifications for new project opportunities',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications!.show(
        _random.nextInt(10000), // Random ID
        'New Project Available! 🎉',
        message,
        notificationDetails,
      );

      debugPrint('✅ Push notification sent: $message');
    } catch (e) {
      debugPrint('❌ Error showing notification: $e');
    }
  }

  /// Format a date for notification display
  static String formatDateForNotification(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}

