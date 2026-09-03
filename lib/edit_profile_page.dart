import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'security_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final Color primaryColor = const Color(0xFF26D0D9);
  final Color inputBgColor = const Color(0xFFF0F9FF);

  // Controller untuk menampung data
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController(); // Email read-only
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // FUNGSI MENGAMBIL DATA DARI METADATA SUPABASE
  void _loadUserData() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final String rawName = user.userMetadata?['full_name'] ?? "";
      setState(() {
        _fullNameController.text =
            rawName.isNotEmpty ? SecurityService.decryptAES(rawName) : "";
        _emailController.text = user.email ?? "";
        _phoneController.text = user.userMetadata?['phone'] ?? "";
        _dobController.text = user.userMetadata?['dob'] ?? "";
      });
    }
  }

  // FUNGSI UNTUK MEMUNCULKAN KALENDER (DATE PICKER)
  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();

    // Jika sudah ada tanggal sebelumnya, arahkan kalender ke tanggal tersebut
    if (_dobController.text.isNotEmpty) {
      try {
        initialDate = DateTime.parse(_dobController.text);
      } catch (e) {
        initialDate = DateTime.now();
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor, // Warna header & seleksi
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: primaryColor),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        // Format YYYY-MM-DD agar standar database
        _dobController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  // FUNGSI UPDATE DATA KE SUPABASE
  Future<void> _handleUpdate() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {
            'full_name':
                SecurityService.encryptAES(_fullNameController.text.trim()),
            'phone': _phoneController.text.trim(),
            'dob': _dobController.text.trim(),
          },
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil berhasil diperbarui!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal update: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          "Edit Profil",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Informasi Data Diri",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text(
              "Perbarui informasi profil Anda di bawah ini.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            _buildDisplayField(
              "Nama Lengkap",
              _fullNameController,
              Icons.person_outline,
            ),
            _buildDisplayField(
              "Email (Tidak dapat diubah)",
              _emailController,
              Icons.email_outlined,
              enabled: false,
            ),
            _buildDisplayField(
              "Nomor Telepon",
              _phoneController,
              Icons.phone_android_outlined,
            ),

            // FIELD TANGGAL LAHIR DENGAN KALENDER
            _buildDisplayField(
              "Tanggal Lahir",
              _dobController,
              Icons.calendar_today_outlined,
              readOnly: true, // Mencegah keyboard muncul
              onTap: () => _selectDate(context), // Memunculkan kalender
            ),

            const SizedBox(height: 40),

            // TOMBOL SIMPAN
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Simpan Perubahan",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // HELPER WIDGET UNTUK TEXTFIELD
  Widget _buildDisplayField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool enabled = true,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: primaryColor),
            filled: true,
            fillColor: enabled ? inputBgColor : Colors.grey.shade100,
            hintText: "Pilih data",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
