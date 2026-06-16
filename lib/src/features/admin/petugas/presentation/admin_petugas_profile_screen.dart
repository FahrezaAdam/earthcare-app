import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../warga/report/data/report_provider.dart';
import '../data/officer_model.dart';

class AdminPetugasProfileScreen extends ConsumerWidget {
  final Officer officer;

  const AdminPetugasProfileScreen({super.key, required this.officer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsyncValue = ref.watch(reportsProvider('all'));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B4332)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Profil Petugas',
          style: TextStyle(
            color: Color(0xFF1B4332),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: officer.avatarUrl != null
                            ? NetworkImage(officer.avatarUrl!)
                            : null,
                        child: officer.avatarUrl == null
                            ? const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                      if (officer.officerStatus == 'Aktif' ||
                          officer.officerStatus == 'Sedang Bertugas')
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    officer.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B4332),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      officer.sector ?? 'Belum ada sektor',
                      style: TextStyle(
                        color: Colors.green[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  _buildContactInfo(Icons.email_outlined, officer.email),
                  const SizedBox(height: 12),
                  _buildContactInfo(
                    Icons.phone_outlined,
                    officer.phone ?? 'Belum ada nomor',
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () =>
                          context.push('/admin/petugas/edit', extra: officer),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D2818),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'Edit Profil',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Use real data from reportsProvider
            reportsAsyncValue.when(
              data: (reports) {
                // Filter reports for this officer
                final officerReports = reports
                    .where((r) =>
                        r.assignedOfficerIds.contains(officer.id) ||
                        r.assignedOfficerId == officer.id)
                    .toList();

                final currentTasks = officerReports
                    .where((r) =>
                        r.status.toLowerCase() == 'assigned' ||
                        r.status.toLowerCase() == 'in_progress')
                    .toList();

                final historyTasks = officerReports
                    .where((r) => r.status.toLowerCase() == 'resolved')
                    .toList();

                return Column(
                  children: [
                    // Current Task
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Tugas Saat Ini',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: currentTasks.isNotEmpty
                                      ? Colors.orange[100]
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  currentTasks.isNotEmpty
                                      ? 'Sedang Berjalan'
                                      : 'Tidak Ada',
                                  style: TextStyle(
                                    color: currentTasks.isNotEmpty
                                        ? Colors.orange[800]
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (currentTasks.isNotEmpty) ...[
                            ...currentTasks.map((task) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        task.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1B4332),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        task.description ??
                                            'Lokasi: ${task.location}',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ] else ...[
                            const Text(
                              'Petugas ini sedang tidak mengerjakan tugas apapun saat ini.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Task History
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Riwayat Tugas',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          if (historyTasks.isEmpty)
                            const Text(
                              'Belum ada riwayat tugas yang selesai.',
                              style: TextStyle(color: Colors.grey),
                            )
                          else
                            ...historyTasks.map((task) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.green[100],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.check_circle_outline,
                                          color: Colors.green[800],
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              task.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Selesai • ${task.time}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        task.ticketId,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                        ],
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF1B4332))),
              error: (err, stack) =>
                  Center(child: Text('Gagal memuat data: $err')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.green[700], size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
        ),
      ],
    );
  }
}
