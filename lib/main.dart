import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'background_service.dart';
import 'firebase_options.dart';
import 'notification_service.dart';
import 'pages/pagesExt.dart';
import 'push_messaging_service.dart';
import 'theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // ✅ Correct Firebase init for each platform
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Notifications allowed on iOS + Android channels for FCM / foreground service
  await NotificationService().initialize();

  // FCM topic `gas_leak_alerts` — deploy `functions/` so alerts reach iOS / killed Android
  await PushMessagingService.instance.setup();

  // Android: foreground service + RTDB listener. iOS: periodic fetch + rely on FCM for alerts.
  await BackgroundGasMonitor.initialize();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (_, themeProvider, __) {
        return MaterialApp(
          title: 'Gas Eye App',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.currentTheme,
          home: const SplashScreen(),
      
        );
      },
    );
  }
}