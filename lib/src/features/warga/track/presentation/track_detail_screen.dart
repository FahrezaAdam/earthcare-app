import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../report/data/report_model.dart';
import '../../../shared/widgets/full_screen_image_viewer.dart';
import '../../report/data/report_provider.dart';
import '../../report/data/report_repository.dart';
import '../../../shared/auth/data/auth_provider.dart';
import '../../../petugas/dashboard/data/status_repository.dart'; // To get status history
import '../data/comment_provider.dart';

class TrackDetailScreen extends ConsumerStatefulWidget {
  final String title;
  final String ticketId;
  final ReportModel? report;

  const TrackDetailScreen({
    super.key,
    this.title = 'Laporan',
    this.ticketId = 'REP-0000',
    this.report,
  });

  @override
  ConsumerState<TrackDetailScreen> createState() => _TrackDetailScreenState();
}

class _TrackDetailScreenState extends ConsumerState<TrackDetailScreen> {
  List<dynamic> _history = [];
  bool _isLoadingHistory = false;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmittingComment = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (widget.report == null) return;
    setState(() => _isLoadingHistory = true);
    try {
      final repo = ref.read(statusRepositoryProvider);
      final history = await repo.getStatusHistory(widget.report!.id);
      if (mounted) setState(() => _history = history);
    } catch (e) {
      debugPrint('Error loading history: $e');
    } finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || widget.report == null) return;

    setState(() => _isSubmittingComment = true);
    try {
      final repo = ref.read(commentRepositoryProvider);
      await repo.addComment(widget.report!.id, text);
      _commentController.clear();
      ref.invalidate(commentsProvider(widget.report!.id));
      ref.invalidate(reportsProvider('all'));
      ref.invalidate(reportsProvider('me'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Komentar ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingComment = false);
    }
  }

  String _formatTime(dynamic dateStr) {
    if (dateStr == null) return '';
    final date =
        DateTime.tryParse(dateStr.toString())?.toLocal() ?? DateTime.now();
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  List<Widget> _buildDynamicTimeline() {
    final List<Widget> items = [];
    final report = widget.report;
    if (report == null) return items;

    final isRejected = report.status.toLowerCase() == 'rejected';

    // 1. Diterima
    final receivedHist = _history
        .where((h) => h['status'] == 'received')
        .toList();
    items.add(
      _buildTimelineItem(
        icon: Icons.play_circle_fill,
        isActive: true,
        title: 'Diterima',
        time: receivedHist.isNotEmpty
            ? _formatTime(receivedHist.last['created_at'])
            : _formatTime(report.time),
        description: 'Laporan masuk ke sistem EarthCare.',
        isFirst: true,
      ),
    );

    // 2. Diverifikasi
    final verifiedHist = _history
        .where((h) => h['status'] == 'verified')
        .toList();
    if (verifiedHist.isNotEmpty) {
      items.add(
        _buildTimelineItem(
          icon: Icons.verified_user,
          isActive: true,
          title: 'Diverifikasi',
          time: _formatTime(verifiedHist.last['created_at']),
          description:
              verifiedHist.last['note'] ??
              'Admin memvalidasi keaslian laporan.',
        ),
      );
    } else if (!isRejected && report.status.toLowerCase() == 'received') {
      items.add(
        _buildTimelineItem(
          icon: Icons.verified_user,
          isActive: false,
          title: 'Diverifikasi',
          time: '',
          description: 'Menunggu proses verifikasi oleh admin.',
        ),
      );
    }

    // 3. Ditugaskan
    final assignedHist = _history
        .where((h) => h['status'] == 'assigned')
        .toList();
    if (assignedHist.isNotEmpty) {
      items.add(
        _buildTimelineItem(
          icon: Icons.assignment_ind,
          isActive: true,
          title: 'Ditugaskan',
          time: _formatTime(assignedHist.last['created_at']),
          description:
              assignedHist.last['note'] ?? 'Laporan diteruskan ke petugas.',
        ),
      );
    } else if (!isRejected && ['received', 'verified'].contains(report.status.toLowerCase())) {
      items.add(
        _buildTimelineItem(
          icon: Icons.assignment_ind,
          isActive: false,
          title: 'Ditugaskan',
          time: '',
          description: 'Menunggu penugasan ke petugas terkait.',
        ),
      );
    }

    // 4. Dalam Penanganan
    // If chronologically top-to-bottom, we want the OLDEST progress first, NEWEST progress last.
    // _history is ordered ASC (oldest first) from backend: `.order("created_at", { ascending: true })`.
    final progressHist = _history
        .where((h) => h['status'] == 'in_progress')
        .toList();
    if (progressHist.isNotEmpty) {
      for (var h in progressHist) {
        items.add(
          _buildTimelineItem(
            icon: Icons.build_circle,
            isActive: true,
            title: 'Dalam Penanganan',
            time: _formatTime(h['created_at']),
            description:
                h['note'] ??
                'Tim Lapangan sedang melakukan penanganan di lokasi.',
            hasImage: h['photo_url'] != null,
            imageUrl: h['photo_url'],
          ),
        );
      }
    } else if (!isRejected && [
      'received',
      'verified',
      'assigned',
    ].contains(report.status.toLowerCase())) {
      items.add(
        _buildTimelineItem(
          icon: Icons.build_circle,
          isActive: false,
          title: 'Dalam Penanganan',
          time: '',
          description:
              'Tim unit reaksi cepat akan menangani laporan di lokasi.',
        ),
      );
    }

    // 5. Selesai
    final resolvedHist = _history
        .where((h) => h['status'] == 'resolved')
        .toList();
    if (resolvedHist.isNotEmpty) {
      for (var h in resolvedHist) {
        items.add(
          _buildTimelineItem(
            icon: Icons.check_circle_outline,
            isActive: true,
            title: 'Selesai',
            time: _formatTime(h['created_at']),
            description:
                h['note'] ?? 'Laporan telah ditangani dan dinyatakan selesai.',
            hasImage: h['photo_url'] != null,
            imageUrl: h['photo_url'],
            isLast: !isRejected,
          ),
        );
      }
    } else if (!isRejected) {
      items.add(
        _buildTimelineItem(
          icon: Icons.check_circle_outline,
          isActive: false,
          title: 'Selesai',
          time: '',
          description: 'Laporan akan ditutup setelah pengerjaan selesai.',
          isLast: true,
        ),
      );
    }

    // 6. Ditolak
    final rejectedHist = _history
        .where((h) => h['status'] == 'rejected')
        .toList();
    if (rejectedHist.isNotEmpty) {
      items.add(
        _buildTimelineItem(
          icon: Icons.cancel,
          isActive: true,
          title: 'Ditolak',
          time: _formatTime(rejectedHist.last['created_at']),
          description:
              rejectedHist.last['note'] ?? 'Laporan ini telah ditolak karena tidak memenuhi kriteria atau di luar yurisdiksi.',
          isLast: true,
        ),
      );
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
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
              style: TextStyle(
                color: Color(0xFF1B4332),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
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
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.report?.title ?? widget.title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Foto Laporan Card
            if (widget.report != null && widget.report!.imageUrl.isNotEmpty)
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
                          const Text(
                            'Foto Laporan Warga',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dokumentasi awal yang Anda lampirkan.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullScreenImageViewer(
                              imageUrl: widget.report!.imageUrl,
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        child: Image.network(
                          widget.report!.imageUrl,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: 200,
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                ),
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            if (_isLoadingHistory)
              const Center(child: CircularProgressIndicator())
            else ...[
              const Text(
                'Status Penanganan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ..._buildDynamicTimeline(),
            ],

            if (widget.report != null) ...[
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Diskusi Komunitas',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Semua pengguna dapat berdiskusi mengenai laporan ini.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),

              // Comments List
              Consumer(
                builder: (context, ref, child) {
                  final commentsAsync = ref.watch(
                    commentsProvider(widget.report!.id),
                  );
                  return commentsAsync.when(
                    data: (comments) {
                      if (comments.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              'Belum ada komentar.',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final c = comments[index];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(
                                  0xFF1B4332,
                                ).withValues(alpha: 0.2),
                                backgroundImage: c.userAvatar != null
                                    ? NetworkImage(c.userAvatar!)
                                    : null,
                                child: c.userAvatar == null
                                    ? const Icon(
                                        Icons.person,
                                        size: 16,
                                        color: Color(0xFF1B4332),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                c.userName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: c.userRole == 'admin'
                                                      ? Colors.red[100]
                                                      : (c.userRole == 'petugas'
                                                            ? Colors.blue[100]
                                                            : Colors
                                                                  .green[100]),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  c.userRole.toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.bold,
                                                    color: c.userRole == 'admin'
                                                        ? Colors.red[800]
                                                        : (c.userRole ==
                                                                  'petugas'
                                                              ? Colors.blue[800]
                                                              : Colors
                                                                    .green[800]),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            _formatTime(c.createdAt),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        c.content,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Text(
                      'Gagal memuat: $e',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),
              // Comment Input Field
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Tambahkan komentar...',
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submitComment(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isSubmittingComment
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: Color(0xFF1B4332),
                          ),
                          onPressed: _submitComment,
                        ),
                ],
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar:
          (widget.report != null &&
              widget.report!.status == 'received' &&
              widget.report!.userId == currentUserId)
          ? Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
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
                      await repo.deleteReport(widget.report!.id);
                      ref.invalidate(reportsProvider('me'));
                      ref.invalidate(reportsProvider('all'));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Laporan berhasil dibatalkan'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        context.pop();
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
                child: const Text(
                  'Batalkan Laporan',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required bool isActive,
    required String title,
    required String time,
    required String description,
    bool isFirst = false,
    bool isLast = false,
    bool hasImage = false,
    String? imageUrl,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and Line
          Column(
            children: [
              Icon(
                icon,
                color: isActive ? const Color(0xFF1B4332) : Colors.grey[300],
                size: 28,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isActive
                        ? const Color(0xFF1B4332)
                        : Colors.grey[300],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: hasImage
                  ? Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF1B4332)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isActive
                                      ? const Color(0xFF1B4332)
                                      : Colors.grey,
                                ),
                              ),
                              Text(
                                time,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 13,
                              color: isActive ? Colors.black87 : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (imageUrl != null)
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FullScreenImageViewer(
                                      imageUrl: imageUrl,
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrl,
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        height: 160,
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.broken_image,
                                          color: Colors.grey,
                                        ),
                                      ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isActive ? Colors.black87 : Colors.grey,
                              ),
                            ),
                            if (time.isNotEmpty)
                              Text(
                                time,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 13,
                            color: isActive ? Colors.black54 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
