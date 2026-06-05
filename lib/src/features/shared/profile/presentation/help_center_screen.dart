import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Pusat Bantuan',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Ada yang bisa kami\nbantu?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4332),
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Grid Options
            Row(
              children: [
                Expanded(
                  child: _buildHelpCard(
                    icon: Icons.menu_book,
                    iconColor: Colors.teal,
                    iconBg: Colors.teal[50]!,
                    title: 'Panduan Penggunaan',
                    desc: 'Pelajari cara melaporkan dan memantau kondisi lingkungan.',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildHelpCard(
                    icon: Icons.manage_accounts,
                    iconColor: Colors.orange,
                    iconBg: Colors.orange[50]!,
                    title: 'Masalah Akun',
                    desc: 'Bantuan masuk, pengaturan profil, dan keamanan data Anda.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildHelpCard(
                    icon: Icons.verified,
                    iconColor: Colors.green,
                    iconBg: Colors.green[50]!,
                    title: 'Laporan & Verifikasi',
                    desc: 'Status validasi laporan dan cara memberikan bukti yang kuat.',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildHelpCard(
                    icon: Icons.shield,
                    iconColor: Colors.brown,
                    iconBg: Colors.brown[50]!,
                    title: 'Kebijakan Privasi',
                    desc: 'Informasi bagaimana EarthCare menjaga dan memproses data Anda.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // FAQ Section
            const Text(
              'Pertanyaan Populer',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            _buildFaqItem(
              'Bagaimana cara melampirkan foto laporan yang jelas?',
              'Pastikan foto diambil pada siang hari atau di tempat dengan pencahayaan yang cukup. Pastikan tidak *blur*, dan objek yang dilaporkan terlihat dengan jelas dari berbagai sudut.',
            ),
            const SizedBox(height: 12),
            _buildFaqItem(
              'Berapa lama proses verifikasi laporan saya?',
              'Laporan Anda akan diverifikasi oleh pihak berwenang dalam kurun waktu 1x24 jam kerja sejak laporan berhasil dikirim. Anda dapat memantaunya melalui menu Lacak.',
            ),
            const SizedBox(height: 48),

            // Contact Us
            const Center(
              child: Text(
                'Masih butuh bantuan? Hubungi Kami',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0C3B2E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 0,
                ),
                onPressed: () {},
                icon: const Icon(Icons.chat, color: Colors.white, size: 18),
                label: const Text(
                  'WhatsApp Kami',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String desc,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                desc,
                style: TextStyle(fontSize: 10, color: Colors.grey[600], height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(String title, String answer) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: Colors.grey[600],
          collapsedIconColor: Colors.grey[600],
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Text(
                answer,
                style: TextStyle(fontSize: 11, color: Colors.grey[600], height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
