import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/officer_model.dart';
import '../data/officer_provider.dart';

class AdminAddPetugasScreen extends ConsumerStatefulWidget {
  final Officer? officer;

  const AdminAddPetugasScreen({super.key, this.officer});

  @override
  ConsumerState<AdminAddPetugasScreen> createState() => _AdminAddPetugasScreenState();
}

class _AdminAddPetugasScreenState extends ConsumerState<AdminAddPetugasScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;

  String? _selectedSector;
  final List<String> _sectors = [
    'Sektor Banjir',
    'Sektor Pohon',
    'Sektor Polusi',
    'Sektor Limbah',
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.officer?.name ?? '');
    _emailController = TextEditingController(text: widget.officer?.email ?? '');
    _phoneController = TextEditingController(text: widget.officer?.phone ?? '');
    _passwordController = TextEditingController();
    _selectedSector = widget.officer?.sector;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveOfficer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSector == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih sektor pengawasan', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(officerRepositoryProvider);
      
      final data = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'sector': _selectedSector,
        if (_passwordController.text.isNotEmpty) 'password': _passwordController.text,
      };

      if (widget.officer == null) {
        // Create new
        if (_passwordController.text.isEmpty) {
          throw Exception('Password wajib diisi untuk petugas baru');
        }
        await repository.createOfficer(data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Petugas berhasil ditambahkan'), backgroundColor: Colors.green),
        );
      } else {
        // Update existing
        await repository.updateOfficer(widget.officer!.id, data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data petugas berhasil diperbarui'), backgroundColor: Colors.green),
        );
      }
      
      // Refresh list
      ref.invalidate(officersProvider);
      if (mounted) context.pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.officer != null;

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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'EarthCare Admin ',
              style: TextStyle(
                color: Color(0xFF1B4332),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Icon(Icons.eco, color: Color(0xFF1B4332), size: 18),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Upload Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey[100],
                          backgroundImage: widget.officer?.avatarUrl != null ? NetworkImage(widget.officer!.avatarUrl!) : null,
                          child: widget.officer?.avatarUrl == null 
                            ? const Icon(Icons.person_outline, size: 40, color: Colors.grey)
                            : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF0D2818),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Unggah Foto Profil',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Form Fields
              _buildTextField('Nama Lengkap', _nameController, 'Masukkan nama lengkap petugas'),
              const SizedBox(height: 16),
              _buildTextField('Email', _emailController, 'contoh@earthcare.com', keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildTextField('Nomor Telepon', _phoneController, '+628...', keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildTextField(
                'Password', 
                _passwordController, 
                isEdit ? 'Biarkan kosong jika tidak diubah' : '******',
                obscureText: true,
                validator: isEdit ? null : (val) {
                  if (val == null || val.isEmpty) return 'Password wajib diisi';
                  if (val.length < 6) return 'Password minimal 6 karakter';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Sector Assignment
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.assignment_ind, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Penugasan Lapangan',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Pilih Sektor Pengawasan',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _sectors.map((sector) {
                        final isSelected = _selectedSector == sector;
                        return ChoiceChip(
                          label: Text(sector),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedSector = sector);
                          },
                          backgroundColor: Colors.white,
                          selectedColor: Colors.green[100],
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.green[800] : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: isSelected ? Colors.green[300]! : Colors.grey[300]!),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveOfficer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D2818),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.save, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Simpan Petugas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label, 
    TextEditingController controller, 
    String hint, {
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          validator: validator ?? (val) {
            if (label != 'Password' && (val == null || val.isEmpty)) {
              return '$label wajib diisi';
            }
            return null;
          },
        ),
      ],
    );
  }
}
