import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:classlens/api/api.dart';
import 'student_colors.dart';
import 'package:lottie/lottie.dart';

class StudentScheduleTab extends StatefulWidget {
  final int studentId;

  const StudentScheduleTab({
    super.key,
    required this.studentId,
  });

  @override
  State<StudentScheduleTab> createState() => _StudentScheduleTabState();
}

class _StudentScheduleTabState extends State<StudentScheduleTab> {
  // Navigation segment: 0 = Today, 1 = Weekly
  int _activeSegment = 0;

  // Daily Schedule state
  bool _dailyLoading = true;
  String? _dailyError;
  bool _isHoliday = false;
  String _holidayName = '';
  List<Map<String, dynamic>> _todaySessions = [];

  // Weekly Timetable state
  bool _weeklyLoading = true;
  String? _weeklyError;
  String? _divisionName;
  Map<String, dynamic> _timetable = {};
  Map<String, dynamic> _weeklyHolidays = {};
  final List<String> _days = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday"
  ];
  String _selectedDay = "Monday";

  @override
  void initState() {
    super.initState();
    // Set default selected day for weekly view based on today's weekday
    final now = DateTime.now();
    if (now.weekday >= 1 && now.weekday <= 6) {
      _selectedDay = _days[now.weekday - 1];
    } else {
      _selectedDay = "Monday";
    }
    _fetchDailySchedule();
    _fetchWeeklyTimetable();
  }

  Future<void> _fetchDailySchedule() async {
    setState(() {
      _dailyLoading = true;
      _dailyError = null;
    });

    try {
      final holidayData = await ApiServices.getDailySchedule(studentId: widget.studentId);
      final isHoliday = holidayData['is_holiday'] ?? false;
      final holidayName = holidayData['holiday_name'] ?? '';
      final rawSessions = holidayData['sessions'];
      final List<Map<String, dynamic>> sessionsList = rawSessions is List
          ? rawSessions.map((s) => Map<String, dynamic>.from(s as Map)).toList()
          : <Map<String, dynamic>>[];

      sessionsList.sort((a, b) => (a['ui_order'] ?? 0).compareTo(b['ui_order'] ?? 0));

      setState(() {
        _isHoliday = isHoliday;
        _holidayName = holidayName;
        _todaySessions = sessionsList;
        _dailyLoading = false;
      });
    } catch (e) {
      setState(() {
        _dailyError = 'Failed to load today\'s schedule. Please try again.';
        _dailyLoading = false;
      });
    }
  }

  Future<void> _fetchWeeklyTimetable() async {
    setState(() {
      _weeklyLoading = true;
      _weeklyError = null;
    });

    try {
      final res = await ApiServices.getWeeklyTimetable(studentId: widget.studentId);
      setState(() {
        _divisionName = res['division_name'];
        _timetable = res['timetable'] ?? {};
        _weeklyHolidays = res['holidays'] ?? {};
        _weeklyLoading = false;
      });
    } catch (e) {
      setState(() {
        _weeklyError = "Failed to load weekly timetable.";
        _weeklyLoading = false;
      });
    }
  }

  String _getWeeklyHolidayText(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('closure') ||
        lowerName.contains('closuer') ||
        lowerName.contains('strike') ||
        lowerName.contains('emergency') ||
        lowerName.contains('lockdown') ||
        lowerName.contains('shutdown') ||
        lowerName.contains('rain') ||
        name.trim().isEmpty) {
      return "Today is marked as Holiday.";
    }
    return "Today is marked as $name.";
  }

  String _getHolidayText() {
    final lowerName = _holidayName.toLowerCase();
    if (lowerName.contains('closure') ||
        lowerName.contains('closuer') ||
        lowerName.contains('strike') ||
        lowerName.contains('emergency') ||
        lowerName.contains('lockdown') ||
        lowerName.contains('shutdown') ||
        lowerName.contains('rain') ||
        _holidayName.trim().isEmpty) {
      return "Today is marked as Holiday.";
    }
    return "Today is marked as $_holidayName.";
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: primaryBackgroundColor,
      body: Stack(
        children: [
          // Background Circle Blobs
          Positioned(
            top: -screenSize.width * 0.3,
            left: -screenSize.width * 0.3,
            child: CircleAvatar(
              radius: screenSize.width * 0.45,
              backgroundColor: circleColor1.withOpacity(0.5),
            ),
          ),
          Positioned(
            bottom: -screenSize.width * 0.4,
            right: -screenSize.width * 0.4,
            child: CircleAvatar(
              radius: screenSize.width * 0.5,
              backgroundColor: circleColor2.withOpacity(0.5),
            ),
          ),

          // Main Content
          Padding(
            padding: EdgeInsets.only(top: kToolbarHeight + topPadding),
            child: Column(
              children: [
                const SizedBox(height: 12),
                _buildSegmentSelector(),
                const SizedBox(height: 16),
                Expanded(
                  child: _activeSegment == 0
                      ? _buildTodayContent()
                      : _buildWeeklyContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Segment selector: Today vs Weekly
  Widget _buildSegmentSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _activeSegment = 0);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: _activeSegment == 0 ? accentColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "Today",
                    style: TextStyle(
                      color: _activeSegment == 0 ? Colors.white : secondaryTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _activeSegment = 1);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: _activeSegment == 1 ? accentColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "Weekly",
                    style: TextStyle(
                      color: _activeSegment == 1 ? Colors.white : secondaryTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TODAY SCHEDULE CONTENT
  Widget _buildTodayContent() {
    if (_dailyLoading) {
      return const Center(
        child: CircularProgressIndicator(color: accentColor),
      );
    }

    if (_dailyError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: attentionColor.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(_dailyError!, style: const TextStyle(color: secondaryTextColor)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchDailySchedule,
              style: ElevatedButton.styleFrom(backgroundColor: accentColor),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_isHoliday) {
      return RefreshIndicator(
        onRefresh: _fetchDailySchedule,
        color: accentColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top - 150,
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset('assets/animations/holiday_chill.json', height: 200),
                const SizedBox(height: 24),
                const Text(
                  "No Classes Today!",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _getHolidayText(),
                  style: const TextStyle(
                    fontSize: 16,
                    color: secondaryTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Enjoy your day off!",
                  style: TextStyle(
                    fontSize: 14,
                    color: successColor,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchDailySchedule,
      color: accentColor,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Schedule",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryTextColor),
              ),
              Text(
                DateFormat('EEEE, MMM d').format(DateTime.now()),
                style: const TextStyle(color: secondaryTextColor, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_todaySessions.isEmpty)
            _buildNoClassesCard()
          else
            ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _todaySessions.length,
              itemBuilder: (context, index) {
                final session = _todaySessions[index];
                return _buildSessionCard(session, index);
              },
            ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Future<void> _shiftSession(int index, int direction) async {
    final targetIndex = index + direction;
    if (targetIndex < 0 || targetIndex >= _todaySessions.length) return;

    setState(() {
      final temp = _todaySessions[index];
      _todaySessions[index] = _todaySessions[targetIndex];
      _todaySessions[targetIndex] = temp;
    });

    for (int i = 0; i < _todaySessions.length; i++) {
      final session = _todaySessions[i];
      final sessionId = session['id'];
      if (sessionId != null) {
        session['ui_order'] = i;
        await ApiServices.updateSessionOrder(
          sessionId: sessionId as int,
          uiOrder: i,
        );
      }
    }
  }

  Widget _buildSessionCard(Map<String, dynamic> session, int index) {
    final subjectName = session['subject_name'] ?? 'Unknown Subject';
    final subjectCode = session['subject_code'] ?? '';
    final teacherName = session['proxy_teacher_name'] != null
        ? "${session['proxy_teacher_name']} (Proxy)"
        : (session['teacher_name'] ?? 'No teacher assigned');
    final isCancelled = session['is_cancelled'] ?? false;
    final isMoved = session['is_moved'] ?? false;
    final attendanceMarked = session['attendance_marked'] ?? false;

    Color badgeColor = accentColor;
    String badgeText = "Scheduled";
    if (isCancelled) {
      badgeColor = attentionColor;
      badgeText = "Cancelled";
    } else if (isMoved) {
      badgeColor = warningColor;
      badgeText = "Moved";
    } else if (attendanceMarked) {
      badgeColor = successColor;
      badgeText = "Completed";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCancelled
                  ? Icons.cancel_outlined
                  : (attendanceMarked ? Icons.check_circle_outline : Icons.book_outlined),
              color: badgeColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subjectName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isCancelled ? secondaryTextColor : primaryTextColor,
                    decoration: isCancelled ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "$subjectCode • $teacherName",
                  style: const TextStyle(fontSize: 12, color: secondaryTextColor),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (index > 0)
                GestureDetector(
                  onTap: () => _shiftSession(index, -1),
                  child: const Icon(Icons.keyboard_arrow_up, size: 24, color: secondaryTextColor),
                ),
              if (index < _todaySessions.length - 1)
                GestureDetector(
                  onTap: () => _shiftSession(index, 1),
                  child: const Icon(Icons.keyboard_arrow_down, size: 24, color: secondaryTextColor),
                ),
            ],
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                color: badgeColor == warningColor ? const Color(0xFFB78103) : badgeColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoClassesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: const Row(
        children: [
          Icon(Icons.calendar_today_outlined, color: secondaryTextColor),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "No sessions scheduled",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Enjoy your free day!",
                  style: TextStyle(fontSize: 12, color: secondaryTextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // WEEKLY TIMETABLE CONTENT
  Widget _buildWeeklyContent() {
    if (_weeklyLoading) {
      return const Center(
        child: CircularProgressIndicator(color: accentColor),
      );
    }

    if (_weeklyError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_weeklyError!, style: const TextStyle(color: secondaryTextColor)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _weeklyLoading = true;
                  _weeklyError = null;
                });
                _fetchWeeklyTimetable();
              },
              style: ElevatedButton.styleFrom(backgroundColor: accentColor),
              child: const Text("Retry", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      );
    }

    return Column(
      children: [
        // Horizontal day selector
        Container(
          height: 60,
          color: Colors.transparent,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: _days.length,
            itemBuilder: (context, index) {
              final day = _days[index];
              final isSelected = day == _selectedDay;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDay = day;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? accentColor : Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: accentColor.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        color: isSelected ? Colors.white : primaryTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Division Header
        if (_divisionName != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Division: $_divisionName",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: secondaryTextColor,
                ),
              ),
            ),
          ),

        // Timetable items
        Expanded(
          child: _buildTimetableList(),
        ),
      ],
    );
  }

  Widget _buildTimetableList() {
    final holidayInfo = _weeklyHolidays[_selectedDay];
    final isHoliday = holidayInfo != null && holidayInfo['is_holiday'] == true;
    final holidayName = holidayInfo != null ? (holidayInfo['holiday_name'] ?? '') : '';

    if (isHoliday) {
      return RefreshIndicator(
        onRefresh: _fetchWeeklyTimetable,
        color: accentColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top - 250,
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset('assets/animations/holiday_chill.json', height: 160),
                const SizedBox(height: 20),
                const Text(
                  "No Classes Today!",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _getWeeklyHolidayText(holidayName),
                  style: const TextStyle(
                    fontSize: 15,
                    color: secondaryTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Enjoy your day off!",
                  style: TextStyle(
                    fontSize: 13,
                    color: successColor,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final daySessions = _timetable[_selectedDay];
    final List<dynamic> sessionsList = daySessions is List ? daySessions : [];

    if (sessionsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 60,
              color: secondaryTextColor.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              "No lectures scheduled for $_selectedDay",
              style: TextStyle(
                color: secondaryTextColor.withOpacity(0.7),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchWeeklyTimetable,
      color: accentColor,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: sessionsList.length,
        itemBuilder: (context, index) {
          final session = sessionsList[index];
          final subjectName = session['subject_name'] ?? 'Unknown Subject';
          final teacherName = session['default_teacher_name'] ?? 'No teacher assigned';
          final program = session['program'] ?? '';
          final semester = session['semester'] ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.book_outlined,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subjectName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        teacherName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: secondaryTextColor,
                        ),
                      ),
                      if (program.toString().isNotEmpty || semester.toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            "${program.toString()} • Sem ${semester.toString()}",
                            style: TextStyle(
                              fontSize: 11,
                              color: secondaryTextColor.withOpacity(0.8),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
