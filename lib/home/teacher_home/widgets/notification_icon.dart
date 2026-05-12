import 'package:classlens/page_animations/slide_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../global/providers/task_manager_provider.dart';
import 'package:classlens/home/teacher_home/notification_screen.dart';

const Color accentColor = Color(0xFF4A90E2);
const Color attentionColor = Color(0xFFE53935);

class NotificationIcon extends ConsumerWidget {
  const NotificationIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final int unreadCount = ref.watch(unreadTaskCountProvider);

    return Tooltip(
      message: 'Notifications',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          navigatorWithAnimation(context,NotificationsScreen());
          print("Notification icon tapped. Unread count: $unreadCount");
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white,
              child: Icon(Icons.notifications_outlined, color: accentColor, size: 22),
            ),
            if (unreadCount > 0)
              Positioned(
                top: -5,
                right: -1,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: attentionColor,
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(
                      BorderSide(color: Colors.white, width: 1.5),
                    ),
                  ),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}