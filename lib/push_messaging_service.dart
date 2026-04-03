import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'firebase_options.dart';
import 'notification_service.dart';

/// FCM background isolate (data messages, or extra handling). Notification
/// payloads are usually shown by the OS when the app is backgrounded.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().initialize(requestPermissions: false);

  final remote = message.notification;
  final title = remote?.title ??
      message.data['title'] ??
      '🚨 GAS LEAK ALERT!';
  final body = remote?.body ??
      message.data['body'] ??
      'Dangerous gas levels detected! Open app immediately.';

  await NotificationService().showGasLeakAlert(
    title: title,
    body: body,
    id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
  );
}

/// Subscribes devices to [gasLeakAlertsTopic] so Cloud Functions (or any sender)
/// can broadcast gas alerts while the app is backgrounded or not running.
class PushMessagingService {
  PushMessagingService._();
  static final PushMessagingService instance = PushMessagingService._();

  static const String gasLeakAlertsTopic = 'gas_leak_alerts';

  Future<void> setup() async {
    if (kIsWeb) return;

    final messaging = FirebaseMessaging.instance;

    if (Platform.isIOS || Platform.isMacOS) {
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      await messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: true,
      );
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final remote = message.notification;
      final title = remote?.title ??
          message.data['title'] ??
          '🚨 GAS LEAK ALERT!';
      final body = remote?.body ??
          message.data['body'] ??
          'Dangerous gas levels detected! Open app immediately.';
      await NotificationService().showGasLeakAlert(
        title: title,
        body: body,
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      );
    });

    try {
      await messaging.subscribeToTopic(gasLeakAlertsTopic);
    } catch (e, st) {
      debugPrint('PushMessagingService: subscribeToTopic failed: $e\n$st');
    }
  }
}
