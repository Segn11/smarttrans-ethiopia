import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: notifsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: 'Failed to load notifications',
          onRetry: () => ref.refresh(notificationsProvider),
        ),
        data: (notifs) {
          if (notifs.isEmpty) {
            return const EmptyState(
              message: 'You have no new notifications.',
              icon: Icons.notifications_none_rounded,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: notifs.length,
            itemBuilder: (context, index) {
              final notif = notifs[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _getColor(notif.notificationType).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIcon(notif.notificationType),
                          color: _getColor(notif.notificationType),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    notif.title,
                                    style: TextStyle(
                                      fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                if (!notif.isRead)
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
                            const SizedBox(height: 6),
                            Text(
                              notif.message,
                              style: const TextStyle(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getColor(String type) {
    return switch (type) {
      'alert' => AppTheme.error,
      'update' => AppTheme.info,
      'promotion' => AppTheme.accent,
      _ => AppTheme.primary,
    };
  }

  IconData _getIcon(String type) {
    return switch (type) {
      'alert' => Icons.warning_rounded,
      'update' => Icons.system_update_rounded,
      'promotion' => Icons.local_offer_rounded,
      _ => Icons.info_outline_rounded,
    };
  }
}
