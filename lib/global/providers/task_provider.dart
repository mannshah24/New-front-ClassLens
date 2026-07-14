import 'dart:async';
import 'package:classlens/data_models/task_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:classlens/api/api.dart';

final apiServiceProvider = Provider((ref) => ApiServices());

final taskStatusProvider = StreamProvider.family<TaskStatus, String>((ref, taskID) {
  final controller = StreamController<TaskStatus>();
  Timer? timer;

  bool isClosedByUs = false;

  int attempts = 0;
  const maxAttempts = 12;
  Duration delay = const Duration(seconds: 2);

  Future<void> poll() async {
    if (isClosedByUs) {
      timer?.cancel();
      return;
    }

    if (attempts >= maxAttempts) {
      if (!isClosedByUs) {
        isClosedByUs = true;
        try { controller.addError('Polling timed out'); } catch (_) {}
        try { await controller.close(); } catch (_) {}
      }
      timer?.cancel();
      return;
    }
    attempts++;

    try {
      final status = await ApiServices.checkTaskStatus(taskID: taskID);

      if (isClosedByUs) {
        timer?.cancel();
        return;
      }


      try { controller.add(status); } catch (_) {}


      if (status.status == 'SUCCESS' || status.status == 'FAILURE') {
        if (!isClosedByUs) {
          isClosedByUs = true; //
          print("status of a task is : " + status.result);
          try { await controller.close(); } catch (_) {}
        }
        timer?.cancel();
      } else {

        delay = Duration(seconds: (delay.inSeconds * 2).clamp(2, 30));
        if (!isClosedByUs) {
          timer = Timer(delay, poll);
        }
      }
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      final isNetworkError = errorStr.contains('socketexception') || 
                             errorStr.contains('handshake') || 
                             errorStr.contains('connection') || 
                             errorStr.contains('clientexception');

      if (isNetworkError) {
        // Server might be offline. Backoff and retry polling.
        // Cap the maximum retry interval at 5 minutes (300 seconds) to avoid spamming.
        final nextSeconds = (delay.inSeconds * 2).clamp(5, 300);
        delay = Duration(seconds: nextSeconds);
        print("taskStatusProvider: Server offline/connection failed. Retrying in ${delay.inSeconds} seconds...");
        if (!isClosedByUs) {
          timer = Timer(delay, poll);
        }
      } else {
        // Real logic failure or max attempts reached for non-network errors
        if (!isClosedByUs) {
          isClosedByUs = true;
          try { controller.addError(e); } catch (_) {}
          try { await controller.close(); } catch (_) {}
        }
        timer?.cancel();
      }
    }
  }


  controller.onListen = () => poll();

  // When the provider is disposed, just set the flag and cancel the timer.
  // This prevents all in-flight polls from doing anything.
  controller.onCancel = () {
    isClosedByUs = true;
    timer?.cancel();
  };

  return controller.stream;
});