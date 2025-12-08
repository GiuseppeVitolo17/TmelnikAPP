import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_firestore_service.dart';
import '../models/project_offer.dart';

/// Service for displaying push notifications when new projects appear
/// Works on Android and iOS only (not web)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final Random _random = Random();
  FlutterLocalNotificationsPlugin? _localNotifications;
  bool _initialized = false;
  // Global toggle: disable local pop-up notifications by default
  static bool notificationsEnabled = false;
  final FirebaseFirestoreService _firestoreService = FirebaseFirestoreService();

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

    // Load notification preference from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    } catch (e) {
      // Default to enabled if error loading
      notificationsEnabled = true;
    }

    if (!notificationsEnabled || _initialized) {
      return;
    }

    if (_initialized) return;

    try {
      // Initialize Firebase Messaging
      final messaging = FirebaseMessaging.instance;
      await messaging.setAutoInitEnabled(true);

      // Request permission (iOS and Android 13+)
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        debugPrint('🔔 Notification permission status: ${settings.authorizationStatus}');
      } else {
        try {
          final androidImpl = _localNotifications
              ?.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
          await androidImpl?.requestNotificationsPermission();
        } catch (_) {}
      }

      // Initialize local notifications
      _localNotifications = FlutterLocalNotificationsPlugin();

      // Android initialization settings (use round launcher icon for softer edges)
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher_round');
      
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

      // FCM: obtain token (for direct sends) and subscribe to topic
      try {
        final token = await messaging.getToken();
        debugPrint('🔔 FCM token: $token');
        await messaging.subscribeToTopic('projects');
        debugPrint('✅ Subscribed to FCM topic: projects');
      } catch (e) {
        debugPrint('❌ Error getting token or subscribing to topic: $e');
      }

      // Foreground message listener (no intrusive popups)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        debugPrint('📩 FCM message (foreground): ${message.messageId} | ${message.notification?.title}');
        // Show a local notification in foreground so the user sees it
        try {
          await _localNotifications?.show(
            _random.nextInt(10000),
            message.notification?.title ?? 'New Project Available! 🎉',
            message.notification?.body ?? 'Open the app to view details',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'new_projects_channel',
                'New Projects',
                channelDescription: 'Notifications for new project opportunities',
                importance: Importance.high,
                priority: Priority.high,
                showWhen: true,
                icon: '@mipmap/ic_launcher_round',
              ),
              iOS: DarwinNotificationDetails(),
            ),
          );
        } catch (_) {}
      });

      // App opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('📬 Opened from notification: ${message.messageId}');
      });

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
    if (kIsWeb || !notificationsEnabled) {
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
        icon: '@mipmap/ic_launcher_round',
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

  /// Handle remote FCM message: fetch project and show local notification
  Future<void> handleRemoteMessage(RemoteMessage message, {bool fromBackground = false}) async {
    try {
      final data = message.data;
      if (data['type'] != 'project_created') return;
      final projectId = data['projectId'];
      if (projectId == null || projectId.isEmpty) return;

      final offer = await _firestoreService.getProjectOfferById(projectId);
      if (offer == null) return;

      final departureDate = offer.departureDate != null
          ? NotificationService.formatDateForNotification(offer.departureDate!)
          : 'TBD';
      final messageText = _getRandomMessage(
        offer.title,
        offer.location.isNotEmpty ? offer.location : 'Unknown',
        departureDate,
      );

      // Only show local notification for background/terminated
      if (fromBackground && notificationsEnabled) {
        await showNewProjectNotification(
          projectName: offer.title,
          cityName: offer.location,
          departureDate: departureDate,
        );
      } else {
        debugPrint('📩 FCM (foreground): $messageText');
      }
    } catch (e) {
      debugPrint('❌ Error handling remote message: $e');
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

