import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/notification/presentation/widgets/notification_bell_button.dart';
import '../data/officer_provider.dart';
import '../data/officer_model.dart';

class AdminPetugasScreen extends ConsumerStatefulWidget {
  const AdminPetugasScreen({super.key});

  @override
  ConsumerState<AdminPetugasScreen> createState() => _AdminPetugasScreenState();
}

class _AdminPetugasScreenState extends ConsumerState<AdminPetugasScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'Semua Petugas';

  @override
  Widget build(BuildContext context) {
    final officersAsync = ref.watch(officersProvider);

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
          'PETUGAS',
          style: TextStyle(
            color: Color(0xFF1B4332),
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 2.0,
          ),
        ),
        actions: const [NotificationBellButton(), SizedBox(width: 8)],
      ),
      body: officersAsync.when(
        data: (officers) {
          final aktifCount = officers
              .where((o) => o.officerStatus == 'Aktif')
              .length;
          final bertugasCount = officers
              .where((o) => o.officerStatus == 'Sedang Bertugas')
              .length;

          var filteredOfficers = officers.where((o) {
            final matchesSearch =
                o.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (o.sector ?? '').toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );
            if (!matchesSearch) return false;

            if (_selectedFilter == 'Sedang Bertugas') {
              return o.officerStatus == 'Sedang Bertugas';
            }
            if (_selectedFilter == 'Tidak Bertugas') {
              return o.officerStatus == 'Aktif';
            }
            return true;
          }).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(officersProvider);
              // Wait for the new future to complete
              try {
                await ref.read(officersProvider.future);
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
                        // Summary Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B4332),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'RINGKASAN OPERASIONAL',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Petugas Lapangan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        officers.length.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          height: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            '$aktifCount Tersedia',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            '$bertugasCount Bertugas',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.people,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Search Bar
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            onChanged: (val) =>
                                setState(() => _searchQuery = val),
                            decoration: const InputDecoration(
                              icon: Icon(Icons.search, color: Colors.grey),
                              hintText: 'Cari petugas atau sektor...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Filters
                        Row(
                          children: [
                            _buildFilterChip('Semua Petugas'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Sedang Bertugas'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Tidak Bertugas'),
                          ],
                        ),
                        const SizedBox(height: 24),

                        const Text(
                          'Registri Petugas Lapangan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B4332),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // Officers List
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final officer = filteredOfficers[index];
                      return _buildOfficerCard(officer);
                    }, childCount: filteredOfficers.length),
                  ),
                ),

                // Bottom padding
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1B4332),
        onPressed: () => context.push('/admin/petugas/add'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B4332) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildOfficerCard(Officer officer) {
    final isOff = officer.officerStatus == 'Off';
    final isSedangBertugas = officer.officerStatus == 'Sedang Bertugas';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: officer.avatarUrl != null
                    ? NetworkImage(officer.avatarUrl!)
                    : null,
                backgroundColor: Colors.grey[300],
                child: officer.avatarUrl == null
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            officer.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isOff
                                ? Colors.grey[200]
                                : (isSedangBertugas
                                      ? Colors.green[100]
                                      : Colors.green[50]),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            officer.officerStatus ?? 'Aktif',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isOff
                                  ? Colors.grey[600]
                                  : (isSedangBertugas
                                        ? Colors.green[800]
                                        : Colors.green[600]),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      officer.sector ?? 'Belum ada sektor',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () =>
                        context.push('/admin/petugas/profile', extra: officer),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D2818),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Kelola',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                width: 48,
                child: ElevatedButton(
                  onPressed: () => _confirmDeleteOfficer(officer),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.red[50],
                    foregroundColor: Colors.red[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(color: Colors.red[200]!),
                    ),
                  ),
                  child: const Icon(Icons.delete_outline),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDeleteOfficer(Officer officer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Petugas'),
        content: Text('Apakah Anda yakin ingin menghapus ${officer.name}? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                // Tampilkan loading sebentar
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Menghapus petugas...')),
                );
                await ref.read(officerRepositoryProvider).deleteOfficer(officer.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Petugas berhasil dihapus')),
                  );
                }
                ref.invalidate(officersProvider);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
