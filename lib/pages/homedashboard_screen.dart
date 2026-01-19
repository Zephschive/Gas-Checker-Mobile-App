import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import 'AlertScreen.dart';
import '../notification_service.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  double _lpgLevel = 75.0;
  bool _isConnected = false;
  bool _isConnecting = false;
  String _safetyStatus = 'All Safe';

  late AnimationController _animController;
  late Animation<double> _progressAnimation;
  StreamSubscription<DatabaseEvent>? _gasLevelSubscription;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: _lpgLevel / 100)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    // Start the animation after a short delay when the widget is inserted into the tree
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _gasLevelSubscription?.cancel();
    super.dispose();
  }

  void _connectToDevice() {
    if (_gasLevelSubscription != null || _isConnecting) return; // Already connecting or connected

    print('🔌 Starting connection to device...');
    setState(() {
      _isConnecting = true;
    });

    final databaseRef = FirebaseDatabase.instance.ref('GasHistory');

    _gasLevelSubscription = databaseRef.onValue.listen((event) {
      final data = event.snapshot.value;
      print('📡 Received data from Firebase: $data');

      if (data != null && data is Map) {
        // Get the latest entry (assuming the last key is the most recent)
        final entries = data.entries.toList();
        print('📊 Found ${entries.length} entries in GasHistory');

        if (entries.isNotEmpty) {
          // Sort by key (Firebase keys are chronological) and take the last one
          entries.sort((a, b) => a.key.compareTo(b.key));
          final latestKey = entries.last.key;
          final latestEntry = entries.last.value;

          print('🆕 Latest entry key: $latestKey');
          print('📋 Latest entry data: $latestEntry');

          if (latestEntry is Map) {
            final gas1Level = latestEntry['Gas1'];
            final gas2Level = latestEntry['Gas2'];
            final statusField = latestEntry['Status']; // Read Status field directly from Firebase
            print('⛽ Gas1 level: $gas1Level, Gas2 level: $gas2Level, Status: $statusField');

            if (gas2Level is num) {
              // Calculate percentage based on gas2 value (2750 = 100%, 0 = 0%)
              final gas2Value = gas2Level.toDouble();
              final rawPercentage = gas2Value / 2750.0;
              final clampedPercentage = rawPercentage.clamp(0.0, 1.0);
              final percentage = clampedPercentage * 100.0;

              print('📊 Percentage calculation: Gas2($gas2Value) / 2750 = ${rawPercentage.toStringAsFixed(3)} → ${percentage.toStringAsFixed(2)}%');

              // Use Status field directly from Firebase instead of calculating
              final safetyStatus = statusField?.toString() ?? 'Unknown';

              setState(() {
                _lpgLevel = percentage;
                _safetyStatus = safetyStatus;
                _isConnected = true;
                _isConnecting = false; // Stop loading
                // Update the animation with new level (already in percentage)
                _progressAnimation = Tween<double>(begin: 0.0, end: _lpgLevel / 100)
                    .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
              });
              print('✅ Connected successfully! Gas1: $gas1Level, Gas2: $gas2Value, LPG Level: ${percentage.toStringAsFixed(1)}%, Firebase Status: $safetyStatus');

              // Check for dangerous conditions and show notifications
              final isDangerous = percentage >= 100.0 || safetyStatus.toUpperCase() == 'LEAKAGE';

              if (isDangerous && mounted) {
                // Show in-app notification
                NotificationService().showInAppAlert(
                  context,
                  title: 'GAS LEAK DETECTED!',
                  message: 'Dangerous gas levels detected. Take immediate action!',
                );

                // Show system notification
                NotificationService().showGasLeakAlert(
                  title: '🚨 GAS LEAK ALERT!',
                  body: 'Dangerous gas levels detected! Open app immediately.',
                  id: 1,
                );

                // Navigate to AlertScreen if LPG level reaches 100%
                if (percentage >= 100.0) {
                  print('🚨 LPG Level reached 100%! Navigating to EmergencyAlert...');
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EmergencyAlert()),
                  );
                }
              }

              // Restart animation if it's completed
              if (_animController.isCompleted) {
                _animController.reset();
                _animController.forward();
              }
            } else {
              print('⚠️ Gas2 field is not a number: $gas2Level');
              // If data exists but no valid Gas2 field, still consider connected
              setState(() {
                _isConnected = true;
                _isConnecting = false;
              });
            }
          } else {
            print('⚠️ Latest entry is not a map: $latestEntry');
            // If latest entry is not a map, still consider connected
            setState(() {
              _isConnected = true;
              _isConnecting = false;
            });
          }
        } else {
          print('⚠️ No entries found in GasHistory');
        }
      } else {
        print('⚠️ No data received or data is not a map');
        // If no data, wait a bit more
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && _isConnecting) {
            print('⏰ Timeout: No data received after 3 seconds');
            setState(() {
              _isConnecting = false;
            });
            // Optionally cancel subscription if no data after timeout
            _gasLevelSubscription?.cancel();
            _gasLevelSubscription = null;
          }
        });
      }
    }, onError: (error) {
      print('❌ Firebase error: $error');
      // Handle errors
      setState(() {
        _isConnecting = false;
      });
      _gasLevelSubscription?.cancel();
      _gasLevelSubscription = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.secondaryCardColor,
      appBar: AppBar(
        backgroundColor: themeProvider.secondaryCardColor,
        elevation: 0,
        title: Text(
          'Home Status',
          style: TextStyle(
            color: themeProvider.textPrimaryColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            
            // LPG Level Circular Progress with filled center (animated)
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Filled circle background
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      color: themeProvider.progressBackgroundColor,
                      shape: BoxShape.circle,
                    ),
                  ),

                  // Animated progress ring + center text
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      final pct = (_progressAnimation.value * 100).toInt();
                      return SizedBox(
                        width: 240,
                        height: 240,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(240, 240),
                              painter: CircularProgressPainter(
                                progress: _progressAnimation.value,
                                progressColor: themeProvider.progressBarColor,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Concentration Level',
                                  style: TextStyle(
                                    color: themeProvider.isDarkMode ? Colors.white.withOpacity(0.5) : themeProvider.textSecondaryColor,
                                    fontSize: 16,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${pct}%',
                                  style: TextStyle(
                                    color: themeProvider.accentColor,
                                    fontSize: 56,
                                    fontWeight: FontWeight.bold,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),


            
            const SizedBox(height: 40),
            
            // Device Status Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: themeProvider.cardBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.wifi,
                      color: themeProvider.accentColor,
                      size: 36,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Device Status',
                      style: TextStyle(
                        color: themeProvider.textPrimaryColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isConnected ? 'Connected' : 'Disconnected',
                      style: TextStyle(
                        color: themeProvider.textSecondaryColor,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!_isConnected)
                      ElevatedButton(
                        onPressed: _isConnecting ? null : _connectToDevice,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeProvider.buttonBackgroundColor,
                          foregroundColor: themeProvider.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isConnecting
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF1A1A1A)),
                                ),
                              )
                            : const Text(
                                'Connect to Device',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Safety Status Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: themeProvider.cardBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.shield,
                      color: themeProvider.accentColor,
                      size: 36,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Safety Status',
                      style: TextStyle(
                        color: themeProvider.textPrimaryColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _safetyStatus,
                      style: TextStyle(
                        color: themeProvider.textSecondaryColor,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            
            
            const SizedBox(height: 40),
          ],
        ),
      ),
      
      // Bottom Navigation Bar
      
    );
  }


}

// Custom Painter for Circular Progress - only draws the progress ring
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;

  CircularProgressPainter({
    required this.progress,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 22.0;

    // Progress arc only
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );

    // Progress indicator dot
    if (progress > 0) {
      final angle = startAngle + sweepAngle;
      final dotX = center.dx + (radius - strokeWidth / 2) * math.cos(angle);
      final dotY = center.dy + (radius - strokeWidth / 2) * math.sin(angle);

      final dotPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(dotX, dotY), 11, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
