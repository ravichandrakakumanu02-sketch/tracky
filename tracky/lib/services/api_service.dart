import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/workout_model.dart';

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
  return 'http://192.168.1.32:3000';
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

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// GET /api/workouts — retrieve all workouts
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
        throw ApiException(
          'Failed to load workouts (HTTP ${response.statusCode})',
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

  /// POST /api/workouts — create a new workout
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
        throw ApiException(
          'Failed to create workout (HTTP ${response.statusCode}): ${response.body}',
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
        throw ApiException(
          'Failed to update workout (HTTP ${response.statusCode}): ${response.body}',
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
        throw ApiException(
          'Failed to delete workout (HTTP ${response.statusCode})',
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
