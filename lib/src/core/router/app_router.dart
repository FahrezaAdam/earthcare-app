import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/shared/auth/data/auth_provider.dart';
import '../../features/warga/report/data/report_model.dart';

import '../../features/shared/auth/presentation/login_screen.dart';
import '../../features/shared/auth/presentation/register_screen.dart';
import '../../features/shared/auth/presentation/forgot_password_screen.dart';
import '../../features/shared/auth/presentation/verification_screen.dart';
import '../../features/shared/auth/presentation/verify_reset_screen.dart';
import '../../features/shared/auth/presentation/new_password_screen.dart';
import '../../features/shared/auth/presentation/success_reset_screen.dart';
import '../../features/warga/dashboard/presentation/dashboard_screen.dart';
import '../../features/warga/report/presentation/report_detail_screen.dart';
import '../../features/warga/report/presentation/in_app_camera_screen.dart';
import '../../features/admin/report/presentation/admin_report_detail_screen.dart';
import '../../features/admin/report/presentation/admin_report_comments_screen.dart';
import '../../features/petugas/report/presentation/petugas_report_comments_screen.dart';
import '../../features/warga/track/presentation/track_detail_screen.dart';
import '../../features/shared/profile/presentation/edit_profile_screen.dart';
import '../../features/shared/profile/presentation/help_center_screen.dart';
import '../../features/admin/dashboard/presentation/admin_dashboard_screen.dart';
import '../../features/petugas/main/presentation/petugas_main_screen.dart';
import '../../features/petugas/report/presentation/petugas_report_detail_screen.dart';
import '../../features/shared/notification/presentation/notification_screen.dart';
import '../../features/admin/petugas/presentation/admin_add_petugas_screen.dart';
import '../../features/admin/petugas/presentation/admin_petugas_profile_screen.dart';
import '../../features/admin/petugas/data/officer_model.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuth = authState.role != null;
      final isGoingToLogin = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/verify' ||
          state.matchedLocation == '/verify-reset' ||
          state.matchedLocation == '/new-password' ||
          state.matchedLocation == '/success-reset';

      if (!isAuth && !isGoingToLogin) {
        return '/login';
      }

      if (isAuth && isGoingToLogin) {
        if (authState.role == 'admin') return '/admin/dashboard';
        if (authState.role == 'petugas' || authState.role == 'officer') {
          return '/petugas/main';
        }
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/verify',
        builder: (context, state) => const VerificationScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-reset',
        builder: (context, state) => const VerifyResetScreen(),
      ),
      GoRoute(
        path: '/new-password',
        builder: (context, state) => const NewPasswordScreen(),
      ),
      GoRoute(
        path: '/success-reset',
        builder: (context, state) => const SuccessResetScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/report-detail',
        builder: (context, state) => const ReportDetailScreen(),
      ),
      GoRoute(
        path: '/camera',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return InAppCameraScreen(
            isProfileMode: extra?['isProfileMode'] as bool? ?? false,
          );
        },
      ),
      GoRoute(
        path: '/track-detail',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return TrackDetailScreen(
            title:
                extra?['title'] as String? ??
                'Laporan Penumpukan Sampah Liar - Kawasan Hutan Kota',
            ticketId: extra?['ticketId'] as String? ?? 'REP-9432',
            report: extra?['report'],
          );
        },
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/help-center',
        builder: (context, state) => const HelpCenterScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/report-detail',
        builder: (context, state) {
          final report = state.extra as ReportModel?;
          if (report == null) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'Laporan tidak ditemukan. Silakan kembali ke halaman sebelumnya.',
                ),
              ),
            );
          }
          return AdminReportDetailScreen(report: report);
        },
      ),
      GoRoute(
        path: '/admin/report-comments',
        builder: (context, state) {
          final report = state.extra as ReportModel?;
          if (report == null) {
            return const Scaffold(
              body: Center(child: Text('Laporan tidak ditemukan.')),
            );
          }
          return AdminReportCommentsScreen(report: report);
        },
      ),
      GoRoute(
        path: '/petugas/main',
        builder: (context, state) => const PetugasMainScreen(),
      ),
      GoRoute(
        path: '/petugas/report-detail',
        builder: (context, state) {
          final report = state.extra as ReportModel?;
          if (report == null) {
            return const Scaffold(
              body: Center(child: Text('Laporan tidak ditemukan.')),
            );
          }
          return PetugasReportDetailScreen(report: report);
        },
      ),
      GoRoute(
        path: '/petugas/report-comments',
        builder: (context, state) {
          final report = state.extra as ReportModel?;
          if (report == null) {
            return const Scaffold(
              body: Center(child: Text('Laporan tidak ditemukan.')),
            );
          }
          return PetugasReportCommentsScreen(report: report);
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        path: '/admin/petugas/add',
        builder: (context, state) => const AdminAddPetugasScreen(),
      ),
      GoRoute(
        path: '/admin/petugas/edit',
        builder: (context, state) {
          final officer = state.extra as Officer?;
          return AdminAddPetugasScreen(officer: officer);
        },
      ),
      GoRoute(
        path: '/admin/petugas/profile',
        builder: (context, state) {
          final officer = state.extra as Officer;
          return AdminPetugasProfileScreen(officer: officer);
        },
      ),
    ],
  );
});
