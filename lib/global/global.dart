import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:classlens/api/api.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:classlens/api/api.dart';

late String userName;
late int userID;
late Box classSessionBox;

// Keys for SharedPreferences
const String _keyRememberMe = "rememberMe";
const String _keyUserType = "userType"; // "student" or "teacher"

// Teacher keys
const String _keyTeacherName = "teacherName";
const String _keyTeacherID = "teacherID";

// Student keys
const String _keyStudentName = "studentName";
const String _keyStudentID = "studentID";
const String _keyStudentPRN = "studentPRN";

// ==================== Common ====================
// Keys for SharedPreferences
const String _keyRememberMe = "rememberMe";
const String _keyUserType = "userType"; // "student" or "teacher"

// Teacher keys
const String _keyTeacherName = "teacherName";
const String _keyTeacherID = "teacherID";

// Student keys
const String _keyStudentName = "studentName";
const String _keyStudentID = "studentID";
const String _keyStudentPRN = "studentPRN";

// ==================== Common ====================

Future<bool> getRememberMe() async {
  SharedPreferences pref = await SharedPreferences.getInstance();
  return pref.getBool(_keyRememberMe) ?? false;
  return pref.getBool(_keyRememberMe) ?? false;
}

Future<String?> getUserType() async {
  SharedPreferences pref = await SharedPreferences.getInstance();
  return pref.getString(_keyUserType);
}

Future<void> clearUserSession() async {
  SharedPreferences pref = await SharedPreferences.getInstance();
  await pref.clear();
}

// ==================== Teacher ====================

Future<String?> getUserType() async {
  SharedPreferences pref = await SharedPreferences.getInstance();
  return pref.getString(_keyUserType);
}

Future<void> clearUserSession() async {
  SharedPreferences pref = await SharedPreferences.getInstance();
  await pref.clear();
}

// ==================== Teacher ====================

Future<String> getUserName() async {
  SharedPreferences pref = await SharedPreferences.getInstance();
  return pref.getString(_keyTeacherName) ?? "Teacher";
  return pref.getString(_keyTeacherName) ?? "Teacher";
}

Future<int?> getUserID() async {
  SharedPreferences pref = await SharedPreferences.getInstance();
  return pref.getInt(_keyTeacherID);
}

Future<void> saveTeacherSession({
  required bool rememberMe,
  required String teacherName,
  required int teacherID,
}) async {
  SharedPreferences pref = await SharedPreferences.getInstance();
  await pref.setBool(_keyRememberMe, rememberMe);
  await pref.setString(_keyUserType, "teacher");
  await pref.setString(_keyTeacherName, teacherName);
  await pref.setInt(_keyTeacherID, teacherID);

  userName = teacherName;
  userID = teacherID;
}

// ==================== Student ====================

Future<String> getStudentName() async {
  SharedPreferences pref = await SharedPreferences.getInstance();
  return pref.getString(_keyStudentName) ?? "Student";
}

Future<int> getStudentID() async {
  SharedPreferences pref = await SharedPreferences.getInstance();
  return pref.getInt(_keyStudentID) ?? 0;
}

Future<String> getStudentPRN() async {
  SharedPreferences pref = await SharedPreferences.getInstance();
  return pref.getString(_keyStudentPRN) ?? "";
}

Future<void> saveStudentSession({
  required bool rememberMe,
  required String studentName,
  required int studentID,
  required String prn,
}) async {
  SharedPreferences pref = await SharedPreferences.getInstance();
  await pref.setBool(_keyRememberMe, rememberMe);
  await pref.setString(_keyUserType, "student");
  await pref.setString(_keyStudentName, studentName);
  await pref.setInt(_keyStudentID, studentID);
  await pref.setString(_keyStudentPRN, prn);
}

// ==================== FCM Notification Token ====================

/// Registers the FCM token for a student after login
Future<void> registerFCMToken(int studentId) async {
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permission for notifications
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await messaging.getToken();

      if (token != null) {
        print("FCM Token: $token");
        await ApiServices.updateNotificationToken(
          studentId: studentId,
          notificationToken: token,
        );
      }

      // Listen for token refresh
      messaging.onTokenRefresh.listen((newToken) async {
        print("FCM Token refreshed: $newToken");
        final currentStudentId = await getStudentID();
        if (currentStudentId > 0) {
          await ApiServices.updateNotificationToken(
            studentId: currentStudentId,
            notificationToken: newToken,
          );
        }
      });
    } else {
      print("Notification permission denied");
    }
  } catch (e) {
    print("Error registering FCM token: $e");
  }
}

/// Removes the FCM token for a student on logout
Future<void> unregisterFCMToken() async {
  try {
    final studentId = await getStudentID();
    if (studentId > 0) {
      await ApiServices.removeNotificationToken(studentId: studentId);
    }
  } catch (e) {
    print("Error unregistering FCM token: $e");
  }
}