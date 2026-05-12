import 'package:hive/hive.dart';
import 'package:classlens/data_models/task_status.dart';
import '../global/providers/task_manager_provider.dart';
part 'notification_hive_model.g.dart';

@HiveType(typeId: 1)
class NotificationHiveModel extends HiveObject {
  @HiveField(0)
  late String taskID;

  @HiveField(1)
  late DateTime submissionTime;

  @HiveField(2)
  late String? status;

  @HiveField(3)
  late bool isRead;

  @HiveField(4)
  late Map<String, dynamic>? result;

  static NotificationHiveModel fromUserTask(UserTask task) {
    print(task.currentStatus?.result);
    return NotificationHiveModel()
      ..taskID = task.taskID
      ..submissionTime = task.submissionTime
      ..status = task.currentStatus?.status
      ..isRead = task.isRead
      ..result = task.currentStatus?.result;
  }

  UserTask toUserTask() {
    return UserTask(
      taskID: taskID,
      submissionTime: submissionTime,
      isRead: isRead,
      currentStatus: (status == null)
          ? null
          : TaskStatus(status: status!, result: result),
    );
  }
}