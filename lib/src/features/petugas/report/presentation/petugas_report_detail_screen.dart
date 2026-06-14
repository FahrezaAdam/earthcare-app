import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../warga/report/data/report_model.dart';
import '../../../warga/report/data/report_provider.dart';
import '../../dashboard/data/status_repository.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../warga/report/data/upload_repository.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import '../../../shared/widgets/full_screen_image_viewer.dart';

class PetugasReportDetailScreen extends ConsumerStatefulWidget {
  final ReportModel report;

  const PetugasReportDetailScreen({super.key, required this.report});

  @override
  ConsumerState<PetugasReportDetailScreen> createState() =>
      _PetugasReportDetailScreenState();
}

class _PetugasReportDetailScreenState
    extends ConsumerState<PetugasReportDetailScreen> {
  bool _isLoading = false;
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final repo = ref.read(statusRepositoryProvider);
      final history = await repo.getStatusHistory(widget.report.id);
      if (mounted) setState(() => _history = history);
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
  }

  Future<void> _updateStatus(
    String newStatus, {
    String? note,
    String? photoUrl,
  }) async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(statusRepositoryProvider);
      await repo.updateStatus(
        reportId: widget.report.id,
        status: newStatus,
        note: note,
        photoUrl: photoUrl,
      );

      if (!mounted) return;
      ref.invalidate(reportsProvider('all'));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'in_progress'
                ? (widget.report.status.toLowerCase() == 'in_progress'
                      ? 'Bukti pengerjaan berhasil dikirim!'
                      : 'Tugas diterima!')
                : 'Tugas diselesaikan!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      if (newStatus == 'resolved' ||
          widget.report.status.toLowerCase() != 'in_progress') {
        context.pop();
      } else {
        _loadHistory(); // Reload history after update
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<File> _addTimestampToImage(
    BuildContext context,
    File imageFile,
  ) async {
    try {
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) throw Exception('Gagal decode image');

      // Bake EXIF orientation so portrait photos don't mess up text rendering
      image = img.bakeOrientation(image);

      // Resize image if it's too large to save bandwidth and make font size proportional
      if (image.width > 1200) {
        image = img.copyResize(image, width: 1200);
      }

      final timestamp = DateFormat(
        'dd MMM yyyy HH:mm:ss',
      ).format(DateTime.now());
      final locationText = widget.report.location.length > 50
          ? '${widget.report.location.substring(0, 50)}...'
          : widget.report.location;
      final coordsText =
          '${widget.report.latitude ?? 0}, ${widget.report.longitude ?? 0}';

      // Draw semi-transparent background (taller for 3 lines)
      img.fillRect(
        image,
        x1: 0,
        y1: image.height - 130,
        x2: image.width,
        y2: image.height,
        color: img.ColorRgb8(0, 0, 0), // Use solid black
      );

      // Draw timestamp text
      img.drawString(
        image,
        'WAKTU    : $timestamp',
        font: img.arial24,
        x: 20,
        y: image.height - 115,
        color: img.ColorRgb8(255, 255, 255),
      );

      // Draw coordinates text
      img.drawString(
        image,
        'KOORDINAT: $coordsText',
        font: img.arial24,
        x: 20,
        y: image.height - 80,
        color: img.ColorRgb8(255, 255, 255),
      );

      // Draw location text
      img.drawString(
        image,
        'LOKASI   : $locationText',
        font: img.arial24,
        x: 20,
        y: image.height - 45,
        color: img.ColorRgb8(255, 255, 255),
      );

      final modifiedBytes = img.encodeJpg(image, quality: 85);
      final newFile = File('${imageFile.path}_stamped.jpg');
      await newFile.writeAsBytes(modifiedBytes);
      return newFile;
    } catch (e) {
      debugPrint('Error stamping image: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan watermark: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return imageFile; // Fallback to original image if stamping fails
    }
  }

  Future<void> _showUpdateDialog(String targetStatus) async {
    final noteController = TextEditingController();
    File? selectedImage;
    bool isUploading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    targetStatus == 'resolved'
                        ? 'Selesaikan Tugas'
                        : 'Update Pengerjaan',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B4332),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    targetStatus == 'resolved'
                        ? 'Harap unggah foto bukti bahwa tugas ini telah selesai dikerjakan.'
                        : 'Harap unggah foto bukti bahwa tugas ini sedang dalam pengerjaan.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Catatan Pengerjaan (Opsional)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Tuliskan tindakan yang telah dilakukan...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Foto Bukti Pengerjaan (Wajib)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final pickedFile = await picker.pickImage(
                        source: ImageSource.camera,
                      );
                      if (pickedFile != null) {
                        setModalState(() => isUploading = true);
                        if (!context.mounted) return;
                        // Add timestamp IMMEDIATELY so user can see it in preview
                        final stamped = await _addTimestampToImage(
                          context,
                          File(pickedFile.path),
                        );
                        setModalState(() {
                          selectedImage = stamped;
                          isUploading = false;
                        });
                      }
                    },
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  size: 40,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Ambil Foto Kamera',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (selectedImage == null || isUploading)
                          ? null
                          : () async {
                              setModalState(() => isUploading = true);
                              try {
                                final uploadRepo = ref.read(
                                  uploadRepositoryProvider,
                                );
                                final filename =
                                    'proof_${DateTime.now().millisecondsSinceEpoch}.jpg';
                                final photoUrl = await uploadRepo.uploadFile(
                                  selectedImage!.path,
                                  filename,
                                );

                                if (!context.mounted) return;
                                Navigator.pop(context); // close modal
                                await _updateStatus(
                                  targetStatus,
                                  note: noteController.text,
                                  photoUrl: photoUrl,
                                );
                              } catch (e) {
                                setModalState(() => isUploading = false);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Gagal upload foto: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A2B1D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isUploading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Kirim Bukti',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.report;
    final isAssigned = r.status.toLowerCase() == 'assigned';
    final isInProgress = r.status.toLowerCase() == 'in_progress';
    final isResolved = r.status.toLowerCase() == 'resolved';

    // Periksa apakah petugas sudah mengupload minimal 1 bukti pengerjaan (status in_progress + ada foto)
    final hasProgressPhoto = _history.any(
      (h) => h['status'] == 'in_progress' && h['photo_url'] != null,
    );

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
          'EarthCare Field',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: 100,
              top: 10,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isResolved ? Colors.green[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isResolved
                          ? Colors.green[200]!
                          : Colors.orange[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isResolved ? Icons.check_circle : Icons.assignment_ind,
                        color: isResolved
                            ? Colors.green[800]
                            : Colors.orange[800],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isResolved
                            ? 'Selesai'
                            : (isAssigned
                                  ? 'Ditugaskan oleh Admin'
                                  : 'Dalam Pengerjaan'),
                        style: TextStyle(
                          color: isResolved
                              ? Colors.green[800]
                              : Colors.orange[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        r.title,
                        style: const TextStyle(
                          color: Color(0xFF1B4332),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                    ),
                    if (!isResolved)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'PRIORITAS TINGGI',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[800],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      r.time,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  r.description ??
                      'Laporan warga mengenai pelanggaran di lokasi ini. Diperlukan pengecekan lapangan segera untuk verifikasi dampak lingkungan.',
                  style: TextStyle(
                    color: Colors.grey[800],
                    height: 1.6,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                // Bukti Laporan Warga
                const Text(
                  'Bukti Laporan Warga',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                if (r.imageUrl.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              FullScreenImageViewer(imageUrl: r.imageUrl),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        r.imageUrl,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
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
                const SizedBox(height: 24),

                // Lokasi Penugasan
                const Text(
                  'Lokasi Penugasan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                if (r.latitude != null && r.longitude != null)
                  _LocationMapWidget(
                    latitude: r.latitude!,
                    longitude: r.longitude!,
                    address: r.location,
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_off, color: Colors.grey[400]),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Koordinat lokasi tidak tersedia untuk laporan ini.',
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                // Pelapor
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        backgroundImage: r.reporterAvatar != null
                            ? NetworkImage(r.reporterAvatar!)
                            : null,
                        child: r.reporterAvatar == null
                            ? const Icon(Icons.person, color: Colors.grey)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PELAPOR',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            r.reporterName ?? 'Warga',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Riwayat Pengerjaan
                if (_history.isNotEmpty) ...[
                  const Text(
                    'Riwayat Pengerjaan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  ..._history.map((h) {
                    final isResolved = h['status'] == 'resolved';
                    final date =
                        DateTime.tryParse(
                          h['created_at'].toString(),
                        )?.toLocal() ??
                        DateTime.now();
                    final timeStr = DateFormat(
                      'dd MMM yyyy, HH:mm',
                    ).format(date);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isResolved ? Icons.done_all : Icons.update,
                                color: isResolved ? Colors.green : Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isResolved
                                    ? 'Tugas Selesai'
                                    : 'Update Pengerjaan',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                timeStr,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          if (h['note'] != null &&
                              h['note'].toString().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              h['note'],
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 13,
                              ),
                            ),
                          ],
                          if (h['photo_url'] != null) ...[
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FullScreenImageViewer(
                                      imageUrl: h['photo_url'],
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  h['photo_url'],
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),

          const SizedBox(height: 60),

          // Bottom Action Button
          if (!isResolved)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      offset: const Offset(0, -5),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isAssigned) ...[
                      const Text(
                        'Konfirmasi kesediaan Anda untuk tugas ini.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () => _updateStatus('in_progress'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A2B1D),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.check_circle_outline),
                                    SizedBox(width: 8),
                                    Text(
                                      'Terima Tugas',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ] else if (isInProgress) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _showUpdateDialog('in_progress'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1B4332),
                                side: const BorderSide(
                                  color: Color(0xFF1B4332),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Update Bukti',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (!hasProgressPhoto) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Anda harus mengirim "Update Bukti" minimal 1 kali sebelum bisa menyelesaikan tugas!',
                                      ),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }
                                _showUpdateDialog('resolved');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0A2B1D),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.done_all, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Selesai',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LocationMapWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String address;

  const _LocationMapWidget({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  @override
  State<_LocationMapWidget> createState() => _LocationMapWidgetState();
}

class _LocationMapWidgetState extends State<_LocationMapWidget> {
  final _mapController = MapController();
  LatLng? _currentLocation;
  double? _distanceInMeters;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    if (!mounted) return;
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        widget.latitude,
        widget.longitude,
      );
    });
  }

  void _centerMapOnCurrentLocation() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 15.0);
    }
  }

  void _launchNavigation() async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${widget.latitude},${widget.longitude}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka peta')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final destLatLng = LatLng(widget.latitude, widget.longitude);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Map
          SizedBox(
            height: 200,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: destLatLng,
                      initialZoom: 15.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.earthcare.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: destLatLng,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                          if (_currentLocation != null)
                            Marker(
                              point: _currentLocation!,
                              width: 40,
                              height: 40,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (_currentLocation != null)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: [_currentLocation!, destLatLng],
                              color: Colors.blue,
                              strokeWidth: 4.0,
                            ),
                          ],
                        ),
                    ],
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: FloatingActionButton.small(
                      heroTag: 'current_loc_fab',
                      backgroundColor: Colors.white,
                      onPressed: _centerMapOnCurrentLocation,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Navigation Panel
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.directions_car,
                            color: Colors.green[800],
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _distanceInMeters != null
                                  ? '${(_distanceInMeters! / 1000).toStringAsFixed(1)} km'
                                  : 'Menghitung...',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (_distanceInMeters != null)
                              Text(
                                '${(_distanceInMeters! / 1000 * 3).toStringAsFixed(0)} Menit',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: _launchNavigation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A2B1D),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Mulai Navigasi',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on, color: Colors.orange[800]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.address,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
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
}
