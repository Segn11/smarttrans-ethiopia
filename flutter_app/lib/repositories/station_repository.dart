import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_client.dart';
import '../models/models.dart';

class StationRepository {
  final Dio _dio;
  StationRepository(this._dio);

  Future<List<StationModel>> listStations({String? cityId}) async {
    final response = await _dio.get('/stations', queryParameters: {
      if (cityId != null) 'city_id': cityId,
      'limit': 100,
    });
    final data = response.data['data'] as List<dynamic>;
    return data.map((e) => StationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<StationModel> getStation(String id) async {
    final response = await _dio.get('/stations/$id');
    return StationModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<NearbyStationModel>> getNearbyStations({
    required double latitude,
    required double longitude,
    double radius = 2000,
  }) async {
    final response = await _dio.get('/stations/nearby', queryParameters: {
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
    });
    final data = response.data['data'] as List<dynamic>;
    return data.map((e) => NearbyStationModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final stationRepositoryProvider = Provider<StationRepository>((ref) {
  return StationRepository(ref.read(dioProvider));
});
