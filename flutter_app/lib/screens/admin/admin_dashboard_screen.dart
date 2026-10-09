import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: 'Failed to load dashboard',
          onRetry: () => ref.refresh(dashboardProvider),
        ),
        data: (stats) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _StatCard(title: 'Users', value: stats.totalUsers.toString(), icon: Icons.people, color: AppTheme.primary),
                    _StatCard(title: 'Stations', value: stats.totalStations.toString(), icon: Icons.location_city, color: AppTheme.info),
                    _StatCard(title: 'Routes', value: stats.totalRoutes.toString(), icon: Icons.route, color: AppTheme.accent),
                    _StatCard(title: 'Reports', value: stats.pendingReports.toString(), icon: Icons.report_problem, color: AppTheme.error),
                  ],
                ),
                const SizedBox(height: 32),
                const SectionHeader(title: 'Management'),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    children: [
                      _AdminOption(title: 'Manage Stations', icon: Icons.location_on, onTap: () => context.push('/admin/stations')),
                      const Divider(color: AppTheme.divider),
                      _AdminOption(title: 'Manage Routes', icon: Icons.route, onTap: () => context.push('/admin/routes')),
                      const Divider(color: AppTheme.divider),
                      _AdminOption(title: 'Review Reports', icon: Icons.report, onTap: () => context.push('/admin/reports')),
                      const Divider(color: AppTheme.divider),
                      _AdminOption(title: 'Push Notifications', icon: Icons.notifications, onTap: () => context.push('/admin/notifications')),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppTheme.surfaceVariant,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          Text(title, style: const TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _AdminOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _AdminOption({required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(title, style: const TextStyle(color: AppTheme.textPrimary)),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textHint),
      onTap: onTap,
    );
  }
}
