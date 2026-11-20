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

      // Restore demo session without hitting the backend.
      if (savedToken == 'demo_token_no_backend') {
        _token = savedToken;
        _currentUser = UserModel(
          id: 0,
          name: 'Demo User',
          email: _demoEmail,
          createdAt: DateTime(2024, 1, 1),
        );
        _isInitialized = true;
        notifyListeners();
        return true;
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

  // ─── Demo credentials (no backend required) ───────────────────────────────
  static const String _demoEmail = 'demo@gmail.com';
  static const String _demoPassword = 'demo@123';

  /// Checks if the given credentials match the built-in demo account.
  bool _isDemoLogin(String email, String password) =>
      email.toLowerCase().trim() == _demoEmail && password == _demoPassword;

  /// Performs a local demo login — sets a fake user and skips any network call.
  Future<String?> _loginAsDemo() async {
    _token = 'demo_token_no_backend';
    _currentUser = UserModel(
      id: 0,
      name: 'Demo User',
      email: _demoEmail,
      createdAt: DateTime(2024, 1, 1),
    );
    // Persist a demo token so splash screen keeps the session alive.
    await _storage.write(key: _tokenStorageKey, value: _token!);
    // Load empty workout list (no backend, starts fresh).
    WorkoutService().clearActiveSessionWorkouts();
    notifyListeners();
    return null; // null = success
  }
  // ──────────────────────────────────────────────────────────────────────────

  /// Log in an existing user with email and password.
  /// Returns null on success, or an error message string on failure.
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    // Demo shortcut — works without backend.
    if (_isDemoLogin(email, password)) {
      return _loginAsDemo();
    }

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
    // Demo session — no backend call needed.
    if (_token == 'demo_token_no_backend') {
      _currentUser = UserModel(
        id: 0,
        name: 'Demo User',
        email: _demoEmail,
        createdAt: DateTime(2024, 1, 1),
      );
      notifyListeners();
      return _currentUser;
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
