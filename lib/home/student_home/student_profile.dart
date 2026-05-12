import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:classlens/global/global.dart';
import 'package:classlens/login/login_selector.dart' show LoginSelector;
import 'student_colors.dart';
import 'face_update_screen.dart';

class StudentProfileTab extends StatelessWidget {
  final String studentName;
  final String prn;

  const StudentProfileTab({super.key, required this.studentName, required this.prn});

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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(width: double.infinity, height: double.infinity, color: primaryBackgroundColor),
          // Background Circles
          Positioned(top: -screenSize.width * 0.3, left: -screenSize.width * 0.3, child: CircleAvatar(radius: screenSize.width * 0.45, backgroundColor: circleColor1.withOpacity(0.5))),
          Positioned(bottom: -screenSize.width * 0.4, right: -screenSize.width * 0.4, child: CircleAvatar(radius: screenSize.width * 0.5, backgroundColor: circleColor2.withOpacity(0.5))),

          SingleChildScrollView(
            padding: EdgeInsets.only(top: kToolbarHeight + topPadding + 20, left: 16, right: 16, bottom: 20),
            child: _buildProfileCard(context),
          ),

          // AppBar
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
  }

  Widget _buildProfileCard(BuildContext context) {
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
          _buildCardHeader(context),
          const SizedBox(height: 66), // 50 (radius) + 16 padding
          Text(studentName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryTextColor)),
          const SizedBox(height: 4),
          const Text("B.E. Computer Science & Engineering", style: TextStyle(fontSize: 16, color: secondaryTextColor)),

          const SizedBox(height: 20),
          _buildStatsRow(),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Divider(color: secondaryTextColor.withOpacity(0.2)),
          ),

          _buildDetailRow(icon: Icons.numbers, title: "PRN", value: prn),
          _buildDetailRow(icon: Icons.calendar_month, title: "Semester", value: "7th (4th Year)"),
          _buildDetailRow(icon: Icons.email_outlined, title: "Email", value: "vyomshah509@gmail.com"),

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

  Widget _buildCardHeader(BuildContext context) {
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
                  child: Text(studentName[0], style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: primaryTextColor)),
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

  Widget _buildStatsRow() {
    // Vyom's actual stats: 14 present out of 24 total records
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem("Attendance", "58%"),
          Container(width: 1, height: 40, color: secondaryTextColor.withOpacity(0.2)),
          _buildStatItem("Total Classes", "24"),
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
