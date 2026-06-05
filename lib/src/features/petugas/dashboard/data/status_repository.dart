import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import 'package:dio/dio.dart';

class StatusRepository {
  final ApiClient _apiClient;

  StatusRepository(this._apiClient);

  Future<bool> updateStatus({
    required String reportId,
    required String status,
    String? note,
    String? photoUrl,
    String? assignedOfficerId,
  }) async {
    try {
      final data = {
        'status': status,
        if (note != null) 'note': note,
        if (photoUrl != null) 'photo_url': photoUrl,
        if (assignedOfficerId != null) 'assigned_officer_id': assignedOfficerId,
      };

      final response = await _apiClient.dio.patch(
        '/api/status/$reportId',
        data: data,
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Gagal memperbarui status',
      );
    }
  }

  Future<List<dynamic>> getStatusHistory(String reportId) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/status/$reportId/history',
      );

      if (response.statusCode == 200) {
        return response.data['data'] ?? [];
      } else {
        throw Exception(
          response.data['message'] ?? 'Gagal memuat riwayat status',
        );
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Gagal memuat riwayat status',
      );
    }
  }
}

final statusRepositoryProvider = Provider<StatusRepository>((ref) {
  return StatusRepository(ref.watch(apiClientProvider));
});
