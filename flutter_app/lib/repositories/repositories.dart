import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_client.dart';
import '../models/models.dart';

class RouteRepository {
  final Dio _dio;
  RouteRepository(this._dio);

  Future<List<RouteModel>> listRoutes({String? cityId, String? status}) async {
    final response = await _dio.get('/routes', queryParameters: {
      if (cityId != null) 'city_id': cityId,
      if (status != null) 'status': status,
      'limit': 100,
    });
    final data = response.data['data'] as List<dynamic>;
    return data.map((e) => RouteModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<RouteModel> getRoute(String id) async {
    final response = await _dio.get('/routes/$id');
    return RouteModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<RouteSearchResult>> searchRoutes({
    required String fromStation,
    required String toStation,
    String sortBy = 'fastest',
  }) async {
    final response = await _dio.get('/routes/search', queryParameters: {
      'from': fromStation,
      'to': toStation,
      'sort_by': sortBy,
    });
    if (response.data['success'] == false) return [];
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => RouteSearchResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class FavoriteRepository {
  final Dio _dio;
  FavoriteRepository(this._dio);

  Future<List<FavoriteModel>> listFavorites() async {
    final response = await _dio.get('/favorites');
    final data = response.data['data'] as List<dynamic>;
    return data.map((e) => FavoriteModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<FavoriteModel> addFavorite({required String routeId, String? label}) async {
    final response = await _dio.post('/favorites', data: {
      'route_id': routeId,
      if (label != null) 'label': label,
    });
    return FavoriteModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> removeFavorite(String id) async {
    await _dio.delete('/favorites/$id');
  }
}

class ReportRepository {
  final Dio _dio;
  ReportRepository(this._dio);

  Future<ReportModel> submitReport({
    required String reportType,
    required String description,
    String? routeId,
  }) async {
    final response = await _dio.post('/reports', data: {
      'report_type': reportType,
      'description': description,
      if (routeId != null) 'route_id': routeId,
    });
    return ReportModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<ReportModel>> myReports() async {
    final response = await _dio.get('/reports/my');
    final data = response.data['data'] as List<dynamic>;
    return data.map((e) => ReportModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}

class NotificationRepository {
  final Dio _dio;
  NotificationRepository(this._dio);

  Future<List<NotificationModel>> listNotifications() async {
    final response = await _dio.get('/notifications');
    final data = response.data['data'] as List<dynamic>;
    return data.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> markRead(String id) async {
    await _dio.put('/notifications/$id/read');
  }
}

class AdminRepository {
  final Dio _dio;
  AdminRepository(this._dio);

  Future<DashboardStats> getDashboard() async {
    final response = await _dio.get('/admin/dashboard');
    return DashboardStats.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<StationModel>> listStations() async {
    final response = await _dio.get('/admin/stations', queryParameters: {'limit': 200});
    final data = response.data['data'] as List<dynamic>;
    return data.map((e) => StationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<StationModel> createStation(Map<String, dynamic> data) async {
    final response = await _dio.post('/admin/stations', data: data);
    return StationModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<StationModel> updateStation(String id, Map<String, dynamic> data) async {
    final response = await _dio.put('/admin/stations/$id', data: data);
    return StationModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteStation(String id) async {
    await _dio.delete('/admin/stations/$id');
  }

  Future<List<RouteModel>> listRoutes() async {
    final response = await _dio.get('/admin/routes', queryParameters: {'limit': 200});
    final data = response.data['data'] as List<dynamic>;
    return data.map((e) => RouteModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<RouteModel> createRoute(Map<String, dynamic> data) async {
    final response = await _dio.post('/admin/routes', data: data);
    return RouteModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<RouteModel> updateRoute(String id, Map<String, dynamic> data) async {
    final response = await _dio.put('/admin/routes/$id', data: data);
    return RouteModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteRoute(String id) async {
    await _dio.delete('/admin/routes/$id');
  }

  Future<List<ReportModel>> listReports({String? status}) async {
    final response = await _dio.get('/admin/reports', queryParameters: {
      if (status != null) 'status': status,
    });
    final data = response.data['data'] as List<dynamic>;
    return data.map((e) => ReportModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> updateReport(String id, String status, {String? adminNotes}) async {
    await _dio.put('/admin/reports/$id', data: {
      'status': status,
      if (adminNotes != null) 'admin_notes': adminNotes,
    });
  }

  Future<List<NotificationModel>> listNotifications() async {
    final response = await _dio.get('/admin/notifications');
    final data = response.data['data'] as List<dynamic>;
    return data.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<NotificationModel> createNotification({
    required String title,
    required String message,
    String type = 'info',
  }) async {
    final response = await _dio.post('/admin/notifications', data: {
      'title': title,
      'message': message,
      'notification_type': type,
    });
    return NotificationModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteNotification(String id) async {
    await _dio.delete('/admin/notifications/$id');
  }
}

// Providers
final routeRepositoryProvider = Provider<RouteRepository>((ref) {
  return RouteRepository(ref.read(dioProvider));
});

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  return FavoriteRepository(ref.read(dioProvider));
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(ref.read(dioProvider));
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.read(dioProvider));
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.read(dioProvider));
});
