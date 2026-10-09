import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/auth_repository.dart';
import '../repositories/repositories.dart';

// ─── Auth Provider ───────────────────────────────────────

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;
  bool get isAdmin => user?.isAdmin ?? false;

  AuthState copyWith({UserModel? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    final user = await _repo.getMe();
    state = state.copyWith(user: user, isLoading: false);
  }

  Future<String?> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repo.login(email: email, password: password);
      state = state.copyWith(user: user, isLoading: false);
      return null;
    } catch (e) {
      final msg = _extractError(e);
      state = state.copyWith(isLoading: false, error: msg);
      return msg;
    }
  }

  Future<String?> register(String name, String email, String password, [String? phone]) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.register(name: name, email: email, password: password, phone: phone);
      state = state.copyWith(isLoading: false);
      return null;
    } catch (e) {
      final msg = _extractError(e);
      state = state.copyWith(isLoading: false, error: msg);
      return msg;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState();
  }

  Future<String?> updateProfile(String? name, String? phone) async {
    try {
      final user = await _repo.updateProfile(name: name, phone: phone);
      state = state.copyWith(user: user);
      return null;
    } catch (e) {
      return _extractError(e);
    }
  }

  String _extractError(dynamic e) {
    try {
      final data = (e as dynamic).response?.data;
      if (data is Map) {
        return data['detail']?.toString() ?? data['message']?.toString() ?? 'An error occurred';
      }
    } catch (_) {}
    return e.toString();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

// ─── Stations Provider ────────────────────────────────────

final stationsProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.read(stationRepositoryProvider);
  return repo.listStations();
});

final nearbyStationsProvider = FutureProvider.family<List<dynamic>, Map<String, double>>(
    (ref, coords) async {
  final repo = ref.read(stationRepositoryProvider);
  return repo.getNearbyStations(
    latitude: coords['lat']!,
    longitude: coords['lng']!,
    radius: coords['radius'] ?? 2000,
  );
});

final stationDetailProvider = FutureProvider.family<dynamic, String>((ref, id) async {
  final repo = ref.read(stationRepositoryProvider);
  return repo.getStation(id);
});

// ─── Routes Provider ─────────────────────────────────────

final routesProvider = FutureProvider<List<RouteModel>>((ref) async {
  final repo = ref.read(routeRepositoryProvider);
  return repo.listRoutes();
});

final routeDetailProvider = FutureProvider.family<RouteModel, String>((ref, id) async {
  final repo = ref.read(routeRepositoryProvider);
  return repo.getRoute(id);
});

class RouteSearchParams {
  final String from;
  final String to;
  final String sortBy;
  RouteSearchParams({required this.from, required this.to, this.sortBy = 'fastest'});
}

final routeSearchProvider =
    FutureProvider.family<List<RouteSearchResult>, RouteSearchParams>((ref, params) async {
  final repo = ref.read(routeRepositoryProvider);
  return repo.searchRoutes(
    fromStation: params.from,
    toStation: params.to,
    sortBy: params.sortBy,
  );
});

// ─── Favorites Provider ──────────────────────────────────

class FavoritesNotifier extends StateNotifier<AsyncValue<List<FavoriteModel>>> {
  final FavoriteRepository _repo;

  FavoritesNotifier(this._repo) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final favs = await _repo.listFavorites();
      state = AsyncValue.data(favs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> add(String routeId, [String? label]) async {
    await _repo.addFavorite(routeId: routeId, label: label);
    await _load();
  }

  Future<void> remove(String id) async {
    await _repo.removeFavorite(id);
    await _load();
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, AsyncValue<List<FavoriteModel>>>((ref) {
  return FavoritesNotifier(ref.read(favoriteRepositoryProvider));
});

// ─── Notifications Provider ──────────────────────────────

final notificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  final repo = ref.read(notificationRepositoryProvider);
  return repo.listNotifications();
});

// ─── Reports Provider ─────────────────────────────────────

final myReportsProvider = FutureProvider<List<ReportModel>>((ref) async {
  final repo = ref.read(reportRepositoryProvider);
  return repo.myReports();
});

// ─── Admin Providers ──────────────────────────────────────

final dashboardProvider = FutureProvider<DashboardStats>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  return repo.getDashboard();
});

final adminStationsProvider = FutureProvider<List<StationModel>>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  return repo.listStations();
});

final adminRoutesProvider = FutureProvider<List<RouteModel>>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  return repo.listRoutes();
});

final adminReportsProvider = FutureProvider<List<ReportModel>>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  return repo.listReports();
});

final adminNotificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  return repo.listNotifications();
});
