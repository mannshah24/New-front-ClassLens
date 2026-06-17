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
  List<Map<String, dynamic>> _allRecentRecords = [];

  // Daily Sessions State
  final Map<String, List<Map<String, dynamic>>> _dailySessionsForDate = {};
  final Map<String, bool> _dailySessionsLoading = {};
  final Map<String, String?> _dailySessionsError = {};

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _fetchDailySessionsForDate(_selectedDate);
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
      final formattedRecent = <Map<String, dynamic>>[];

      for (final entry in recentActivity) {
        final parsedDate = attendanceRecordDate(entry);
        if (parsedDate == null) {
          continue;
        }

        final dateKey = DateFormat('yyyy-MM-dd').format(parsedDate);
        groupedHistory.putIfAbsent(dateKey, () => []);

        final subjectName = attendanceRecordSubject(entry);
        final status = attendanceRecordStatus(entry);
        final timeStr = DateFormat.jm().format(parsedDate);
        final code = entry['subject_code'] ?? entry['code'] ?? '';

        groupedHistory[dateKey]!.add({
          'subject': subjectName,
          'status': status,
          'time': timeStr,
          'subject_code': code,
        });

        formattedRecent.add({
          'subject': subjectName,
          'status': status,
          'dateTime': parsedDate,
          'formattedDateTime': DateFormat('MMM d, yyyy • h:mm a').format(parsedDate),
          'subject_code': code,
        });
      }

      if (mounted) {
        setState(() {
          _historyData = groupedHistory;
          _allRecentRecords = formattedRecent;
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

  Future<void> _fetchDailySessionsForDate(DateTime date) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    if (_dailySessionsForDate.containsKey(dateKey) && _dailySessionsLoading[dateKey] != true) {
      // Already fetched, no need to refetch unless refreshed
      return;
    }

    setState(() {
      _dailySessionsLoading[dateKey] = true;
      _dailySessionsError[dateKey] = null;
    });

    try {
      final studentId = await getStudentID();
      if (studentId <= 0) return;

      final result = await ApiServices.getDailySchedule(
        studentId: studentId,
        date: dateKey,
      );

      final rawSessions = result['sessions'];
      final List<Map<String, dynamic>> sessionsList = rawSessions is List
          ? rawSessions.map((s) => Map<String, dynamic>.from(s as Map)).toList()
          : <Map<String, dynamic>>[];

      // Sort by ui_order
      sessionsList.sort((a, b) => (a['ui_order'] ?? 0).compareTo(b['ui_order'] ?? 0));

      if (mounted) {
        setState(() {
          _dailySessionsForDate[dateKey] = sessionsList;
          _dailySessionsLoading[dateKey] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dailySessionsError[dateKey] = e.toString();
          _dailySessionsLoading[dateKey] = false;
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
            colorScheme: const ColorScheme.light(
              primary: accentColor,
              onPrimary: Colors.white,
              onSurface: primaryTextColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchDailySessionsForDate(picked);
    }
  }

  bool matches(Map<String, dynamic> session, Map<String, dynamic> record) {
    final sessionCode = normalizeSubjectKey(session['subject_code']);
    final sessionName = normalizeSubjectKey(session['subject_name']);

    final recordCode = normalizeSubjectKey(record['subject_code']);
    final recordSubject = normalizeSubjectKey(record['subject']);

    if (sessionCode.isNotEmpty && recordCode.isNotEmpty) {
      if (sessionCode == recordCode) return true;
    }
    if (sessionName.isNotEmpty && recordSubject.isNotEmpty) {
      if (sessionName == recordSubject) return true;
    }
    return false;
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
      body: Stack(
        children: [
          // Background
          Positioned(
            top: -screenSize.width * 0.2,
            right: -screenSize.width * 0.2,
            child: CircleAvatar(
              radius: screenSize.width * 0.4,
              backgroundColor: circleColor1.withOpacity(0.3),
            ),
          ),

          Column(
            children: [
              SizedBox(height: kToolbarHeight + MediaQuery.of(context).padding.top),
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
                        _selectedDate.year == DateTime.now().year &&
                                _selectedDate.month == DateTime.now().month &&
                                _selectedDate.day == DateTime.now().day
                            ? "Today"
                            : "Past",
                        style: const TextStyle(fontSize: 12, color: secondaryTextColor, fontWeight: FontWeight.bold),
                      ),
                    ),
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
                width: 50,
                height: 80,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
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
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              reverse: true, // Start from today
              padding: const EdgeInsets.only(right: 16),
              itemCount: 30, // Last 30 days
              itemBuilder: (context, index) {
                DateTime date = DateTime.now().subtract(Duration(days: index));
                bool isSelected = date.year == _selectedDate.year &&
                    date.month == _selectedDate.month &&
                    date.day == _selectedDate.day;
                bool hasData = _historyData.containsKey(DateFormat('yyyy-MM-dd').format(date));

                Color dotColor = Colors.transparent;
                if (hasData) {
                  List classes = _historyData[DateFormat('yyyy-MM-dd').format(date)]!;
                  bool anyAbsent = classes.any((c) => c['status'] == 'Absent');
                  dotColor = anyAbsent ? attentionColor : successColor;
                }

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedDate = date);
                    _fetchDailySessionsForDate(date);
                  },
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
    // A specific date is selected!
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final isLoadingSessions = _dailySessionsLoading[dateKey] ?? false;

    if (isLoadingSessions) {
      return const Center(
        child: CircularProgressIndicator(color: accentColor),
      );
    }

    final sessionError = _dailySessionsError[dateKey];
    if (sessionError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: attentionColor, size: 56),
            const SizedBox(height: 12),
            Text(
              'Failed to load sessions: $sessionError',
              style: const TextStyle(color: primaryTextColor, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _fetchDailySessionsForDate(_selectedDate),
              style: ElevatedButton.styleFrom(backgroundColor: accentColor),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    // Merge marked attendance records with daily sessions to cross-reference
    final markedRecords = _historyData[dateKey] ?? [];
    final dailySessions = _dailySessionsForDate[dateKey] ?? [];

    final List<Map<String, dynamic>> mergedList = [];
    final Set<String> matchedSessionIds = {};

    // 1. Add all marked records (we also try to match them with daily sessions to get ui_order)
    for (final record in markedRecords) {
      final Map<String, dynamic> recordCopy = Map<String, dynamic>.from(record);
      recordCopy['isMarked'] = true;
      recordCopy['ui_order'] = 999; // Default ui_order if no daily session match

      // Look for a matching daily session to copy ui_order
      for (final session in dailySessions) {
        if (matches(session, recordCopy)) {
          recordCopy['ui_order'] = session['ui_order'] ?? 0;
          matchedSessionIds.add(session['id']?.toString() ?? '');
          break;
        }
      }
      mergedList.add(recordCopy);
    }

    // 2. Add daily sessions that have no corresponding marked attendance record
    for (final session in dailySessions) {
      final sessionId = session['id']?.toString() ?? '';
      bool alreadyMatched = matchedSessionIds.contains(sessionId);

      // Also double-check match using helper in case id is not present or matched differently
      if (!alreadyMatched) {
        final hasMatch = markedRecords.any((rec) => matches(session, rec));
        if (hasMatch) {
          alreadyMatched = true;
        }
      }

      if (!alreadyMatched) {
        final isCancelled = session['is_cancelled'] ?? false;
        final attendanceMarked = session['attendance_marked'] ?? false;
        final status = isCancelled 
            ? 'Canceled' 
            : (attendanceMarked ? 'Absent' : 'Not Marked');

        mergedList.add({
          'subject': session['subject_name'] ?? 'Unknown Subject',
          'subject_code': session['subject_code'] ?? '',
          'status': status,
          'time': '', // No time display
          'isMarked': false,
          'ui_order': session['ui_order'] ?? 0,
        });
      }
    }

    // 3. Sort by ui_order
    mergedList.sort((a, b) => (a['ui_order'] ?? 0).compareTo(b['ui_order'] ?? 0));

    if (mergedList.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          await _loadHistory();
          await _fetchDailySessionsForDate(_selectedDate);
        },
        color: accentColor,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 60, color: secondaryTextColor.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  const Text("No classes or attendance records for this date", style: TextStyle(color: secondaryTextColor)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadHistory();
        await _fetchDailySessionsForDate(_selectedDate);
      },
      color: accentColor,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: mergedList.length,
        itemBuilder: (context, index) {
          final cls = mergedList[index];
          final status = cls['status'] ?? 'Unknown';

          Color statusColor;
          IconData statusIcon;

          if (status == 'Present') {
            statusColor = successColor;
            statusIcon = Icons.check_circle;
          } else if (status == 'Absent') {
            statusColor = attentionColor;
            statusIcon = Icons.cancel;
          } else if (status == 'Canceled' || status == 'Cancelled') {
            statusColor = attentionColor;
            statusIcon = Icons.cancel_outlined;
          } else {
            // Not Marked
            statusColor = secondaryTextColor;
            statusIcon = Icons.help_outline;
          }

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
                      if (cls['time'] != null && cls['time'].toString().isNotEmpty)
                        Text(
                          cls['time'],
                          style: const TextStyle(color: secondaryTextColor, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        cls['subject'] ?? 'Subject',
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
                      Icon(statusIcon, color: statusColor, size: 14),
                      const SizedBox(width: 4),
                      Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
