import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../warga/report/data/report_model.dart';
import '../../../warga/report/data/report_provider.dart';
import '../../../warga/track/data/comment_provider.dart';

class AdminReportCommentsScreen extends ConsumerStatefulWidget {
  final ReportModel report;

  const AdminReportCommentsScreen({super.key, required this.report});

  @override
  ConsumerState<AdminReportCommentsScreen> createState() =>
      _AdminReportCommentsScreenState();
}

class _AdminReportCommentsScreenState
    extends ConsumerState<AdminReportCommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmittingComment = false;

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmittingComment = true);
    try {
      final repo = ref.read(commentRepositoryProvider);
      await repo.addComment(widget.report.id, text);
      _commentController.clear();
      ref.invalidate(commentsProvider(widget.report.id));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Diskusi Komunitas',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.report.ticketId,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final commentsAsync = ref.watch(
                  commentsProvider(widget.report.id),
                );
                return commentsAsync.when(
                  data: (comments) {
                    if (comments.isEmpty) {
                      return Center(
                        child: Text(
                          'Belum ada komentar pada laporan ini.',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                                          : Colors.green[100]),
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
                                                      : (c.userRole == 'petugas'
                                                            ? Colors.blue[800]
                                                            : Colors
                                                                  .green[800]),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          DateFormat(
                                            'dd/MM HH:mm',
                                          ).format(c.createdAt),
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
                  error: (e, st) => Center(
                    child: Text(
                      'Gagal memuat: $e',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Input Field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, -4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
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
                      : Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF1B4332),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: _submitComment,
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
