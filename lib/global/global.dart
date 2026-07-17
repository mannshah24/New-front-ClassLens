import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:classlens/api/api.dart';
import 'package:permission_handler/permission_handler.dart';

late String userName;
late int userID;
late Box classSessionBox;

const String _keyRememberMe = "rememberMe";
const String _keyUserType = "userType";
const String _keyTeacherName = "teacherName";
const String _keyTeacherID = "teacherID";
const String _keyStudentName = "studentName";
const String _keyStudentID = "studentID";
const String _keyStudentPRN = "studentPRN";
const String _keyStudentAccessToken = "studentAccessToken";

bool _isFCMTokenRefreshListenerStarted = false;

Future<bool> getRememberMe() async {
  final pref = await SharedPreferences.getInstance();
  return pref.getBool(_keyRememberMe) ?? false;
}

Future<String?> getUserType() async {
  final pref = await SharedPreferences.getInstance();
  return pref.getString(_keyUserType);
}

Future<void> clearUserSession() async {
  final pref = await SharedPreferences.getInstance();
  await pref.clear();
}

Future<String> getUserName() async {
  final pref = await SharedPreferences.getInstance();
  return pref.getString(_keyTeacherName) ?? "Teacher";
}

Future<int?> getUserID() async {
  final pref = await SharedPreferences.getInstance();
  return pref.getInt(_keyTeacherID);
}

Future<void> saveTeacherSession({
  required bool rememberMe,
  required String teacherName,
  required int teacherID,
}) async {
  final pref = await SharedPreferences.getInstance();
  await pref.setBool(_keyRememberMe, rememberMe);
  await pref.setString(_keyUserType, "teacher");
  await pref.setString(_keyTeacherName, teacherName);
  await pref.setInt(_keyTeacherID, teacherID);

  userName = teacherName;
  userID = teacherID;
}

Future<String> getStudentName() async {
  final pref = await SharedPreferences.getInstance();
  return pref.getString(_keyStudentName) ?? "Student";
}

Future<int> getStudentID() async {
  final pref = await SharedPreferences.getInstance();
  return pref.getInt(_keyStudentID) ?? 0;
}

Future<String> getStudentPRN() async {
  final pref = await SharedPreferences.getInstance();
  return pref.getString(_keyStudentPRN) ?? "";
}

Future<void> saveStudentSession({
  required bool rememberMe,
  required String studentName,
  required int studentID,
  required String prn,
  String? accessToken,
}) async {
  final pref = await SharedPreferences.getInstance();
  await pref.setBool(_keyRememberMe, rememberMe);
  await pref.setString(_keyUserType, "student");
  await pref.setString(_keyStudentName, studentName);
  await pref.setInt(_keyStudentID, studentID);
  await pref.setString(_keyStudentPRN, prn);

  if (accessToken != null && accessToken.trim().isNotEmpty) {
    await pref.setString(_keyStudentAccessToken, accessToken.trim());
  } else {
    await pref.remove(_keyStudentAccessToken);
  }
}

Future<String> getStudentAccessToken() async {
  final pref = await SharedPreferences.getInstance();
  return pref.getString(_keyStudentAccessToken) ?? "";
}

// Future<String?> _getFCMToken() async {
//   if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
//     return null;
//   }
//   try {
//     PermissionStatus status = await Permission.notification.request();
//     if (status.isGranted) {
//       await FirebaseMessaging.instance.requestPermission(
//         alert: true,
//         sound: true,
//         badge: true,
//       );
//       return await FirebaseMessaging.instance.getToken();
//     } else {
//       print("Notification permission is not granted: $status");
//     }
//   } catch (e) {
//     print("Error fetching FCM token: $e");
//   }
//   return null;
// }
Future<String?> _getFCMToken() async {
  if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
    return null;
  }

  try {
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print("Notification permission: ${settings.authorizationStatus}");

    String? token = await FirebaseMessaging.instance.getToken();

    print("FCM TOKEN = $token");

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      print("FCM TOKEN REFRESHED = $newToken");
    });

    return token;
  } catch (e) {
    print("FCM TOKEN ERROR: $e");
    return null;
  }
}

Future<void> registerFCMToken(int studentId) async {
  final token = await _getFCMToken();
  if (token != null) {
    await ApiServices.updateNotificationToken(
      studentId: studentId,
      notificationToken: token,
    );
  } else {
    print("FCM skipped/unavailable for student $studentId.");
  }
}

Future<void> unregisterFCMToken() async {
  final studentId = await getStudentID();
  if (studentId > 0 && !kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await ApiServices.removeNotificationToken(studentId: studentId);
  }
}

Future<void> registerTeacherFCMToken(int teacherId) async {
  final token = await _getFCMToken();
  if (token != null) {
    await ApiServices.updateTeacherNotificationToken(
      teacherId: teacherId,
      notificationToken: token,
    );
  } else {
    print("FCM skipped/unavailable for teacher $teacherId.");
  }
}

void startFCMTokenRefreshListener() {
  if (_isFCMTokenRefreshListenerStarted ||
      kIsWeb ||
      (!Platform.isAndroid && !Platform.isIOS)) {
    return;
  }

  _isFCMTokenRefreshListenerStarted = true;
  FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
    final userType = await getUserType();

    if (userType == "student") {
      final studentId = await getStudentID();
      if (studentId > 0) {
        await ApiServices.updateNotificationToken(
          studentId: studentId,
          notificationToken: token,
        );
      }
    } else if (userType == "teacher") {
      final teacherId = await getUserID();
      if (teacherId != null && teacherId > 0) {
        await ApiServices.updateTeacherNotificationToken(
          teacherId: teacherId,
          notificationToken: token,
        );
      }
    }
  }, onError: (Object error) {
    print("FCM token refresh listener error: $error");
  });
}

Future<void> unregisterTeacherFCMToken(int teacherId) async {
  if (teacherId > 0 && !kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await ApiServices.removeTeacherNotificationToken(teacherId: teacherId);
  }
}

// Student notification storage helpers using a simple Hive box
Future<void> saveStudentNotification(String title, String body) async {
  try {
    final box = await Hive.openBox('student_notifications_box');
    final item = {
      'title': title,
      'body': body,
      'timestamp': DateTime.now().toIso8601String(),
      'isRead': false,
    };
    await box.add(item);
    print("Saved student notification: $item");
  } catch (e) {
    print("Error saving student notification: $e");
  }
}

Future<List<Map<dynamic, dynamic>>> getStudentNotifications() async {
  try {
    final box = await Hive.openBox('student_notifications_box');
    final List<Map<dynamic, dynamic>> list = [];
    for (int i = 0; i < box.length; i++) {
      final value = box.getAt(i);
      if (value is Map) {
        // Create a mutable copy of the map so we can change 'isRead' locally if needed,
        // or just keep it as is.
        final map = Map<dynamic, dynamic>.from(value);
        list.add(map);
      }
    }
    return list;
  } catch (e) {
    print("Error getting student notifications: $e");
    return [];
  }
}

Future<void> markAllStudentNotificationsAsRead() async {
  try {
    final box = await Hive.openBox('student_notifications_box');
    for (int i = 0; i < box.length; i++) {
      final value = box.getAt(i);
      if (value is Map) {
        final map = Map<dynamic, dynamic>.from(value);
        if (map['isRead'] == false) {
          map['isRead'] = true;
          await box.putAt(i, map);
        }
      }
    }
  } catch (e) {
    print("Error marking notifications as read: $e");
  }
}

Future<void> clearStudentNotifications() async {
  try {
    final box = await Hive.openBox('student_notifications_box');
    await box.clear();
  } catch (e) {
    print("Error clearing notifications: $e");
  }
}

Future<int> getUnreadStudentNotificationsCount() async {
  try {
    final box = await Hive.openBox('student_notifications_box');
    int count = 0;
    for (var value in box.values) {
      if (value is Map && value['isRead'] == false) {
        count++;
      }
    }
    return count;
  } catch (e) {
    print("Error getting unread notifications count: $e");
    return 0;
  }
}
