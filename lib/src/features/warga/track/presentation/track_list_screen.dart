import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../report/data/report_provider.dart';
import '../../report/data/report_repository.dart';
import '../../../shared/auth/data/auth_provider.dart';
import '../../../shared/notification/presentation/widgets/notification_bell_button.dart';

class TrackListScreen extends ConsumerStatefulWidget {
  const TrackListScreen({super.key});

  @override
  ConsumerState<TrackListScreen> createState() => _TrackListScreenState();
}

class _TrackListScreenState extends ConsumerState<TrackListScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final reportsAsyncValue = ref.watch(reportsProvider(_filter));
    final currentUserId = ref.watch(authProvider).user?['id'];

    return Scaffold(
      backgroundColor: Colors.grey[50],
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
          'LACAK',
          style: TextStyle(
            color: Color(0xFF1B4332),
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 2.0,
          ),
        ),
        actions: const [NotificationBellButton(), SizedBox(width: 8)],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF1B4332),
        onRefresh: () async {
          ref.invalidate(reportsProvider(_filter));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter Toggle
              Row(
                children: [
                  Expanded(
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'all',
                          label: Text('Semua'),
                          icon: Icon(Icons.public),
                        ),
                        ButtonSegment(
                          value: 'me',
                          label: Text('Laporan Saya'),
                          icon: Icon(Icons.person),
                        ),
                      ],
                      selected: {_filter},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          _filter = newSelection.first;
                        });
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return const Color(
                                0xFF1B4332,
                              ).withValues(alpha: 0.1);
                            }
                            return Colors.transparent;
                          },
                        ),
                        foregroundColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return const Color(0xFF1B4332);
                            }
                            return Colors.black54;
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Async Value Handling
              reportsAsyncValue.when(
                data: (reports) {
                  if (reports.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _filter == 'me'
                                  ? 'Belum ada laporan yang Anda buat.'
                                  : 'Belum ada laporan.',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: reports.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      return _buildReportCard(
                        context: context,
                        imageUrl: report.imageUrl,
                        badgeLabel: _formatStatus(report.status),
                        badgeColor: _getBadgeColor(report.status),
                        ticketId: report.ticketId,
                        title: report.title,
                        category: _formatCategory(report.category),
                        location: report.location,
                        time: report.time,
                        isCompleted: report.isCompleted,
                        rawReport:
                            report, // Pass the whole object if needed for detail screen
                        currentUserId: currentUserId,
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(color: Color(0xFF1B4332)),
                  ),
                ),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada laporan.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 80), // bottom nav spacing
            ],
          ),
        ),
      ),
    );
  }

  Color _getBadgeColor(String status) {
    switch (status.toLowerCase()) {
      case 'received':
        return Colors.orange;
      case 'kritis':
        return Colors.red[700]!;
      case 'verified':
        return Colors.blue;
      case 'assigned':
        return Colors.indigo;
      case 'in_progress':
        return Colors.purple;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'received':
        return 'DITERIMA';
      case 'kritis':
        return 'KRITIS';
      case 'verified':
        return 'DIVERIFIKASI';
      case 'assigned':
        return 'DITUGASKAN';
      case 'in_progress':
        return 'DIPROSES';
      case 'resolved':
        return 'SELESAI';
      default:
        return status.toUpperCase();
    }
  }

  String _formatCategory(String category) {
    if (category.isEmpty) return category;
    return category
        .split('_')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  Widget _buildReportCard({
    required BuildContext context,
    required String imageUrl,
    required String badgeLabel,
    required Color badgeColor,
    required String ticketId,
    required String title,
    required String category,
    required String location,
    required String time,
    required bool isCompleted,
    required dynamic rawReport,
    required String? currentUserId,
  }) {
    return InkWell(
      onTap: () {
        context.push(
          '/track-detail',
          extra: {'title': title, 'ticketId': ticketId, 'report': rawReport},
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.network(
                imageUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tags
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badgeLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ticketId,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Details
                  Row(
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        category,
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_outlined,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isCompleted ? Icons.check_circle : Icons.pending,
                            size: 14,
                            color: isCompleted ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isCompleted ? 'Selesai' : 'Sedang Diproses',
                            style: TextStyle(
                              color: isCompleted ? Colors.green : Colors.orange,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (rawReport.status == 'received' &&
                          (_filter == 'me' ||
                              rawReport.userId == currentUserId))
                        InkWell(
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text(
                                  'Batalkan Laporan?',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                content: const Text(
                                  'Apakah Anda yakin ingin membatalkan laporan ini? Data akan dihapus permanen.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => context.pop(false),
                                    child: const Text(
                                      'Tidak',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () => context.pop(true),
                                    child: const Text(
                                      'Ya, Batalkan',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true && context.mounted) {
                              try {
                                final repo = ref.read(reportRepositoryProvider);
                                await repo.deleteReport(rawReport.id);
                                ref.invalidate(reportsProvider('me'));
                                ref.invalidate(reportsProvider('all'));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Laporan berhasil dibatalkan',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Gagal: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Batalkan',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
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
      ),
    );
  }
}
