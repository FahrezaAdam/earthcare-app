import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../warga/report/data/report_provider.dart';
import '../../../warga/report/data/report_model.dart';
import '../../../shared/auth/data/auth_provider.dart';
import '../../../shared/notification/presentation/widgets/notification_bell_button.dart';

class PetugasDashboardScreen extends ConsumerWidget {
  const PetugasDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsyncValue = ref.watch(reportsProvider('all'));
    final authState = ref.watch(authProvider);
    final userId = authState.user?['id'];

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leadingWidth: 140,
          leading: Row(
            children: [
              const SizedBox(width: 16),
              const Icon(Icons.eco, color: Color(0xFF1B4332), size: 20),
              const SizedBox(width: 4),
              const Text(
                'EarthCare',
                style: TextStyle(
                  color: Color(0xFF1B4332),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          title: const Text(
            'LAPORAN',
            style: TextStyle(
              color: Color(0xFF1B4332),
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 2.0,
            ),
          ),
          actions: const [NotificationBellButton(), SizedBox(width: 8)],
          bottom: const TabBar(
            labelColor: Color(0xFF1B4332),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF1B4332),
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Semua'),
              Tab(text: 'Sedang Berjalan'),
              Tab(text: 'Selesai'),
            ],
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: reportsAsyncValue.when(
                data: (reports) {
                  // Filter for this officer ONLY
                  final myReports = reports
                      .where(
                        (r) =>
                            r.assignedOfficerIds.contains(userId) ||
                            r.assignedOfficerId == userId,
                      )
                      .toList();

                  final berjalanReports = myReports
                      .where((r) => r.status.toLowerCase() == 'in_progress')
                      .toList();
                  final selesaiReports = myReports
                      .where((r) => r.status.toLowerCase() == 'resolved')
                      .toList();

                  return TabBarView(
                    children: [
                      _buildReportList(context, ref, myReports, 'Semua'),
                      _buildReportList(
                        context,
                        ref,
                        berjalanReports,
                        'Sedang Berjalan',
                      ),
                      _buildReportList(context, ref, selesaiReports, 'Selesai'),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportList(
    BuildContext context,
    WidgetRef ref,
    List<ReportModel> reports,
    String tabType,
  ) {
    if (reports.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada laporan di antrean $tabType.',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(reportsProvider('all'));
        try {
          await ref.read(reportsProvider('all').future);
        } catch (_) {}
      },
      color: const Color(0xFF1B4332),
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: reports.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final report = reports[index];
          return _buildTaskCard(context, report, tabType);
        },
      ),
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    ReportModel report,
    String tabType,
  ) {
    final isSelesai = report.status.toLowerCase() == 'resolved';
    final isBaru = report.status.toLowerCase() == 'assigned';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with category and time
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.orange[800],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatCategory(report.category).toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                    if (report.commentCount >= 5) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              color: Colors.red,
                              size: 10,
                            ),
                            SizedBox(width: 2),
                            Text(
                              'URGENT',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Title and Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  report.description ??
                      'Laporan warga mengenai pelanggaran di lokasi ini.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Image preview (if any)
          if (report.imageUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  report.imageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 120,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),
          const Divider(height: 1),

          // Footer actions
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      report.time,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
                Row(
                  children: [
                    SizedBox(
                      height: 36,
                      width: 36,
                      child: ElevatedButton(
                        onPressed: () {
                          context.push(
                            '/petugas/report-comments',
                            extra: report,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0F3224),
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(Icons.chat_bubble_outline, size: 16),
                            if (report.commentCount > 0)
                              Positioned(
                                right: 4,
                                top: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 10,
                                    minHeight: 10,
                                  ),
                                  child: Text(
                                    '${report.commentCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 6,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        context.push('/petugas/report-detail', extra: report);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelesai
                            ? Colors.grey[300]
                            : const Color(0xFF0A2B1D),
                        foregroundColor: isSelesai
                            ? Colors.grey[800]
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isSelesai
                            ? 'Detail Tugas'
                            : (isBaru ? 'Terima Tugas ->' : 'Update Tugas ->'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCategory(String category) {
    if (category.isEmpty) return category;
    return category
        .split('_')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1)}'
              : '',
        )
        .join(' ');
  }
}
