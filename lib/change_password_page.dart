import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final Color primaryColor = const Color(0xFF26D0D9);
  final Color inputBgColor = const Color(0xFFF0F9FF);

  // Controller Tambahan untuk Password Lama
  final _oldPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isObscureOld = true;
  bool _isObscureNew = true;
  bool _isObscureConfirm = true;

  Future<void> _handleUpdatePassword() async {
    final oldPassword = _oldPasswordController.text.trim();
    final newPassword = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // 1. Validasi Input Dasar
    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar("Semua kolom harus diisi!", Colors.orange);
      return;
    }

    if (newPassword.length < 6) {
      _showSnackBar("Password baru minimal 6 karakter!", Colors.orange);
      return;
    }

    if (newPassword != confirmPassword) {
      _showSnackBar("Konfirmasi password baru tidak cocok!", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;

      // 2. VERIFIKASI PASSWORD LAMA (Re-authentication)
      // Kita coba login pakai email user saat ini + password lama yang diinput
      await Supabase.instance.client.auth.signInWithPassword(
        email: currentUser!.email!,
        password: oldPassword,
      );

      // 3. JIKA LOLOS, BARU UPDATE PASSWORD BARU
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (mounted) {
        _showSnackBar("Password berhasil diganti!", Colors.green);
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      // Jika login gagal, berarti password lama salah
      String errorMsg = "Terjadi kesalahan";
      if (e.message.contains("Invalid login credentials")) {
        errorMsg = "Password lama yang Anda masukkan salah!";
      } else {
        errorMsg = e.message;
      }
      if (mounted) _showSnackBar(errorMsg, Colors.red);
    } catch (e) {
      if (mounted) _showSnackBar("Gagal: ${e.toString()}", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
          "Ganti Password",
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
              "Keamanan Akun",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Masukkan password lama Anda untuk memverifikasi identitas.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // FIELD PASSWORD LAMA
            _buildPasswordField(
              label: "Password Lama",
              hint: "Masukkan password saat ini",
              controller: _oldPasswordController,
              isObscure: _isObscureOld,
              onToggle: () => setState(() => _isObscureOld = !_isObscureOld),
            ),

            const Divider(height: 40),

            // FIELD PASSWORD BARU
            _buildPasswordField(
              label: "Password Baru",
              hint: "Masukkan password baru",
              controller: _passwordController,
              isObscure: _isObscureNew,
              onToggle: () => setState(() => _isObscureNew = !_isObscureNew),
            ),

            // FIELD KONFIRMASI
            _buildPasswordField(
              label: "Konfirmasi Password Baru",
              hint: "Ulangi password baru",
              controller: _confirmPasswordController,
              isObscure: _isObscureConfirm,
              onToggle: () =>
                  setState(() => _isObscureConfirm = !_isObscureConfirm),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleUpdatePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Update Password",
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

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool isObscure,
    required VoidCallback onToggle,
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
          obscureText: isObscure,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: primaryColor.withValues(alpha: 0.4)),
            prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
            suffixIcon: IconButton(
              icon: Icon(
                isObscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.grey,
              ),
              onPressed: onToggle,
            ),
            filled: true,
            fillColor: inputBgColor,
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
