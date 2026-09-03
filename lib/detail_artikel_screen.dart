import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart'; // Import model Artikel
import 'security_service.dart';

class DetailArtikelScreen extends StatelessWidget {
  final Artikel artikel;
  const DetailArtikelScreen({super.key, required this.artikel});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF26D0D9);

    // 1. Ambil data user yang sedang login dari Supabase
    final user = Supabase.instance.client.auth.currentUser;

    // 2. Logika Nama Dinamis
    final String rawName =
        user?.userMetadata?['full_name'] ??
        user?.userMetadata?['name'] ??
        "";
    final String displayName = rawName.isNotEmpty
        ? SecurityService.decryptAES(rawName)
        : (user?.email?.split('@')[0] ?? "User");

    // 3. Logika Foto Profil Dinamis (Mendukung URL atau Asset)
    final String avatarPath =
        user?.userMetadata?['avatar_url'] ??
        user?.userMetadata?['avatar_path'] ??
        'Asset/login.png';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header dengan Nama & Foto User (Tanpa kata Halo!)
            _buildHeader(primaryColor, displayName, avatarPath),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeroSection(context, primaryColor),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        artikel.isi,
                        textAlign: TextAlign.justify,
                        style: const TextStyle(fontSize: 15, height: 1.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // HEADER: Menampilkan Nama dan Foto User yang Login
  Widget _buildHeader(Color primaryColor, String name, String avatarPath) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.search, color: Colors.grey),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    name, // Langsung menampilkan nama user
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16, // Sedikit diperbesar karena sendirian
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[200],
                backgroundImage: avatarPath.startsWith('http')
                    ? NetworkImage(avatarPath) as ImageProvider
                    : AssetImage(avatarPath),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // HERO SECTION
  Widget _buildHeroSection(BuildContext context, Color primaryColor) {
    return Stack(
      children: [
        // Deteksi apakah path gambar artikel dari Asset atau Network
        artikel.imagePath.startsWith('http') ||
                artikel.imagePath.startsWith('https')
            ? Image.network(
                artikel.imagePath,
                width: double.infinity,
                height: 260,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildErrorImage(),
              )
            : Image.asset(
                artikel.imagePath,
                width: double.infinity,
                height: 260,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildErrorImage(),
              ),

        Positioned(
          top: 15,
          left: 15,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.black26,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),

        Positioned(
          bottom: 20,
          left: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(40),
              ),
            ),
            child: Text(
              artikel.judul,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorImage() {
    return Container(
      height: 260,
      width: double.infinity,
      color: Colors.grey[300],
      child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
    );
  }
}
