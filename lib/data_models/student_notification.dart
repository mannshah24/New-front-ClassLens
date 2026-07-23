import 'package:hive/hive.dart';

part 'student_notification.g.dart';

@HiveType(typeId: 3)
class StudentNotification extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String body;

  @HiveField(3)
  late DateTime timestamp;

  @HiveField(4)
  late bool isRead;

  @HiveField(5)
  late String type;

  @HiveField(6)
  late String? subject;

  @HiveField(7)
  late String? status;

  StudentNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.isRead,
    required this.type,
    this.subject,
    this.status,
  });
}
