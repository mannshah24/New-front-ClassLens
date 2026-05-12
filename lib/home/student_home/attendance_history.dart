import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'student_colors.dart';

class AttendanceHistoryTab extends StatefulWidget {
  const AttendanceHistoryTab({super.key});

  @override
  State<AttendanceHistoryTab> createState() => _AttendanceHistoryTabState();
}

class _AttendanceHistoryTabState extends State<AttendanceHistoryTab> {
  DateTime _selectedDate = DateTime.now();

  // Vyom's actual attendance data (PRN: 8022054043)
  final Map<String, List<Map<String, dynamic>>> _historyData = {
    "2025-11-29": [
      {"subject": "Applied Mathematics-III-CSE", "status": "Present", "time": "12:33 AM"},
    ],
    "2025-11-28": [
      {"subject": "Applied Mathematics-III-CSE", "status": "Present", "time": "11:51 PM"},
      {"subject": "Applied Mathematics-III-CSE", "status": "Present", "time": "11:36 PM"},
      {"subject": "Applied Mathematics-III-CSE", "status": "Present", "time": "05:01 PM"},
      {"subject": "Applied Mathematics-III-CSE", "status": "Present", "time": "04:03 PM"},
    ],
    "2025-11-26": [
      {"subject": "Applied Mathematics-III-CSE", "status": "Present", "time": "03:12 PM"},
      {"subject": "Applied Mathematics-III-CSE", "status": "Present", "time": "03:09 PM"},
    ],
    "2025-11-25": [
      {"subject": "Electronics Engineering-CSE", "status": "Absent", "time": "11:55 PM"},
      {"subject": "Electronics Engineering-CSE", "status": "Present", "time": "04:16 PM"},
      {"subject": "Applied Mathematics-III-CSE", "status": "Present", "time": "04:11 PM"},
      {"subject": "Applied Mathematics-III-CSE", "status": "Absent", "time": "04:09 PM"},
      {"subject": "Applied Mathematics-III-CSE", "status": "Present", "time": "03:58 PM"},
      {"subject": "Applied Mathematics-III-CSE", "status": "Absent", "time": "03:53 PM"},
    ],
    "2025-11-24": [
      {"subject": "Electronics Engineering-CSE", "status": "Present", "time": "12:16 AM"},
      {"subject": "Applied Mathematics-III-CSE", "status": "Present", "time": "12:14 AM"},
    ],
    "2025-11-23": [
      {"subject": "Applied Mathematics-III-CSE", "status": "Present", "time": "11:56 PM"},
      {"subject": "Applied Mathematics-III-CSE", "status": "Absent", "time": "11:46 PM"},
      {"subject": "Applied Mathematics-III-CSE", "status": "Absent", "time": "11:43 PM"},
      {"subject": "Applied Mathematics-III-CSE", "status": "Present", "time": "08:25 PM"},
      {"subject": "Applied Mathematics-III-CSE", "status": "Absent", "time": "08:17 PM"},
      {"subject": "Applied Mathematics-III-CSE", "status": "Absent", "time": "08:12 PM"},
      {"subject": "Applied Mathematics-III-CSE", "status": "Absent", "time": "08:07 PM"},
      {"subject": "Applied Mathematics-III-CSE", "status": "Absent", "time": "07:54 PM"},
      {"subject": "Applied Mathematics-III-CSE", "status": "Absent", "time": "07:46 PM"},
    ],
  };

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: accentColor, onPrimary: Colors.white, onSurface: primaryTextColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: primaryBackgroundColor,
      appBar: AppBar(
        title: const Text("Attendance History", style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background
          Positioned(top: -screenSize.width * 0.2, right: -screenSize.width * 0.2, child: CircleAvatar(radius: screenSize.width * 0.4, backgroundColor: circleColor1.withOpacity(0.3))),

          Column(
            children: [
              // 1. Calendar Control Strip
              _buildCalendarStrip(),

              const SizedBox(height: 16),

              // 2. Selected Date Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Text(
                      DateFormat('EEEE, MMM d').format(_selectedDate),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryTextColor),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        _selectedDate.day == DateTime.now().day ? "Today" : "Past",
                        style: const TextStyle(fontSize: 12, color: secondaryTextColor, fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 3. Class List for Selected Date
              Expanded(
                child: _buildClassListForDate(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarStrip() {
    return SizedBox(
      height: 90,
      child: Row(
        children: [
          // Date Picker Button
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: GestureDetector(
              onTap: _pickDate,
              child: Container(
                width: 50, height: 80,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [BoxShadow(color: accentColor.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_month, color: Colors.white),
                    SizedBox(height: 4),
                    Text("Pick", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),

          // Scrollable Strip
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              // PHYSICS CHANGED: Ensures scrollability even if content fits
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              reverse: true, // Start from today
              padding: const EdgeInsets.only(right: 16),
              itemCount: 30, // Last 30 days
              itemBuilder: (context, index) {
                DateTime date = DateTime.now().subtract(Duration(days: index));
                bool isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month && date.year == _selectedDate.year;
                bool hasData = _historyData.containsKey(DateFormat('yyyy-MM-dd').format(date));

                Color dotColor = Colors.transparent;
                if (hasData) {
                  List classes = _historyData[DateFormat('yyyy-MM-dd').format(date)]!;
                  bool anyAbsent = classes.any((c) => c['status'] == 'Absent');
                  dotColor = anyAbsent ? attentionColor : successColor;
                }

                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : cardBackgroundColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? accentColor : Colors.transparent, width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(DateFormat('E').format(date), style: const TextStyle(color: secondaryTextColor, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(DateFormat('d').format(date), style: const TextStyle(color: primaryTextColor, fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 4),
                        if (hasData) CircleAvatar(radius: 3, backgroundColor: dotColor),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassListForDate() {
    String dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    List<Map<String, dynamic>> classes = _historyData[dateKey] ?? [];

    if (classes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 60, color: secondaryTextColor.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text("No records for this date", style: TextStyle(color: secondaryTextColor.withOpacity(0.5))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final cls = classes[index];
        bool isPresent = cls['status'] == 'Present';
        Color statusColor = isPresent ? successColor : attentionColor;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border(left: BorderSide(color: statusColor, width: 4)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cls['time'], style: const TextStyle(color: secondaryTextColor, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(cls['subject'], style: const TextStyle(color: primaryTextColor, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Icon(isPresent ? Icons.check_circle : Icons.cancel, color: statusColor, size: 14),
                    const SizedBox(width: 4),
                    Text(cls['status'], style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
