import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'workout_service.dart';

/// Manages authentication state, secure token storage, and session lifecycles.
class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal();

  static const String _tokenStorageKey = 'tracky_jwt_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  UserModel? _currentUser;
  String? _token;
  bool _isInitialized = false;

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _token != null && _currentUser != null;

  /// Initialize session on application boot by checking stored JWT token.
  Future<bool> init() async {
    try {
      final savedToken = await _storage.read(key: _tokenStorageKey);
      if (savedToken == null || savedToken.isEmpty) {
        _token = null;
        _currentUser = null;
        _isInitialized = true;
        notifyListeners();
        return false;
      }

      _token = savedToken;
      // Validate token with backend /api/auth/me
      final user = await ApiService().getCurrentUser(savedToken);
      _currentUser = user;
      _isInitialized = true;
      notifyListeners();
      return true;
    } catch (_) {
      // If token is invalid, expired, or network fails on boot
      await _storage.delete(key: _tokenStorageKey);
      _token = null;
      _currentUser = null;
      _isInitialized = true;
      notifyListeners();
      return false;
    }
  }

  /// Register a new user with name, email, and password.
  /// Returns null on success, or an error message string on failure.
  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final data = await ApiService().register(name, email, password);
      final rawToken = data['token'] as String?;
      final userData = data['user'] as Map<String, dynamic>?;

      if (rawToken == null || userData == null) {
        return 'Invalid response received from server.';
      }

      _token = rawToken;
      _currentUser = UserModel.fromMap(userData);
      await _storage.write(key: _tokenStorageKey, value: rawToken);

      // Refresh workouts for the newly registered user
      await WorkoutService().loadWorkouts();

      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Registration failed: $e';
    }
  }

  /// Log in an existing user with email and password.
  /// Returns null on success, or an error message string on failure.
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      final data = await ApiService().login(email, password);
      final rawToken = data['token'] as String?;
      final userData = data['user'] as Map<String, dynamic>?;

      if (rawToken == null || userData == null) {
        return 'Invalid response received from server.';
      }

      _token = rawToken;
      _currentUser = UserModel.fromMap(userData);
      await _storage.write(key: _tokenStorageKey, value: rawToken);

      // Load workouts belonging to the logged-in user
      await WorkoutService().loadWorkouts();

      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Login failed: $e';
    }
  }

  /// Fetch or refresh the current user profile from the backend using the active JWT token.
  Future<UserModel?> fetchCurrentUser() async {
    if (_currentUser != null) return _currentUser;
    if (_token == null) {
      final savedToken = await _storage.read(key: _tokenStorageKey);
      if (savedToken == null || savedToken.isEmpty) return null;
      _token = savedToken;
    }
    try {
      final user = await ApiService().getCurrentUser(_token!);
      _currentUser = user;
      notifyListeners();
      return _currentUser;
    } catch (_) {
      return _currentUser;
    }
  }

  /// Log out the currently authenticated user and clear sensitive state.
  Future<void> logout() async {
    try {
      await _storage.delete(key: _tokenStorageKey);
    } catch (_) {}

    _token = null;
    _currentUser = null;

    // Clear workouts from active in-memory state
    WorkoutService().clearActiveSessionWorkouts();

    notifyListeners();
  }

  /// Handle unexpected 401 Unauthorized errors from API calls.
  void handleUnauthorized() {
    logout();
  }
}
