import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Background message handler must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
  }
}

class MessagingService {
  static final MessagingService _instance = MessagingService._internal();

  factory MessagingService() {
    return _instance;
  }

  MessagingService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'high_importance_channel';
  static const String _channelName = 'High Importance Notifications';
  static const String _channelDescription =
      'This channel is used for important notifications.';

  Future<void> initialize() async {
    // 1. Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) print('User granted permission');
      
      // 2. Initialize Local Notifications (for foreground display)
      await _initializeLocalNotifications();

      // 3. Setup message listeners
      _setupMessageListeners();

      // 4. Background Handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // 5. Subscribe to Topic (when logged in)
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        if (user != null) {
          _subscribeToTopic();
        }
      });
      // Try initializing subscription if already logged in
      if (FirebaseAuth.instance.currentUser != null) {
          await _subscribeToTopic();
      }

      // 6. Token logic
      if (kDebugMode) {
        String? token = await _firebaseMessaging.getToken();
        print("FCM Token: $token");
      }
      
      // Handle token setup/refresh if needed (e.g., sending to backend)
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        if (kDebugMode) print("FCM Token Refreshed: $newToken");
        // TODO: specific backend update logic if user had one
      });

    } else {
      if (kDebugMode) print('User declined or has not accepted permission');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    // Android Setup
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS Setup
    // identifying if we want to rely on presentation options or local notifications
    // User requested flutter_local_notifications for iOS display explicitly.
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false, // Already requested by FCM
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification tap logic here if needed
        if (kDebugMode) print("Notification Tapped: ${details.payload}");
      },
    );

    // Create Android Channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
        
    // Allow iOS to show foreground notifications natively as well (backup/alternative)
    // This allows heads-up notifications on iOS even without local notifications plugin explicitly triggering it
    // IF the message comes as a notification message.
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true, 
      badge: true,
      sound: true,
    );
  }

  void _setupMessageListeners() {
    // Foreground Message Handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
      }

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // If notification is present, show it locally
      if (notification != null && android != null) {
        _flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDescription,
              icon: '@mipmap/ic_launcher',
              // other properties...
            ),
             // iOS details can be simple or omitted if reliance is on presentation options,
             // but if we want to FORCE a local notification:
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true, 
              presentSound: true,
            ),
          ),
        );
      }
    });

    // Handle when app is opened from a terminated state
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        if (kDebugMode) print('App opened from terminated state by notification');
        // Handle navigation if payload exists, adhering to "Open the app when tapped"
      }
    });

    // Handle when app is opened from background state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) print('App opened from background state by notification');
       // Handle navigation
    });
  }

  Future<void> _subscribeToTopic() async {
    const String topicKey = 'subscribed_to_all_users';
    final prefs = await SharedPreferences.getInstance();
    bool isSubscribed = prefs.getBool(topicKey) ?? false;

    if (!isSubscribed) {
      try {
        await _firebaseMessaging.subscribeToTopic('all_users');
        await prefs.setBool(topicKey, true);
        if (kDebugMode) print("Subscribed to all_users topic");
      } catch (e) {
        if (kDebugMode) print("Failed to subscribe to topic: $e");
      }
    }
  }
}
