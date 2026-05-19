import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:classlens/api/api.dart';
import 'student_colors.dart';
import 'subject_detail_screen.dart';

class StudentDashboard extends StatefulWidget {
  final String studentName;
  final String prn;
  final int studentId;

  const StudentDashboard({
    super.key,
    required this.studentName,
    required this.prn,
    required this.studentId,
  });

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  bool _isLoading = true;
  String? _errorMessage;
  double? _overallAttendance;
  int _classesAttended = 0;
  int _classesTotal = 0;
  List<Map<String, dynamic>> _mySubjects = [];
  List<Map<String, dynamic>> _recentActivity = [];
  String _displayStudentName = '';
  String _displayPrn = '';

  @override
  void initState() {
    super.initState();
    _displayStudentName = widget.studentName;
    _displayPrn = widget.prn;
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiServices.getStudentDashboard(
        studentId: widget.studentId,
      );

      if (result['status'] == true) {
        final data = result['data'];
        final subjects = List<Map<String, dynamic>>.from(
          data['subjects'] ?? data['attendance_by_subject'] ?? [],
        );

        final attended = subjects.fold<int>(0, (sum, item) {
          final value = item['attended'] ?? item['present_count'] ?? 0;
          return sum + (value is int ? value : int.tryParse(value.toString()) ?? 0);
        });

        final total = subjects.fold<int>(0, (sum, item) {
          final value = item['total'] ?? item['total_classes'] ?? 0;
          return sum + (value is int ? value : int.tryParse(value.toString()) ?? 0);
        });

        final rawOverall = data['overall_attendance'];
        final overall = rawOverall is num
            ? rawOverall.toDouble()
            : double.tryParse(rawOverall?.toString() ?? '');
        final liveStudentName = data['student_name']?.toString();
        final livePrn = data['prn']?.toString();

        setState(() {
          _mySubjects = subjects;
          _recentActivity = List<Map<String, dynamic>>.from(data['recent_activity'] ?? []);
          _overallAttendance = overall ?? (total > 0 ? (attended / total) * 100 : null);
          _classesAttended = attended;
          _classesTotal = total;
          _displayStudentName = liveStudentName?.isNotEmpty == true ? liveStudentName! : widget.studentName;
          _displayPrn = livePrn?.isNotEmpty == true ? livePrn! : widget.prn;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        // Background
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
          child: _buildBody(),
        ),

        // App Bar
        _buildPersistentAppBar(context, topPadding),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: accentColor),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: attentionColor.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(color: secondaryTextColor)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchDashboardData,
              style: ElevatedButton.styleFrom(backgroundColor: accentColor),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchDashboardData,
      color: accentColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
              _buildOverallSummaryCard(),
              const SizedBox(height: 20),
            const Text(
              "Attendance Overview",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryTextColor),
            ),
            const SizedBox(height: 4),
            const Text(
              "Tap a subject for detailed history",
              style: TextStyle(fontSize: 12, color: secondaryTextColor),
            ),
            const SizedBox(height: 12),

            if (_mySubjects.isEmpty)
              _buildEmptyState("No subjects enrolled")
            else
              ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _mySubjects.length,
                itemBuilder: (context, index) => _buildSubjectCard(context, _mySubjects[index]),
              ),

            const SizedBox(height: 24),
            const Text(
              "Recent Activity",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryTextColor),
            ),
            const SizedBox(height: 12),

            if (_recentActivity.isEmpty)
              _buildEmptyState("No recent activity")
            else
              _buildRecentActivityList(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: secondaryTextColor.withOpacity(0.3)),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: secondaryTextColor.withOpacity(0.5))),
        ],
      ),
    );
  }

  Widget _buildOverallSummaryCard() {
    final attendance = (_overallAttendance ?? 0).clamp(0, 100).toDouble();
    final statusColor = attendance >= 75
        ? successColor
        : (attendance >= 60 ? warningColor : attentionColor);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2533), Color(0xFF2C3E50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overall Attendance',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(
            _overallAttendance == null ? 'N/A' : '${attendance.toStringAsFixed(1)}%',
            style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: _overallAttendance == null ? 0 : attendance / 100,
              backgroundColor: Colors.white.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _classesTotal > 0
                ? '$_classesAttended / $_classesTotal classes attended'
                : 'No attendance records yet',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPersistentAppBar(BuildContext context, double topPadding) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            padding: EdgeInsets.only(top: topPadding, left: 16.0, right: 16.0),
            height: kToolbarHeight + topPadding,
            color: Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child:
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Welcome back,",
                      style: TextStyle(color: secondaryTextColor, fontSize: 12),
                    ),
                    SizedBox(child: Text(
                      _displayStudentName,
                      style: const TextStyle(
                        color: primaryTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    )),
                  ],
                )),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_outlined, color: primaryTextColor),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectCard(BuildContext context, Map<String, dynamic> subject) {
    final percentageValue = subject['percentage'];
    double percentage = percentageValue is num
      ? percentageValue.toDouble()
      : double.tryParse(percentageValue?.toString() ?? '0') ?? 0;
    Color statusColor = percentage >= 75
        ? successColor
        : (percentage >= 60 ? warningColor : attentionColor);
    final attendedValue = subject['attended'] ?? subject['present_count'] ?? 0;
    final totalValue = subject['total'] ?? subject['total_classes'] ?? 0;
    final attended = attendedValue is int ? attendedValue : int.tryParse(attendedValue.toString()) ?? 0;
    final total = totalValue is int ? totalValue : int.tryParse(totalValue.toString()) ?? 0;
    final teacher = subject['teacher']?.toString() ?? 'Assigned teacher not available';
    final missed = total > attended ? total - attended : 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubjectDetailScreen(subject: subject),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBackgroundColor,
          borderRadius: BorderRadius.circular(16.0),
          border: percentage < 75
              ? Border.all(color: statusColor.withOpacity(0.5), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: statusColor.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    strokeWidth: 4,
                  ),
                  Text(
                    "${percentage.toInt()}%",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject['name'] ?? 'Unknown Subject',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    teacher,
                    style: const TextStyle(fontSize: 12, color: secondaryTextColor),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "$attended/$total Sessions",
                    style: const TextStyle(fontSize: 12, color: secondaryTextColor),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 7,
                      value: total > 0 ? attended / total : 0,
                      backgroundColor: statusColor.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    missed > 0 ? '$missed classes missed' : 'Perfect attendance so far',
                    style: const TextStyle(fontSize: 11, color: secondaryTextColor),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: secondaryTextColor),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityList() {
    return Column(
      children: _recentActivity.map((activity) {
        String statusText = activity['status'] ?? 'Unknown';
        Color statusColor = statusText == "Present"
            ? successColor
            : (statusText == "Absent" ? attentionColor : warningColor);
        IconData icon = statusText == "Present"
            ? Icons.check_circle
            : (statusText == "Absent" ? Icons.cancel : Icons.hourglass_top);

        DateTime? date;
        try {
          date = DateTime.parse(activity['date']);
        } catch (_) {
          date = DateTime.now();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: cardBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Icon(icon, color: statusColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['subject'] ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      DateFormat.yMMMd().format(date),
                      style: const TextStyle(color: secondaryTextColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              )
            ],
          ),
        );
      }).toList(),
    );
  }
}