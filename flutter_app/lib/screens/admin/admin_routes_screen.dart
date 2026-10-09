import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';

class AdminRoutesScreen extends ConsumerWidget {
  const AdminRoutesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routesAsync = ref.watch(adminRoutesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Routes')),
      body: routesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (routes) => ListView.builder(
          itemCount: routes.length,
          itemBuilder: (context, index) {
            final r = routes[index];
            return ListTile(
              title: Text(r.name, style: const TextStyle(color: AppTheme.textPrimary)),
              subtitle: Text('${r.transportType?.name} - ${r.status}', style: const TextStyle(color: AppTheme.textSecondary)),
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
