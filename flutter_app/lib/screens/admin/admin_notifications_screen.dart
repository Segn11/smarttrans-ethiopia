import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';

class AdminNotificationsScreen extends ConsumerWidget {
  const AdminNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(adminNotificationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Push Notifications')),
      body: notifsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (notifs) => ListView.builder(
          itemCount: notifs.length,
          itemBuilder: (context, index) {
            final n = notifs[index];
            return ListTile(
              title: Text(n.title, style: const TextStyle(color: AppTheme.textPrimary)),
              subtitle: Text(n.message, style: const TextStyle(color: AppTheme.textSecondary)),
              trailing: const Icon(Icons.delete, color: AppTheme.error),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.send),
      ),
    );
  }
}
