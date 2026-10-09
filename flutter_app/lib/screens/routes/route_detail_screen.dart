import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';

class RouteDetailScreen extends ConsumerWidget {
  final String routeId;

  const RouteDetailScreen({super.key, required this.routeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeAsync = ref.watch(routeDetailProvider(routeId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Route Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.warning_amber_rounded),
            onPressed: () => context.push('/reports/submit', extra: {'routeId': routeId}),
            tooltip: 'Report Issue',
          ),
        ],
      ),
      body: routeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: 'Failed to load route details',
          onRetry: () => ref.refresh(routeDetailProvider(routeId)),
        ),
        data: (route) => _buildBody(context, ref, route),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, RouteModel route) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          AppCard(
            color: AppTheme.surfaceVariant,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TransportBadge(
                      icon: route.transportIcon,
                      label: route.transportType?.name ?? 'Transport',
                    ),
                    StatusChip(
                      label: route.status.toUpperCase(),
                      color: route.status == 'active' ? AppTheme.success : AppTheme.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  route.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _InfoItem(
                        icon: Icons.attach_money_rounded,
                        label: 'Fare',
                        value: route.primaryFareFormatted),
                    _InfoItem(
                        icon: Icons.schedule_rounded,
                        label: 'Time',
                        value: route.estimatedTimeFormatted),
                    _InfoItem(
                        icon: Icons.route_rounded,
                        label: 'Distance',
                        value: route.distance != null ? '${route.distance} km' : 'N/A'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/map', extra: {'routeId': route.id}),
                  icon: const Icon(Icons.map_rounded),
                  label: const Text('View on Map'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Consumer(builder: (context, ref, _) {
                  final isFav = ref.watch(favoritesProvider).valueOrNull?.any((f) => f.routeId == route.id) ?? false;
                  return ElevatedButton.icon(
                    onPressed: () {
                      if (isFav) {
                        final fav = ref.read(favoritesProvider).valueOrNull?.firstWhere((f) => f.routeId == route.id);
                        if (fav != null) ref.read(favoritesProvider.notifier).remove(fav.id);
                      } else {
                        ref.read(favoritesProvider.notifier).add(route.id);
                      }
                    },
                    icon: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded),
                    label: Text(isFav ? 'Saved' : 'Save Route'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFav ? AppTheme.surfaceVariant : AppTheme.primary,
                      foregroundColor: isFav ? AppTheme.error : Colors.white,
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Operating Hours
          if (route.operatingHours != null) ...[
            const SectionHeader(title: 'Operating Hours'),
            const SizedBox(height: 12),
            AppCard(
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded, color: AppTheme.accent),
                  const SizedBox(width: 12),
                  Text(
                    route.operatingHours!,
                    style: const TextStyle(fontSize: 16, color: AppTheme.textPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],

          // Stops Timeline
          const SectionHeader(title: 'Route Stops'),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(0),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: route.routeStops.length,
              separatorBuilder: (context, index) => const Divider(color: AppTheme.divider, height: 1),
              itemBuilder: (context, index) {
                final stop = route.routeStops[index];
                final isFirst = index == 0;
                final isLast = index == route.routeStops.length - 1;
                
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isFirst || isLast ? Icons.trip_origin : Icons.circle,
                        size: isFirst || isLast ? 16 : 10,
                        color: isFirst ? AppTheme.success : (isLast ? AppTheme.error : AppTheme.primary),
                      ),
                    ],
                  ),
                  title: Text(
                    stop.station?.name ?? 'Unknown Station',
                    style: TextStyle(
                      fontWeight: isFirst || isLast ? FontWeight.bold : FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textHint),
                  onTap: stop.station != null
                      ? () => context.push('/stations/${stop.station!.id}')
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.textHint, size: 20),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }
}
