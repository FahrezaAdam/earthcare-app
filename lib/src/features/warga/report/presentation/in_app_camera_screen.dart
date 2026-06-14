import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img_pkg;
import 'package:intl/intl.dart';

class InAppCameraScreen extends StatefulWidget {
  final bool isProfileMode;
  const InAppCameraScreen({super.key, this.isProfileMode = false});

  @override
  State<InAppCameraScreen> createState() => _InAppCameraScreenState();
}

class _InAppCameraScreenState extends State<InAppCameraScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitializing = true;
  int _selectedCameraIndex = 0;
  Position? _currentPosition;
  String _currentTime = '';
  String _address = 'Mencari lokasi...';

  @override
  void initState() {
    super.initState();
    _initCamera();
    _fetchLocation();
    _updateTime();
  }

  void _updateTime() {
    if (!mounted) return;
    final now = DateTime.now();
    setState(() {
      _currentTime = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    });
    Future.delayed(const Duration(seconds: 1), _updateTime);
  }

  Future<void> _fetchLocation() async {
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

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    if (mounted) {
      setState(() {
        _currentPosition = position;
      });
      _fetchAddress(position.latitude, position.longitude);
    }
  }

  Future<void> _fetchAddress(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        final addr = '${place.street ?? place.name}, ${place.subLocality ?? place.locality}, ${place.administrativeArea}';
        if (mounted) {
          setState(() {
            _address = addr;
          });
        }
      }
    } catch (e) {
      // Ignored
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        await _setupCameraController(_cameras[_selectedCameraIndex]);
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _setupCameraController(CameraDescription camera) async {
    final newController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _controller = newController;

    try {
      await newController.initialize();
    } catch (e) {
      debugPrint('Error initializing camera controller: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kamera gagal dibuka: $e')),
        );
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.isEmpty || _cameras.length == 1) return;
    if (_controller == null) return;
    
    final nextIndex = (_selectedCameraIndex + 1) % _cameras.length;
    final newCamera = _cameras[nextIndex];
    
    try {
      // Switch the active lens without dropping the CameraPreview widget
      await _controller!.setDescription(newCamera);
      setState(() {
        _selectedCameraIndex = nextIndex;
      });
    } catch (e) {
      debugPrint('Error using setDescription: $e');
      // If setDescription fails, fallback to recreating the controller
      setState(() {
        _isInitializing = true;
      });
      
      try {
        await _controller!.dispose();
      } catch (_) {}
      
      final fallbackController = CameraController(
        newCamera,
        ResolutionPreset.medium, // Use medium to avoid hardware limits on front camera
        enableAudio: false,
      );
      
      try {
        await fallbackController.initialize();
        _controller = fallbackController;
        setState(() {
          _selectedCameraIndex = nextIndex;
        });
      } catch (err) {
        debugPrint('Fallback init failed: $err');
      }
      
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isTakingPicture) return;

    try {
      setState(() {
        _isInitializing = true;
      });

      final XFile picture = await _controller!.takePicture();
      
      // Process image to add timestamp
      final File file = File(picture.path);
      final bytes = await file.readAsBytes();
      img_pkg.Image? decodedImage = img_pkg.decodeImage(bytes);
      
      if (decodedImage != null) {
        // Bake EXIF orientation so portrait photos don't mess up text rendering
        decodedImage = img_pkg.bakeOrientation(decodedImage);

        // Resize image to ensure watermark is proportional
        if (decodedImage.width > 1200) {
          decodedImage = img_pkg.copyResize(decodedImage, width: 1200);
        }

        if (!widget.isProfileMode) {
          final timestamp = DateFormat('dd MMM yyyy HH:mm:ss').format(DateTime.now());
          final coordsText = _currentPosition != null 
              ? '${_currentPosition!.latitude}, ${_currentPosition!.longitude}' 
              : '0, 0';
          
          // Draw semi-transparent black background
          img_pkg.fillRect(
            decodedImage,
            x1: 0,
            y1: decodedImage.height - 130,
            x2: decodedImage.width,
            y2: decodedImage.height,
            color: img_pkg.ColorRgb8(0, 0, 0),
          );

          // Draw Timestamp
          img_pkg.drawString(
            decodedImage,
            'WAKTU    : $timestamp',
            font: img_pkg.arial24,
            x: 20,
            y: decodedImage.height - 115,
            color: img_pkg.ColorRgb8(255, 255, 255),
          );
          
          // Draw Coordinates
          img_pkg.drawString(
            decodedImage,
            'KOORDINAT: $coordsText',
            font: img_pkg.arial24,
            x: 20,
            y: decodedImage.height - 80,
            color: img_pkg.ColorRgb8(255, 255, 255),
          );
          
          // Draw Location
          final displayAddress = _address.length > 50 ? '${_address.substring(0, 50)}...' : _address;
          img_pkg.drawString(
            decodedImage,
            'LOKASI   : $displayAddress',
            font: img_pkg.arial24,
            x: 20,
            y: decodedImage.height - 45,
            color: img_pkg.ColorRgb8(255, 255, 255),
          );
        }
        
        final outBytes = img_pkg.encodeJpg(decodedImage, quality: 90);
        await file.writeAsBytes(outBytes);
      }

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        // Return the picture path to the previous screen
        context.pop(picture.path);
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Kamera tidak tersedia.',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          Positioned.fill(child: CameraPreview(_controller!)),

          // Cyber/Futuristic Overlay Box
          if (!widget.isProfileMode)
            Positioned(
              left: 24,
              bottom: 140,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.greenAccent,
                          size: 12,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'EVIDENCE VALIDATED',
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.8),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _buildOverlayText('GPS: ${_currentPosition != null ? '${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}' : 'Mencari lokasi...'}'),
                    _buildOverlayText('Time: $_currentTime WIB'),
                    _buildOverlayText('Accuracy: ${_currentPosition != null ? '${_currentPosition!.accuracy.toStringAsFixed(1)}m' : '...'} | Report ID: AUTO'),
                  ],
                ),
              ),
            ),

          // Top Header (EarthCare & Flash)
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    const Row(
                      children: [
                        Icon(Icons.eco, color: Colors.white, size: 18),
                        SizedBox(width: 4),
                        Text(
                          'EarthCare',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.flash_off, color: Colors.white),
                      onPressed: () {
                        // toggle flash
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Controls (Shutter, Flip)
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Empty spacer to keep shutter centered
                const SizedBox(width: 48, height: 48),

                // Shutter Button
                GestureDetector(
                  onTap: _takePicture,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),

                // Flip Camera Button (only for profile mode)
                if (widget.isProfileMode)
                  GestureDetector(
                    onTap: _switchCamera,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.flip_camera_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 48, height: 48), // Empty spacer to keep shutter centered
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 10,
          fontFamily: 'Courier', // monospace for techy look
          shadows: [
            Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 2),
          ],
        ),
      ),
    );
  }
}
