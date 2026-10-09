import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';

class MapScreen extends ConsumerStatefulWidget {
  final String? routeId;
  final String? stationId;

  const MapScreen({super.key, this.routeId, this.stationId});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    // Determine context (all stations vs specific route vs specific station)
    AsyncValue<List<dynamic>> mapData;
    
    if (widget.routeId != null) {
      final r = ref.watch(routeDetailProvider(widget.routeId!));
      mapData = r.whenData((route) {
        return route.routeStops.map((rs) => rs.station).where((s) => s != null).toList();
      });
    } else if (widget.stationId != null) {
      final s = ref.watch(stationDetailProvider(widget.stationId!));
      mapData = s.whenData((station) => [station]);
    } else {
      mapData = ref.watch(stationsProvider);
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Map View')),
      body: mapData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (stationsData) {
          final stations = stationsData.cast(); // StationModel items
          
          LatLng center = const LatLng(AppConstants.defaultLat, AppConstants.defaultLng);
          if (stations.isNotEmpty) {
            center = LatLng(stations.first.latitude, stations.first.longitude);
          }

          final markers = stations.map<Marker>((s) {
            return Marker(
              point: LatLng(s.latitude, s.longitude),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: AppTheme.surface,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) => _buildStationSheet(s),
                  );
                },
                child: const Icon(Icons.location_on, color: AppTheme.primary, size: 40),
              ),
            );
          }).toList();

          List<Polyline> polylines = [];
          if (widget.routeId != null && stations.length > 1) {
            polylines.add(
              Polyline(
                points: stations.map<LatLng>((s) => LatLng(s.latitude, s.longitude)).toList(),
                color: AppTheme.primary,
                strokeWidth: 4.0,
              ),
            );
          }

          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: AppConstants.defaultZoom,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'et.smarttrans',
                tileBuilder: (context, widget, tile) {
                  // Basic dark mode filter for tiles
                  return ColorFiltered(
                    colorFilter: const ColorFilter.matrix([
                      -1,  0,  0, 0, 255,
                       0, -1,  0, 0, 255,
                       0,  0, -1, 0, 255,
                       0,  0,  0, 1,   0,
                    ]),
                    child: widget,
                  );
                },
              ),
              PolylineLayer(polylines: polylines),
              MarkerLayer(markers: markers),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStationSheet(dynamic station) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            station.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            station.description ?? 'No description available',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
