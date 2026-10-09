import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';

// In a real app we would use Geolocator to get current coordinates.
// For Version 1, we use static demo coordinates.
const _currentLat = AppConstants.defaultLat;
const _currentLng = AppConstants.defaultLng;

class NearbyStationsScreen extends ConsumerWidget {
  const NearbyStationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nearbyAsync = ref.watch(nearbyStationsProvider({'lat': _currentLat, 'lng': _currentLng, 'radius': 5000.0}));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Nearby Stations'),
      ),
      body: nearbyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: 'Failed to find nearby stations',
          onRetry: () => ref.refresh(nearbyStationsProvider({'lat': _currentLat, 'lng': _currentLng, 'radius': 5000.0})),
        ),
        data: (data) {
          final nearby = data.cast<NearbyStationModel>();
          if (nearby.isEmpty) {
            return const EmptyState(
              message: 'No stations found near your location.',
              icon: Icons.location_off_rounded,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: nearby.length,
            itemBuilder: (context, index) {
              final item = nearby[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  onTap: () => context.push('/stations/${item.station.id}'),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.info.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.near_me_rounded, color: AppTheme.info),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.station.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.formattedDistance} away',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.primaryLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppTheme.textHint),
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
}
