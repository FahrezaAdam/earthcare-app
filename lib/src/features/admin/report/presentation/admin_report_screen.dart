import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/notification/presentation/widgets/notification_bell_button.dart';
import '../../../warga/report/data/report_model.dart';
import '../../../warga/report/data/report_provider.dart';

class AdminReportScreen extends ConsumerStatefulWidget {
  const AdminReportScreen({super.key});

  @override
  ConsumerState<AdminReportScreen> createState() => _AdminReportScreenState();
}

class _AdminReportScreenState extends ConsumerState<AdminReportScreen> {
  String _selectedUrgency = 'Urgensi';
  String _selectedStatus = 'Status';
  String _selectedCategory = 'Kategori';

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(reportsProvider('all'));

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
          'LAPORAN',
          style: TextStyle(
            color: Color(0xFF1B4332),
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 2.0,
          ),
        ),
        actions: const [NotificationBellButton(), SizedBox(width: 8)],
      ),
      body: reportsAsync.when(
        data: (reports) {
          // Calculate stats
          final criticalCount = reports
              .where(
                (r) => r.category == 'Limbah Industri' || r.status == 'kritis',
              )
              .length;
          final waitingCount = reports
              .where((r) => r.status == 'received' || r.status == 'verified')
              .length;
          final resolvedCount = reports
              .where((r) => r.isCompleted || r.status == 'resolved')
              .length;

          final cKritis = criticalCount;
          final cMenunggu = waitingCount;
          final cSelesai = resolvedCount;

          // Apply filters
          final filteredReports = reports.where((report) {
            // Urgency Filter
            bool matchesUrgency = true;
            if (_selectedUrgency != 'Urgensi') {
              final isCritical =
                  report.status == 'kritis' ||
                  report.category == 'Limbah Industri';
              final isResolved =
                  report.status == 'resolved' || report.isCompleted;

              if (_selectedUrgency == 'Kritis') {
                matchesUrgency = isCritical;
              } else if (_selectedUrgency == 'Teratasi') {
                matchesUrgency = isResolved;
              } else if (_selectedUrgency == 'Aktif') {
                matchesUrgency = !isCritical && !isResolved;
              }
            }

            // Status Filter
            bool matchesStatus = true;
            if (_selectedStatus != 'Status') {
              final s = _selectedStatus.toLowerCase();
              if (s == 'diterima') {
                matchesStatus = report.status == 'received';
              } else if (s == 'diverifikasi') {
                matchesStatus = report.status == 'verified';
              } else if (s == 'ditugaskan') {
                matchesStatus = report.status == 'assigned';
              } else if (s == 'diproses') {
                matchesStatus = report.status == 'in_progress';
              } else if (s == 'selesai') {
                matchesStatus = report.status == 'resolved';
              }
            }

            // Category Filter
            bool matchesCategory = true;
            if (_selectedCategory != 'Kategori') {
              matchesCategory =
                  _formatCategory(report.category) == _selectedCategory ||
                  report.category.toLowerCase() ==
                      _selectedCategory.toLowerCase();
            }

            return matchesUrgency && matchesStatus && matchesCategory;
          }).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(reportsProvider('all'));
              try {
                await ref.read(reportsProvider('all').future);
              } catch (_) {}
            },
            color: const Color(0xFF1B4332),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Row
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 24),
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
                                children: [
                                  Text(
                                    reports.length.toString(),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1B4332),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'LAPORAN\nDITERIMA',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[600],
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 24),
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
                                children: [
                                  Text(
                                    cSelesai.toString(),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1B4332),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'SELESAI\n',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[600],
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Stats Row 1
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.warning_amber_rounded,
                              count: cKritis.toString(),
                              label: 'LAPORAN KRITIS',
                              bgColor: const Color(0xFF224231),
                              textColor: Colors.white,
                              iconColor: Colors.white70,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.calendar_today_outlined,
                              count: cMenunggu.toString(),
                              label: 'MENUNGGU\nPENUGASAN',
                              bgColor: Colors.white,
                              textColor: Colors.black87,
                              iconColor: Colors.black54,
                              borderColor: Colors.grey[300],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Stats Row 2 (Weekly)
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.47,
                        child: _buildStatCard(
                          icon: Icons.check_circle_outline,
                          count: cSelesai.toString(),
                          label: 'TERSELESAIKAN\nMINGGUAN',
                          bgColor: const Color(0xFFF9B872),
                          textColor: Colors.black87,
                          iconColor: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Filters
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              value: _selectedUrgency,
                              items: ['Urgensi', 'Aktif', 'Kritis', 'Teratasi'],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedUrgency = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildDropdown(
                              value: _selectedStatus,
                              items: [
                                'Status',
                                'Diterima',
                                'Diverifikasi',
                                'Ditugaskan',
                                'Diproses',
                                'Selesai',
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedStatus = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildDropdown(
                              value: _selectedCategory,
                              items: [
                                'Kategori',
                                'Sampah Liar',
                                'Sungai Tercemar',
                                'Pohon Tumbang',
                                'Banjir',
                                'Polusi Udara',
                                'Kerusakan Fasilitas',
                                'Lainnya',
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedCategory = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Reports List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: filteredReports.isEmpty
                    ? const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Center(
                            child: Text('Belum ada laporan yang sesuai filter'),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20.0),
                            child: _buildReportCard(filteredReports[index]),
                          );
                        }, childCount: filteredReports.length),
                      ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
            ],
          ),
        );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF1B4332)),
        ),
        error: (err, st) => Center(child: Text('Gagal memuat laporan: $err')),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String count,
    required String label,
    required Color bgColor,
    required Color textColor,
    required Color iconColor,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: borderColor != null ? Border.all(color: borderColor) : null,
        boxShadow: [
          if (borderColor == null)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: textColor.withValues(alpha: 0.8),
              letterSpacing: 1.1,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16),
          isExpanded: true,
          style: const TextStyle(fontSize: 11, color: Colors.black87),
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildReportCard(ReportModel report) {
    // Determine card specific styles based on status
    Color tagColor;
    String tagText;
    String buttonText = 'Tugaskan / Update Status';

    switch (report.status.toLowerCase()) {
      case 'received':
        tagColor = Colors.orange;
        tagText = 'DITERIMA';
        buttonText = 'Verifikasi Laporan';
        break;
      case 'kritis':
        tagColor = Colors.red[700]!;
        tagText = 'KRITIS';
        buttonText = 'Verifikasi Segera';
        break;
      case 'verified':
        tagColor = Colors.blue;
        tagText = 'DIVERIFIKASI';
        buttonText = 'Tugaskan Petugas';
        break;
      case 'assigned':
        tagColor = Colors.indigo;
        tagText = 'DITUGASKAN';
        buttonText = 'Pantau Penugasan';
        break;
      case 'in_progress':
        tagColor = Colors.purple;
        tagText = 'DIPROSES';
        buttonText = 'Update Status';
        break;
      case 'resolved':
        tagColor = Colors.green;
        tagText = 'SELESAI';
        buttonText = 'Lihat Detail';
        break;
      case 'rejected':
        tagColor = Colors.red;
        tagText = 'DITOLAK';
        buttonText = 'Lihat Detail';
        break;
      default:
        tagColor = Colors.grey;
        tagText = report.status.toUpperCase();
    }

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
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              report.imageUrl,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 160,
                color: Colors.grey[200],
                child: const Icon(
                  Icons.image_not_supported,
                  color: Colors.grey,
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16.0),
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
                        color: tagColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tagText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      report.ticketId,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
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
                const SizedBox(height: 12),

                // Title
                Text(
                  report.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                // Info rows
                _buildInfoRow(
                  Icons.person_outline,
                  _formatCategory(report.category),
                ),
                const SizedBox(height: 6),
                _buildInfoRow(Icons.location_on_outlined, report.location),
                const SizedBox(height: 6),
                _buildInfoRow(Icons.access_time, report.time),

                const SizedBox(height: 16),

                // Action Button
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          context.push('/admin/report-detail', extra: report);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F3224),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          buttonText,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 44,
                      width: 44,
                      child: ElevatedButton(
                        onPressed: () {
                          context.push('/admin/report-comments', extra: report);
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
                            const Icon(Icons.chat_bubble_outline, size: 20),
                            if (report.commentCount > 0)
                              Positioned(
                                right: 6,
                                top: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 12,
                                    minHeight: 12,
                                  ),
                                  child: Text(
                                    '${report.commentCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
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
                    SizedBox(
                      height: 44, // Match approx height of the adjacent button
                      width: 44,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (report.latitude != null &&
                              report.longitude != null) {
                            final url = Uri.parse(
                              'https://www.google.com/maps/dir/?api=1&destination=${report.latitude},${report.longitude}',
                            );
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          }
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
                        child: const Icon(Icons.map_outlined, size: 20),
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
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
}
