import 'package:classlens/data_models/class_session_data.dart';
import 'package:classlens/data_models/notification_hive_model.dart';
import 'package:classlens/global/global.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'firebase_options.dart';
import 'splash_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kReleaseMode) {
    // App is in release mode (production)
    await dotenv.load(fileName: ".env.prod");
  } else {
    // App is in debug mode (development)
    await dotenv.load(fileName: ".env.dev");
  }

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
      // Show local notification
      _showLocalNotification(message);
    }
  });

  await Hive.initFlutter();
  Hive.registerAdapter(NotificationHiveModelAdapter());
  Hive.registerAdapter(SessionStatsAdapter());
  await Hive.openBox<NotificationHiveModel>('notifications');

  //await Hive.deleteBoxFromDisk("classSessionBox");

  classSessionBox = await Hive.openBox<SessionStats>("classSessionBox");

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
  final List<NotificationHiveModel> notifications = notificationsBox.values
      .toList();
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

// Show local notification when app is in foreground
void _showLocalNotification(RemoteMessage message) async {
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
    message.hashCode,
    message.notification?.title ?? 'ClassLens',
    message.notification?.body ?? '',
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
