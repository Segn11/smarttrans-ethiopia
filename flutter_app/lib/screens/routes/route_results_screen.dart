import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';

class RouteResultsScreen extends ConsumerStatefulWidget {
  final String fromStationId;
  final String toStationId;
  final String fromName;
  final String toName;

  const RouteResultsScreen({
    super.key,
    required this.fromStationId,
    required this.toStationId,
    required this.fromName,
    required this.toName,
  });

  @override
  ConsumerState<RouteResultsScreen> createState() => _RouteResultsScreenState();
}

class _RouteResultsScreenState extends ConsumerState<RouteResultsScreen> {
  String _sortBy = 'fastest';

  @override
  Widget build(BuildContext context) {
    final params = RouteSearchParams(
      from: widget.fromStationId,
      to: widget.toStationId,
      sortBy: _sortBy,
    );
    final resultsAsync = ref.watch(routeSearchProvider(params));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.fromName} → ${widget.toName}',
                style: const TextStyle(fontSize: 16)),
            Text('Route Results',
                style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter/Sort Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: AppTheme.surface,
            child: Row(
              children: [
                const Text('Sort by: ', style: TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(width: 8),
                _buildSortChip('Fastest', 'fastest'),
                const SizedBox(width: 8),
                _buildSortChip('Cheapest', 'cheapest'),
                const SizedBox(width: 8),
                _buildSortChip('Fewest Transfers', 'fewest_transfers'),
              ],
            ),
          ),
          Expanded(
            child: resultsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorState(
                message: 'Failed to search routes',
                onRetry: () => ref.refresh(routeSearchProvider(params)),
              ),
              data: (results) {
                if (results.isEmpty) {
                  return const EmptyState(
                    message: 'No routes found between these stations.',
                    icon: Icons.route_outlined,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final res = results[index];
                    return _buildResultCard(context, res);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () => setState(() => _sortBy = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? AppTheme.primary : AppTheme.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textPrimary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, RouteSearchResult res) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        onTap: () => context.push('/routes/${res.route.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TransportBadge(
                  icon: res.route.transportIcon,
                  label: res.route.transportType?.name ?? 'Transport',
                ),
                const Spacer(),
                Text(
                  res.fareFormatted,
                  style: const TextStyle(
                    color: AppTheme.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              res.route.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Text(
                  res.timeFormatted,
                  style: const TextStyle(color: AppTheme.textPrimary),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.transfer_within_a_station_rounded,
                    size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${res.transfers} transfers',
                  style: const TextStyle(color: AppTheme.textPrimary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
