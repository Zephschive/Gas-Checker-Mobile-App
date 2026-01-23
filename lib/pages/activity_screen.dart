import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';

class ActivityLog extends StatefulWidget {
  const ActivityLog({super.key});

  @override
  State<ActivityLog> createState() => _ActivityLogState();
}

class ActivityLogEntry {
  final String key;
  final int gas1;
  final int gas2;
  final String status;
  final DateTime dateTime;

  ActivityLogEntry({
    required this.key,
    required this.gas1,
    required this.gas2,
    required this.status,
    required this.dateTime,
  });

  static ActivityLogEntry? fromMap(String key, Map<dynamic, dynamic> data) {
    final rawDateTime = data['DateTime'];
   

    if (rawDateTime is! String || rawDateTime.trim().isEmpty) {
    
      return null;
    }

    final dateTimeString = rawDateTime.trim();
    

    DateTime parsedDateTime;
    try {
      // Convert "yyyy-MM-dd HH:mm:ss" to ISO format by replacing space with 'T'
      final isoString = dateTimeString.replaceFirst(' ', 'T');
      parsedDateTime = DateTime.parse(isoString);
   
    } catch (e) {
   
      return null;
    }

    return ActivityLogEntry(
      key: key,
      gas1: data['Gas1'] ?? 0,
      gas2: data['Gas2'] ?? 0,
      status: data['Status'] ?? 'UNKNOWN',
      dateTime: parsedDateTime,
    );
  }
}

class _ActivityLogState extends State<ActivityLog> {
  String _selectedFilter = 'All';
  bool _isLoading = true;
  bool _dataReceived = false;
  List<ActivityLogEntry> _todayEntries = [];
  List<ActivityLogEntry> _yesterdayEntries = [];
  List<ActivityLogEntry> _olderEntries = [];
  StreamSubscription<DatabaseEvent>? _activitySubscription;

  @override
  void initState() {
    super.initState();
    _loadActivityData();
  }

  @override
  void dispose() {
    _activitySubscription?.cancel();
    super.dispose();
  }

  void _loadActivityData() {
    setState(() {
      _isLoading = true;
      _dataReceived = false;
    });

    final databaseRef = FirebaseDatabase.instance.ref('GasHistory');

    // Set minimum 5-second loading delay
    Timer(const Duration(seconds: 5), () {
      if (mounted && _dataReceived && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    });

    _activitySubscription = databaseRef.onValue.listen((event) {
      final data = event.snapshot.value;

      if (data != null && data is Map) {
        final allEntries = <ActivityLogEntry>[];

        // Convert Firebase data to ActivityLogEntry objects
        data.forEach((key, value) {
          if (value is Map) {
            try {
              final entry = ActivityLogEntry.fromMap(key, value);
              if (entry != null) {
                allEntries.add(entry);
              }
            } catch (e) {

            }
          }
        });

        // Sort entries by date and time (newest first)
        allEntries.sort((a, b) => b.dateTime.compareTo(a.dateTime));

        // Group entries by date
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));

        final todayEntries = <ActivityLogEntry>[];
        final yesterdayEntries = <ActivityLogEntry>[];
        final olderEntries = <ActivityLogEntry>[];

        for (final entry in allEntries) {
          final entryDate = DateTime(entry.dateTime.year, entry.dateTime.month, entry.dateTime.day);
          if (entryDate == today) {
            todayEntries.add(entry);
          } else if (entryDate == yesterday) {
            yesterdayEntries.add(entry);
          } else {
            olderEntries.add(entry);
          }
        }

        // Sort each date group by time (newest first within each day)
        todayEntries.sort((a, b) => b.dateTime.compareTo(a.dateTime));
        yesterdayEntries.sort((a, b) => b.dateTime.compareTo(a.dateTime));
        olderEntries.sort((a, b) => b.dateTime.compareTo(a.dateTime));

        // Mark data as received and update data
        setState(() {
          _todayEntries = todayEntries;
          _yesterdayEntries = yesterdayEntries;
          _olderEntries = olderEntries;
          _dataReceived = true;
        });

        // The timer will handle stopping the loading after the minimum delay

      } else {
        // Keep loading state until we get some data
        // Don't set _isLoading = false here
      }
    }, onError: (error) {
      // On error, stop loading immediately and show error state
      setState(() {
        _isLoading = false;
        _dataReceived = true;
      });
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
          'Activity Log',
          style: TextStyle(
            color: themeProvider.textPrimaryColor,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _buildFilterChip('All', true),
                const SizedBox(width: 12),
                _buildFilterChip('Readings', false),
                const SizedBox(width: 12),
                _buildFilterChip('Alerts', false),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Activity list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF2FD7D)),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: _buildActivityList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: _selectedFilter == label
              ? themeProvider.accentColor
              : themeProvider.cardBackgroundColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: _selectedFilter == label
                ? (themeProvider.isDarkMode ? Colors.black : themeProvider.textPrimaryColor)
                : themeProvider.textSecondaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String title,
    required String subtitle,
    required String time,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Icon circle
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: backgroundColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),

          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: themeProvider.textPrimaryColor,
                    fontSize: 17,
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

          // Time
          Text(
            time,
            style: TextStyle(
              color: themeProvider.textSecondaryColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActivityList() {
    // Filter entries based on selected filter
    List<ActivityLogEntry> filteredTodayEntries = _filterEntries(_todayEntries);
    List<ActivityLogEntry> filteredYesterdayEntries = _filterEntries(_yesterdayEntries);
    List<ActivityLogEntry> filteredOlderEntries = _filterEntries(_olderEntries);

    final widgets = <Widget>[];

    // Today section
    if (filteredTodayEntries.isNotEmpty) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      widgets.addAll([
        Text(
          'Today',
          style: TextStyle(
            color: themeProvider.textPrimaryColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
      ]);

      for (int i = 0; i < filteredTodayEntries.length; i++) {
        final entry = filteredTodayEntries[i];
        widgets.add(_buildActivityCardForEntry(entry));
        if (i < filteredTodayEntries.length - 1) {
          widgets.add(const SizedBox(height: 12));
        }
      }

      widgets.add(const SizedBox(height: 32));
    }

    // Yesterday section
    if (filteredYesterdayEntries.isNotEmpty) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      widgets.addAll([
        Text(
          'Yesterday',
          style: TextStyle(
            color: themeProvider.textPrimaryColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
      ]);

      for (int i = 0; i < filteredYesterdayEntries.length; i++) {
        final entry = filteredYesterdayEntries[i];
        widgets.add(_buildActivityCardForEntry(entry));
        if (i < filteredYesterdayEntries.length - 1) {
          widgets.add(const SizedBox(height: 12));
        }
      }

      widgets.add(const SizedBox(height: 32));
    }

    // Older entries section
    if (filteredOlderEntries.isNotEmpty) {
      // Group older entries by date
      final groupedEntries = <String, List<ActivityLogEntry>>{};
      for (final entry in filteredOlderEntries) {
        final dateKey = DateFormat('MMMM d, y').format(entry.dateTime);
        if (!groupedEntries.containsKey(dateKey)) {
          groupedEntries[dateKey] = [];
        }
        groupedEntries[dateKey]!.add(entry);
      }

      // Sort dates (newest first)
      final sortedDates = groupedEntries.keys.toList()
        ..sort((a, b) => DateFormat('MMMM d, y').parse(b).compareTo(DateFormat('MMMM d, y').parse(a)));

      for (final dateKey in sortedDates) {
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        widgets.addAll([
          Text(
            dateKey,
            style: TextStyle(
              color: themeProvider.textPrimaryColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
        ]);

        final entries = groupedEntries[dateKey]!;
        for (int i = 0; i < entries.length; i++) {
          final entry = entries[i];
          widgets.add(_buildActivityCardForEntry(entry));
          if (i < entries.length - 1) {
            widgets.add(const SizedBox(height: 12));
          }
        }

        widgets.add(const SizedBox(height: 32));
      }
    }

    // If no entries match the filter
    if (filteredTodayEntries.isEmpty && filteredYesterdayEntries.isEmpty && filteredOlderEntries.isEmpty) {
      String message = 'No activity data available';
      if (_selectedFilter != 'All') {
        message = 'No ${_selectedFilter.toLowerCase()} found';
      }

      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      widgets.addAll([
        const SizedBox(height: 100),
        Center(
          child: Text(
            message,
            style: TextStyle(
              color: themeProvider.textSecondaryColor,
              fontSize: 18,
            ),
          ),
        ),
      ]);
    }

    return widgets;
  }

  List<ActivityLogEntry> _filterEntries(List<ActivityLogEntry> entries) {


    List<ActivityLogEntry> filtered;

    if (_selectedFilter == 'All') {
      filtered = entries;

    } else if (_selectedFilter == 'Alerts') {
      filtered = entries.where((entry) {
        final status = entry.status.toUpperCase();
        final isAlert = status == 'ALERT' || status == 'DANGER' || status == 'LEAKAGE';
        if (isAlert) print('🚨 Alert found: ${entry.key} with status ${entry.status}');
        return isAlert;
      }).toList();

    } else if (_selectedFilter == 'Readings') {
      filtered = entries.where((entry) {
        final status = entry.status.toUpperCase();
        final isReading = status == 'SAFE' || (status != 'ALERT' && status != 'DANGER' && status != 'LEAKAGE');
        if (isReading) print('📊 Reading found: ${entry.key} with status ${entry.status}');
        return isReading;
      }).toList();

    } else {
      filtered = entries;
    }

    return filtered;
  }

  Widget _buildActivityCardForEntry(ActivityLogEntry entry) {
    // Determine icon and colors based on status
    IconData icon;
    Color iconColor;
    Color backgroundColor;
    String title;
    String subtitle;

    switch (entry.status.toUpperCase()) {
      case 'SAFE':
        icon = Icons.shield;
        iconColor = const Color(0xFF00C853);
        backgroundColor = const Color(0xFF00C853);
        title = 'System Status: Safe';
        subtitle = 'Gas1: ${entry.gas1}, Gas2: ${entry.gas2}';
        break;
      case 'ALERT':
      case 'DANGER':
      case 'LEAKAGE':
        icon = Icons.warning;
        iconColor = const Color(0xFFE53935);
        backgroundColor = const Color(0xFFE53935);
        title = entry.status.toUpperCase() == 'LEAKAGE' ? 'Gas Leakage Detected' : 'Alert Detected';
        subtitle = 'Gas1: ${entry.gas1}, Gas2: ${entry.gas2}';
        break;
      default:
        icon = Icons.show_chart;
        iconColor = const Color(0xFF00C853);
        backgroundColor = const Color(0xFF00C853);
        title = 'Gas Reading';
        subtitle = 'Gas1: ${entry.gas1}, Gas2: ${entry.gas2}';
    }

    final timeString = DateFormat('h:mm a').format(entry.dateTime);

    return _buildActivityCard(
      icon: icon,
      iconColor: iconColor,
      backgroundColor: backgroundColor,
      title: title,
      subtitle: subtitle,
      time: timeString,
    );
  }
}
