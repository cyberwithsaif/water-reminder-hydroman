import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../services/api_service.dart';
import '../services/sync_service.dart';

// Singleton ApiService
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Singleton SyncService
final syncServiceProvider = Provider<SyncService>((ref) {
  final api = ref.watch(apiServiceProvider);
  return SyncService(api);
});

// Auth state
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final api = ref.watch(apiServiceProvider);
  final sync = ref.watch(syncServiceProvider);
  return AuthNotifier(api, sync);
});

// Convenience provider to check if logged in
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isLoggedIn;
});

class AuthState {
  final String? token;
  final String? phone;
  final bool isLoading;
  final String? error;

  const AuthState({this.token, this.phone, this.isLoading = false, this.error});

  bool get isLoggedIn => token != null;

  AuthState copyWith({
    String? token,
    String? phone,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      token: token ?? this.token,
      phone: phone ?? this.phone,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api;
  final SyncService _sync;
  static const String _authBox = 'auth';
  Future<void>? _loadTokenFuture;

  AuthNotifier(this._api, this._sync) : super(const AuthState()) {
    _loadTokenFuture = _loadSavedToken();
  }

  /// Wait for the saved token to be loaded from Hive.
  /// Call this before checking isLoggedIn to avoid race conditions.
  Future<void> ensureLoaded() async {
    await _loadTokenFuture;
  }

  Future<void> _loadSavedToken() async {
    final box = await Hive.openBox(_authBox);
    final token = box.get('token') as String?;
    final phone = box.get('phone') as String?;
    if (token != null) {
      _api.setToken(token);
      state = AuthState(token: token, phone: phone);
      // Fire-and-forget sync — don't block app startup
      _sync.syncAll().catchError((e) {
        debugPrint('AuthNotifier: Background sync failed: $e');
      });
    }
  }

  Future<bool> sendOtp(String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.sendOtp(phone);
      state = state.copyWith(isLoading: false, phone: phone);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Connection failed');
      return false;
    }
  }

  Future<bool> verifyOtp(String phone, String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _api.verifyOtp(phone, code);
      final token = result['token'] as String;

      _api.setToken(token);

      // Persist
      final box = await Hive.openBox(_authBox);
      await box.put('token', token);
      await box.put('phone', phone);

      state = AuthState(token: token, phone: phone);

      // Trigger sync after login and wait for it to complete so we can skip onboarding if they exist
      await _sync.syncAll();

      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Connection failed');
      return false;
    }
  }

  Future<void> logout() async {
    _api.setToken(null);
    final box = await Hive.openBox(_authBox);
    await box.delete('token');
    await box.delete('phone');
    state = const AuthState();
  }
}
