import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'widgets/evidence_guide_sheet.dart';
import '../data/report_repository.dart';
import '../data/upload_repository.dart';
import '../data/report_provider.dart';
import '../../../shared/notification/presentation/widgets/notification_bell_button.dart';
import '../../../shared/notification/data/notification_provider.dart';

class CreateReportScreen extends ConsumerStatefulWidget {
  const CreateReportScreen({super.key});

  @override
  ConsumerState<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends ConsumerState<CreateReportScreen> {
  final List<String> _imagePaths = [];
  String _selectedCategoryId = 'sampah_liar';
  LatLng _selectedLocation = const LatLng(
    -6.1830,
    106.8285,
  ); // Default: Jl. Kebon Sirih
  String _address = 'Memuat lokasi...';
  bool _isMapReady = false;
  final MapController _mapController = MapController();

  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _updateAddress(_selectedLocation);
    _getCurrentLocation();
  }

  Future<void> _updateAddress(LatLng point) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        if (mounted) {
          setState(() {
            _address =
                '${place.street ?? place.name}, ${place.subLocality ?? place.locality}, ${place.administrativeArea}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _address =
              '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;
    if (!serviceEnabled) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('GPS tidak aktif.')));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Izin lokasi ditolak.')));
        return;
      }
    }

    if (!mounted) return;
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izin lokasi ditolak permanen.')),
      );
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    final currentLatLng = LatLng(position.latitude, position.longitude);

    if (mounted) {
      setState(() {
        _selectedLocation = currentLatLng;
      });
      if (_isMapReady) {
        _mapController.move(currentLatLng, 15.0);
      }
    }
    _updateAddress(currentLatLng);
  }

  final List<Map<String, dynamic>> _categories = [
    {'id': 'sampah_liar', 'name': 'Sampah Liar', 'icon': Icons.delete_outline},
    {
      'id': 'sungai_tercemar',
      'name': 'Sungai Tercemar',
      'icon': Icons.water_drop_outlined,
    },
    {
      'id': 'pohon_tumbang',
      'name': 'Pohon Tumbang',
      'icon': Icons.park_outlined,
    },
    {'id': 'banjir', 'name': 'Banjir', 'icon': Icons.flood_outlined},
    {'id': 'polusi_udara', 'name': 'Polusi Udara', 'icon': Icons.air_outlined},
    {
      'id': 'kerusakan_fasilitas',
      'name': 'Fasilitas Rusak',
      'icon': Icons.broken_image_outlined,
    },
  ];

  void _showEvidenceGuide() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EvidenceGuideSheet(
        onProceed: () async {
          context.pop(); // close sheet
          // Navigate to camera and wait for result
          final result = await context.push<String>('/camera');
          if (result != null) {
            setState(() {
              _imagePaths.add(result);
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
          'LAPOR',
          style: TextStyle(
            color: Color(0xFF1B4332),
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 2.0,
          ),
        ),
        actions: const [NotificationBellButton(), SizedBox(width: 8)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo Area
            if (_imagePaths.isEmpty)
              GestureDetector(
                onTap: _showEvidenceGuide,
                child: Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 1.5,
                      style: BorderStyle.none,
                    ),
                  ),
                  child: CustomPaint(
                    painter: DashedBorderPainter(),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.grey,
                            size: 32,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tambah',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Image (first in list)
                  Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: FileImage(File(_imagePaths.first)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Thumbnails Row
                  SizedBox(
                    height: 64,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _imagePaths.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _imagePaths.length) {
                          // Add Button
                          return GestureDetector(
                            onTap: _showEvidenceGuide,
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: CustomPaint(
                                painter: DashedBorderPainter(),
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.camera_alt_outlined,
                                        color: Colors.grey,
                                        size: 16,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Tambah',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        // Thumbnail
                        return Container(
                          width: 64,
                          height: 64,
                          margin: const EdgeInsets.only(right: 12),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(_imagePaths[index]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _imagePaths.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 32),

            // KATEGORI LINGKUNGAN
            const Text(
              'KATEGORI LINGKUNGAN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategoryId == cat['id'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategoryId = cat['id']),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1B4332)
                          : Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1B4332)
                            : Colors.grey[300]!,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          cat['icon'],
                          color: isSelected ? Colors.white : Colors.black87,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cat['name'],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // DETAIL LAPORAN
            const Text(
              'DETAIL LAPORAN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'Jelaskan situasi yang Anda temukan secara mendetail...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1B4332)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // LOKASI KEJADIAN
            const Text(
              'LOKASI KEJADIAN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _selectedLocation,
                        initialZoom: 15.0,
                        onMapReady: () {
                          _isMapReady = true;
                          _mapController.move(_selectedLocation, 15.0);
                        },
                        onTap: (tapPosition, point) {
                          setState(() {
                            _selectedLocation = point;
                            _address = 'Memuat lokasi...';
                          });
                          _updateAddress(point);
                        },
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.earth_care',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _selectedLocation,
                              width: 48,
                              height: 48,
                              child: const Icon(
                                Icons.location_on,
                                color: Color(0xFF1B4332),
                                size: 48,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 4),
                          ],
                        ),
                        child: Text(
                          _address,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: _getCurrentLocation,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1B4332),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // KIRIM LAPORAN BUTTON
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0C3B2E),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                if (_imagePaths.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Harap tambahkan minimal 1 foto bukti.'),
                    ),
                  );
                  return;
                }

                final desc = _descriptionController.text.trim();
                if (desc.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Harap tuliskan detail laporan.'),
                    ),
                  );
                  return;
                }

                String category = _selectedCategoryId;

                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1B4332)),
                  ),
                );

                try {
                  // 1. Upload Photo
                  final uploadRepo = ref.read(uploadRepositoryProvider);
                  final photoPath = _imagePaths.first;
                  final filename =
                      'report_${DateTime.now().millisecondsSinceEpoch}.jpg';

                  final publicUrl = await uploadRepo.uploadFile(
                    photoPath,
                    filename,
                  );

                  final categoryName = _categories.firstWhere(
                    (c) => c['id'] == category,
                    orElse: () => {'name': category},
                  )['name'];

                  final reportTitle = 'Laporan $categoryName';

                  // 2. Submit Report
                  final reportRepo = ref.read(reportRepositoryProvider);
                  final success = await reportRepo.createReport(
                    title: reportTitle,
                    description: desc,
                    category: category,
                    latitude: _selectedLocation.latitude,
                    longitude: _selectedLocation.longitude,
                    address: _address,
                    photoUrl: publicUrl,
                  );

                  if (!context.mounted) return;
                  Navigator.pop(context); // close loading

                  if (success) {
                    ref.invalidate(reportsProvider('me'));
                    ref.invalidate(notificationsProvider);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Laporan berhasil dikirim!'),
                          ],
                        ),
                        backgroundColor: const Color(0xFF1B4332),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );

                    // Clear form
                    setState(() {
                      _imagePaths.clear();
                      _selectedCategoryId = 'sampah_liar';
                      _descriptionController.clear();
                    });

                    // Refresh report list
                    ref.invalidate(reportsProvider);
                    ref.invalidate(heatmapProvider);

                    // Back to dashboard
                    context.go('/dashboard');
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  Navigator.pop(context); // close loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Kirim Laporan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.send, color: Colors.white, size: 16),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Dengan menekan kirim, Anda berkontribusi pada pelestarian\nekosistem lokal secara transparan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 80), // spacing for bottom nav
          ],
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(12),
    );

    // Create dashed path
    ui.Path path = ui.Path()..addRRect(rrect);
    ui.Path dashPath = ui.Path();
    for (ui.PathMetric measurePath in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < measurePath.length) {
        dashPath.addPath(
          measurePath.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
