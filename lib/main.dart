import 'package:classlens/data_models/class_session_data.dart';
import 'package:classlens/data_models/notification_hive_model.dart';
import 'package:classlens/global/global.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'splash_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Firebase messaging is disabled for the Windows desktop build.
void _handleBackgroundMessagePlaceholder() {}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kReleaseMode) {
    // App is in release mode (production)
    await dotenv.load(fileName: ".env.prod");
  } else {
    // App is in debug mode (development)
    await dotenv.load(fileName: ".env.dev");
  }

  _handleBackgroundMessagePlaceholder();

  try {
    await Hive.initFlutter();
  } catch (e) {
    print("Hive initialization warning: $e");
  }

  Hive.registerAdapter(NotificationHiveModelAdapter());
  Hive.registerAdapter(SessionStatsAdapter());

  try {
    await Hive.openBox<NotificationHiveModel>('notifications');
  } catch (e) {
    print("Error opening notifications box: $e");
    // Try to delete and recreate
    try {
      await Hive.deleteBoxFromDisk('notifications');
      await Hive.openBox<NotificationHiveModel>('notifications');
    } catch (e2) {
      print("Failed to recover notifications box: $e2");
    }
  }

  try {
    classSessionBox = await Hive.openBox<SessionStats>("classSessionBox");
  } catch (e) {
    print("Error opening classSessionBox: $e");
    // Try to delete and recreate
    try {
      await Hive.deleteBoxFromDisk("classSessionBox");
      classSessionBox = await Hive.openBox<SessionStats>("classSessionBox");
    } catch (e2) {
      print("Failed to recover classSessionBox: $e2");
    }
  }

  print("Total sessions are ${classSessionBox.length}");
  print("totals keys are ${classSessionBox.keys}");

  clearExpiredNotification();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings("app_icon.png");
  const WindowsInitializationSettings initializationSettingsWindows =
      WindowsInitializationSettings(
        appName: "ClassLens",
        appUserModelId: "ClassLens.ClassLens_Frontend",
        guid: 'c454aee5-f2e8-462e-876a-a0b37c234a33',
        iconPath: 'assets/icons/app_icon.ico',
      );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    windows: initializationSettingsWindows,
  );
  flutterLocalNotificationsPlugin.initialize(initializationSettings);

  userName = await getUserName();
  final savedID = await getUserID();
  userID = savedID??0;

  runApp(ProviderScope(child: MyApp()));
}

void clearExpiredNotification() {
  final notificationsBox = Hive.box<NotificationHiveModel>('notifications');
  final DateTime cutoffDate = DateTime.now().subtract(const Duration(days: 2));

  final expiredKeys = notificationsBox.values
      .where(
        (notifications) => notifications.submissionTime.isBefore(cutoffDate),
      )
      .map((notifications) => notifications.taskID)
      .toList();

  if (expiredKeys.isNotEmpty) {
    notificationsBox.deleteAll(expiredKeys);
    print("Cleared ${expiredKeys.length} expired notifications.");
  }
}

// Show local notification when app is in foreground.
void _showLocalNotification({String? title, String? body}) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'attendance_channel',
        'Attendance Notifications',
        channelDescription: 'Notifications for attendance updates',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );

  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );

  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
    title ?? 'ClassLens',
    body ?? '',
    platformChannelSpecifics,
  );
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClassLens',
      theme: ThemeData(primarySwatch: Colors.teal, fontFamily: 'Lato'),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
