import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/notification_provider.dart';
import '../data/notification_repository.dart';
import '../data/notification_model.dart';
import '../../auth/data/auth_provider.dart';
import '../../../warga/report/data/report_repository.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  Map<String, dynamic> _getNotifStyle(String title, String body) {
    final lowerText = '${title.toLowerCase()} ${body.toLowerCase()}';
    if (lowerText.contains('komentar')) {
      return {
        'tag': 'KOMENTAR BARU',
        'tagColor': Colors.orange[800],
        'icon': Icons.person,
        'iconBg': Colors.orange[100],
        'iconColor': Colors.orange[800],
        'isAvatar': true,
      };
    } else if (lowerText.contains('sistem') ||
        lowerText.contains('tim') ||
        lowerText.contains('sedang menuju')) {
      return {
        'tag': 'UPDATE SISTEM',
        'tagColor': Colors.black87,
        'icon': Icons.local_shipping,
        'iconBg': const Color(0xFF1B4332),
        'iconColor': Colors.white,
        'isAvatar': false,
      };
    } else if (lowerText.contains('cuaca') ||
        lowerText.contains('peringatan')) {
      return {
        'tag': 'PERINGATAN CUACA',
        'tagColor': Colors.red[700],
        'icon': Icons.warning_amber_rounded,
        'iconBg': Colors.red[100],
        'iconColor': Colors.red[700],
        'isAvatar': false,
      };
    } else {
      return {
        'tag': 'UPDATE STATUS',
        'tagColor': const Color(0xFF1B4332),
        'icon': Icons.check_circle_outline,
        'iconBg': const Color(0xFF1B4332).withValues(alpha: 0.1),
        'iconColor': const Color(0xFF1B4332),
        'isAvatar': false,
      };
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await ref.read(notificationRepositoryProvider).markAllAsRead();
                ref.invalidate(notificationsProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menandai semua dibaca: $e')),
                  );
                }
              }
            },
            child: Text(
              'Tandai Dibaca Semua',
              style: TextStyle(
                color: Color(0xFF1B4332),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(child: Text('Tidak ada notifikasi.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final style = _getNotifStyle(notif.title, notif.body);

              // Simple grouping mock based on index for visual fidelity to screenshot
              // In production, you would parse createdAt and compare dates
              Widget? header;
              if (index == 0) {
                header = _buildHeader('HARI INI');
              } else if (index == 3 && notifications.length > 3) {
                header = _buildHeader('KEMARIN');
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ?header,
                  _buildNotificationCard(context, ref, notif, style),
                  const SizedBox(height: 16),
                ],
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF1B4332)),
        ),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey[500],
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notif,
    Map<String, dynamic> style,
  ) {
    return GestureDetector(
      onTap: () async {
        if (!notif.isRead) {
          try {
            await ref.read(notificationRepositoryProvider).markAsRead(notif.id);
            ref.invalidate(notificationsProvider);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Gagal menandai dibaca: $e')),
              );
            }
          }
        }

        // Navigasi ke detail laporan jika reportId ada
        if (notif.reportId != null && notif.reportId!.isNotEmpty) {
          final role = ref.read(authProvider).role;
          if (role != null) {
            try {
              // Tampilkan indikator loading (opsional, tapi disarankan)
              if (context.mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1B4332)),
                  ),
                );
              }

              final reportRepo = ref.read(reportRepositoryProvider);
              final report = await reportRepo.getReportById(notif.reportId!);

              if (context.mounted) {
                Navigator.of(context).pop(); // Tutup loading dialog

                if (role == 'warga' || role == 'citizen') {
                  context.push(
                    '/track-detail',
                    extra: {
                      'report': report,
                      'title': report.title,
                      'ticketId': report.id,
                    },
                  );
                } else if (role == 'admin') {
                  context.push('/admin/report-detail', extra: report);
                } else if (role == 'petugas' || role == 'officer') {
                  context.push('/petugas/report-detail', extra: report);
                }
              }
            } catch (e) {
              if (context.mounted) {
                Navigator.of(context).pop(); // Tutup loading dialog jika error
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal memuat detail laporan: $e')),
                );
              }
            }
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: notif.isRead
              ? Colors.white
              : const Color(0xFFF0FDF4), // Colors.green[50]
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon or Avatar
            style['isAvatar']
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      'https://images.unsplash.com/photo-1599566150163-29194dcaad36?q=80&w=100&auto=format&fit=crop',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: style['iconBg'],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(style['icon'], color: style['iconColor']),
                      ),
                    ),
                  )
                : Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: style['iconBg'],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(style['icon'], color: style['iconColor']),
                  ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        style['tag'],
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: style['tagColor'],
                          letterSpacing: 1.1,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            _formatMockTime(notif.createdAt),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                          if (!notif.isRead) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF1B4332),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Text combination
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: notif.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                        if (notif.body.isNotEmpty)
                          TextSpan(
                            text: ' ${notif.body}',
                            style: const TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 13,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Optional Status text check
                  if (notif.body.toLowerCase().contains('status:'))
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _extractStatus(notif.body),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D6A4F),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMockTime(String? date) {
    if (date == null) return 'Baru saja';
    // Dummy parse
    return '10 mnt';
  }

  String _extractStatus(String body) {
    final idx = body.toLowerCase().indexOf('status:');
    if (idx != -1) {
      return body.substring(idx);
    }
    return '';
  }
}
