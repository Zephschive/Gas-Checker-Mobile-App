import 'package:flutter/material.dart';
import 'dart:async';
import 'pagesExt.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _loadingController;
  
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotateAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Text animation controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Loading animation controller
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    // Logo scale animation with bounce
    _logoScaleAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );
    
    // Logo subtle rotation
    _logoRotateAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );
    
    // Text fade in
    _textFadeAnimation = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    );
    
    // Text slide up
    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animations
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      _textController.forward();
    });
    
    // Navigate to home page after 3 seconds
    Timer(const Duration(seconds: 5), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B7B5A),
      body: Stack(
        children:[ 
           Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background.jpeg'),
              fit: BoxFit.cover,
            ),
          ),
        ),

         Container(
          color: Colors.black.withOpacity(0.7), // 0.5 = 50% dark
        ),
          
          Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated logo
              
              const SizedBox(height: 40),
              
              // Animated text
              FadeTransition(
                opacity: _textFadeAnimation,
                child: SlideTransition(
                  position: _textSlideAnimation,
                  child: Column(
                    children: [
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Gas',
                              style: TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ),
                            TextSpan(
                              text: 'Eye',
                              style: TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFDB913),
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Your Safety, Our Priority.',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 100),
              
              // Modern animated loading indicator
              SizedBox(
                width: 200,
                height: 4,
                child: AnimatedBuilder(
                  animation: _loadingController,
                  builder: (context, child) {
                    return Stack(
                      children: [
                        // Background
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF157759),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        // Animated bar
                        FractionallySizedBox(
                          widthFactor: 0.3,
                          child: Transform.translate(
                            offset: Offset(
                              (200 * 0.7) * _loadingController.value,
                              0,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFDB913),
                                    Color(0xFFFDD663),
                                    Color(0xFFFDB913),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFDB913).withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Loading text with pulse animation
              AnimatedBuilder(
                animation: _loadingController,
                builder: (context, child) {
                  return Opacity(
                    opacity: 0.5 + (_loadingController.value * 0.5),
                    child: const Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        letterSpacing: 1.5,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        ]
      ),
    );
  }
}