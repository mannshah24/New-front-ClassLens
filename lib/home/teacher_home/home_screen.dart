import 'dart:ui';
import 'package:classlens/api/api.dart';
import 'package:classlens/global/providers/connectivity_provider.dart';
import 'package:classlens/home/teacher_home/attendance_result.dart';
import 'package:classlens/home/teacher_home/teacher_profile.dart';
import 'package:classlens/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:classlens/login/login_selector.dart';
import 'package:classlens/global/global.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:classlens/home/teacher_home/take_attendance.dart';
import '../../data_models/class_session_data.dart';
import '../../data_models/notification_hive_model.dart';
import '../../global/providers/task_manager_provider.dart';
import '../../page_animations/slide_animation.dart';
import 'package:classlens/home/teacher_home/widgets/notification_icon.dart';
import 'package:classlens/home/teacher_home/students_percentage_status.dart';
import 'package:connectivity_plus/connectivity_plus.dart';


const Color primaryBackgroundColor = Color(0xFFF0F4F8);
const Color cardBackgroundColor = Colors.white;
const Color primaryTextColor = Color(0xFF1A2533);
const Color secondaryTextColor = Color(0xFF6C757D);
const Color accentColor = Color(0xFF4A90E2);
const Color attentionColor = Color(0xFFE53935); // For low attendance
const Color warningColor = Color(0xFFFDD835); // For medium attendance
const Color successColor = Color(0xFF43A047); // For high attendance

const Color circleColor1 = Color.fromARGB(255, 178, 218, 255);
const Color circleColor2 = Color.fromARGB(255, 201, 247, 222);

class Home extends ConsumerStatefulWidget {
  final String? teacherName;
  final int teacherID;
  const Home({super.key, this.teacherName, required this.teacherID});

  @override
  ConsumerState<Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {
  int _selectedIndex = 0;
  String? _displayTeacherName;


  late final List<Widget> _pages;

  @override
  void initState(){
    super.initState();
    requestNotificationPermissions();
    _displayTeacherName = widget.teacherName ?? userName;
    _loadTeacherProfileName();

    _pages = <Widget>[
      SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TakeAttendanceCard(onPressed: _requestCameraPermission,),
            const SizedBox(height: 24),
            RecentActivitySection(teacherID: widget.teacherID),
            const SizedBox(height: 24),
            const MyClassesSection(),
            const SizedBox(height: 20),
          ],
        ),
      ),

      //page 1 student page
      StudentsPercentageStatus(teacherName: widget.teacherName,teacherID: widget.teacherID,),

      //page 2
      AttendanceResult(teacherID: widget.teacherID),
    ];
  }

  Future<void> _loadTeacherProfileName() async {
    try {
      final profile = await ApiServices.getTeacherProfile(teacherID: widget.teacherID);
      if (!mounted) {
        return;
      }

      if (profile.name.isNotEmpty) {
        setState(() {
          _displayTeacherName = profile.name;
        });
      }
    } catch (e) {
      print("Failed to refresh teacher profile name: $e");
    }
  }
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

  }

  void _handleSystemBack() {
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          icon: const Icon(Icons.logout_rounded, color: attentionColor, size: 40),
          title: const Text(
            'Confirm Logout',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, color: primaryTextColor),
          ),
          content: const Text(
            'Are you sure you want to log out?',
            textAlign: TextAlign.center,
            style: TextStyle(color: secondaryTextColor),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.only(bottom: 20.0, left: 20.0, right: 20.0),
          actions: <Widget>[
            // Cancel Button
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: secondaryTextColor, fontSize: 16)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            const SizedBox(width: 8),
            // Logout Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: attentionColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Logout', style: TextStyle(fontSize: 16)),
              onPressed: () async {

                print("Logout confirmed");
                Navigator.of(dialogContext).pop();
                SharedPreferences pref = await SharedPreferences.getInstance();
                pref.setBool("rememberMe", false);
                pref.remove("teacherName");
                pref.remove("teacherID");
                final notificationsBox = Hive.box<NotificationHiveModel>('notifications');
                final sessionsBox = Hive.box<SessionStats>('classSessionBox');

                await notificationsBox.clear();
                await sessionsBox.clear();

                print("Cleared all user-specific Hive boxes.");
                Navigator.of(context).pop();
                Navigator.push(context, MaterialPageRoute(builder: (context)=>const LoginSelector()));
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();

    if(status.isGranted && mounted){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Camera permission granted")));
      final result = await navigatorWithAnimation<String>(context,AttendanceUploadScreen());
      if(result!=null && mounted){
            if(result.startsWith("Error")){
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result), backgroundColor: Colors.red),
              );
            }
            else{
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Attendance submitted successfully!"), backgroundColor: Colors.green),
              );
              final taskID = result;

              // start notification tracking with taskID
              ref.read(taskManagerProvider.notifier).addTask(taskID);

            }
      }
    }
    else if(status.isDenied && mounted){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Camera permission denied")));

    }
    else if(status.isPermanentlyDenied && mounted){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Camera permission denied")));

    }
  }

  Future<void> requestNotificationPermissions() async{
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation=flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();
  }

  Future<void> showNotification() async{
    const AndroidNotificationDetails androidNotificationDetails=AndroidNotificationDetails(
        "Attendance Result",
        "Attendance Status",
      importance: Importance.max,
      priority: Priority.high
    );

    WindowsNotificationDetails windowsNotificationDetails=WindowsNotificationDetails();

    final NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        windows: windowsNotificationDetails
    );

    await flutterLocalNotificationsPlugin.show(0, "Attendance Result", "Your attendance has been evaluated", notificationDetails);

  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final screenSize = MediaQuery.of(context).size;

    final connectivity = ref.watch(connectivityStreamProvider);
    final tasks = ref.watch(taskManagerProvider);

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _handleSystemBack();
        }
      },
      child: Scaffold(
        backgroundColor: primaryBackgroundColor,
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            ref.read(taskManagerProvider.notifier).deleteAllNotification();
          }
        ),

        body: Stack(
          fit: StackFit.expand,
          children: [

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

          Padding(
            padding: EdgeInsets.only(top: kToolbarHeight + topPadding),
            child:connectivity.when(
                data: (statusList){

                  if(statusList.contains(ConnectivityResult.none)){
                    return _buildOfflineUI();
                  }else{
                   return IndexedStack(
                     index: _selectedIndex,
                     children: _pages,
                   );
                  }
                },
                error: (err,track){
                  return IndexedStack(
                    index: _selectedIndex,
                    children: _pages,
                  );
                },
                loading: (){
                  return IndexedStack(
                    index: _selectedIndex,
                    children: _pages,
                  );
                }
            ),
          ),

          _buildPersistentAppBar(),
          ],
        ),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  Widget _buildPersistentAppBar() {

    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(

            padding: EdgeInsets.only(
              top: topPadding,
              left: 16.0,
              right: 16.0,
            ),
            height: kToolbarHeight + topPadding,
            color: Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _displayTeacherName ?? widget.teacherName ?? userName,
                      style: const TextStyle(
                        color: primaryTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: const NotificationIcon(),
                ),
                PopupMenuButton<String>(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13.0),
                  ),
                  color: cardBackgroundColor,
                  elevation: 8,
                  onSelected: (value) {
                    if (value == 'logout') {
                      _showLogoutDialog(context);
                    }
                    if (value == 'profile') {
                      navigatorWithAnimation(context, UserProfile(teacherID: widget.teacherID));
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'profile',
                      child: ListTile(
                        leading: Icon(Icons.person_outline, color: secondaryTextColor),
                        title: Text('Profile', style: TextStyle(color: primaryTextColor)),
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: ListTile(
                        leading: Icon(Icons.logout, color: attentionColor),
                        title: Text('Logout', style: TextStyle(color: attentionColor)),
                      ),
                    ),
                  ],
                  child: const CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: accentColor, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBar _buildBottomNavBar() {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home_filled),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Students',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.fact_check_outlined),
          label: 'Attendance',
        ),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: accentColor,
      unselectedItemColor: secondaryTextColor,
      backgroundColor: cardBackgroundColor,
      elevation: 10,
      onTap: _onItemTapped,
    );
  }

  Widget _buildOfflineUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/no_internet_connection.json',
              height: 150,
            ),
            const SizedBox(height: 24),
            const Text(
              'You Are Offline',
              style: TextStyle(
                color: primaryTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your network connection.',
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class TakeAttendanceCard extends StatelessWidget {
  final VoidCallback onPressed;
  const TakeAttendanceCard({super.key,required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.camera_alt_outlined, size: 50, color: accentColor),
          const SizedBox(height: 12),
          const Text(
            "Ready to start your class?",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Tap below to begin the AI attendance scan.",
            textAlign: TextAlign.center,
            style: TextStyle(color: secondaryTextColor, fontSize: 14),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.camera),
            label: const Text('Take Attendance'),
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }
}

class RecentActivitySection extends StatefulWidget {
  final int teacherID;

  const RecentActivitySection({super.key, required this.teacherID});

  @override
  State<RecentActivitySection> createState() => _RecentActivitySectionState();
}

class _RecentActivitySectionState extends State<RecentActivitySection> {
  List<_RecentActivityItem> recentStats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentActivity();
  }

  Future<void> _loadRecentActivity() async {
    setState(() {
      _isLoading = true;
    });

    final remoteSessions = await ApiServices.getTeacherClassSessions(
      teacherID: widget.teacherID,
      limit: 10,
    );

    if (remoteSessions.isNotEmpty) {
      final parsed = remoteSessions
          .map(_mapRemoteSession)
          .whereType<_RecentActivityItem>()
          .toList();

      parsed.sort((a, b) => b.stats.date.compareTo(a.stats.date));
      _syncRemoteToHive(parsed);

      if (mounted) {
        setState(() {
          recentStats = parsed.take(2).toList();
          _isLoading = false;
        });
      }
      return;
    }

    final localStats = classSessionBox.values.cast<SessionStats>().toList();
    localStats.sort((a, b) => b.date.compareTo(a.date));

    if (mounted) {
      setState(() {
        recentStats = localStats
            .take(2)
            .map((stats) => _RecentActivityItem(stats: stats))
            .toList();
        _isLoading = false;
      });
    }
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

  _RecentActivityItem? _mapRemoteSession(Map<String, dynamic> item) {
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

    return _RecentActivityItem(stats: stats, divisionName: divisionName);
  }

  void _syncRemoteToHive(List<_RecentActivityItem> sessions) {
    for (final item in sessions) {
      classSessionBox.put(item.stats.classSessionId, item.stats);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Recent Activity",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor),
            ),

            IconButton(
              icon: const Icon(Icons.refresh, color: secondaryTextColor),
              onPressed: () {
                _loadRecentActivity();
              },
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          )
        else if (recentStats.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: cardBackgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                "No recent activity found.",
                style: TextStyle(color: secondaryTextColor, fontSize: 14),
              ),
            ),
          )
        else
          Column(
            children: [
              for (int i = 0; i < recentStats.length; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: i == recentStats.length - 1 ? 0 : 10),
                  child: _buildActivityItemFromStats(recentStats[i]),
                ),
            ],
          ),
      ],
    );
  }
  Widget _buildActivityItemFromStats(_RecentActivityItem item) {

    final stats = item.stats;

    final total = stats.presentCount + stats.absentCount;
    final percentage = (total == 0) ? 0.0 : (stats.presentCount / total) * 100;

    final Color color;
    if (percentage >= 75) {
      color = successColor;
    } else if (percentage >= 50) {
      color = warningColor;
    } else {
      color = attentionColor;
    }


    final String dateString = (stats.date == null)
      ? "No Date"
      : DateFormat.yMMMd().add_jm().format(stats.date);

    final subjectTitle = (item.divisionName != null && item.divisionName!.trim().isNotEmpty)
        ? '${stats.subject} (${item.divisionName})'
        : stats.subject;

    return _buildActivityItem(
      subjectTitle,
      dateString,
      percentage.toInt(),
      color,
    );
  }


  Widget _buildActivityItem(
      String title, String subtitle, int percentage, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(Icons.check_circle_outline, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: primaryTextColor)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        color: secondaryTextColor, fontSize: 12)),
              ],
            ),
          ),
          Text(
            "$percentage%",
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18, color: color),
          ),
        ],
      ),
    );
  }

}

class _RecentActivityItem {
  final SessionStats stats;
  final String? divisionName;

  const _RecentActivityItem({required this.stats, this.divisionName});
}

class MyClassesSection extends StatelessWidget {
  const MyClassesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recent News (MSU)",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryTextColor),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

