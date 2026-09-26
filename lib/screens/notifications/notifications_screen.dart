import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/notification_model.dart';
import '../../providers/notifications_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';
import '../profile/photographer_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsProvider>().loadAll();
    });
  }

  IconData _iconFor(String type) {
    switch (type) {
      case NotificationModel.typeFollow:
        return Icons.person_add;
      case NotificationModel.typeSale:
        return Icons.sell;
      case NotificationModel.typePurchase:
        return Icons.shopping_cart;
      case NotificationModel.typeComment:
        return Icons.comment;
      case NotificationModel.typeRating:
        return Icons.star;
      case NotificationModel.typeFavorite:
        return Icons.favorite;
      case NotificationModel.typeDailyReward:
        return Icons.card_giftcard;
      case NotificationModel.typeAdminGrant:
        return Icons.admin_panel_settings;
      case 'system':
        return Icons.campaign;
      default:
        return Icons.notifications;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case NotificationModel.typeFollow:
        return AppTheme.primary;
      case NotificationModel.typeSale:
        return AppTheme.success;
      case NotificationModel.typePurchase:
        return AppTheme.secondary;
      case NotificationModel.typeDailyReward:
        return AppTheme.warning;
      case NotificationModel.typeAdminGrant:
        return AppTheme.accent;
      case 'system':
        return AppTheme.error;
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          Consumer<NotificationsProvider>(
            builder: (context, provider, _) {
              if (provider.unreadCount == 0) {
                return const SizedBox.shrink();
              }
              return TextButton.icon(
                onPressed: () => provider.markAllAsRead(),
                icon: const Icon(Icons.done_all, size: 18),
                label: const Text('قراءة الكل'),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.notifications.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none,
                        size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'لا توجد إشعارات',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'ستظهر هنا الإشعارات عند حدوث أي جديد',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadAll(),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: provider.notifications.length,
              itemBuilder: (context, index) {
                final n = provider.notifications[index];
                final color = _colorFor(n.type);
                return Dismissible(
                  key: Key(n.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => provider.delete(n.id),
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                        vertical: 4, horizontal: 0),
                    color: n.isRead ? null : color.withValues(alpha: 0.08),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_iconFor(n.type), color: color, size: 22),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              n.title,
                              style: TextStyle(
                                fontWeight: n.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!n.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(n.body),
                          const SizedBox(height: 4),
                          Text(
                            Helpers.timeAgo(n.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).disabledColor,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        if (!n.isRead) provider.markAsRead(n.id);
                        _handleTap(n);
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _handleTap(NotificationModel n) {
    if (n.type == NotificationModel.typeFollow &&
        n.data != null &&
        n.data!['follower_id'] != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PhotographerScreen(userId: n.data!['follower_id'] as String),
        ),
      );
    }
  }
}
