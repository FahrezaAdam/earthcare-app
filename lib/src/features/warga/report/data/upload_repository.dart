import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import 'package:dio/dio.dart';

class UploadRepository {
  final ApiClient _apiClient;

  UploadRepository(this._apiClient);

  Future<Map<String, dynamic>> getSignedUrl(String filename, String contentType) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/upload/signed-url',
        data: {
          'filename': filename,
          'content_type': contentType,
        },
      );
      
      if (response.statusCode == 200) {
        return response.data['data']; // Returns { signed_url, token, path, public_url }
      } else {
        throw Exception(response.data['message'] ?? 'Gagal mendapatkan signed URL');
      }
    } catch (e) {
      print('DEBUG SIGNED URL ERROR: $e');
      if (e is DioException) {
        throw Exception(e.response?.data['message'] ?? 'Gagal terhubung ke server');
      }
      throw Exception('Gagal terhubung ke server');
    }
  }

  Future<String> uploadFile(String filePath, String filename) async {
    try {
      // 1. Get signed URL
      final ext = filename.split('.').last.toLowerCase();
      String contentType = 'image/jpeg';
      if (ext == 'png') contentType = 'image/png';
      
      final signedUrlData = await getSignedUrl(filename, contentType);
      final signedUrl = signedUrlData['signed_url'];
      final publicUrl = signedUrlData['public_url'];

      // 2. Upload to Supabase Storage using PUT
      final dio = Dio();
      final file = File(filePath);
      final fileBytes = await file.readAsBytes();
      
      final uploadResponse = await dio.put(
        signedUrl,
        data: fileBytes,
        options: Options(
          headers: {
            'Content-Type': contentType,
            'x-upsert': 'true',
          },
        ),
      );

      if (uploadResponse.statusCode == 200 || uploadResponse.statusCode == 201) {
        return publicUrl;
      } else {
        throw Exception('Gagal mengunggah foto');
      }
    } catch (e) {
      print('DEBUG UPLOAD ERROR: $e');
      if (e is DioException) {
        throw Exception('Terjadi kesalahan jaringan saat mengunggah foto: ${e.message}');
      }
      throw Exception('Terjadi kesalahan saat mengunggah foto: $e');
    }
  }

  Future<bool> deletePhoto(String path) async {
    try {
      final response = await _apiClient.dio.delete(
        '/api/upload',
        data: {'path': path},
      );
      
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal menghapus foto');
    }
  }
}

final uploadRepositoryProvider = Provider<UploadRepository>((ref) {
  return UploadRepository(ref.watch(apiClientProvider));
});
