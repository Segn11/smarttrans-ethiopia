// App Constants
class AppConstants {
  // API
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';
  // For physical device testing, change to your machine's local IP:
  // static const String baseUrl = 'http://192.168.1.xxx:8000/api/v1';
  // For production, change to your deployed FastAPI URL

  // Storage keys
  static const String tokenKey = 'access_token';
  static const String userKey = 'user_data';

  // Default location (Addis Ababa center)
  static const double defaultLat = 9.0320;
  static const double defaultLng = 38.7469;

  // Map
  static const double defaultZoom = 13.0;
  static const double nearbyRadius = 2000; // meters

  // Pagination
  static const int pageSize = 20;

  // Transport type icons (emoji fallback)
  static const Map<String, String> transportIcons = {
    'Minibus': '🚐',
    'Bus': '🚌',
    'LRT': '🚊',
    'Taxi': '🚕',
  };
}
