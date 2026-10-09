import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(adminReportsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Review Reports')),
      body: reportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (reports) => ListView.builder(
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final r = reports[index];
            return ListTile(
              title: Text(r.reportType, style: const TextStyle(color: AppTheme.textPrimary)),
              subtitle: Text(r.description, style: const TextStyle(color: AppTheme.textSecondary)),
              trailing: Text(r.status, style: TextStyle(color: r.status == 'pending' ? AppTheme.warning : AppTheme.success)),
            );
          },
        ),
      ),
    );
  }
}
