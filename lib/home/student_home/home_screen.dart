import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:classlens/global/global.dart';
import 'student_colors.dart';
import 'student_dashboard.dart';
import 'student_schedule.dart';
import 'attendance_history.dart';
import 'student_profile.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _selectedIndex = 0;
  List<Widget> _pages = [];
  bool _isLoading = true;
  String _studentName = '';
  String _studentPrn = '';
  int _studentId = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final studentName = await getStudentName();
    final studentId = await getStudentID();
    final prn = await getStudentPRN();

    if (mounted) {
      setState(() {
        _studentName = studentName;
        _studentPrn = prn;
        _studentId = studentId;
        _pages = [
          StudentDashboard(
            studentName: studentName,
            prn: prn,
            studentId: studentId,
          ),
          StudentScheduleTab(
            studentId: studentId,
          ),
          const AttendanceHistoryTab(),
        ];
        _isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _handleSystemBack() {
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
    }
  }

  String getInitials(String name) {
    if (name.isEmpty) return '?';
    List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  Widget _buildGlobalAppBar(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final initials = getInitials(_studentName);

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
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Welcome back,",
                        style: TextStyle(color: secondaryTextColor, fontSize: 12),
                      ),
                      Text(
                        _studentName,
                        style: const TextStyle(
                          color: primaryTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_outlined, color: primaryTextColor),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StudentProfileTab(
                              studentName: _studentName,
                              prn: _studentPrn,
                            ),
                          ),
                        ).then((_) {
                          _loadUserData();
                        });
                      },
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: accentColor,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: primaryBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _handleSystemBack();
        }
      },
      child: Scaffold(
        backgroundColor: primaryBackgroundColor,
        body: Stack(
          children: [
            IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
            _buildGlobalAppBar(context),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today_rounded), label: 'Schedule'),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: accentColor,
          unselectedItemColor: secondaryTextColor,
          backgroundColor: cardBackgroundColor,
          elevation: 10,
          type: BottomNavigationBarType.fixed,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
