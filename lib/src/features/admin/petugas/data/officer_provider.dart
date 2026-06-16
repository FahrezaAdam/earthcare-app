import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import 'officer_model.dart';

class OfficerRepository {
  final ApiClient _apiClient;

  OfficerRepository(this._apiClient);

  Future<List<Officer>> getOfficers() async {
    try {
      final response = await _apiClient.dio.get('/api/auth/officers');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => Officer.fromJson(json)).toList();
      }
      throw Exception('Gagal memuat petugas');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal memuat petugas');
    }
  }

  Future<Officer> createOfficer(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/auth/officers',
        data: data,
      );
      if (response.statusCode == 201) {
        return Officer.fromJson(response.data['data']);
      }
      throw Exception('Gagal menambahkan petugas');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Gagal menambahkan petugas',
      );
    }
  }

  Future<Officer> updateOfficer(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put(
        '/api/auth/officers/$id',
        data: data,
      );
      if (response.statusCode == 200) {
        return Officer.fromJson(response.data['data']);
      }
      throw Exception('Gagal mengupdate petugas');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Gagal mengupdate petugas',
      );
    }
  }
  Future<void> deleteOfficer(String id) async {
    try {
      final response = await _apiClient.dio.delete('/api/auth/officers/$id');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Gagal menghapus petugas');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Gagal menghapus petugas',
      );
    }
  }
}

final officerRepositoryProvider = Provider<OfficerRepository>((ref) {
  return OfficerRepository(ref.watch(apiClientProvider));
});

final officersProvider = FutureProvider<List<Officer>>((ref) async {
  final repository = ref.watch(officerRepositoryProvider);
  return repository.getOfficers();
});
