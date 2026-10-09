// Data Models for SmartTrans Ethiopia

// ─── User ──────────────────────────────────────────────
class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.isActive,
  });

  bool get isAdmin => role == 'admin';

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        role: json['role'] as String? ?? 'passenger',
        isActive: json['is_active'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'is_active': isActive,
      };
}

// ─── City ───────────────────────────────────────────────
class CityModel {
  final String id;
  final String name;
  final String? description;
  final double? latitude;
  final double? longitude;
  final bool isActive;

  const CityModel({
    required this.id,
    required this.name,
    this.description,
    this.latitude,
    this.longitude,
    required this.isActive,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) => CityModel(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        isActive: json['is_active'] as bool? ?? true,
      );
}

// ─── TransportType ──────────────────────────────────────
class TransportTypeModel {
  final String id;
  final String name;
  final String? icon;
  final String? description;
  final bool isActive;

  const TransportTypeModel({
    required this.id,
    required this.name,
    this.icon,
    this.description,
    required this.isActive,
  });

  factory TransportTypeModel.fromJson(Map<String, dynamic> json) =>
      TransportTypeModel(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String?,
        description: json['description'] as String?,
        isActive: json['is_active'] as bool? ?? true,
      );

  String get displayIcon => icon ?? '🚌';
}

// ─── Station ────────────────────────────────────────────
class StationModel {
  final String id;
  final String name;
  final String? description;
  final String cityId;
  final double latitude;
  final double longitude;
  final String? operatingHours;
  final String status;
  final CityModel? city;

  const StationModel({
    required this.id,
    required this.name,
    this.description,
    required this.cityId,
    required this.latitude,
    required this.longitude,
    this.operatingHours,
    required this.status,
    this.city,
  });

  factory StationModel.fromJson(Map<String, dynamic> json) => StationModel(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        cityId: json['city_id'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        operatingHours: json['operating_hours'] as String?,
        status: json['status'] as String? ?? 'active',
        city: json['city'] != null
            ? CityModel.fromJson(json['city'] as Map<String, dynamic>)
            : null,
      );
}

class NearbyStationModel {
  final StationModel station;
  final double distanceMeters;

  const NearbyStationModel({
    required this.station,
    required this.distanceMeters,
  });

  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    } else {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  factory NearbyStationModel.fromJson(Map<String, dynamic> json) =>
      NearbyStationModel(
        station: StationModel.fromJson(json['station'] as Map<String, dynamic>),
        distanceMeters: (json['distance_meters'] as num).toDouble(),
      );
}

// ─── RouteStop ──────────────────────────────────────────
class RouteStopModel {
  final String id;
  final String routeId;
  final String stationId;
  final int stopOrder;
  final StationModel? station;

  const RouteStopModel({
    required this.id,
    required this.routeId,
    required this.stationId,
    required this.stopOrder,
    this.station,
  });

  factory RouteStopModel.fromJson(Map<String, dynamic> json) => RouteStopModel(
        id: json['id'] as String,
        routeId: json['route_id'] as String,
        stationId: json['station_id'] as String,
        stopOrder: json['stop_order'] as int,
        station: json['station'] != null
            ? StationModel.fromJson(json['station'] as Map<String, dynamic>)
            : null,
      );
}

// ─── Fare ───────────────────────────────────────────────
class FareModel {
  final String id;
  final String routeId;
  final String transportTypeId;
  final double amount;
  final String currency;
  final TransportTypeModel? transportType;

  const FareModel({
    required this.id,
    required this.routeId,
    required this.transportTypeId,
    required this.amount,
    required this.currency,
    this.transportType,
  });

  factory FareModel.fromJson(Map<String, dynamic> json) => FareModel(
        id: json['id'] as String,
        routeId: json['route_id'] as String,
        transportTypeId: json['transport_type_id'] as String,
        amount: (json['amount'] as num).toDouble(),
        currency: json['currency'] as String? ?? 'ETB',
        transportType: json['transport_type'] != null
            ? TransportTypeModel.fromJson(
                json['transport_type'] as Map<String, dynamic>)
            : null,
      );

  String get formattedAmount => '${amount.toStringAsFixed(0)} $currency';
}

// ─── Route ──────────────────────────────────────────────
class RouteModel {
  final String id;
  final String name;
  final String cityId;
  final String transportTypeId;
  final int? estimatedTime;
  final double? distance;
  final String? operatingHours;
  final String status;
  final TransportTypeModel? transportType;
  final List<RouteStopModel> routeStops;
  final List<FareModel> fares;

  const RouteModel({
    required this.id,
    required this.name,
    required this.cityId,
    required this.transportTypeId,
    this.estimatedTime,
    this.distance,
    this.operatingHours,
    required this.status,
    this.transportType,
    this.routeStops = const [],
    this.fares = const [],
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) => RouteModel(
        id: json['id'] as String,
        name: json['name'] as String,
        cityId: json['city_id'] as String,
        transportTypeId: json['transport_type_id'] as String,
        estimatedTime: json['estimated_time'] as int?,
        distance: (json['distance'] as num?)?.toDouble(),
        operatingHours: json['operating_hours'] as String?,
        status: json['status'] as String? ?? 'active',
        transportType: json['transport_type'] != null
            ? TransportTypeModel.fromJson(
                json['transport_type'] as Map<String, dynamic>)
            : null,
        routeStops: (json['route_stops'] as List<dynamic>? ?? [])
            .map((e) => RouteStopModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        fares: (json['fares'] as List<dynamic>? ?? [])
            .map((e) => FareModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  String get primaryFareFormatted =>
      fares.isNotEmpty ? fares.first.formattedAmount : 'N/A';
  String get transportIcon =>
      transportType?.displayIcon ?? '🚌';
  String get estimatedTimeFormatted =>
      estimatedTime != null ? '$estimatedTime min' : 'N/A';
}

// ─── Route Search Result ─────────────────────────────────
class RouteSearchResult {
  final RouteModel route;
  final int transfers;
  final int estimatedTime;
  final double estimatedFare;
  final bool isMultiRoute;
  final List<RouteModel> routes;

  const RouteSearchResult({
    required this.route,
    required this.transfers,
    required this.estimatedTime,
    required this.estimatedFare,
    this.isMultiRoute = false,
    this.routes = const [],
  });

  factory RouteSearchResult.fromJson(Map<String, dynamic> json) =>
      RouteSearchResult(
        route: RouteModel.fromJson(json['route'] as Map<String, dynamic>),
        transfers: json['transfers'] as int? ?? 0,
        estimatedTime: json['estimated_time'] as int? ?? 0,
        estimatedFare: (json['estimated_fare'] as num?)?.toDouble() ?? 0,
        isMultiRoute: json['is_multi_route'] as bool? ?? false,
        routes: (json['routes'] as List<dynamic>? ?? [])
            .map((e) => RouteModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  String get fareFormatted => '${estimatedFare.toStringAsFixed(0)} ETB';
  String get timeFormatted => '$estimatedTime min';
}

// ─── Favorite ───────────────────────────────────────────
class FavoriteModel {
  final String id;
  final String userId;
  final String routeId;
  final String? label;
  final RouteModel? route;

  const FavoriteModel({
    required this.id,
    required this.userId,
    required this.routeId,
    this.label,
    this.route,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) => FavoriteModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        routeId: json['route_id'] as String,
        label: json['label'] as String?,
        route: json['route'] != null
            ? RouteModel.fromJson(json['route'] as Map<String, dynamic>)
            : null,
      );
}

// ─── Report ─────────────────────────────────────────────
class ReportModel {
  final String id;
  final String? userId;
  final String? routeId;
  final String reportType;
  final String description;
  final String status;
  final String? adminNotes;

  const ReportModel({
    required this.id,
    this.userId,
    this.routeId,
    required this.reportType,
    required this.description,
    required this.status,
    this.adminNotes,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) => ReportModel(
        id: json['id'] as String,
        userId: json['user_id'] as String?,
        routeId: json['route_id'] as String?,
        reportType: json['report_type'] as String,
        description: json['description'] as String,
        status: json['status'] as String? ?? 'pending',
        adminNotes: json['admin_notes'] as String?,
      );

  String get reportTypeDisplay {
    return switch (reportType) {
      'route_unavailable' => 'Route Unavailable',
      'station_closed' => 'Station Closed',
      'fare_changed' => 'Fare Changed',
      'heavy_traffic' => 'Heavy Traffic',
      'incorrect_info' => 'Incorrect Information',
      _ => 'Other',
    };
  }
}

// ─── Notification ────────────────────────────────────────
class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String notificationType;
  final bool isActive;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.notificationType,
    required this.isActive,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
        notificationType: json['notification_type'] as String? ?? 'info',
        isActive: json['is_active'] as bool? ?? true,
        isRead: json['is_read'] as bool? ?? false,
      );
}

// ─── Dashboard Stats ─────────────────────────────────────
class DashboardStats {
  final int totalUsers;
  final int totalStations;
  final int totalRoutes;
  final int totalReports;
  final int activeRoutes;
  final int pendingReports;

  const DashboardStats({
    required this.totalUsers,
    required this.totalStations,
    required this.totalRoutes,
    required this.totalReports,
    required this.activeRoutes,
    required this.pendingReports,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
        totalUsers: json['total_users'] as int? ?? 0,
        totalStations: json['total_stations'] as int? ?? 0,
        totalRoutes: json['total_routes'] as int? ?? 0,
        totalReports: json['total_reports'] as int? ?? 0,
        activeRoutes: json['active_routes'] as int? ?? 0,
        pendingReports: json['pending_reports'] as int? ?? 0,
      );
}
