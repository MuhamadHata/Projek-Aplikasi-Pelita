import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Sekarang akan terpakai
import 'detail_hasil_screen.dart';
import 'security_service.dart';

class HasilPerhitunganScreen extends StatelessWidget {
  const HasilPerhitunganScreen({super.key});

  final Color primaryColor = const Color(0xFF26D0D9);

  @override
  Widget build(BuildContext context) {
    // BARIS INI YANG MEMBUAT IMPORT SUPABASE DIGUNAKAN:
    // Kita mengambil data user yang sedang login dari Supabase
    final user = Supabase.instance.client.auth.currentUser;
    final String rawName = user?.userMetadata?['full_name'] ?? "";
    final String displayName = rawName.isNotEmpty
        ? SecurityService.decryptAES(rawName)
        : (user?.email?.split('@')[0] ?? "User");

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Hasil Perhitungan",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Agar teks rata kiri
          children: [
            // Menampilkan Nama User yang login
            Text(
              "Halo, $displayName",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Berikut adalah hasil analisis gizi Anda:",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Grid Gambar (IMT, Energi, BBI)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildImageCard(
                        context,
                        "Asset/Menukalkulator/imt.png",
                        "imt",
                      ),
                      const SizedBox(height: 15),
                      _buildImageCard(
                        context,
                        "Asset/Menukalkulator/energi.png",
                        "energi",
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  flex: 1,
                  child: _buildImageCard(
                    context,
                    "Asset/Menukalkulator/bbi.png",
                    "bbi",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            _buildImageCard(
              context,
              "Asset/Menukalkulator/kesimpulan.png",
              "kesimpulan",
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget dengan Navigasi ke Detail
  Widget _buildImageCard(BuildContext context, String assetPath, String tipe) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailHasilScreen(tipeHasil: tipe),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(assetPath, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
