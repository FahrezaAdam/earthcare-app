import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../auth/data/auth_provider.dart';
import '../../auth/data/auth_repository.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  String _email = '';
  String? _avatarUrl;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isLoading = false;

  late String _initialName;
  late String _initialPhone;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _initialName =
        user?['full_name']?.toString() ?? user?['name']?.toString() ?? '';
    _email = user?['email']?.toString() ?? '';
    _initialPhone =
        user?['phone']?.toString() ??
        user?['phone_number']?.toString() ??
        user?['phoneNumber']?.toString() ??
        user?['no_hp']?.toString() ??
        user?['telepon']?.toString() ??
        user?['no_telp']?.toString() ??
        user?['telp']?.toString() ??
        user?['user_metadata']?['phone']?.toString() ??
        user?['raw_user_meta_data']?['phone']?.toString() ??
        '';
    _avatarUrl = user?['avatar_url']?.toString();

    _nameController = TextEditingController(text: _initialName);
    _phoneController = TextEditingController(text: _initialPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1000,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageName = pickedFile.name;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih gambar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  context.pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Ambil dari Kamera'),
                onTap: () async {
                  context.pop();
                  final result = await context.push<String>(
                    '/camera',
                    extra: {'isProfileMode': true},
                  );
                  if (result != null) {
                    final bytes = await File(result).readAsBytes();
                    setState(() {
                      _selectedImageBytes = bytes;
                      _selectedImageName = result.split('/').last;
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmSaveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final currentName = _nameController.text.trim();
    final currentPhone = _phoneController.text.trim();

    if (currentName == _initialName &&
        currentPhone == _initialPhone &&
        _selectedImageBytes == null) {
      if (context.mounted) context.pop();
      return;
    }

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Simpan Perubahan?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: const Text(
            'Apakah Anda yakin ingin menyimpan perubahan profil ini?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Batal',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4332),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Ya, Simpan',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldSave == true) {
      _saveProfile();
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      String? uploadedUrl;

      // 1. Upload photo if selected
      if (_selectedImageBytes != null && _selectedImageName != null) {
        final ext = _selectedImageName!.split('.').last.toLowerCase();
        String contentType = 'image/jpeg';
        if (ext == 'png') contentType = 'image/png';
        if (ext == 'webp') contentType = 'image/webp';

        // Get signed URL
        final uploadData = await authRepo.getSignedUploadUrl(
          _selectedImageName!,
          contentType,
        );

        final signedUrl = uploadData['signed_url'];
        uploadedUrl = uploadData['public_url'];

        // Put the file to the signed URL
        final dio = Dio();
        final response = await dio.put(
          signedUrl,
          data: _selectedImageBytes!,
          options: Options(
            headers: {
              'Content-Type': contentType,
              'Content-Length': _selectedImageBytes!.length.toString(),
            },
          ),
        );

        if (response.statusCode != 200) {
          throw Exception('Gagal mengunggah foto ke storage.');
        }
      }

      // 2. Update Profile via API
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();

      await authRepo.updateProfile(
        name: name,
        phone: phone,
        avatarUrl: uploadedUrl ?? _avatarUrl,
      );

      // 3. Update local auth provider state
      ref
          .read(authProvider.notifier)
          .updateProfileData(
            name: name,
            phone: phone,
            avatarUrl: uploadedUrl ?? _avatarUrl,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil disimpan!'),
            backgroundColor: Color(0xFF1B4332),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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
          'Edit Profil',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B4332)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Consumer(
                  builder: (context, ref, child) {
                    final role = ref.watch(authProvider).role;
                    return Column(
                      children: [
                        // Profile Photo Edit
                        Center(
                          child: GestureDetector(
                            onTap: _showImagePickerOptions,
                            child: Column(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      clipBehavior: Clip.antiAlias,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black87,
                                      ),
                                      child: ClipOval(
                                        child: _selectedImageBytes != null
                                            ? Image.memory(
                                                _selectedImageBytes!,
                                                fit: BoxFit.cover,
                                                width: 80,
                                                height: 80,
                                              )
                                            : (_avatarUrl != null &&
                                                  _avatarUrl!.isNotEmpty)
                                            ? Image.network(
                                                _avatarUrl!,
                                                fit: BoxFit.cover,
                                                width: 80,
                                                height: 80,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => const Icon(
                                                      Icons.broken_image,
                                                      color: Colors.white,
                                                      size: 40,
                                                    ),
                                              )
                                            : const Icon(
                                                Icons.person,
                                                color: Colors.white,
                                                size: 50,
                                              ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1B4332),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Ubah Foto',
                                  style: TextStyle(
                                    color: Color(0xFF1B4332),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Form Container
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTextField(
                                label: 'NAMA LENGKAP',
                                controller: _nameController,
                                validator: (val) => (val == null || val.isEmpty)
                                    ? 'Nama tidak boleh kosong'
                                    : null,
                              ),
                              const SizedBox(height: 20),
                              // Email is read-only
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ALAMAT EMAIL',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[600],
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    initialValue: _email,
                                    readOnly: true,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black54,
                                    ),
                                    decoration: InputDecoration(
                                      fillColor: Colors.grey[100],
                                      filled: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: Colors.grey[200]!,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: Colors.grey[200]!,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (role != 'admin') ...[
                                const SizedBox(height: 20),
                                _buildTextField(
                                  label: 'NOMOR TELEPON',
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B4332),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            onPressed: _confirmSaveProfile,
                            icon: const Icon(
                              Icons.save,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: const Text(
                              'Simpan Perubahan',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1B4332)),
            ),
          ),
        ),
      ],
    );
  }
}
