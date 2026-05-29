import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:classlens/global/providers/task_manager_provider.dart';
import 'package:classlens/global/config.dart';

const Color primaryTextColor = Color(0xFF1A2533);
const Color secondaryTextColor = Color(0xFF6C757D);
const Color accentColor = Color(0xFF4A90E2);
const Color successColor = Color(0xFF43A047);
const Color pendingColor = Color(0xFFFDD835);
const Color errorColor = Color(0xFFE53935);

class NotificationTaskItem extends ConsumerWidget {
  final UserTask task;
  final bool isRead;

  const NotificationTaskItem({
    required this.task,
    required this.isRead,
    super.key,
  });

  String? _extractImageUrl(dynamic payload) {
    if (payload == null) {
      return null;
    }

    if (payload is String) {
      final value = payload.trim();
      return value.isEmpty ? null : value;
    }

    if (payload is List) {
      for (final item in payload) {
        final url = _extractImageUrl(item);
        if (url != null) {
          return url;
        }
      }
      return null;
    }

    if (payload is Map) {
      final map = payload.cast<dynamic, dynamic>();
      const directKeys = [
        'image_url',
        'image',
        'result_image',
        'processed_image',
        'annotated_image',
        'attendance_image',
        'photo_url',
      ];

      for (final key in directKeys) {
        final value = map[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }

      final imageUrls = map['image_urls'];
      if (imageUrls is List) {
        for (final item in imageUrls) {
          if (item is String && item.trim().isNotEmpty) {
            return item.trim();
          }
        }
      }

      for (final value in map.values) {
        final nested = _extractImageUrl(value);
        if (nested != null) {
          return nested;
        }
      }
    }

    return null;
  }

  String _toAbsoluteImageUrl(String rawUrl) {
    final url = rawUrl.trim();
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    final apiUri = Uri.parse(AppConfig.baseUrl);
    final origin = '${apiUri.scheme}://${apiUri.host}${apiUri.hasPort ? ':${apiUri.port}' : ''}';

    if (url.startsWith('/')) {
      return '$origin$url';
    }

    return '$origin/$url';
  }

  void _showResultImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(12),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Attendance Result", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                loadingBuilder: (context, child, progress) =>
                progress == null ? child : const Center(child: CircularProgressIndicator()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ({Color color, IconData icon}) _getStatusStyle(String? status) {
    switch (status) {
      case 'SUCCESS':
        return (color: successColor, icon: Icons.check_circle_outline);
      case 'PENDING':
      case 'STARTED':
        return (color: pendingColor, icon: Icons.hourglass_bottom_rounded);
      case 'FAILURE':
        return (color: errorColor, icon: Icons.error_outline_rounded);
      default: // Handle null or unknown status
        return (color: Colors.grey, icon: Icons.hourglass_empty);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final taskManager = ref.read(taskManagerProvider.notifier);
    final status = task.currentStatus;

    final statusStyle = _getStatusStyle(status?.status);
    final String subtitle;
    Widget trailingWidget;

    if (status == null) {
      subtitle = "Initializing...";
      trailingWidget = const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5));
    } else if (status.status.trim() == 'SUCCESS') {
      subtitle = 'Status: ${status.status}';
      trailingWidget = TextButton(
        child: const Text("View", style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          if (!isRead) taskManager.markAllRead();
          final rawImageUrl = _extractImageUrl(status.result);
          if (rawImageUrl != null) {
            _showResultImage(context, _toAbsoluteImageUrl(rawImageUrl));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Attendance processed, but no result image was returned.'),
              ),
            );
          }
        },
      );
    } else if (status.status.trim() == 'FAILURE' || status.status.trim()=='error') {
      subtitle = 'Status: Failed';
      trailingWidget = const Icon(Icons.error_outline, color: errorColor);
    } else {
      subtitle = 'Status: ${status.status}';
      trailingWidget = const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5));
    }


    return _buildLayout(
      context: context,
      icon: statusStyle.icon,
      iconColor: statusStyle.color,
      title: "Attendance Scan",
      subtitle: subtitle,
      trailing: trailingWidget,
    );
  }

  Widget _buildLayout({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return InkWell(
      onTap: () {
        final taskManager = ProviderScope.containerOf(context).read(taskManagerProvider.notifier);
        if (!isRead) taskManager.markAllRead();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(

          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: iconColor.withOpacity(0.15),
                  child: Icon(icon, color: iconColor, size: 26),
                ),
                if (!isRead)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: primaryTextColor, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: secondaryTextColor, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      ),
    );
  }
}