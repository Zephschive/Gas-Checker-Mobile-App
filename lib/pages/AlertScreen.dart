import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'pagesExt.dart';

class EmergencyAlert extends StatefulWidget {
  const EmergencyAlert({super.key});

  @override
  State<EmergencyAlert> createState() => _EmergencyAlertState();
}

class _EmergencyAlertState extends State<EmergencyAlert> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _playAlarmSound();
  }

  @override
  void dispose() {
    _stopAlarmSound();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAlarmSound() async {
    try {
      // Try to play alarm sound from assets
      await _audioPlayer.setReleaseMode(ReleaseMode.loop); // Loop the alarm
      await _audioPlayer.setVolume(1.0); // Full volume
      await _audioPlayer.play(AssetSource('sounds/alarm.wav'));
      setState(() {
        _isPlaying = true;
      });
      print('🚨 Alarm sound started playing');
    } catch (e) {
      print('❌ Error playing alarm sound: $e');
      // Fallback: try to play a system sound or beep if available
      _playSystemSound();
    }
  }

  Future<void> _playSystemSound() async {
    try {
      // This is a fallback for devices that might support system sounds
      // On Android, this might play a notification sound
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(0.8);
      // You might need to adjust this based on device capabilities
      print('🔊 Attempting to play system notification sound');
    } catch (e) {
      print('❌ System sound not available: $e');
    }
  }

  Future<void> _stopAlarmSound() async {
    try {
      await _audioPlayer.stop();
      setState(() {
        _isPlaying = false;
      });
      print('🔇 Alarm sound stopped');
    } catch (e) {
      print('❌ Error stopping alarm sound: $e');
    }
  }

  Future<void> _stopAlarmSoundWithoutState() async {
    try {
      await _audioPlayer.stop();
      print('🔇 Alarm sound stopped');
    } catch (e) {
      print('❌ Error stopping alarm sound: $e');
    }
  }

  void _navigateToHome() {
    // Use addPostFrameCallback to ensure navigation happens after the frame is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () async {
            await _stopAlarmSoundWithoutState();
            _navigateToHome();
          },
        ),
        title: const Text(
          'EMERGENCY',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isPlaying ? Icons.volume_up : Icons.volume_off, color: Colors.white, size: 32),
            onPressed: () async {
              if (_isPlaying) {
                await _stopAlarmSound();
              } else {
                await _playAlarmSound();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Main danger message
              const Text(
                'DANGER: Gas Leak\nDetected',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 12),

              // Warning subtitle
              Text(
                'Act Immediately! Your safety is at risk.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 30),

              // Safety instructions card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D4A43),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Safety Instructions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildInstruction(
                      icon: Icons.power_settings_new,
                      text: 'Do NOT use electronics or light switches.',
                    ),
                    const SizedBox(height: 16),

                    _buildInstruction(
                      icon: Icons.local_fire_department,
                      text: 'Extinguish all open flames immediately.',
                    ),
                    const SizedBox(height: 16),

                    _buildInstruction(
                      icon: Icons.window,
                      text: 'Open all windows and doors for ventilation.',
                    ),
                    const SizedBox(height: 16),

                    _buildInstruction(
                      icon: Icons.directions_run,
                      text: 'Evacuate the premises immediately.',
                    ),
                    const SizedBox(height: 16),

                    _buildInstruction(
                      icon: Icons.gas_meter,
                      text: 'Turn off the gas supply IF safe to do so.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Call emergency button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5F5DC),
                    foregroundColor: const Color(0xFFE53935),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.phone, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Call Emergency Services',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstruction({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: const Color(0xFFE8F447),
          size: 28,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
