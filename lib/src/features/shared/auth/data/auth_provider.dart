import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_repository.dart';

class AuthState {
  final bool isLoading;
  final String? error;
  final String? role;
  final String? registrationEmail;
  final String? resetEmail;
  final String? resetOtp;
  final Map<String, dynamic>? user;

  AuthState({
    this.isLoading = false,
    this.error,
    this.role,
    this.registrationEmail,
    this.resetEmail,
    this.resetOtp,
    this.user,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    String? role,
    String? registrationEmail,
    String? resetEmail,
    String? resetOtp,
    Map<String, dynamic>? user,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      role: role ?? this.role,
      registrationEmail: registrationEmail ?? this.registrationEmail,
      resetEmail: resetEmail ?? this.resetEmail,
      resetOtp: resetOtp ?? this.resetOtp,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _checkInitialAuth();
    return AuthState();
  }

  Future<void> _checkInitialAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role');
    final token = prefs.getString('auth_token');
    
    if (token != null && role != null) {
      state = state.copyWith(role: role);
      try {
        final repository = ref.read(authRepositoryProvider);
        final user = await repository.getProfile();
        state = state.copyWith(user: user);
      } catch (e) {
        // Token might be expired, ignore for now or logout
      }
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repository = ref.read(authRepositoryProvider);
      final data = await repository.login(email, password);

      final token = data['data']?['token'] ?? data['token'] as String?;
      final user = data['data']?['user'] ?? data['user'] as Map<String, dynamic>?;
      
      // Debug print to see exact API response in console
      print('=== LOGIN RESPONSE ===');
      print('Data: $data');
      print('======================');

      final rawRole = user?['role']?.toString().toLowerCase();
      final role = rawRole ?? 'warga';

      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('user_role', role);

        state = state.copyWith(isLoading: false, role: role, user: user);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Token not found in response',
        );
        return false;
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  Future<bool> sendOtp(String name, String email, String password, String phone) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      registrationEmail: email, // Store email for next step
    );
    try {
      final repository = ref.read(authRepositoryProvider);
      final success = await repository.sendOtp(name, email, password, phone);
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  Future<bool> verifyCode(String code) async {
    if (state.registrationEmail == null) {
      state = state.copyWith(error: 'Email tidak ditemukan. Silakan ulangi pendaftaran.');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repository = ref.read(authRepositoryProvider);
      final data = await repository.verifyCode(state.registrationEmail!, code);
      
      final token = data['data']?['token'] ?? data['token'] as String?;
      final user = data['data']?['user'] ?? data['user'] as Map<String, dynamic>?;

      if (token != null) {
        final rawRole = user?['role']?.toString().toLowerCase();
        final role = rawRole ?? 'citizen';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('user_role', role);

        state = state.copyWith(isLoading: false, role: role, registrationEmail: null, user: user);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Token not found in response',
        );
        return false;
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  Future<bool> resendOtp() async {
    if (state.registrationEmail == null) return false;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repository = ref.read(authRepositoryProvider);
      final success = await repository.resendOtp(state.registrationEmail!);
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, clearError: true, resetEmail: email);
    try {
      final repository = ref.read(authRepositoryProvider);
      final success = await repository.forgotPassword(email);
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) errorMessage = errorMessage.substring(11);
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  Future<bool> verifyForgotPassword(String code) async {
    if (state.resetEmail == null) {
      state = state.copyWith(error: 'Email tidak ditemukan.');
      return false;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repository = ref.read(authRepositoryProvider);
      final token = await repository.verifyForgotPassword(state.resetEmail!, code);
      if (token != null) {
        state = state.copyWith(isLoading: false, resetOtp: token);
        return true;
      } else {
        // Fallback to code if token is somehow not returned
        state = state.copyWith(isLoading: false, resetOtp: code);
        return true;
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) errorMessage = errorMessage.substring(11);
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  Future<bool> resetPassword(String newPassword) async {
    if (state.resetEmail == null || state.resetOtp == null) {
      state = state.copyWith(error: 'Data pemulihan tidak valid.');
      return false;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repository = ref.read(authRepositoryProvider);
      final success = await repository.resetPassword(state.resetEmail!, state.resetOtp!, newPassword);
      if (success) {
        state = state.copyWith(isLoading: false, resetEmail: null, resetOtp: null);
      }
      return success;
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) errorMessage = errorMessage.substring(11);
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  void updateProfileData({String? name, String? phone, String? avatarUrl}) {
    if (state.user == null) return;
    
    final updatedUser = Map<String, dynamic>.from(state.user!);
    if (name != null) updatedUser['name'] = name;
    if (phone != null) updatedUser['phone'] = phone;
    if (avatarUrl != null) updatedUser['avatar_url'] = avatarUrl;
    
    state = state.copyWith(user: updatedUser);
  }


  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_role');
    state = AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
