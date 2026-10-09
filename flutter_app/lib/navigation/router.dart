import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/routes/route_search_screen.dart';
import '../screens/routes/route_results_screen.dart';
import '../screens/routes/route_detail_screen.dart';
import '../screens/stations/stations_screen.dart';
import '../screens/stations/station_detail_screen.dart';
import '../screens/stations/nearby_stations_screen.dart';
import '../screens/favorites/favorites_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/reports/submit_report_screen.dart';
import '../screens/reports/my_reports_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/map/map_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_stations_screen.dart';
import '../screens/admin/admin_routes_screen.dart';
import '../screens/admin/admin_reports_screen.dart';
import '../screens/admin/admin_notifications_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      if (isLoading) return null;

      final isAuth = authState.isAuthenticated;
      final isAuthRoute =
          state.matchedLocation == '/login' || state.matchedLocation == '/register';

      // Protected routes
      final protectedRoutes = [
        '/favorites', '/profile', '/reports', '/admin',
      ];
      final isProtected = protectedRoutes.any((r) => state.matchedLocation.startsWith(r));

      if (isProtected && !isAuth) return '/login';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),

      // Routes
      GoRoute(path: '/search', builder: (_, __) => const RouteSearchScreen()),
      GoRoute(
        path: '/search/results',
        builder: (_, state) {
          final extra = state.extra as Map<String, String>?;
          return RouteResultsScreen(
            fromStationId: extra?['from'] ?? '',
            toStationId: extra?['to'] ?? '',
            fromName: extra?['fromName'] ?? '',
            toName: extra?['toName'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/routes/:id',
        builder: (_, state) => RouteDetailScreen(routeId: state.pathParameters['id']!),
      ),

      // Stations
      GoRoute(path: '/stations', builder: (_, __) => const StationsScreen()),
      GoRoute(
        path: '/stations/nearby',
        builder: (_, __) => const NearbyStationsScreen(),
      ),
      GoRoute(
        path: '/stations/:id',
        builder: (_, state) => StationDetailScreen(stationId: state.pathParameters['id']!),
      ),

      // Map
      GoRoute(
        path: '/map',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return MapScreen(
            routeId: extra?['routeId'] as String?,
            stationId: extra?['stationId'] as String?,
          );
        },
      ),

      // Favorites
      GoRoute(path: '/favorites', builder: (_, __) => const FavoritesScreen()),

      // Notifications
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),

      // Reports
      GoRoute(
        path: '/reports/submit',
        builder: (_, state) {
          final extra = state.extra as Map<String, String?>?;
          return SubmitReportScreen(routeId: extra?['routeId']);
        },
      ),
      GoRoute(path: '/reports/my', builder: (_, __) => const MyReportsScreen()),

      // Profile
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),

      // Admin
      GoRoute(path: '/admin', builder: (_, __) => const AdminDashboardScreen()),
      GoRoute(path: '/admin/stations', builder: (_, __) => const AdminStationsScreen()),
      GoRoute(path: '/admin/routes', builder: (_, __) => const AdminRoutesScreen()),
      GoRoute(path: '/admin/reports', builder: (_, __) => const AdminReportsScreen()),
      GoRoute(path: '/admin/notifications', builder: (_, __) => const AdminNotificationsScreen()),
    ],
  );
});
