import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';

class AdminStationsScreen extends ConsumerWidget {
  const AdminStationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stationsAsync = ref.watch(adminStationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Stations')),
      body: stationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (stations) => ListView.builder(
          itemCount: stations.length,
          itemBuilder: (context, index) {
            final s = stations[index];
            return ListTile(
              title: Text(s.name, style: const TextStyle(color: AppTheme.textPrimary)),
              subtitle: Text(s.city?.name ?? '', style: const TextStyle(color: AppTheme.textSecondary)),
              trailing: const Icon(Icons.edit, color: AppTheme.primary),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
