import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../report/data/report_model.dart';
import '../../report/data/report_provider.dart';
import '../../../shared/notification/presentation/widgets/notification_bell_button.dart';
import '../../../shared/auth/data/auth_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToReport;
  const MapScreen({super.key, this.onNavigateToReport});
  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final ValueNotifier<double> _panelHeightNotifier = ValueNotifier<double>(0);
  final double _minPanel = 0;
  final double _maxPanel = 500;

  // ignore: unused_field
  ReportModel? _selectedData;
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  bool _isMapReady = false;

  String? _formatCategory(String? category) {
    if (category == null || category.isEmpty) return category;
    return category
        .split('_')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _panelHeightNotifier.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Layanan lokasi dinonaktifkan.')),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Izin lokasi ditolak.')));
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin lokasi ditolak secara permanen.')),
        );
      }
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      if (_isMapReady) {
        try {
          _mapController.move(_currentLocation!, 16.0);
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(reportsProvider('all'));
    final authState = ref.watch(authProvider);
    final userRole = authState.user?['role'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: userRole == 'warga'
          ? AppBar(
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
                'PETA',
                style: TextStyle(
                  color: Color(0xFF1B4332),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 2.0,
                ),
              ),
              actions: const [NotificationBellButton(), SizedBox(width: 8)],
            )
          : null,
      body: Column(
        children: [
          // ===== MAP (takes remaining space) =====
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: reportsAsync.when(
                    data: (reports) {
                      final markers = reports.map((data) {
                        // Determine color based on status
                        Color markerColor;
                        if (data.commentCount >= 5) {
                          markerColor = Colors.red[700]!; // Kritis (Urgent)
                        } else {
                          switch (data.status.toLowerCase()) {
                            case 'received':
                            case 'assigned':
                              markerColor = Colors.orange; // Aktif
                              break;
                            case 'in_progress':
                              markerColor = Colors.purple; // Sedang diproses
                              break;
                            case 'resolved':
                              markerColor = Colors.green; // Teratasi
                              break;
                            default:
                              markerColor = Colors.orange; // Default Aktif
                          }
                        }

                        return Marker(
                          point: LatLng(
                            data.latitude ?? 0.0,
                            data.longitude ?? 0.0,
                          ),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedData = data;
                              });
                              _panelHeightNotifier.value = 280;
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: markerColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.warning,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        );
                      }).toList();

                      return FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter:
                              _currentLocation ??
                              const LatLng(-6.2088, 106.8456),
                          initialZoom: 14.0,
                          onMapReady: () {
                            _isMapReady = true;
                            if (_currentLocation != null) {
                              try {
                                _mapController.move(_currentLocation!, 16.0);
                              } catch (_) {}
                            }
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.earth_care',
                          ),
                          MarkerLayer(
                            markers: [
                              ...markers,
                              if (_currentLocation != null)
                                Marker(
                                  point: _currentLocation!,
                                  width: 24,
                                  height: 24,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1B4332),
                      ),
                    ),
                    error: (error, stack) => Center(
                      child: Text(
                        'Gagal memuat peta: $error',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ),

                // Notification Button (Petugas Only)
                if (userRole != 'warga')
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 16,
                    right: 16,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 8),
                        ],
                      ),
                      child: const NotificationBellButton(),
                    ),
                  ),

                // Urgensi Legend
                Positioned(
                  top: userRole == 'warga'
                      ? 16
                      : MediaQuery.of(context).padding.top + 80,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'URGENSI',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _legendItem(Colors.red, 'Kritis'),
                        const SizedBox(height: 4),
                        _legendItem(Colors.orange, 'Aktif'),
                        const SizedBox(height: 4),
                        _legendItem(Colors.green, 'Teratasi'),
                      ],
                    ),
                  ),
                ),

                // Map Controls
                Positioned(
                  bottom: 24, // Keep it above bottom edge
                  right: 16,
                  child: Column(
                    children: [
                      FloatingActionButton(
                        heroTag: 'btn_location',
                        mini: true,
                        backgroundColor: Colors.white,
                        onPressed: _getCurrentLocation,
                        child: const Icon(
                          Icons.my_location,
                          color: Color(0xFF1B4332),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        heroTag: 'btn_zoom_in',
                        mini: true,
                        backgroundColor: Colors.white,
                        onPressed: () {
                          _mapController.move(
                            _mapController.camera.center,
                            _mapController.camera.zoom + 1,
                          );
                        },
                        child: const Icon(Icons.add, color: Color(0xFF1B4332)),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        heroTag: 'btn_zoom_out',
                        mini: true,
                        backgroundColor: Colors.white,
                        onPressed: () {
                          _mapController.move(
                            _mapController.camera.center,
                            _mapController.camera.zoom - 1,
                          );
                        },
                        child: const Icon(
                          Icons.remove,
                          color: Color(0xFF1B4332),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ===== DRAGGABLE PANEL (fixed at bottom, draggable height) =====
          ValueListenableBuilder<double>(
            valueListenable: _panelHeightNotifier,
            builder: (context, panelHeight, child) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (details) {
                  double newHeight = panelHeight - details.delta.dy;
                  _panelHeightNotifier.value = newHeight.clamp(
                    _minPanel,
                    _maxPanel,
                  );
                },
                onVerticalDragEnd: (_) {
                  // Snap
                  final snaps = [_minPanel, 280.0, _maxPanel];
                  double best = snaps[0];
                  for (final s in snaps) {
                    if ((panelHeight - s).abs() < (panelHeight - best).abs()) {
                      best = s;
                    }
                  }
                  _panelHeightNotifier.value = best;
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeOut,
                  height: panelHeight,
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: panelHeight > 0
                        ? const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 12,
                              offset: Offset(0, -4),
                            ),
                          ]
                        : [],
                  ),
                  child: child,
                ),
              );
            },
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: SizedBox(
                height: _maxPanel,
                child: Column(
                  children: [
                    // Drag Handle
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Ringkasan Zona Terdekat',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[200]!),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          (_selectedData?.category
                                                      .toLowerCase()
                                                      .contains('limbah') ==
                                                  true ||
                                              _selectedData?.category
                                                      .toLowerCase()
                                                      .contains('sampah') ==
                                                  true)
                                          ? Colors.red[50]
                                          : (_selectedData?.category
                                                        .toLowerCase()
                                                        .contains('hutan') ==
                                                    true
                                                ? Colors.green[50]
                                                : Colors.orange[50]),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      (_selectedData?.category
                                                      .toLowerCase()
                                                      .contains('limbah') ==
                                                  true ||
                                              _selectedData?.category
                                                      .toLowerCase()
                                                      .contains('sampah') ==
                                                  true)
                                          ? 'KRITIS'
                                          : (_selectedData?.category
                                                        .toLowerCase()
                                                        .contains('hutan') ==
                                                    true
                                                ? 'TERATASI'
                                                : 'AKTIF'),
                                      style: TextStyle(
                                        color:
                                            (_selectedData?.category
                                                        .toLowerCase()
                                                        .contains('limbah') ==
                                                    true ||
                                                _selectedData?.category
                                                        .toLowerCase()
                                                        .contains('sampah') ==
                                                    true)
                                            ? Colors.red
                                            : (_selectedData?.category
                                                          .toLowerCase()
                                                          .contains('hutan') ==
                                                      true
                                                  ? Colors.green
                                                  : Colors.orange),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatCategory(_selectedData?.category) ??
                                        'Penumpukan Sampah Liar',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: Colors.grey[500],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Dilaporkan 2 jam lalu',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (userRole == 'warga') ...[
                              const SizedBox(height: 16),
                              // CTA
                              InkWell(
                                onTap: widget.onNavigateToReport,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(
                                        0xFF1B4332,
                                      ).withValues(alpha: 0.2),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.add_circle_outline,
                                        color: Color(0xFF1B4332),
                                        size: 32,
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Lihat sesuatu di sekitarmu?',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: Color(0xFF1B4332),
                                              ),
                                            ),
                                            Text(
                                              'Bantu komunitas dengan melaporkannya sekarang.',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            // Button
                            if (userRole != 'warga')
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 56,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: const Color(
                                            0xFF0C3B2E,
                                          ),
                                          side: const BorderSide(
                                            color: Color(0xFF0C3B2E),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        onPressed: () async {
                                          if (_selectedData?.latitude != null &&
                                              _selectedData?.longitude !=
                                                  null) {
                                            final url = Uri.parse(
                                              'https://www.google.com/maps/dir/?api=1&destination=${_selectedData!.latitude},${_selectedData!.longitude}',
                                            );
                                            if (await canLaunchUrl(url)) {
                                              await launchUrl(url);
                                            }
                                          }
                                        },
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.directions, size: 16),
                                            SizedBox(width: 8),
                                            Text(
                                              'Rute',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: SizedBox(
                                      height: 56,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF0C3B2E,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        onPressed: () {
                                          if (_selectedData != null) {
                                            context.push(
                                              '/track-detail',
                                              extra: {
                                                'title': _selectedData!.title,
                                                'ticketId':
                                                    _selectedData!.ticketId,
                                                'report': _selectedData,
                                              },
                                            );
                                          }
                                        },
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              _getActionButtonText(
                                                _selectedData?.status,
                                              ),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(
                                              Icons.arrow_forward,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0C3B2E),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () {
                                    if (_selectedData != null) {
                                      context.push(
                                        '/track-detail',
                                        extra: {
                                          'title': _selectedData!.title,
                                          'ticketId': _selectedData!.ticketId,
                                          'report': _selectedData,
                                        },
                                      );
                                    }
                                  },
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Lihat Detail Laporan',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getActionButtonText(String? status) {
    if (status == null) return 'Detail';
    switch (status.toLowerCase()) {
      case 'received':
        return 'Verifikasi';
      case 'kritis':
        return 'Verifikasi';
      case 'verified':
        return 'Tugaskan';
      case 'assigned':
        return 'Pantau';
      case 'in_progress':
        return 'Update';
      case 'resolved':
        return 'Detail';
      default:
        return 'Detail';
    }
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
