import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:classlens/data_models/student_notification.dart';
import 'package:intl/intl.dart';

class StudentNotificationsScreen extends StatefulWidget {
  const StudentNotificationsScreen({super.key});

  @override
  State<StudentNotificationsScreen> createState() => _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState extends State<StudentNotificationsScreen> {
  final _box = Hive.box<StudentNotification>('student_notifications');

  // Theme Constants matching student dashboard/profile
  static const Color primaryBackgroundColor = Color(0xFFF8F9FA);
  static const Color cardBackgroundColor = Colors.white;
  static const Color primaryTextColor = Color(0xFF1E293B);
  static const Color secondaryTextColor = Color(0xFF64748B);
  static const Color accentColor = Color(0xFF0F172A);
  static const Color presentColor = Color(0xFF10B981);
  static const Color absentColor = Color(0xFFEF4444);
  static const Color borderColor = Color(0xFFE2E8F0);

  void _markAllAsRead() {
    for (var notification in _box.values) {
      if (!notification.isRead) {
        notification.isRead = true;
        notification.save();
      }
    }
  }

  void _deleteAllNotifications() {
    _box.clear();
  }

  void _toggleReadStatus(StudentNotification notification) {
    notification.isRead = !notification.isRead;
    notification.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: primaryTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: primaryTextColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          ValueListenableBuilder<Box<StudentNotification>>(
            valueListenable: _box.listenable(),
            builder: (context, box, _) {
              if (box.isEmpty) return const SizedBox.shrink();
              return PopupMenuButton<String>(
                color: cardBackgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onSelected: (value) {
                  if (value == 'read_all') {
                    _markAllAsRead();
                  } else if (value == 'delete_all') {
                    _deleteAllNotifications();
                  }
                },
                icon: const Icon(Icons.more_vert_rounded, color: primaryTextColor),
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'read_all',
                    child: Row(
                      children: [
                        Icon(Icons.mark_email_read_outlined, size: 20, color: secondaryTextColor),
                        SizedBox(width: 10),
                        Text('Mark all as read', style: TextStyle(color: primaryTextColor)),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete_all',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 20, color: absentColor),
                        SizedBox(width: 10),
                        Text('Clear all', style: TextStyle(color: absentColor)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<Box<StudentNotification>>(
        valueListenable: _box.listenable(),
        builder: (context, box, _) {
          if (box.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      size: 64,
                      color: secondaryTextColor.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'All Caught Up!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No new attendance notifications found.',
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            );
          }

          // Sort notifications: newest first
          final notifications = box.values.toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final isPresent = notification.status?.toLowerCase() == 'present';
              final formattedTime = DateFormat('dd MMM yyyy, hh:mm a').format(notification.timestamp);

              return Dismissible(
                key: Key(notification.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24.0),
                  margin: const EdgeInsets.symmetric(vertical: 6.0),
                  decoration: BoxDecoration(
                    color: absentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: absentColor, size: 28),
                ),
                onDismissed: (direction) {
                  notification.delete();
                },
                child: GestureDetector(
                  onTap: () {
                    if (!notification.isRead) {
                      _toggleReadStatus(notification);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: cardBackgroundColor,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(
                        color: notification.isRead ? borderColor : Colors.blue.withOpacity(0.3),
                        width: notification.isRead ? 1.0 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Indicator dot for unread status
                        if (!notification.isRead)
                          Padding(
                            padding: const EdgeInsets.only(top: 6.0, right: 8.0),
                            child: CircleAvatar(
                              radius: 4,
                              backgroundColor: Colors.blue.shade600,
                            ),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      notification.title,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold,
                                        color: primaryTextColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isPresent
                                          ? presentColor.withOpacity(0.1)
                                          : absentColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isPresent ? 'Present ✓' : 'Absent ✗',
                                      style: TextStyle(
                                        color: isPresent ? presentColor : absentColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                notification.body,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: secondaryTextColor,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                formattedTime,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: secondaryTextColor.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
