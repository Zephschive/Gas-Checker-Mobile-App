import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../notification_service.dart';

class EmergencyAlert extends StatefulWidget {
  const EmergencyAlert({super.key});

  /// True while an [EmergencyAlert] route is on the stack (prevents duplicate pushes).
  static bool isRouteActive = false;

  @override
  State<EmergencyAlert> createState() => _EmergencyAlertState();
}

class _EmergencyAlertState extends State<EmergencyAlert> {
  late final AudioPlayer _audioPlayer;
  StreamSubscription<DatabaseEvent>? _gasSub;

  bool _isPlaying = false;
  bool _playerReleased = false;
  /// Latest snapshot says concentration / status are no longer in emergency range.
  bool _readingsSafe = false;
  /// User turned alarm off manually — do not auto-restart if danger returns.
  bool _userSilencedAlarm = false;

  @override
  void initState() {
    super.initState();
    EmergencyAlert.isRouteActive = true;
    _audioPlayer = AudioPlayer();
    _playAlarmSound();
    _subscribeGasHistory();
  }

  void _subscribeGasHistory() {
    _gasSub = FirebaseDatabase.instance.ref('GasHistory').onValue.listen(
      (event) {
        final data = event.snapshot.value;
        if (data == null || data is! Map) return;

        final entries = data.entries.toList();
        if (entries.isEmpty) return;
        entries.sort((a, b) => a.key.compareTo(b.key));
        final latest = entries.last.value;
        if (latest is! Map) return;

        final gas2 = latest['Gas2'];
        final statusField = latest['Status']?.toString() ?? 'Unknown';
        if (gas2 is! num) return;

        final pct = (gas2.toDouble() / 2750.0).clamp(0.0, 1.0) * 100.0;
        final dangerous =
            pct >= 100.0 || statusField.toUpperCase() == 'LEAKAGE';

        if (!mounted) return;

        if (!dangerous) {
          _onReadingsNoLongerDangerous(pct, statusField);
        } else {
          _onReadingsDangerousAgain();
        }
      },
      onError: (_) {},
    );
  }

  void _onReadingsNoLongerDangerous(double pct, String statusField) {
    final u = statusField.toUpperCase();
    if (pct < 100.0 && u != 'LEAKAGE') {
      unawaited(NotificationService().resetGasAlertSoundCooldown());
    }
    if (_readingsSafe) return;
    unawaited(_stopPlaybackOnly());
    if (!mounted) return;
    setState(() {
      _readingsSafe = true;
      _isPlaying = false;
    });
  }

  void _onReadingsDangerousAgain() {
    if (_userSilencedAlarm || _playerReleased || !mounted) return;
    if (!_readingsSafe) return;
    setState(() => _readingsSafe = false);
    _playAlarmSound();
  }

  Future<void> _releasePlayer() async {
    if (_playerReleased) return;
    _playerReleased = true;
    try {
      await _audioPlayer.stop();
    } catch (_) {}
    try {
      await _audioPlayer.dispose();
    } catch (_) {}
  }

  @override
  void dispose() {
    EmergencyAlert.isRouteActive = false;
    _gasSub?.cancel();
    unawaited(_releasePlayer());
    super.dispose();
  }

  Future<void> _playAlarmSound() async {
    if (_playerReleased || !mounted || _readingsSafe) return;
    try {
      if (Platform.isIOS || Platform.isMacOS) {
        await _audioPlayer.setAudioContext(
          AudioContext(
            iOS: AudioContextIOS(
              category: AVAudioSessionCategory.playback,
              options: const {AVAudioSessionOptions.mixWithOthers},
            ),
          ),
        );
      } else if (Platform.isAndroid) {
        await _audioPlayer.setAudioContext(
          AudioContext(
            android: const AudioContextAndroid(
              isSpeakerphoneOn: true,
              stayAwake: true,
              contentType: AndroidContentType.sonification,
              usageType: AndroidUsageType.alarm,
              audioFocus: AndroidAudioFocus.gainTransientMayDuck,
            ),
          ),
        );
      }
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource('sounds/alarm.wav'));
      if (mounted) {
        setState(() => _isPlaying = true);
      }
    } catch (e) {
      debugPrint('Alarm sound error: $e');
    }
  }

  Future<void> _stopPlaybackOnly() async {
    if (_playerReleased || !mounted) return;
    try {
      await _audioPlayer.stop();
    } catch (_) {}
  }

  Future<void> _leaveScreen() async {
    await _releasePlayer();
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Pop only — do not pushReplacement(MainScreen): that stacks a second MainScreen
      // and Firebase listeners, which re-opens EmergencyAlert and doubles alarm audio.
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          unawaited(_releasePlayer());
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: _leaveScreen,
          ),
          title: Text(
            _readingsSafe ? 'STATUS UPDATE' : 'EMERGENCY',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                _isPlaying ? Icons.volume_up : Icons.volume_off,
                color: Colors.white,
                size: 32,
              ),
              onPressed: () async {
                if (_playerReleased) return;
                if (_isPlaying) {
                  await _stopPlaybackOnly();
                  if (mounted) {
                    setState(() {
                      _isPlaying = false;
                      _userSilencedAlarm = true;
                    });
                  }
                } else {
                  _userSilencedAlarm = false;
                  if (!_readingsSafe) {
                    await _playAlarmSound();
                  }
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
                Text(
                  _readingsSafe
                      ? 'Readings back in\nsafe range'
                      : 'DANGER: Gas Leak\nDetected',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _readingsSafe
                        ? const Color(0xFF81C784)
                        : Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _readingsSafe
                      ? 'The alarm has been silenced. You can return to the dashboard when ready.'
                      : 'Act Immediately! Your safety is at risk.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _readingsSafe
                        ? const Color(0xFF1B3D2F)
                        : const Color(0xFF2D4A43),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _readingsSafe ? 'Next steps' : 'Safety Instructions',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_readingsSafe) ...[
                        _buildInstruction(
                          icon: Icons.info_outline,
                          text:
                              'Stay alert until you are sure the area is fully safe.',
                        ),
                        const SizedBox(height: 16),
                        _buildInstruction(
                          icon: Icons.home,
                          text:
                              'Use the back button to return to the home dashboard.',
                        ),
                      ] else ...[
                        _buildInstruction(
                          icon: Icons.power_settings_new,
                          text:
                              'Do NOT use electronics or light switches.',
                        ),
                        const SizedBox(height: 16),
                        _buildInstruction(
                          icon: Icons.local_fire_department,
                          text:
                              'Extinguish all open flames immediately.',
                        ),
                        const SizedBox(height: 16),
                        _buildInstruction(
                          icon: Icons.window,
                          text:
                              'Open all windows and doors for ventilation.',
                        ),
                        const SizedBox(height: 16),
                        _buildInstruction(
                          icon: Icons.directions_run,
                          text: 'Evacuate the premises immediately.',
                        ),
                        const SizedBox(height: 16),
                        _buildInstruction(
                          icon: Icons.gas_meter,
                          text:
                              'Turn off the gas supply IF safe to do so.',
                        ),
                      ],
                    ],
                  ),
                ),
                if (!_readingsSafe) ...[
                  const SizedBox(height: 30),
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
                ],
                const SizedBox(height: 20),
              ],
            ),
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
