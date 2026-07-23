import 'package:classlens/global/global.dart';
import 'package:classlens/global/providers/task_provider.dart';
import 'package:classlens/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:classlens/data_models/notification_hive_model.dart';
import 'package:classlens/data_models/task_status.dart';
import 'package:classlens/data_models/class_session_data.dart';


class UserTask {
  late final String taskID;
  late final DateTime submissionTime;
  TaskStatus? currentStatus;
  late bool isRead;
  final String? subject;

  UserTask({
    required this.taskID,
    required this.submissionTime,
    this.currentStatus,
    this.isRead = true,
    this.subject,
  });

  bool get isCompleted {
    final current = currentStatus?.status.trim();
    return current == 'SUCCESS' || current == 'FAILURE' || current == 'error';
  }
}


class TaskManagerNotifier extends Notifier<List<UserTask>> {

  final _box = Hive.box<NotificationHiveModel>('notifications');

  @override
  List<UserTask> build() {
    final tasksFromHive =
    _box.values.map((hiveTask) => hiveTask.toUserTask()).toList();
    print("CONSTRUCTOR: Loaded ${tasksFromHive.length} tasks from Hive.");


    for (final task in tasksFromHive) {
      if (!task.isCompleted) {
        print("CONSTRUCTOR LOOP: Task ${task.taskID} is NOT complete. Calling _listenToSingleTask.");
        _listenToSingleTask(task);
      } else {
        print("CONSTRUCTOR LOOP: Task ${task.taskID} IS complete. Skipping listener.");
      }
    }

    return tasksFromHive;
  }


  final Map<String, ProviderSubscription<AsyncValue<TaskStatus>>> _activeSubscriptions = {};

  DateTime? _extractRecordedTime(dynamic result) {
    if (result is! Map) {
      return null;
    }

    for (final key in ['marked_at', 'timestamp', 'created_at', 'date']) {
      final value = result[key];
      if (value == null) {
        continue;
      }

      final parsed = DateTime.tryParse(value.toString());
      if (parsed != null) {
        return parsed.toLocal();
      }
    }

    return null;
  }


  void _listenToSingleTask(UserTask task) {
    if (_activeSubscriptions.containsKey(task.taskID)) {
      print("Listener for ${task.taskID} already exists. Skipping.");
      return;
    }
    print("Starting listener (manual) for task ${task.taskID}");


    final subscription = ref.listen<AsyncValue<TaskStatus>>(
      taskStatusProvider(task.taskID),
          (previous, next) {
        next.when(
          data: (TaskStatus status) {
            print("_listen CALLBACK (${task.taskID}): State is DATA. Status='${status.status}'");


            final existingTask = state.firstWhere(
                  (t) => t.taskID == task.taskID,
              orElse: () => task,
            );
            final previousStatus = existingTask.currentStatus?.status.trim();
            final newStatus = status.status.trim();

            if (previousStatus != newStatus) {
              print("_listen CALLBACK (${task.taskID}): Status changed. Calling updateTaskStatus.");
              updateTaskStatus(task.taskID, status);
            }

            if (newStatus == 'SUCCESS' || newStatus == 'FAILURE'||newStatus == 'error') {
              print("_listen CALLBACK (${task.taskID}): Final state detected. Closing listener.");
              _cancelSubscription(task.taskID); // Close the listener
            }
          },
          error: (err, stack) {
            print("_listen CALLBACK (${task.taskID}): State is ERROR: $err. Closing listener.");
            updateTaskStatus(task.taskID, TaskStatus(status: 'FAILURE', result: 'Connection lost or server offline'));
            _cancelSubscription(task.taskID); // Close the listener
          },
          loading: () {
            print("_listen CALLBACK (${task.taskID}): State is LOADING.");
          },
        );
      },
    );

    _activeSubscriptions[task.taskID] = subscription;
  }

  void _cancelSubscription(String taskID) {
    if (_activeSubscriptions.containsKey(taskID)) {
      _activeSubscriptions[taskID]?.close();
      _activeSubscriptions.remove(taskID);
      print("Subscription for task $taskID CANCELLED.");
    }
  }

  void setupDispose() {
    ref.onDispose(() {
      print("Disposing TaskManagerNotifier. Cancelling ${_activeSubscriptions.length} subscriptions.");
      for (final sub in _activeSubscriptions.values) {
        sub.close();
      }
      _activeSubscriptions.clear();
    });
  }


  void addTask(String taskID, {String? subject}) {
    if (state.any((task) => task.taskID == taskID)) return;
    final newTask = UserTask(taskID: taskID, submissionTime: DateTime.now(), subject: subject);


    state = [...state, newTask];

    _saveStateToHive();
    _listenToSingleTask(newTask);
  }

  void updateTaskStatus(String taskID, TaskStatus status) {
    final cleanStatus = status.status.trim();
    String? subjectName;
    try {
      final existing = state.firstWhere((t) => t.taskID == taskID);
      subjectName = existing.subject;
    } catch (_) {}

    if (cleanStatus == 'SUCCESS') {
      print("updateTaskStatus ($taskID): Status is SUCCESS. Result: ${status.result}");
      dynamic classSessionID = status.result["class_session_id"];
      dynamic presentCount = status.result["present_count"];
      dynamic absentCount = status.result["absent_count"];
      dynamic subject = status.result["subject"];
      if (subject is String) {
        subjectName = subject;
      }

      // NOTE: No local notification here — the backend sends an FCM push directly
      // to the teacher device when attendance is processed. Calling showLocalNotification()
      // here would produce a duplicate (one from FCM + one from polling).

      if (classSessionID is int && presentCount is int && absentCount is int) {
        if (!classSessionBox.containsKey(classSessionID)) {
          final newStats = SessionStats()
            ..subject=subject
            ..classSessionId=classSessionID
            ..presentCount=presentCount
            ..absentCount=absentCount
            ..date=_extractRecordedTime(status.result) ?? DateTime.now();
          classSessionBox.put(classSessionID, newStats);
          print("updateTaskStatus ($taskID): Saved new ID $classSessionID to Hive.");
        } else {
          final existing = classSessionBox.get(classSessionID);
          if (existing != null) {
            existing.presentCount = presentCount;
            existing.absentCount = absentCount;
            existing.save();
            print("updateTaskStatus ($taskID): Updated existing ID $classSessionID in Hive.");
          }
        }
      }
    } else if (cleanStatus == 'FAILURE' || cleanStatus == 'error') {
      // NOTE: No local notification here — the backend handles failure notifications
      // via FCM push as well. The in-app notification badge/tray is updated below.
      print("updateTaskStatus ($taskID): Task FAILED. Backend FCM push handles teacher notification.");
    }

    state = [
      for (final task in state)
        if (task.taskID == taskID)
          UserTask(
            taskID: task.taskID,
            submissionTime: task.submissionTime,
            currentStatus: status,
            isRead: (cleanStatus == 'SUCCESS' || cleanStatus == 'FAILURE' || cleanStatus == 'error')
                ? false
                : task.isRead,
            subject: subjectName ?? task.subject,
          )
        else
          task
    ];
    _saveStateToHive();
  }

  void _saveStateToHive() {
    final existingKeys = _box.keys.cast<String>().toSet();

    for (var task in state) {
      print(task.isCompleted);
      final model = NotificationHiveModel.fromUserTask(task);
      print(model.taskID);
      _box.put(task.taskID, model);
      existingKeys.remove(task.taskID);
    }

    for (var obsoleteKey in existingKeys) {
      print("${obsoleteKey}deleted");
      _box.delete(obsoleteKey);
    }
  }


  void markAllRead() {
    state = [
      for(final task in state)
        UserTask(
          taskID: task.taskID,
          submissionTime: task.submissionTime,
          currentStatus: task.currentStatus,
          isRead: true,
        )
    ];
    _saveStateToHive();
  }

  void deleteAllNotification(){
    state=[];
    _box.clear();
    print("cleared notification");
  }

}


final taskManagerProvider =
NotifierProvider<TaskManagerNotifier, List<UserTask>>(() {
  return TaskManagerNotifier();
});


final unreadTaskCountProvider = Provider<int>((ref) {
  final tasks = ref.watch(taskManagerProvider);
  return tasks.where((task) => !task.isRead && task.isCompleted).length;
});