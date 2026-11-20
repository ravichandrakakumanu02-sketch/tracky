import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'auth_service.dart';

class ChatMessage {
  String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
  };
}

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final ApiService _apiService = ApiService();

  /// Returns a stream of AI response chunks.
  Stream<String> getChatStream(String message, List<ChatMessage> history) async* {
    final url = Uri.parse('${_apiService.baseUrl}/api/ai/chat');
    
    final token = AuthService().token;
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final client = http.Client();
    final request = http.Request('POST', url);
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
    request.body = jsonEncode({
      'message': message,
      'history': history.map((m) => m.toJson()).toList(),
      'stream': true,
    });

    try {
      final response = await client.send(request).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        final errorData = jsonDecode(body);
        throw Exception(errorData['error'] ?? 'Failed to get AI response');
      }

      // Listen to the stream of chunks
      await for (final chunk in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
        if (chunk.startsWith('data: ')) {
          final data = chunk.substring(6).trim();
          if (data == '[DONE]') {
            break;
          }
          try {
            final json = jsonDecode(data);
            if (json['content'] != null) {
              yield json['content'];
            }
            if (json['error'] != null) {
              throw Exception(json['error']);
            }
          } catch (e) {
            // Ignore parse errors for partial chunks if they happen
          }
        }
      }
    } finally {
      client.close();
    }
  }

  // Deprecated: Maintained for backward compatibility if needed elsewhere
  Future<String> getChatResponse(String message, List<ChatMessage> history) async {
    final url = Uri.parse('${_apiService.baseUrl}/api/ai/chat');
    
    final token = AuthService().token;
    if (token == null) {
      throw Exception('Not authenticated');
    }

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'message': message,
          'history': history.map((m) => m.toJson()).toList(),
          'stream': false,
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reply'];
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get AI response');
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception('Network error. Please check your connection.');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getRecommendations() async {
    final response = await getChatResponse("Analyze my workout progress and provide a recommendation.", []);
    return {
      'recommendation': response,
      'hasData': true,
    };
  }
}
