import 'dart:async';
import 'dart:math';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Background message received: ${message.messageId}");
}

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  BuildContext? _context; // Store context for navigation

  void setContext(BuildContext context) {
    _context = context;
  }

  Future<void> initNotifications() async {
    // Request notification permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print('User denied permission');
      return; // Stop initialization if permission is denied
    } else if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      print('User has not yet decided on permissions');
      // Handle this case as needed
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final fCMToken = await _firebaseMessaging.getToken();
    print('Token: $fCMToken');

    _initializeLocalNotifications();
    _setupFirebaseListeners();
    _scheduleRandomNotifications();
  }

  void _initializeLocalNotifications() {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: androidSettings);

    _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _navigateToMainPage();
      },
    );

    // Create notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'spartan_news_channel', // id
      'Spartan News Notifications', // title
      description: 'This channel is used for Spartan News notifications.',
      importance: Importance.high,
    );

    _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
  }

  void _setupFirebaseListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Message received in foreground: ${message.notification?.title}");
      _sendNotification(
        message.notification?.title ?? "Spartan News",
        message.notification?.body ?? "Check out the latest articles!",
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Message clicked! Navigating to main page.");
      _navigateToMainPage();
    });
  }

  void _scheduleRandomNotifications() {
    Timer.periodic(Duration(minutes: Random().nextInt(60) + 30), (timer) {
      _sendNotification(
        "Have you read some Spartan News today?",
        "Stay updated with the latest articles!",
      );
    });
  }

  void _sendNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'spartan_news_channel',
      'Spartan News Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      0,
      title,
      body,
      notificationDetails,
    );
  }

  void _navigateToMainPage() {
    if (_context == null) return;
    Navigator.pushNamed(_context!, "/main");
  }
}
