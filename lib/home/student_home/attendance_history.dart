import 'package:classlens/api/api.dart';
import 'package:classlens/global/global.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'student_colors.dart';
import 'attendance_record_utils.dart';
import 'package:classlens/data_models/subjects.dart';

class AttendanceHistoryTab extends StatefulWidget {
  const AttendanceHistoryTab({super.key});

  @override
  State<AttendanceHistoryTab> createState() => _AttendanceHistoryTabState();
}

class _AttendanceHistoryTabState extends State<AttendanceHistoryTab> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, List<Map<String, dynamic>>> _historyData = {};

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final studentId = await getStudentID();
      if (studentId <= 0) {
        throw Exception('Student session not found');
      }

      final result = await ApiServices.getStudentDashboard(studentId: studentId);
      if (result['status'] != true) {
        throw Exception(result['message'] ?? 'Failed to load attendance history');
      }

      final data = Map<String, dynamic>.from(result['data'] as Map);
      final studentYear = int.tryParse(data['year']?.toString() ?? '');
      final studentSemester = int.tryParse(data['semester']?.toString() ?? '');
      final departmentName = data['department_name']?.toString() ?? '';
      final semesterSubjects = (studentYear != null && studentSemester != null && departmentName.isNotEmpty)
          ? await ApiServices.getSubjects(
              departmentName: departmentName,
              year: studentYear,
              semester: studentSemester,
            )
          : <Subjects>[];
      final recentActivity = await loadStudentAttendanceRecords(
        semesterSubjects: semesterSubjects,
        dashboardData: data,
        studentId: studentId,
      );
      final groupedHistory = <String, List<Map<String, dynamic>>>{};

      for (final entry in recentActivity) {
        final parsedDate = attendanceRecordDate(entry);
        if (parsedDate == null) {
          continue;
        }

        final dateKey = DateFormat('yyyy-MM-dd').format(parsedDate);
        groupedHistory.putIfAbsent(dateKey, () => []);
        groupedHistory[dateKey]!.add({
          'subject': attendanceRecordSubject(entry),
          'status': attendanceRecordStatus(entry),
          'time': DateFormat.jm().format(parsedDate),
        });
      }

      if (mounted) {
        setState(() {
          _historyData = groupedHistory;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

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

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: primaryBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: accentColor)),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: primaryBackgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: attentionColor, size: 56),
                const SizedBox(height: 12),
                Text(
                  'Unable to load live attendance history.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: primaryTextColor, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: secondaryTextColor),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadHistory,
                  style: ElevatedButton.styleFrom(backgroundColor: accentColor),
                  child: const Text('Retry', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
                        _selectedDate.year == DateTime.now().year && _selectedDate.month == DateTime.now().month && _selectedDate.day == DateTime.now().day ? "Today" : "Past",
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
                bool isSelected = date.year == _selectedDate.year && date.month == _selectedDate.month && date.day == _selectedDate.day;
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
            Text("No live records for this date", style: TextStyle(color: secondaryTextColor.withOpacity(0.5))),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cls['time'], style: const TextStyle(color: secondaryTextColor, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        cls['subject'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: primaryTextColor, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
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
