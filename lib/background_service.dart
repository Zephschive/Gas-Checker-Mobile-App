import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'notification_service.dart';

/// iOS background fetch entry (15–30s max). Real-time monitoring is not
/// possible on iOS like Android; this performs a single snapshot check.
@pragma('vm:entry-point')
Future<bool> onIosBackgroundGasCheck(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final snap =
        await FirebaseDatabase.instance.ref('GasHistory').orderByKey().limitToLast(1).get();
    final val = snap.value;
    if (val is Map && val.isNotEmpty) {
      final latest = val.values.last;
      if (latest is Map) {
        final gas2 = latest['Gas2'];
        final statusField = latest['Status']?.toString() ?? 'Unknown';
        if (gas2 is num) {
          final pct = (gas2.toDouble() / 2750.0).clamp(0.0, 1.0) * 100.0;
          final dangerous =
              pct >= 100.0 || statusField.toUpperCase() == 'LEAKAGE';
          if (dangerous) {
            final prefs = await SharedPreferences.getInstance();
            if (prefs.getBool('notifications_enabled') ?? true) {
              final notifications = NotificationService();
              await notifications.initialize(requestPermissions: false);
              await notifications.showGasLeakAlert(
                title: '🚨 GAS LEAK ALERT!',
                body: 'Dangerous gas levels detected! Open app immediately.',
                id: 3,
              );
            }
          }
        }
      }
    }
  } catch (e) {
    print('onIosBackgroundGasCheck: $e');
  }
  return true;
}

class BackgroundGasMonitor {
  StreamSubscription<DatabaseEvent>? _backgroundSubscription;
  Timer? _heartbeatTimer;

  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'gas_leak_channel',
        initialNotificationTitle: 'Gas Monitor',
        initialNotificationContent: 'Active monitoring',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: _onStart,
        onBackground: onIosBackgroundGasCheck,
      ),
    );

    await service.startService();
  }

  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await NotificationService().initialize(requestPermissions: false);

    final backgroundMonitor = BackgroundGasMonitor();
    await backgroundMonitor._startMonitoring();

    // Handle service control
    service.on('stopService').listen((event) {
      service.stopSelf();
      backgroundMonitor._stopMonitoring();
    });

    // Heartbeat to keep service alive
    Timer.periodic(const Duration(minutes: 5), (timer) async {
      print('🔄 Background gas monitor heartbeat');
    });
  }

  Future<void> _startMonitoring() async {
    print('🚀 Starting background gas monitoring...');

    try {
      final databaseRef = FirebaseDatabase.instance.ref('GasHistory');

      _backgroundSubscription = databaseRef.onValue.listen((event) async {
        final data = event.snapshot.value;
        print('📡 Background: Received Firebase data');

        if (data != null && data is Map) {
          // Get the latest entry
          final entries = data.entries.toList();
          if (entries.isNotEmpty) {
            entries.sort((a, b) => a.key.compareTo(b.key));
            final latestEntry = entries.last.value;

            if (latestEntry is Map) {
              final gas2Level = latestEntry['Gas2'];
              final statusField = latestEntry['Status'];

              if (gas2Level is num) {
                final gas2Value = gas2Level.toDouble();
                final percentage = (gas2Value / 2750.0).clamp(0.0, 1.0) * 100.0;
                final safetyStatus = statusField?.toString() ?? 'Unknown';

                print('📊 Background: Gas2: $gas2Value, Percentage: ${percentage.toStringAsFixed(1)}%, Status: $safetyStatus');

                // Check for dangerous conditions
                final isDangerous = percentage >= 100.0 || safetyStatus.toUpperCase() == 'LEAKAGE';

                if (isDangerous) {
                  await _triggerBackgroundAlert(percentage, safetyStatus);
                }
              }
            }
          }
        }
      }, onError: (error) {
        print('❌ Background monitoring error: $error');
      });

      print('✅ Background gas monitoring started successfully');
    } catch (e) {
      print('❌ Failed to start background monitoring: $e');
    }
  }

  Future<void> _triggerBackgroundAlert(double percentage, String status) async {
    print('🚨 Background alert triggered! Percentage: $percentage, Status: $status');

    // Check notification settings
    final prefs = await SharedPreferences.getInstance();
    final pushNotificationsEnabled = prefs.getBool('notifications_enabled') ?? true;

    if (pushNotificationsEnabled) {
      try {
        final notificationService = NotificationService();
        await notificationService.showGasLeakAlert(
          title: '🚨 BACKGROUND GAS ALERT!',
          body: 'Dangerous gas levels detected! Open app immediately.',
          id: 2, // Different ID for background alerts
        );
        print('✅ Background notification sent');
      } catch (e) {
        print('❌ Failed to send background notification: $e');
      }
    } else {
      print('⚠️ Background notifications disabled in settings');
    }
  }

  void _stopMonitoring() {
    print('🛑 Stopping background gas monitoring...');
    _backgroundSubscription?.cancel();
    _heartbeatTimer?.cancel();
  }

  static Future<void> stopService() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }

  static Future<bool> isServiceRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }
}
