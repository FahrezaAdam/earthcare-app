import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../report/data/report_model.dart';
import '../../report/data/report_provider.dart';
import '../../report/data/report_repository.dart';
import '../../../shared/auth/data/auth_provider.dart';

class TrackDetailScreen extends ConsumerWidget {
  final String title;
  final String ticketId;
  final ReportModel? report;

  const TrackDetailScreen({
    super.key,
    this.title = 'Laporan',
    this.ticketId = 'REP-0000',
    this.report,
  });

  int _getStepIndex(String status) {
    switch (status.toLowerCase()) {
      case 'received': return 0;
      case 'verified': return 1;
      case 'assigned': return 1;
      case 'in_progress': return 2;
      case 'resolved': return 3;
      default: return 0;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = report != null ? _getStepIndex(report!.status) : 0;
    final currentUserId = ref.watch(authProvider).user?['id'];
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.eco, color: Color(0xFF1B4332), size: 20),
            const SizedBox(width: 8),
            const Text(
              'EarthCare',
              style: TextStyle(color: Color(0xFF1B4332), fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status Laporan:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              report?.title ?? title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Stepper Container
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStep(icon: Icons.assignment, label: 'Diterima', color: const Color(0xFF1B4332), isCompleted: step > 0, isCurrent: step == 0),
                  _buildLine(isCompleted: step > 0),
                  _buildStep(icon: Icons.verified_user, label: 'Diverifikasi', color: const Color(0xFF1B4332), isCompleted: step > 1, isCurrent: step == 1),
                  _buildLine(isCompleted: step > 1),
                  _buildStep(icon: Icons.build, label: 'Diproses', color: Colors.lightGreen, isCompleted: step > 2, isCurrent: step == 2),
                  _buildLine(isCompleted: step > 2),
                  _buildStep(icon: Icons.check, label: 'Selesai', color: Colors.green, isCompleted: step > 3, isCurrent: step == 3),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Foto Laporan Card
            if (report != null && report!.imageUrl.isNotEmpty)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Foto Laporan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('Dokumentasi awal yang Anda lampirkan.', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    // Image
                    ClipRRect(
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
                      child: Image.network(
                        report!.imageUrl,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Riwayat Update Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Riwayat Update', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 24),
                  
                  _buildTimelineItem(
                    title: 'Selesai',
                    time: report?.time ?? '',
                    desc: 'Laporan telah ditangani dan dinyatakan selesai.',
                    isLast: false,
                    isCurrent: step == 3,
                    isPast: step > 3,
                    color: Colors.green,
                  ),
                  _buildTimelineItem(
                    title: 'Pembersihan Sedang Berlangsung',
                    time: report?.time ?? '',
                    desc: 'Tim unit reaksi cepat sedang menangani laporan di lokasi.',
                    isLast: false,
                    isCurrent: step == 2,
                    isPast: step > 2,
                    color: Colors.lightGreen,
                  ),
                  _buildTimelineItem(
                    title: 'Laporan Telah Diverifikasi',
                    time: report?.time ?? '',
                    desc: 'Validasi lokasi dan jenis pelanggaran selesai dilakukan.',
                    isLast: false,
                    isCurrent: step == 1,
                    isPast: step > 1,
                    color: const Color(0xFF1B4332),
                  ),
                  _buildTimelineItem(
                    title: 'Laporan Dikirim',
                    time: report?.time ?? '',
                    desc: 'Terima kasih atas kontribusi Anda terhadap bumi.',
                    isLast: true,
                    isCurrent: step == 0,
                    isPast: step > 0,
                    color: const Color(0xFF1B4332),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: (report != null && report!.status == 'received' && report!.userId == currentUserId)
          ? Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Batalkan Laporan?', style: TextStyle(fontWeight: FontWeight.bold)),
                      content: const Text('Apakah Anda yakin ingin membatalkan laporan ini? Data akan dihapus permanen.'),
                      actions: [
                        TextButton(
                          onPressed: () => context.pop(false),
                          child: const Text('Tidak', style: TextStyle(color: Colors.grey)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () => context.pop(true),
                          child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    try {
                      final repo = ref.read(reportRepositoryProvider);
                      await repo.deleteReport(report!.id);
                      ref.invalidate(reportsProvider('me'));
                      ref.invalidate(reportsProvider('all'));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Laporan berhasil dibatalkan'), backgroundColor: Colors.green),
                        );
                        context.pop();
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  }
                },
                child: const Text('Batalkan Laporan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            )
          : null,
    );
  }

  Widget _buildStep({required IconData icon, required String label, required Color color, required bool isCompleted, bool isCurrent = false}) {
    final isFuture = !isCompleted && !isCurrent;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isFuture ? Colors.grey[100] : color.withValues(alpha: isCurrent ? 0.2 : 1.0),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: isFuture ? Colors.grey[400] : (isCompleted ? Colors.white : color), size: 16),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: isFuture ? FontWeight.normal : FontWeight.bold, color: isFuture ? Colors.grey : Colors.black87)),
      ],
    );
  }

  Widget _buildLine({required bool isCompleted}) {
    return Expanded(
      child: Container(
        height: 2,
        color: isCompleted ? const Color(0xFF1B4332) : Colors.grey[200],
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
      ),
    );
  }

  Widget _buildTimelineItem({required String title, required String time, required String desc, required bool isLast, bool isCurrent = false, bool isPast = false, Color color = const Color(0xFF1B4332)}) {
    final isFuture = !isCurrent && !isPast;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isFuture ? Colors.grey[300] : color,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: isFuture ? Colors.grey[200] : color.withAlpha(80),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600, fontSize: 13, color: isFuture ? Colors.grey[400] : (isCurrent ? Colors.black87 : Colors.grey[800]))),
                const SizedBox(height: 4),
                Text(isFuture ? 'Menunggu...' : time, style: TextStyle(fontSize: 10, color: isFuture ? Colors.grey[300] : Colors.grey[500])),
                const SizedBox(height: 8),
                Text(desc, style: TextStyle(fontSize: 11, color: isFuture ? Colors.grey[300] : Colors.grey[600], height: 1.4)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
