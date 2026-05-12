import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:classlens/global/providers/task_manager_provider.dart';
import 'package:classlens/home/teacher_home/widgets/notification_task_item.dart';

// --- Design Constants ---
const Color primaryBackgroundColor = Color(0xFFF0F4F8);
const Color primaryTextColor = Color(0xFF1A2533);
const Color accentColor = Color(0xFF4A90E2);
const Color cardBackgroundColor = Colors.white;
const Color unreadCardBackgroundColor = Color(0xFFE8F0F9);
const Color circleColor1 = Color.fromARGB(255, 178, 218, 255);
const Color circleColor2 = Color.fromARGB(255, 201, 247, 222);

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskManagerProvider);
    final unreadCount = ref.watch(unreadTaskCountProvider);
    final taskManager = ref.read(taskManagerProvider.notifier);
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: primaryBackgroundColor,

      appBar: AppBar(
        backgroundColor: primaryBackgroundColor,
        elevation: 1,
        leading: const BackButton(color: primaryTextColor),
        titleSpacing: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (tasks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: TextButton(
                onPressed: unreadCount > 0 ? () => taskManager.markAllRead() : null,
                style: TextButton.styleFrom(
                  foregroundColor: accentColor,
                  disabledForegroundColor: Colors.grey.withOpacity(0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Mark all as read'),
              ),
            ),
        ],
      ),
      // The body uses a Stack to layer the decorative circles behind the list
      body: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: screenSize.height * 0.1,
            left: -screenSize.width * 0.2,
            child: CircleAvatar(
              radius: screenSize.width * 0.4,
              backgroundColor: circleColor1.withOpacity(0.5),
            ),
          ),
          Positioned(
            bottom: screenSize.height * 0.05,
            right: -screenSize.width * 0.3,
            child: CircleAvatar(
              radius: screenSize.width * 0.45,
              backgroundColor: circleColor2.withOpacity(0.6),
            ),
          ),
          // Main content: either the empty state or the list
          tasks.isEmpty
              ? const _EmptyState()
              : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[tasks.length - 1 - index];
              return AnimatedListItem(
                index: index,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  decoration: BoxDecoration(
                    color: task.isRead ? cardBackgroundColor : unreadCardBackgroundColor,
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: NotificationTaskItem(
                    task: task,
                    isRead: task.isRead,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Helper widget for the empty state
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_active_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('All caught up!', style: TextStyle(fontSize: 18, color: Colors.grey)),
          SizedBox(height: 4),
          Text('You have no new notifications.', style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }
}

// Helper widget for list item animation
class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;

  const AnimatedListItem({required this.child, required this.index, super.key});

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    final delay = (widget.index * 100).clamp(0, 400).toDouble();
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(delay / 400, 1.0, curve: Curves.easeOutCubic),
    ));
    _slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(delay / 400, 1.0, curve: Curves.easeOutCubic),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}