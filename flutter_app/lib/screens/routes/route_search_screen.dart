import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';

class RouteSearchScreen extends ConsumerStatefulWidget {
  const RouteSearchScreen({super.key});

  @override
  ConsumerState<RouteSearchScreen> createState() => _RouteSearchScreenState();
}

class _RouteSearchScreenState extends ConsumerState<RouteSearchScreen> {
  StationModel? _fromStation;
  StationModel? _toStation;
  
  @override
  Widget build(BuildContext context) {
    final stationsAsync = ref.watch(stationsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Find Route'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: stationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: 'Failed to load stations',
          onRetry: () => ref.refresh(stationsProvider),
        ),
        data: (stationsData) {
          final stations = stationsData.cast<StationModel>();
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  child: Column(
                    children: [
                      _buildStationDropdown(
                        label: 'From',
                        value: _fromStation,
                        items: stations,
                        onChanged: (val) => setState(() => _fromStation = val),
                        icon: Icons.my_location_rounded,
                        color: AppTheme.primary,
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 20),
                        child: Divider(color: AppTheme.divider, height: 24),
                      ),
                      _buildStationDropdown(
                        label: 'To',
                        value: _toStation,
                        items: stations,
                        onChanged: (val) => setState(() => _toStation = val),
                        icon: Icons.location_on_rounded,
                        color: AppTheme.error,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GradientButton(
                  label: 'Search Routes',
                  icon: Icons.search_rounded,
                  onPressed: (_fromStation != null && _toStation != null)
                      ? () {
                          if (_fromStation!.id == _toStation!.id) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Origin and destination cannot be the same')),
                            );
                            return;
                          }
                          context.push(
                            '/search/results',
                            extra: {
                              'from': _fromStation!.id,
                              'to': _toStation!.id,
                              'fromName': _fromStation!.name,
                              'toName': _toStation!.name,
                            },
                          );
                        }
                      : null,
                ),
                const SizedBox(height: 32),
                const SectionHeader(title: 'Recent Searches'),
                const SizedBox(height: 16),
                const EmptyState(
                  message: 'No recent searches yet',
                  icon: Icons.history_rounded,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStationDropdown({
    required String label,
    required StationModel? value,
    required List<StationModel> items,
    required ValueChanged<StationModel?> onChanged,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<StationModel>(
              value: value,
              hint: Text('Select $label', style: const TextStyle(color: AppTheme.textHint)),
              isExpanded: true,
              dropdownColor: AppTheme.surfaceVariant,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              items: items.map((station) {
                return DropdownMenuItem(
                  value: station,
                  child: Text(station.name),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
