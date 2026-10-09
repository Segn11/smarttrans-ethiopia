import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';

class StationDetailScreen extends ConsumerWidget {
  final String stationId;

  const StationDetailScreen({super.key, required this.stationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stationAsync = ref.watch(stationDetailProvider(stationId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Station Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.warning_amber_rounded),
            onPressed: () => context.push('/reports/submit'),
            tooltip: 'Report Issue',
          ),
        ],
      ),
      body: stationAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: 'Failed to load station details',
          onRetry: () => ref.refresh(stationDetailProvider(stationId)),
        ),
        data: (station) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  color: AppTheme.surfaceVariant,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StatusChip(
                            label: station.status.toUpperCase(),
                            color: station.status == 'active' ? AppTheme.success : AppTheme.error,
                          ),
                          Text(
                            station.city?.name ?? 'City',
                            style: const TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        station.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (station.description != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          station.description!,
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (station.operatingHours != null)
                        InfoRow(
                          icon: Icons.access_time_rounded,
                          label: 'Operating Hours',
                          value: station.operatingHours!,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GradientButton(
                  label: 'View on Map',
                  icon: Icons.map_rounded,
                  onPressed: () => context.push('/map', extra: {'stationId': station.id}),
                ),
                const SizedBox(height: 32),
                const SectionHeader(title: 'Available Routes'),
                const SizedBox(height: 16),
                const EmptyState(
                  message: 'To see routes, please use the route search.',
                  icon: Icons.route_rounded,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
