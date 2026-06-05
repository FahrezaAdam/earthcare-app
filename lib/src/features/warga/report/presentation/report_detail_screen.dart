import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ReportDetailScreen extends StatelessWidget {
  const ReportDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Detail Laporan',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estimasi Selesai Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1B4332), // Dark green
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ESTIMASI SELESAI',
                        style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '2 Jam 14 Menit Lagi',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F), // Red
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.error_outline, color: Colors.white, size: 16),
                    label: const Text('ESKALASI', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tumpukan Sampah Liar',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: const Text(
                          'Jl. Rimba Hijau No. 45,\nJakarta Pusat',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Status Penanganan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),

            // Timeline
            _buildTimelineItem(
              icon: Icons.check_circle_outline,
              isActive: false,
              title: 'Selesai',
              time: '',
              description: 'Laporan akan ditutup setelah verifikasi warga',
              isFirst: true,
            ),
            _buildTimelineItem(
              icon: Icons.build_circle,
              isActive: true,
              title: 'Dalam Penanganan',
              time: '10:30 WIB',
              description: 'Tim Lapangan Dinas Kebersihan sedang melakukan pengangkutan material di lokasi.',
              hasImage: true,
            ),
            _buildTimelineItem(
              icon: Icons.assignment_ind,
              isActive: true,
              title: 'Ditugaskan',
              time: '09:15 WIB',
              description: 'Laporan diteruskan ke Satuan Tugas Kebersihan Wilayah III.',
            ),
            _buildTimelineItem(
              icon: Icons.verified_user,
              isActive: true,
              title: 'Diverifikasi',
              time: '08:45 WIB',
              description: 'Admin memvalidasi keaslian laporan dan lokasi koordinat.',
            ),
            _buildTimelineItem(
              icon: Icons.play_circle_fill,
              isActive: true,
              title: 'Diterima',
              time: '08:00 WIB',
              description: 'Laporan masuk ke sistem EarthCare.',
              isLast: true,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1B4332),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), activeIcon: Icon(Icons.map), label: 'Peta'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), activeIcon: Icon(Icons.add_circle), label: 'Lapor'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), activeIcon: Icon(Icons.assignment), label: 'Lacak'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
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
                    color: isActive ? const Color(0xFF1B4332) : Colors.grey[300],
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
                              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? const Color(0xFF1B4332) : Colors.grey)),
                              Text(time, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(description, style: TextStyle(fontSize: 13, color: isActive ? Colors.black87 : Colors.grey)),
                          const SizedBox(height: 12),
                          // Mock Image Placeholder
                          Container(
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B4332),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Stack(
                              children: [
                                const Center(child: Icon(Icons.image, color: Colors.white54, size: 40)),
                                Positioned(
                                  bottom: 8,
                                  left: 8,
                                  child: Text(
                                    'BUKTI PETUGAS: 12/10/23 10:32',
                                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 8, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
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
                            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? Colors.black87 : Colors.grey)),
                            if (time.isNotEmpty) Text(time, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(description, style: TextStyle(fontSize: 13, color: isActive ? Colors.black54 : Colors.grey)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
