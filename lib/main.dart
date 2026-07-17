import 'package:classlens/data_models/class_session_data.dart';
import 'package:classlens/data_models/notification_hive_model.dart';
import 'package:classlens/data_models/student_notification.dart';
import 'package:classlens/global/global.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

import 'splash_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling background message: ${message.messageId}");
  try {
    final type = message.data['type'] ?? '';
    if (type == 'attendance') {
      await Hive.initFlutter();
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(StudentNotificationAdapter());
      }
      final box = await Hive.openBox<StudentNotification>('student_notifications');
      final id = message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();
      final title = message.notification?.title ?? "Attendance Marked - ${message.data['subject'] ?? ''}";
      final body = message.notification?.body ?? "You were marked ${message.data['status'] == 'present' ? 'Present ✓' : 'Absent ✗'}";
      
      final notif = StudentNotification(
        id: id,
        title: title,
        body: body,
        timestamp: DateTime.now(),
        isRead: false,
        type: type,
        subject: message.data['subject'],
        status: message.data['status'],
      );
      await box.put(id, notif);
      print("Saved background notification: $id");
    }
  } catch (e) {
    print("Error saving background notification: $e");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (kReleaseMode) {
      // App is in release mode (production)
      await dotenv.load(fileName: ".env.prod");
    } else {
      // App is in debug mode (development)
      await dotenv.load(fileName: ".env.dev");
    }
  } catch (e) {
    debugPrint("Note: DotEnv failed to load: $e. Using environment compilation/defaults.");
  }

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        if (message.notification != null) {
          showLocalNotification(
            title: message.notification!.title,
            body: message.notification!.body,
          );
        }
        try {
          final type = message.data['type'] ?? '';
          if (type == 'attendance') {
            final box = Hive.box<StudentNotification>('student_notifications');
            final id = message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();
            final title = message.notification?.title ?? "Attendance Marked - ${message.data['subject'] ?? ''}";
            final body = message.notification?.body ?? "You were marked ${message.data['status'] == 'present' ? 'Present ✓' : 'Absent ✗'}";
            
            final notif = StudentNotification(
              id: id,
              title: title,
              body: body,
              timestamp: DateTime.now(),
              isRead: false,
              type: type,
              subject: message.data['subject'],
              status: message.data['status'],
            );
            await box.put(id, notif);
            print("Saved foreground notification: $id");
          }
        } catch (e) {
          print("Error saving foreground notification: $e");
        }
      });
    } catch (e) {
      print("Firebase initialization error: $e");
    }
  }

  try {
    await Hive.initFlutter();
  } catch (e) {
    print("Hive initialization warning: $e");
  }

  Hive.registerAdapter(NotificationHiveModelAdapter());
  Hive.registerAdapter(SessionStatsAdapter());
  Hive.registerAdapter(StudentNotificationAdapter());

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
    await Hive.openBox<StudentNotification>('student_notifications');
  } catch (e) {
    print("Error opening student_notifications box: $e");
    try {
      await Hive.deleteBoxFromDisk('student_notifications');
      await Hive.openBox<StudentNotification>('student_notifications');
    } catch (e2) {
      print("Failed to recover student_notifications box: $e2");
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
      AndroidInitializationSettings("app_icon");
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
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  if (!kIsWeb && Platform.isAndroid) {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'attendance_channel',
      'Attendance Notifications',
      description: 'Notifications for attendance updates',
      importance: Importance.max,
      playSound: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

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
void showLocalNotification({String? title, String? body}) async {
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
