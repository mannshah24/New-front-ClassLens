import 'dart:ui';

import 'package:classlens/api/api.dart';
import 'package:classlens/global/global.dart';
import 'package:classlens/login/login_selector.dart' show LoginSelector;
import 'package:flutter/material.dart';

import 'face_update_screen.dart';
import 'student_colors.dart';

class StudentProfileTab extends StatefulWidget {
  final String studentName;
  final String prn;

  const StudentProfileTab({super.key, required this.studentName, required this.prn});

  @override
  State<StudentProfileTab> createState() => _StudentProfileTabState();
}

class _StudentProfileTabState extends State<StudentProfileTab> {
  late final Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfileData();
  }

  Future<Map<String, dynamic>> _loadProfileData() async {
    final studentId = await getStudentID();
    if (studentId <= 0) {
      throw Exception('Student session not found');
    }

    final result = await ApiServices.getStudentDashboard(studentId: studentId);
    if (result['status'] != true) {
      throw Exception(result['message'] ?? 'Failed to load student profile');
    }

    final data = Map<String, dynamic>.from(result['data'] as Map);
    data['student_id'] = studentId;
    return data;
  }

  String _displayName(Map<String, dynamic> data) {
    final liveName = data['student_name']?.toString().trim() ?? '';
    return liveName.isNotEmpty ? liveName : widget.studentName;
  }

  String _displayPrn(Map<String, dynamic> data) {
    final livePrn = data['prn']?.toString().trim() ?? '';
    return livePrn.isNotEmpty ? livePrn : widget.prn;
  }

  int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double? _overallAttendance(Map<String, dynamic> data, List<Map<String, dynamic>> subjects) {
    final rawAttendance = data['overall_attendance'];
    if (rawAttendance is num) {
      return rawAttendance.toDouble();
    }

    final parsed = double.tryParse(rawAttendance?.toString() ?? '');
    if (parsed != null) {
      return parsed;
    }

    final attended = subjects.fold<int>(0, (sum, item) => sum + _asInt(item['attended'] ?? item['present_count']));
    final total = subjects.fold<int>(0, (sum, item) => sum + _asInt(item['total'] ?? item['total_classes']));
    if (total == 0) {
      return null;
    }
    return (attended / total) * 100;
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: attentionColor),
            onPressed: () async {
              Navigator.pop(context);
              // Remove FCM token from server before clearing session
              await unregisterFCMToken();
              // Clear all saved session data
              await clearUserSession();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginSelector()),
                    (route) => false,
              );
            },
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;

    return FutureBuilder<Map<String, dynamic>>(
      future: _profileFuture,
      builder: (context, snapshot) {
        final data = snapshot.data ?? const <String, dynamic>{};
        final studentName = _displayName(data);
        final prn = _displayPrn(data);
        final subjects = List<Map<String, dynamic>>.from(data['subjects'] ?? const []);
        final recentActivity = List<Map<String, dynamic>>.from(data['recent_activity'] ?? const []);
        final overallAttendance = _overallAttendance(data, subjects);
        final attended = subjects.fold<int>(0, (sum, item) => sum + _asInt(item['attended'] ?? item['present_count']));
        final totalClasses = subjects.fold<int>(0, (sum, item) => sum + _asInt(item['total'] ?? item['total_classes']));
        final studentId = data['student_id']?.toString() ?? '';
        final email = data['email']?.toString() ?? '';
        final year = data['year']?.toString() ?? '';
        final departmentName = data['department_name']?.toString() ?? '';
        final semester = data['semester']?.toString() ?? '';

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Container(width: double.infinity, height: double.infinity, color: primaryBackgroundColor),
              Positioned(top: -screenSize.width * 0.3, left: -screenSize.width * 0.3, child: CircleAvatar(radius: screenSize.width * 0.45, backgroundColor: circleColor1.withOpacity(0.5))),
              Positioned(bottom: -screenSize.width * 0.4, right: -screenSize.width * 0.4, child: CircleAvatar(radius: screenSize.width * 0.5, backgroundColor: circleColor2.withOpacity(0.5))),

              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator(color: accentColor))
              else if (snapshot.hasError)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Unable to load live profile data.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: primaryTextColor.withOpacity(0.85), fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: secondaryTextColor, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SingleChildScrollView(
                  padding: EdgeInsets.only(top: kToolbarHeight + topPadding + 20, left: 16, right: 16, bottom: 20),
                  child: _buildProfileCard(
                    context,
                    studentName: studentName,
                    prn: prn,
                    studentId: studentId,
                    overallAttendance: overallAttendance,
                    attended: attended,
                    totalClasses: totalClasses,
                    subjectsCount: subjects.length,
                    recentActivityCount: recentActivity.length,
                    email: email,
                    year: year,
                    departmentName: departmentName,
                    semester: semester,
                  ),
                ),

              Positioned(
                top: 0, left: 0, right: 0,
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
                          const Text('Profile', style: TextStyle(color: primaryTextColor, fontSize: 20, fontWeight: FontWeight.w500)),
                          IconButton(icon: const Icon(Icons.logout, color: attentionColor), onPressed: () => _showLogoutDialog(context)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileCard(
    BuildContext context, {
    required String studentName,
    required String prn,
    required String studentId,
    required double? overallAttendance,
    required int attended,
    required int totalClasses,
    required int subjectsCount,
    required int recentActivityCount,
    required String email,
    required String year,
    required String departmentName,
    required String semester,
  }) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCardHeader(context, studentName),
          const SizedBox(height: 66), // 50 (radius) + 16 padding
          Text(studentName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryTextColor)),
          const SizedBox(height: 4),
          const Text("Live student profile", style: TextStyle(fontSize: 16, color: secondaryTextColor)),

          const SizedBox(height: 20),
          _buildStatsRow(overallAttendance, subjectsCount, recentActivityCount),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Divider(color: secondaryTextColor.withOpacity(0.2)),
          ),

          _buildDetailRow(icon: Icons.numbers, title: "PRN", value: prn),
          _buildDetailRow(icon: Icons.badge_outlined, title: "Student ID", value: studentId.isEmpty ? 'N/A' : studentId),
          _buildDetailRow(icon: Icons.email_outlined, title: "Email", value: email.isEmpty ? 'N/A' : email),
          _buildDetailRow(icon: Icons.school_outlined, title: "Department", value: departmentName.isEmpty ? 'N/A' : departmentName),
          _buildDetailRow(icon: Icons.calendar_month, title: "Year", value: year.isEmpty ? 'N/A' : year),
          _buildDetailRow(icon: Icons.menu_book_rounded, title: "Semester", value: semester.isEmpty ? 'N/A' : semester),
          _buildDetailRow(icon: Icons.fact_check_outlined, title: "Classes Attended", value: attended.toString()),
          _buildDetailRow(icon: Icons.event_note, title: "Total Classes", value: totalClasses.toString()),

          const SizedBox(height: 16),

          // Face Update Button
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.face_retouching_natural),
                label: const Text("Update Face ID"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const StudentFaceUpdateScreen()));
                },
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCardHeader(BuildContext context, String studentName) {
    final initial = studentName.trim().isNotEmpty ? studentName.trim()[0].toUpperCase() : '?';

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          height: 120,
          decoration: const BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24.0), topRight: Radius.circular(24.0)),
            gradient: LinearGradient(colors: [accentColor, Color(0xFF6E8CF3)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
        ),
        Positioned(
          top: 120 - 50,
          child: Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 46,
                  backgroundColor: primaryBackgroundColor,
                  child: Text(initial, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: primaryTextColor)),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: primaryTextColor, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(double? overallAttendance, int subjectsCount, int recentActivityCount) {
    final attendanceLabel = overallAttendance == null ? 'N/A' : '${overallAttendance.toStringAsFixed(1)}%';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem("Attendance", attendanceLabel),
          Container(width: 1, height: 40, color: secondaryTextColor.withOpacity(0.2)),
          _buildStatItem("Subjects", subjectsCount.toString()),
          Container(width: 1, height: 40, color: secondaryTextColor.withOpacity(0.2)),
          _buildStatItem("Recent", recentActivityCount.toString()),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryTextColor)),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 14, color: secondaryTextColor)),
      ],
    );
  }

  Widget _buildDetailRow({required IconData icon, required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: accentColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, color: secondaryTextColor)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: primaryTextColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
