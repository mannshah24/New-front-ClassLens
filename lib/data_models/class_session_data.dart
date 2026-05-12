import 'package:hive/hive.dart';

part 'class_session_data.g.dart';

@HiveType(typeId: 2)
class SessionStats extends HiveObject {
  @HiveField(0)
  late int classSessionId;

  @HiveField(1)
  late int presentCount;

  @HiveField(2)
  late int absentCount;

  @HiveField(3)
  late String subject;
  @HiveField(4)
  late DateTime date;
}