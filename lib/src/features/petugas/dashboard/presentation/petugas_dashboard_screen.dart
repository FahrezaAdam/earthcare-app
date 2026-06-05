import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../warga/report/data/report_provider.dart';
import '../data/status_repository.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/auth/data/auth_provider.dart';

class PetugasDashboardScreen extends ConsumerWidget {
  const PetugasDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsyncValue = ref.watch(reportsProvider('all'));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Dashboard Petugas', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: reportsAsyncValue.when(
        data: (reports) {
          // Petugas typically handles 'assigned', 'in_progress', 'resolved'
          // For now, let's just show all for demo purposes, or filter by not 'received'
          final activeReports = reports.where((r) => r.status != 'received').toList();
          
          if (activeReports.isEmpty) {
            return const Center(child: Text('Belum ada tugas lapangan yang diberikan kepada Anda.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: activeReports.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final report = activeReports[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(report.ticketId, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              report.status.toUpperCase(),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(report.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(report.location, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Ubah Status:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          DropdownButton<String>(
                            value: report.status.toLowerCase(),
                            items: const [
                              DropdownMenuItem(value: 'assigned', child: Text('Ditugaskan', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'in_progress', child: Text('Diproses', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'resolved', child: Text('Selesai', style: TextStyle(fontSize: 12))),
                            ],
                            onChanged: (newStatus) async {
                              if (newStatus == null || newStatus == report.status.toLowerCase()) return;
                              
                              // Show loading
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(child: CircularProgressIndicator()),
                              );
                              
                              try {
                                final repo = ref.read(statusRepositoryProvider);
                                await repo.updateStatus(reportId: report.id, status: newStatus);
                                
                                if (!context.mounted) return;
                                Navigator.pop(context); // close dialog
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Status berhasil diperbarui!'), backgroundColor: Colors.green),
                                );
                                
                                ref.invalidate(reportsProvider('all')); // Refresh list
                              } catch (e) {
                                if (!context.mounted) return;
                                Navigator.pop(context); // close dialog
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
