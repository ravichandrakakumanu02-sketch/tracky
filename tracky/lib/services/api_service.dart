import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/workout_model.dart';
import 'auth_service.dart';

/// Exception thrown when an API operation fails.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

/// Service handling all HTTP communication with the Tracky Node.js backend.
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal();

  /// Default API base URL configured for the Android emulator.
  /// Automatically uses localhost for Web and Desktop platforms.
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:3000';
      }
    } catch (_) {
      // Fallback if Platform check is unsupported
    }
    return 'http://localhost:3000';
  }

  String _baseUrl = defaultBaseUrl;

  /// Get current base URL.
  String get baseUrl => _baseUrl;

  /// Custom base URL setter (e.g. if testing on a physical device with a LAN IP).
  set baseUrl(String url) {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static const Duration _timeout = Duration(seconds: 10);

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = AuthService().token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  String _extractErrorMessage(http.Response response, String fallback) {
    try {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['error'] != null) {
        return decoded['error'].toString();
      }
    } catch (_) {}
    return '$fallback (HTTP ${response.statusCode})';
  }

  void _checkUnauthorized(int statusCode) {
    if (statusCode == 401) {
      AuthService().handleUnauthorized();
    }
  }

  // ---------------------------------------------------------------------------
  // AUTHENTICATION APIS
  // ---------------------------------------------------------------------------

  /// POST /api/auth/register
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    final uri = Uri.parse('$_baseUrl/api/auth/register');
    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode({
              'name': name.trim(),
              'email': email.trim().toLowerCase(),
              'password': password,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw ApiException(
          _extractErrorMessage(response, 'Registration failed'),
          response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      throw ApiException(
        'Could not reach server at $_baseUrl. Please ensure your backend is running. ($e)',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error during registration: $e');
    }
  }

  /// POST /api/auth/login
  Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final uri = Uri.parse('$_baseUrl/api/auth/login');
    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode({
              'email': email.trim().toLowerCase(),
              'password': password,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw ApiException(
          _extractErrorMessage(response, 'Login failed'),
          response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      throw ApiException(
        'Could not reach server at $_baseUrl. Please ensure your backend is running. ($e)',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error during login: $e');
    }
  }

  /// GET /api/auth/me
  Future<UserModel> getCurrentUser(String token) async {
    final uri = Uri.parse('$_baseUrl/api/auth/me');
    try {
      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final userData = decoded['user'] as Map<String, dynamic>;
        return UserModel.fromMap(userData);
      } else {
        _checkUnauthorized(response.statusCode);
        throw ApiException(
          _extractErrorMessage(response, 'Failed to fetch user profile'),
          response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      throw ApiException(
        'Could not reach server at $_baseUrl. ($e)',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error fetching profile: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // WORKOUT APIS (PROTECTED)
  // ---------------------------------------------------------------------------

  /// GET /api/workouts — retrieve all workouts for the authenticated user
  Future<List<Workout>> getWorkouts() async {
    final uri = Uri.parse('$_baseUrl/api/workouts');
    try {
      final response = await http.get(uri, headers: _headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded
              .map((item) => Workout.fromMap(item as Map<String, dynamic>))
              .toList();
        }
        return [];
      } else {
        _checkUnauthorized(response.statusCode);
        throw ApiException(
          _extractErrorMessage(response, 'Failed to load workouts'),
          response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      throw ApiException(
        'Could not reach server at $_baseUrl. Please ensure your backend is running. ($e)',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error while loading workouts: $e');
    }
  }

  /// POST /api/workouts — create a new workout for the authenticated user
  Future<Workout> createWorkout(Workout workout) async {
    final uri = Uri.parse('$_baseUrl/api/workouts');
    try {
      final response = await http
          .post(
            uri,
            headers: _headers,
            body: jsonEncode(workout.toMap()),
          )
          .timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        return Workout.fromMap(data);
      } else {
        _checkUnauthorized(response.statusCode);
        throw ApiException(
          _extractErrorMessage(response, 'Failed to create workout'),
          response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      throw ApiException(
        'Could not reach server at $_baseUrl. Please ensure your backend is running. ($e)',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error while saving workout: $e');
    }
  }

  /// PUT /api/workouts/:id — update an existing workout
  Future<Workout> updateWorkout(Workout workout) async {
    if (workout.id.isEmpty) {
      throw const ApiException('Cannot update a workout without a valid ID');
    }

    final uri = Uri.parse('$_baseUrl/api/workouts/${workout.id}');
    try {
      final response = await http
          .put(
            uri,
            headers: _headers,
            body: jsonEncode(workout.toMap()),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        return Workout.fromMap(data);
      } else {
        _checkUnauthorized(response.statusCode);
        throw ApiException(
          _extractErrorMessage(response, 'Failed to update workout'),
          response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      throw ApiException(
        'Could not reach server at $_baseUrl. Please ensure your backend is running. ($e)',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error while updating workout: $e');
    }
  }

  /// DELETE /api/workouts/:id — delete a workout
  Future<void> deleteWorkout(String id) async {
    if (id.isEmpty) {
      throw const ApiException('Cannot delete a workout without a valid ID');
    }

    final uri = Uri.parse('$_baseUrl/api/workouts/$id');
    try {
      final response = await http
          .delete(uri, headers: _headers)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return;
      } else {
        _checkUnauthorized(response.statusCode);
        throw ApiException(
          _extractErrorMessage(response, 'Failed to delete workout'),
          response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      throw ApiException(
        'Could not reach server at $_baseUrl. Please ensure your backend is running. ($e)',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error while deleting workout: $e');
    }
  }
}
