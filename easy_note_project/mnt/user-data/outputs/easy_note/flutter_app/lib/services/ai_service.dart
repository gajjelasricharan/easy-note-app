// lib/services/ai_service.dart
import 'dart:io';
import 'package:dio/dio.dart';

class AIService {
  // Replace with your deployed Node.js backend URL
  static const String _baseUrl = 'https://your-backend.com/api';

  final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    headers: {'Content-Type': 'application/json'},
  ));

  /// Transcribe audio file to text
  Future<String?> transcribeAudio(File audioFile, String authToken) async {
    try {
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(
          audioFile.path,
          filename: 'recording.m4a',
        ),
      });

      final response = await _dio.post(
        '/ai/transcribe',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      return response.data['transcript'] as String?;
    } on DioException catch (e) {
      print('Transcription error: ${e.message}');
      return null;
    }
  }

  /// Summarize note content
  Future<String?> summarizeNote(String content, String authToken) async {
    try {
      final response = await _dio.post(
        '/ai/summarize',
        data: {'content': content},
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );
      return response.data['summary'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Generate smart tags from content
  Future<List<String>> generateTags(String content, String authToken) async {
    try {
      final response = await _dio.post(
        '/ai/tags',
        data: {'content': content},
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );
      return List<String>.from(response.data['tags'] ?? []);
    } catch (e) {
      return [];
    }
  }

  /// Convert note to checklist
  Future<List<Map<String, dynamic>>?> convertToChecklist(
    String content,
    String authToken,
  ) async {
    try {
      final response = await _dio.post(
        '/ai/checklist',
        data: {'content': content},
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );
      return List<Map<String, dynamic>>.from(response.data['items'] ?? []);
    } catch (e) {
      return null;
    }
  }

  /// Detect content type: shopping, medicine, reminder, general
  Future<String?> detectContentType(String content, String authToken) async {
    try {
      final response = await _dio.post(
        '/ai/detect-type',
        data: {'content': content},
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );
      return response.data['type'] as String?;
    } catch (e) {
      return null;
    }
  }
}
