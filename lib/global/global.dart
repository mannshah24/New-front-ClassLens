import 'package:classlens/api/api.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}) async {
  final pref = await SharedPreferences.getInstance();
  await pref.setBool(_keyRememberMe, rememberMe);
  await pref.setString(_keyUserType, "student");
  await pref.setString(_keyStudentName, studentName);
  await pref.setInt(_keyStudentID, studentID);
  await pref.setString(_keyStudentPRN, prn);
}

Future<void> registerFCMToken(int studentId) async {
  print(
    "FCM disabled on this desktop build; skipping registration for student $studentId.",
  );
}

Future<void> unregisterFCMToken() async {
  final studentId = await getStudentID();
  if (studentId > 0) {
    print(
      "FCM disabled on this desktop build; skipping unregister for student $studentId.",
    );
  }
}