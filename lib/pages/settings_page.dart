import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';

class SettingsAlerts extends StatefulWidget {
  const SettingsAlerts({super.key});

  @override
  State<SettingsAlerts> createState() => _SettingsAlertsState();
}

class _SettingsAlertsState extends State<SettingsAlerts> {
  bool _inAppNotifications = true;
  bool _loudSoundAlarm = true;
  bool _pushNotifications = true;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.secondaryCardColor,
      appBar: AppBar(
        backgroundColor: themeProvider.secondaryCardColor,
        elevation: 0,
        title: Text(
          'Settings & Alerts',
          style: TextStyle(
            color: themeProvider.textPrimaryColor,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Alert Methods Section
          Text(
            'Alert Methods',
            style: TextStyle(
              color: themeProvider.textPrimaryColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // In-App Notifications
          _buildSettingItem(
            icon: Icons.notifications,
            title: 'In-App Notifications',
            subtitle: 'Receive alerts directly within the app',
            value: _inAppNotifications,
            onChanged: (val) {
              setState(() {
                _inAppNotifications = val;
              });
            },
          ),

          const SizedBox(height: 16),

          // Push Notifications
          _buildSettingItem(
            icon: Icons.notifications_active,
            title: 'Push Notifications',
            subtitle: 'Receive alerts even when app is closed',
            value: _pushNotifications,
            onChanged: (val) {
              setState(() {
                _pushNotifications = val;
              });
            },
          ),

          const SizedBox(height: 16),

          // Loud Sound Alarm
          _buildSettingItem(
            icon: Icons.volume_up,
            title: 'Loud Sound Alarm',
            subtitle: 'Trigger a loud alarm from your phone',
            value: _loudSoundAlarm,
            onChanged: (val) {
              setState(() {
                _loudSoundAlarm = val;
              });
            },
          ),
          

          
          // Appearance Section
          Text(
            'Appearance',
            style: TextStyle(
              color: themeProvider.textPrimaryColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Dark Mode
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return _buildSettingItem(
                icon: themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                title: themeProvider.isDarkMode ? 'Dark Mode' : 'Light Mode',
                subtitle: themeProvider.isDarkMode ? 'Reduce eye strain in low light' : 'Use light theme for better visibility',
                value: themeProvider.isDarkMode,
                onChanged: (val) {
                  themeProvider.setDarkMode(val);
                },
              );
            },
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: themeProvider.accentColor,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: themeProvider.textPrimaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: themeProvider.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: themeProvider.isDarkMode ? Colors.white : const Color(0xFF2D3436),
            activeTrackColor: const Color(0xFF4A9B8E),
            inactiveThumbColor: themeProvider.isDarkMode ? Colors.white : const Color(0xFF2D3436),
            inactiveTrackColor: themeProvider.isDarkMode ? const Color(0xFF3A3A3A) : const Color(0xFFE9ECEF),
          ),
        ],
      ),
    );
  }


}
