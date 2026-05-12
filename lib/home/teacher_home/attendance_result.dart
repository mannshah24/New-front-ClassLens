import 'package:classlens/page_animations/slide_animation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data_models/class_session_data.dart';
import '../../global/global.dart';
import 'class_session_attendance.dart';


const Color primaryTextColor = Color(0xFF1A2533);
const Color secondaryTextColor = Color(0xFF6C757D);
const Color cardBackgroundColor = Colors.white;
const Color successColor = Color(0xFF43A047);
const Color attentionColor = Color(0xFFE53935);

class AttendanceResult extends StatefulWidget {
  const AttendanceResult({super.key});

  @override
  State<AttendanceResult> createState() => _AttendanceResult();
}

class _AttendanceResult extends State<AttendanceResult> {
  List<SessionStats> sessionStatsList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  void _loadData() {
    final stats = classSessionBox.values.cast<SessionStats>().toList();


    stats.sort((a, b) {
      if (a.date == null && b.date == null) return 0;
      if (a.date == null) return 1;
      if (b.date == null) return -1;
      return b.date.compareTo(a.date);
    });

    // Update the state
    setState(() {
      sessionStatsList = stats;
    });
  }

  Future<void> _onRefresh() async {

    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (sessionStatsList.isEmpty) {

      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: Stack(
          children: [
            ListView(),
            const Center(
              child: Text(
                'No attendance results found.',
                style: TextStyle(fontSize: 18, color: secondaryTextColor),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(

        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        itemCount: sessionStatsList.length,
        itemBuilder: (context, index) {
          final stats = sessionStatsList[index];

          return _buildStatCard(
            stats: stats,
            onTap: () {
              print("Tapped on session ID: ${stats.classSessionId}");
              navigatorWithAnimation(context, ClassSessionAttendance(sessionID: stats.classSessionId,subjectName: stats.subject,));
            },
          );
        },
      ),
    );
  }

  Widget _buildStatCard({required SessionStats stats, required VoidCallback onTap}) {

    final int presentCount = stats.presentCount ;
    final int absentCount = stats.absentCount;
    final int total = presentCount + absentCount;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: cardBackgroundColor,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stats.subject,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(

                stats.date == null
                    ? 'No Date Available'
                    : DateFormat.yMMMd().format(stats.date!),
                style: const TextStyle(
                  fontSize: 13,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem("Present", presentCount, successColor),
                  _buildStatItem("Absent", absentCount, attentionColor),
                  _buildStatItem("Total", total, primaryTextColor),
                ],
              ),

              if (total > 0) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: presentCount / total,
                    backgroundColor: attentionColor.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(successColor),
                    minHeight: 8,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: secondaryTextColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}