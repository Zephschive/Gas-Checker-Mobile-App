import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'pagesExt.dart';
import '../notification_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  double _lpgLevel = 75.0;
  bool _isConnected = false;
  bool _isConnecting = false;
  String _safetyStatus = 'All Safe';
  StreamSubscription<DatabaseEvent>? _gasLevelSubscription;
  double _previousLpgLevel = 75.0;
  String _previousSafetyStatus = 'All Safe';

  @override
  void initState() {
    super.initState();
    // Start Firebase connection automatically
    _connectToDevice();
  }

  List<Widget> get _pages => [
    HomeDashboard(
      lpgLevel: _lpgLevel,
      isConnected: _isConnected,
      isConnecting: _isConnecting,
      safetyStatus: _safetyStatus,
    ),
    const ActivityLog(),
    const SettingsAlerts(),
  ];

  @override
  void dispose() {
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
                _previousLpgLevel = _lpgLevel;
                _previousSafetyStatus = _safetyStatus;
                _lpgLevel = percentage;
                _safetyStatus = safetyStatus;
                _isConnected = true;
                _isConnecting = false; // Stop loading
              });
              print('✅ Connected successfully! Gas1: $gas1Level, Gas2: $gas2Value, LPG Level: ${percentage.toStringAsFixed(1)}%, Firebase Status: $safetyStatus');
              
              // Check for dangerous conditions when data changes
              _checkForDangerousConditions();
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

  void _checkForDangerousConditions() {
    final isDangerous = _lpgLevel >= 100.0 || _safetyStatus.toUpperCase() == 'LEAKAGE';
    final wasDangerous = _previousLpgLevel >= 100.0 || _previousSafetyStatus.toUpperCase() == 'LEAKAGE';
    
    // Only trigger if it just became dangerous (not if it was already dangerous)
    if (isDangerous && !wasDangerous && mounted) {
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

      // Navigate to AlertScreen if LPG level reaches 100% or status is LEAKAGE
      if (_lpgLevel >= 100.0 || _safetyStatus.toUpperCase() == 'LEAKAGE') {
        print('🚨 Dangerous condition detected! LPG Level: ${_lpgLevel}%, Status: $_safetyStatus. Navigating to EmergencyAlert...');
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EmergencyAlert()),
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
        bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0E1512),
          border: Border(
            top: BorderSide(
              color: const Color(0xFF1B5544).withOpacity(0.5),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home, 'Dashboard', 0),
                _buildNavItem(Icons.history, 'History', 1),
                _buildNavItem(Icons.settings, 'Settings', 2),
              ],
            ),
          ),
        ),
      )
    );
  }

   Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFFDB913) : Colors.white60,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFFFDB913) : Colors.white60,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
