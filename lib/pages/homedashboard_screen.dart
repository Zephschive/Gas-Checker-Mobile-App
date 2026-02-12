import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:provider/provider.dart';
import '../theme_provider.dart';

class HomeDashboard extends StatefulWidget {
  final double lpgLevel;
  final bool isConnected;
  final bool isConnecting;
  final String safetyStatus;

  const HomeDashboard({
    super.key,
    required this.lpgLevel,
    required this.isConnected,
    required this.isConnecting,
    required this.safetyStatus,
  });

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _updateAnimation();

    // Start the animation after a short delay when the widget is inserted into the tree
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _animController.forward();
    });
  }

  @override
  void didUpdateWidget(HomeDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lpgLevel != widget.lpgLevel) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    _progressAnimation = Tween<double>(begin: 0.0, end: widget.lpgLevel / 100)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.secondaryCardColor,
      appBar: AppBar(
        backgroundColor: themeProvider.secondaryCardColor,
        automaticallyImplyLeading: false,
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
                      widget.isConnected ? 'Connected' : 'Disconnected',
                      style: TextStyle(
                        color: themeProvider.textSecondaryColor,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!widget.isConnected)
                      ElevatedButton(
                        onPressed: widget.isConnecting ? null : () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeProvider.buttonBackgroundColor,
                          foregroundColor: themeProvider.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: widget.isConnecting
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF1A1A1A)),
                                ),
                              )
                            : const Text(
                                'Connecting...',
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
                      widget.safetyStatus,
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
