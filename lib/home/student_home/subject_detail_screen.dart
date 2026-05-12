import 'package:classlens/api/api.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'student_colors.dart';

class SubjectDetailScreen extends StatefulWidget {
  final Map<String, dynamic> subject;

  const SubjectDetailScreen({super.key, required this.subject});

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value == null) {
      return null;
    }
    return int.tryParse(value.toString());
  }

  Future<void> _loadHistory() async {
    final subjectId = _asInt(widget.subject['id']);
    if (subjectId == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    final history = await ApiServices.getStudentSubjectAttendance(
      subjectId: subjectId,
      divisionId: _asInt(widget.subject['division_id'] ?? widget.subject['divisionId']),
      year: _asInt(widget.subject['year']),
      semester: _asInt(widget.subject['semester']),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _history = history;
      _isLoading = false;
    });
  }

  String _attendanceLabel(dynamic statusValue) {
    if (statusValue is bool) {
      return statusValue ? 'Present' : 'Absent';
    }

    final text = statusValue?.toString() ?? '';
    if (text.isEmpty) {
      return 'Unknown';
    }

    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectName = widget.subject['name']?.toString() ?? 'Subject Details';
    final teacherName = widget.subject['teacher']?.toString() ?? 'Teacher unavailable';
    final total = widget.subject['total'] ?? widget.subject['total_classes'] ?? 0;
    final attended = widget.subject['attended'] ?? widget.subject['present_count'] ?? 0;
    final percentage = widget.subject['percentage'] ?? 0;

    return Scaffold(
      backgroundColor: primaryBackgroundColor,
      appBar: AppBar(
        title: Text(
          subjectName,
          style: const TextStyle(
            color: primaryTextColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryTextColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6E8CF3), accentColor]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDetailStat('Total', '$total'),
                  Container(width: 1, height: 40, color: Colors.white30),
                  _buildDetailStat('Attended', '$attended'),
                  Container(width: 1, height: 40, color: Colors.white30),
                  _buildDetailStat('Percentage', '${percentage is num ? percentage.toInt() : int.tryParse(percentage.toString()) ?? 0}%'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.history, color: secondaryTextColor),
                const SizedBox(width: 8),
                const Text(
                  'Attendance Log',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryTextColor),
                ),
                const Spacer(),
                Text(
                  'Teacher: $teacherName',
                  style: const TextStyle(fontSize: 12, color: secondaryTextColor),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(),
              )
            else if (_history.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Detailed attendance history is not available for this subject yet.',
                  style: TextStyle(color: secondaryTextColor),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final session = _history[index];
                  final statusText = _attendanceLabel(session['status']);
                  final isPresent = statusText == 'Present';
                  final date = _parseDate(session['date'] ?? session['marked_at'] ?? session['class_datetime']) ?? DateTime.now();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          DateFormat.yMMMd().format(date),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: primaryTextColor),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isPresent ? successColor : attentionColor).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: isPresent ? successColor : attentionColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      ],
                    ),
                  );
                },
              )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
