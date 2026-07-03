import 'package:classlens/page_animations/slide_animation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';
import '../../api/api.dart';
import '../../data_models/class_session_data.dart';
import '../../global/global.dart';
import '../../global/providers/task_manager_provider.dart';
import 'class_session_attendance.dart';


const Color primaryTextColor = Color(0xFF1A2533);
const Color secondaryTextColor = Color(0xFF6C757D);
const Color cardBackgroundColor = Colors.white;
const Color successColor = Color(0xFF43A047);
const Color attentionColor = Color(0xFFE53935);

class AttendanceResult extends ConsumerStatefulWidget {
  final int teacherID;

  const AttendanceResult({super.key, required this.teacherID});

  @override
  ConsumerState<AttendanceResult> createState() => _AttendanceResult();
}

class _AttendanceResult extends ConsumerState<AttendanceResult> {
  List<_AttendanceSessionItem> sessionStatsList = [];
  bool _isLoading = true;
  StreamSubscription<RemoteMessage>? _fcmSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupFCMListener();
  }

  @override
  void dispose() {
    _fcmSubscription?.cancel();
    super.dispose();
  }

  void _setupFCMListener() {
    _fcmSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data['type'] == 'teacher_attendance') {
        print("AttendanceResult FCM: Refreshing history list.");
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final remoteSessions = await ApiServices.getTeacherClassSessions(
      teacherID: widget.teacherID,
    );

    if (remoteSessions.isNotEmpty) {
      final parsed = remoteSessions
          .map(_mapRemoteSession)
          .whereType<_AttendanceSessionItem>()
          .toList();
      parsed.sort((a, b) => b.stats.date.compareTo(a.stats.date));
      _syncRemoteToHive(parsed);

      if (mounted) {
        setState(() {
          sessionStatsList = parsed;
          _isLoading = false;
        });
      }
      return;
    }

    final localStats = classSessionBox.values.cast<SessionStats>().toList();
    localStats.sort((a, b) => b.date.compareTo(a.date));

    if (mounted) {
      setState(() {
        sessionStatsList = localStats
            .map((stats) => _AttendanceSessionItem(stats: stats))
            .toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {

    await _loadData();
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  DateTime _asDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
    }
    return DateTime.now();
  }

  _AttendanceSessionItem? _mapRemoteSession(Map<String, dynamic> item) {
    final sessionId = _asInt(item['class_session_id'] ?? item['session_id'] ?? item['id']);
    if (sessionId == null) return null;

    final subject = (item['subject_name'] ?? item['subject'] ?? item['subject_title'])?.toString();
    if (subject == null || subject.trim().isEmpty) return null;

    final present = _asInt(item['present_count']) ?? 0;
    int absent = _asInt(item['absent_count']) ?? 0;
    final total = _asInt(item['total_count']);
    if (total != null && absent == 0 && total >= present) {
      absent = total - present;
    }

    final sessionDate = _asDateTime(
      item['class_datetime'] ?? item['marked_at'] ?? item['created_at'],
    );

    final divisionName = (item['division_name'] ??
            item['division'] ??
            item['division_label'])
        ?.toString();

    final stats = SessionStats()
      ..classSessionId = sessionId
      ..presentCount = present
      ..absentCount = absent
      ..subject = subject
      ..date = sessionDate;

    return _AttendanceSessionItem(stats: stats, divisionName: divisionName);
  }

  void _syncRemoteToHive(List<_AttendanceSessionItem> sessions) {
    for (final item in sessions) {
      classSessionBox.put(item.stats.classSessionId, item.stats);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: _isLoading
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 180),
                Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
              ],
            )
          : sessionStatsList.isEmpty
              ? Stack(
                  children: [
                    ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                    ),
                    const Center(
                      child: Text(
                        'No attendance results found.',
                        style: TextStyle(fontSize: 18, color: secondaryTextColor),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  itemCount: sessionStatsList.length,
                  itemBuilder: (context, index) {
                    final item = sessionStatsList[index];
                    final stat = item.stats;
                    final detailTitle = (item.divisionName != null && item.divisionName!.trim().isNotEmpty)
                        ? '${stat.subject} (${item.divisionName})'
                        : stat.subject;

                    return _buildStatCard(
                      session: item,
                      onTap: () {
                        print("Tapped on session ID: ${stat.classSessionId}");
                        navigatorWithAnimation(
                          context,
                          ClassSessionAttendance(
                            sessionID: stat.classSessionId,
                            subjectName: detailTitle,
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }

  Widget _buildStatCard({required _AttendanceSessionItem session, required VoidCallback onTap}) {

    final stats = session.stats;

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
              if (session.divisionName != null && session.divisionName!.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'Division: ${session.divisionName}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: secondaryTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(

                stats.date != null
                    ? DateFormat.yMMMd().add_jm().format(stats.date!)
                    : 'No Date Available',
                style: const TextStyle(
                  fontSize: 13,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 12),
              if (total == 0 && ref.watch(taskManagerProvider).any((task) {
                if (task.isCompleted) return false;
                final taskSub = task.subject?.trim().toLowerCase() ?? '';
                final sessSub = stats.subject.trim().toLowerCase();
                return taskSub.isNotEmpty && (taskSub == sessSub || sessSub.contains(taskSub) || taskSub.contains(sessSub));
              })) ...[
                Row(
                  children: const [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Processing AI Attendance...",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem("Present", presentCount, successColor),
                    _buildStatItem("Absent", absentCount, attentionColor),
                    _buildStatItem("Total", total, primaryTextColor),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0.0 : presentCount / total,
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

class _AttendanceSessionItem {
  final SessionStats stats;
  final String? divisionName;

  const _AttendanceSessionItem({required this.stats, this.divisionName});
}