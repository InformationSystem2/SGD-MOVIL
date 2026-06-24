// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/navigation_drawer.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final service =
          Provider.of<NotificationService>(context, listen: false);
      if (!service.isLoading && service.hasMore) {
        service.loadNotifications();
      }
    }
  }

  Future<void> _onRefresh() async {
    await Provider.of<NotificationService>(context, listen: false)
        .loadNotifications(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          Consumer<NotificationService>(
            builder: (context, service, _) {
              final hasUnread = service.unreadCount > 0;
              return TextButton.icon(
                onPressed: hasUnread
                    ? () async {
                        await service.markAllAsRead();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Todas las notificaciones marcadas como leídas'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    : null,
                icon: Icon(
                  Icons.done_all,
                  size: 18,
                  color: hasUnread
                      ? (isDark ? Colors.white : AppTheme.primary)
                      : Colors.grey,
                ),
                label: Text(
                  'Marcar todo como leído',
                  style: TextStyle(
                    fontSize: 12,
                    color: hasUnread
                        ? (isDark ? Colors.white : AppTheme.primary)
                        : Colors.grey,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: const NavigationDrawerWidget(activeRoute: '/notifications'),
      body: Consumer<NotificationService>(
        builder: (context, service, _) {
          if (service.isLoading && service.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (service.notifications.isEmpty) {
            return _buildEmptyState(isDark);
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: service.notifications.length + (service.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == service.notifications.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final notification = service.notifications[index];
                return _NotificationTile(
                  notification: notification,
                  isDark: isDark,
                  onTap: () async {
                    if (!notification.isRead) {
                      await service.markAsRead(notification.id);
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 72,
            color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
          ),
          const SizedBox(height: 16),
          Text(
            'Sin notificaciones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aquí aparecerán tus notificaciones cuando las recibas.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final bool isDark;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.isDark,
    required this.onTap,
  });

  IconData _iconForType(String type) {
    if (type.startsWith('TASK_')) return Icons.task_alt;
    if (type.startsWith('DOC_')) return Icons.description;
    if (type.startsWith('TENANT_')) return Icons.business;
    if (type.startsWith('SECURITY_')) return Icons.security;
    if (type.startsWith('SYSTEM_')) return Icons.settings;
    if (type.startsWith('COLLABORATION_')) return Icons.chat_bubble_outline;
    return Icons.notifications_outlined;
  }

  Color _colorForType(String type, bool isDark) {
    if (type.startsWith('TASK_')) return Colors.blue;
    if (type.startsWith('DOC_')) return Colors.teal;
    if (type.startsWith('TENANT_')) return Colors.orange;
    if (type.startsWith('SECURITY_')) return Colors.red;
    if (type.startsWith('SYSTEM_')) return Colors.grey;
    if (type.startsWith('COLLABORATION_')) return Colors.purple;
    return AppTheme.primary;
  }

  String _relativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return 'hace un momento';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return 'hace $m ${m == 1 ? 'minuto' : 'minutos'}';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return 'hace $h ${h == 1 ? 'hora' : 'horas'}';
    }
    final d = diff.inDays;
    return 'hace $d ${d == 1 ? 'día' : 'días'}';
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final typeColor = _colorForType(notification.type, isDark);

    Color tileBackground;
    if (isUnread) {
      tileBackground = isDark
          ? AppTheme.primary.withOpacity(0.08)
          : AppTheme.primary.withOpacity(0.05);
    } else {
      tileBackground = Colors.transparent;
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        color: tileBackground,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon badge
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _iconForType(notification.type),
                      color: typeColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                                  color: isDark
                                      ? AppTheme.textPrimaryDark
                                      : AppTheme.textPrimaryLight,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isUnread) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppTheme.textSecondaryDark
                                : AppTheme.textSecondaryLight,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _relativeTime(notification.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.05),
            ),
          ],
        ),
      ),
    );
  }
}
