import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance =
      NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const _kLastGasAlertSoundMs = 'last_gas_alert_sound_ms';
  static const _gasAlertSoundCooldownMs = 120000;

  /// Call when gas is back below emergency (not 100%+ and not LEAKAGE) so the
  /// next alert is allowed to play notification sound again.
  Future<void> resetGasAlertSoundCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLastGasAlertSoundMs);
  }

  /// INITIALIZE NOTIFICATIONS
  ///
  /// Set [requestPermissions] to false in headless/background isolates where
  /// dialogs are not allowed and permissions were already granted in [main].
  Future<void> initialize({bool requestPermissions = true}) async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (requestPermissions) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      if (Platform.isIOS || Platform.isMacOS) {
        await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }
    }

    if (Platform.isAndroid) {
      await ensureAndroidNotificationChannels();
    }
  }

  /// Creates channels before FCM / foreground service use them.
  Future<void> ensureAndroidNotificationChannels() async {
    if (!Platform.isAndroid) return;

    final android = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    await android.createNotificationChannel(const AndroidNotificationChannel(
      'gas_alerts',
      'Gas Leak Alerts',
      description: 'Gas leak emergency alerts',
      importance: Importance.max,
    ));

    await android.createNotificationChannel(const AndroidNotificationChannel(
      'gas_leak_channel',
      'Gas monitor service',
      description: 'Keeps live monitoring active in the background',
      importance: Importance.low,
    ));
  }

  /// Shows a gas alert. Notification always posts; if [playSound] is true, sound
  /// only plays again after [_gasAlertSoundCooldownMs] unless
  /// [resetGasAlertSoundCooldown] ran (readings back to safe).
  Future<void> showGasLeakAlert({
    required String title,
    required String body,
    int id = 0,
    bool playSound = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notifications_enabled') ?? true;
    if (!enabled) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    var effectiveSound = playSound;
    if (playSound) {
      final lastSound = prefs.getInt(_kLastGasAlertSoundMs) ?? 0;
      if (now - lastSound < _gasAlertSoundCooldownMs) {
        effectiveSound = false;
      } else {
        await prefs.setInt(_kLastGasAlertSoundMs, now);
      }
    }

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'gas_alerts',
      'Gas Leak Alerts',
      channelDescription: 'Gas leak emergency alerts',
      importance: Importance.max,
      priority: Priority.high,
      playSound: effectiveSound,
      enableVibration: effectiveSound,
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: effectiveSound,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      details,
    );
  }

  /// HANDLE NOTIFICATION TAP
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped');
  }

  /// IN-APP SNACKBAR
  Future<void> showInAppAlert(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    if (!context.mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final enabled =
        prefs.getBool('in_app_notifications_enabled') ?? true;
    if (!enabled) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade800,
        duration: const Duration(seconds: 5),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> cancel(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}
