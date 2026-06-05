import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'report_model.dart';

class ReportRepository {
  final ApiClient _apiClient;

  ReportRepository(this._apiClient);

  Future<List<ReportModel>> getReports({int page = 1, int limit = 10, String? category, String? status, String filter = 'all'}) async {
    try {
      final queryParams = {
        if (category != null) 'category': category,
        if (status != null) 'status': status,
      };
      
      final endpoint = filter == 'me' ? '/api/reports/me' : '/api/reports';
      final response = await _apiClient.dio.get(endpoint, queryParameters: queryParams.isNotEmpty ? queryParams : null);
      
      if (response.statusCode == 200) {
        List<dynamic> data = [];
        if (response.data is List) {
          data = response.data;
        } else if (response.data is Map) {
          data = response.data['data'] ?? response.data['reports'] ?? [];
        }
        return data.map((json) => ReportModel.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Gagal memuat laporan');
      }
    } catch (e) {
      print('DEBUG GET REPORTS ERROR: $e');
      throw Exception('Gagal memuat laporan: $e');
    }
  }

  Future<bool> createReport({
    required String title,
    required String description,
    required String category,
    required double latitude,
    required double longitude,
    required String address,
    required String photoUrl,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/reports',
        data: {
          'title': title,
          'description': description,
          'category': category,
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
          'photo_url': photoUrl,
        },
      );
      
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('DEBUG CREATE REPORT ERROR: $e');
      if (e is DioException) {
        throw Exception(e.response?.data['message'] ?? 'Gagal membuat laporan: ${e.message}');
      }
      throw Exception('Gagal membuat laporan: $e');
    }
  }

  Future<List<HeatmapData>> getHeatmapData() async {
    try {
      final response = await _apiClient.dio.get('/api/reports/heatmap');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => HeatmapData.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Gagal memuat data heatmap');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal memuat data heatmap: ${e.message}');
    }
  }

  Future<bool> deleteReport(String reportId) async {
    try {
      final response = await _apiClient.dio.delete('/api/reports/$reportId');
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal membatalkan laporan: ${e.message}');
    }
  }
}

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(ref.watch(apiClientProvider));
});
