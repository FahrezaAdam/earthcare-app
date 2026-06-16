import '../../../../core/network/api_client.dart';
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
        data: {'report_id': reportId, 'content': content},
      );

      if (response.statusCode == 201) {
        return CommentModel.fromJson(response.data['data']);
      } else {
        throw Exception(
          response.data['message'] ?? 'Gagal menambahkan komentar',
        );
      }
    } catch (e) {
      throw Exception('Gagal menambahkan komentar: $e');
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      final response = await _apiClient.dio.delete('/api/comments/$commentId');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          response.data['message'] ?? 'Gagal menghapus komentar',
        );
      }
    } catch (e) {
      throw Exception('Gagal menghapus komentar: $e');
    }
  }
}
