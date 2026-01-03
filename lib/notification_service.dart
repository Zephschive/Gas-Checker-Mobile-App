import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Android initialization settings
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings (if needed)
    const DarwinInitializationSettings iosInitializationSettings =
        DarwinInitializationSettings();

    // Combined initialization settings
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    // Initialize the plugin
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // Request Android permissions
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Request iOS permissions if needed
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> showGasLeakAlert({
    required String title,
    required String body,
    int id = 0,
  }) async {
    // Check if notifications are enabled
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;

    if (!notificationsEnabled) return;

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'gas_leak_channel',
      'Gas Leak Alerts',
      channelDescription: 'Alerts for gas leak detection',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    // Handle notification tap - could navigate to specific screen
    print('Notification tapped: ${notificationResponse.payload}');
  }

  Future<void> showInAppAlert(BuildContext context, {
    required String title,
    required String message,
  }) async {
    // Check if in-app notifications are enabled
    final prefs = await SharedPreferences.getInstance();
    final inAppNotificationsEnabled = prefs.getBool('in_app_notifications_enabled') ?? true;

    if (!inAppNotificationsEnabled || !context.mounted) return;

    // Show in-app notification (snackbar)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red.shade800,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'VIEW',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to alert screen or dashboard
            Navigator.of(context).pushNamed('/alert');
          },
        ),
      ),
    );
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }
}
