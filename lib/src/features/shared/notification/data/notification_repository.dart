import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'notification_model.dart';

class NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepository(this._apiClient);

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _apiClient.dio.get('/api/status/notifications');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => NotificationModel.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Gagal memuat notifikasi');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal memuat notifikasi dari server');
    }
  }

  Future<bool> markAsRead(String id) async {
    try {
      final response = await _apiClient.dio.patch('/api/status/notifications/$id/read');
      
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal menandai notifikasi');
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final response = await _apiClient.dio.patch('/api/status/notifications/read-all');
      
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal menandai semua notifikasi');
    }
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(apiClientProvider));
});
