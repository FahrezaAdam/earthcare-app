import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'comment_model.dart';

class CommentRepository {
  final ApiClient _apiClient;

  CommentRepository(this._apiClient);

  Future<List<CommentModel>> getComments(String reportId) async {
    try {
      final response = await _apiClient.dio.get('/api/comments/$reportId');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => CommentModel.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Gagal memuat komentar');
      }
    } catch (e) {
      throw Exception('Gagal memuat komentar: $e');
    }
  }

  Future<CommentModel> addComment(String reportId, String content) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/comments',
        data: {
          'report_id': reportId,
          'content': content,
        },
      );
      
      if (response.statusCode == 201) {
        return CommentModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Gagal menambahkan komentar');
      }
    } catch (e) {
      throw Exception('Gagal menambahkan komentar: $e');
    }
  }
}
