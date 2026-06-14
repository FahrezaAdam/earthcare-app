import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import 'package:dio/dio.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? 'Login failed');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? e.message ?? 'Login failed',
      );
    }
  }

  // Register User (Send OTP)
  Future<bool> sendOtp(
    String name,
    String email,
    String password,
    String phone,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          'role': 'citizen',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw Exception(response.data['message'] ?? 'Gagal mengirim OTP');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? e.message ?? 'Gagal mengirim OTP',
      );
    }
  }

  // Verify Registration OTP
  Future<Map<String, dynamic>> verifyCode(String email, String code) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/auth/register/verify',
        data: {'email': email, 'otp': code},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? 'Verifikasi gagal');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? e.message ?? 'Verifikasi gagal',
      );
    }
  }

  // Resend Registration OTP
  Future<bool> resendOtp(String email) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/auth/register/resend',
        data: {'email': email},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw Exception(response.data['message'] ?? 'Gagal mengirim ulang OTP');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? e.message ?? 'Gagal mengirim ulang OTP',
      );
    }
  }

  // Forgot Password (Send OTP)
  Future<bool> forgotPassword(String email) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/auth/forgot-password',
        data: {'email': email},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw Exception(
          response.data['message'] ?? 'Gagal mengirim OTP lupa sandi',
        );
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ??
            e.message ??
            'Gagal mengirim OTP lupa sandi',
      );
    }
  }

  // Verify Forgot Password OTP
  Future<String?> verifyForgotPassword(String email, String code) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/auth/forgot-password/verify',
        data: {'email': email, 'otp': code},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Return the token from the response
        final data = response.data['data'];
        final token =
            data?['token'] ??
            data?['reset_token'] ??
            response.data['token'] ??
            response.data['reset_token'];

        if (token == null) {
          // If we still can't find it, return the whole response as error so we can see it
          throw Exception("VERIFY SUCCESS BUT NO TOKEN: ${response.data}");
        }

        return token.toString();
      } else {
        throw Exception(response.data['message'] ?? 'Verifikasi gagal');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? e.message ?? 'Verifikasi gagal',
      );
    }
  }

  // Reset Password
  Future<bool> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/auth/reset-password',
        data: {'email': email, 'token': code, 'new_password': newPassword},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw Exception(response.data['message'] ?? 'Gagal reset sandi');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? e.message ?? 'Gagal reset sandi',
      );
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _apiClient.dio.get('/api/auth/me');
      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? 'Gagal mengambil profil');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? e.message ?? 'Gagal mengambil profil',
      );
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '/api/auth/profile',
        data: {
          'name': ?name,
          'phone': ?phone,
          'avatar_url': ?avatarUrl,
        },
      );
      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? 'Gagal update profil');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? e.message ?? 'Gagal update profil',
      );
    }
  }

  Future<Map<String, dynamic>> getSignedUploadUrl(
    String filename,
    String contentType,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/upload/signed-url',
        data: {'filename': filename, 'content_type': contentType},
      );
      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? 'Gagal get signed URL');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? e.message ?? 'Gagal get signed URL',
      );
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});
