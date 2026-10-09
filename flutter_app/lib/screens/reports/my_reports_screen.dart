import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class MyReportsScreen extends ConsumerWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(myReportsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('My Reports')),
      body: reportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: 'Failed to load reports',
          onRetry: () => ref.refresh(myReportsProvider),
        ),
        data: (reports) {
          if (reports.isEmpty) {
            return const EmptyState(
              message: 'You have not submitted any reports.',
              icon: Icons.history_rounded,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            report.reportTypeDisplay,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                            ),
                          ),
                          StatusChip(
                            label: report.status.toUpperCase(),
                            color: _getStatusColor(report.status),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        report.description,
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                      if (report.adminNotes != null) ...[
                        const Divider(color: AppTheme.divider, height: 24),
                        const Text('Admin Notes:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                        const SizedBox(height: 4),
                        Text(report.adminNotes!, style: const TextStyle(color: AppTheme.textPrimary)),
                      ],
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

  Color _getStatusColor(String status) {
    return switch (status) {
      'resolved' => AppTheme.success,
      'rejected' => AppTheme.error,
      'in_progress' => AppTheme.info,
      _ => AppTheme.warning,
    };
  }
}
