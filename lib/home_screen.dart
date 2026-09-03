import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'detail_artikel_screen.dart';
import 'kalkulator_gizi_screen.dart';
import 'konsultasi_screen.dart';
import 'profile.dart';
import 'riwayat.dart';
import 'security_service.dart'; // 1. WAJIB IMPORT INI

// --- MODEL DATA ---
class Artikel {
  final String judul;
  final String isi;
  final String imagePath;
  Artikel({required this.judul, required this.isi, required this.imagePath});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Color primaryColor = const Color(0xFF26D0D9);

  // Controller untuk slider artikel
  final PageController _pageController = PageController(viewportFraction: 0.85);

  String _userName = "User";
  String _avatarPath = 'Asset/login.png';

  final List<Artikel> daftarArtikel = [
    Artikel(
      judul: "Apa itu Nutrisi?",
      imagePath: "Asset/menuartikel/nutrisi.png",
      isi:
          '''Nutrisi merupakan bagian penting dari kesehatan dan perkembangan. Nutrisi yang lebih baik berkaitan dengan peningkatan kesehatan bayi, anak, dan ibu, sistem kekebalan tubuh yang lebih kuat, kehamilan dan persalinan yang lebih aman, risiko penyakit tidak menular yang lebih rendah (seperti diabetes dan penyakit kardiovaskular), dan umur panjang.

Anak-anak yang sehat belajar lebih baik. Orang-orang dengan nutrisi yang cukup lebih produktif dan dapat menciptakan peluang untuk secara bertahap memutus siklus kemiskinan dan kelaparan.

Malnutrisi, dalam segala bentuknya, menimbulkan ancaman signifikan bagi kesehatan manusia. Saat ini dunia menghadapi beban ganda malnutrisi yang meliputi kekurangan gizi dan kelebihan berat badan, terutama di negara-negara berpenghasilan rendah dan menengah. Terdapat berbagai bentuk malnutrisi, termasuk kekurangan gizi (kurus kering atau kerdil), kekurangan vitamin atau mineral, kelebihan berat badan, obesitas, dan penyakit tidak menular yang diakibatkan oleh pola makan.

Dampak perkembangan, ekonomi, sosial, dan medis dari beban kekurangan gizi global sangat serius dan berlangsung lama bagi individu dan keluarga mereka, bagi komunitas, dan bagi negara.''',
    ),
    Artikel(
      judul: "Apa itu Stunting?",
      imagePath: "Asset/menuartikel/stunting.png",
      isi:
          '''Stunting adalah gangguan pertumbuhan dan perkembangan yang dialami anak-anak akibat gizi buruk, infeksi berulang, dan kurangnya stimulasi psikososial. Anak-anak didefinisikan sebagai mengalami stunting jika tinggi badan menurut usia mereka lebih dari dua standar deviasi di bawah median Standar Pertumbuhan Anak WHO.

Pertumbuhan terhambat di awal kehidupan—terutama dalam 1000 hari pertama sejak konsepsi hingga usia dua tahun—memiliki konsekuensi fungsional yang merugikan bagi anak. Beberapa konsekuensi tersebut meliputi kemampuan kognitif dan prestasi pendidikan yang buruk, upah dewasa yang rendah, hilangnya produktivitas, dan, jika disertai dengan peningkatan berat badan yang berlebihan di kemudian hari pada masa kanak-kanak, peningkatan risiko penyakit kronis terkait nutrisi di masa dewasa.

Pertumbuhan linier pada masa kanak-kanak awal merupakan penanda kuat pertumbuhan yang sehat mengingat hubungannya dengan risiko morbiditas dan mortalitas, penyakit tidak menular di kemudian hari, serta kapasitas belajar dan produktivitas. Pertumbuhan ini juga terkait erat dengan perkembangan anak dalam beberapa bidang, termasuk kemampuan kognitif, bahasa, dan sensorimotor.''',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 2. FUNGSI LOAD DATA DENGAN DEKRIPSI
  void _loadUserData() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && mounted) {
      setState(() {
        // AMBIL DATA MENTAH
        String rawName = user.userMetadata?['full_name'] ?? "";

        // PROSES DEKRIPSI
        // Jika rawName ada isinya, kita decrypt.
        // Jika kosong, kita ambil dari email atau default "User"
        _userName = rawName.isNotEmpty
            ? SecurityService.decryptAES(rawName)
            : (user.email?.split('@')[0] ?? "User");

        _avatarPath = user.userMetadata?['avatar_path'] ?? 'Asset/login.png';
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildSectionDivider(), // Garis pembatas

              _buildWelcomeSection(),
              _buildSectionDivider(), // Garis pembatas

              const SizedBox(height: 10),
              _buildMenuGrid(context),
              const SizedBox(height: 20),

              _buildArticleSection(), // Bagian Artikel (Background Teal)
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // --- WIDGET GARIS PEMBATAS ---
  Widget _buildSectionDivider() {
    return Divider(
      thickness: 1,
      color: Colors.grey[200],
      indent: 20,
      endIndent: 20,
    );
  }

  // --- 1. HEADER SECTION ---
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.search, color: Colors.black54),
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            ).then((_) => _loadUserData()),
            child: Row(
              children: [
                Text(
                  _userName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 18,
                  backgroundImage: AssetImage(_avatarPath),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. WELCOME SECTION ---
  Widget _buildWelcomeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  "Selamat Datang di Pelita!",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF26D0D9),
                  ),
                ),
              ),
              Image.asset("Asset/Logo/logo.png", height: 60),
            ],
          ),
          const SizedBox(height: 5),
          const Text(
            "Apa yang anda butuhkan?",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // --- 3. MENU GRID (HANYA GAMBAR) ---
  Widget _buildMenuGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _menuItem(
            "Asset/menuutama/status.png",
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const KalkulatorGiziScreen(),
              ),
            ),
          ),
          _menuItem("Asset/menuutama/riwayat.png", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RiwayatScreen()),
            );
          }),
          _menuItem(
            "Asset/menuutama/konsultasi.png",
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const KonsultasiScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(String imagePath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 100,
        height: 100,
        child: Image.asset(imagePath, fit: BoxFit.contain),
      ),
    );
  }

  // --- 4. ARTICLE SECTION (SLIDER FIX) ---
  Widget _buildArticleSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 25),
      decoration: BoxDecoration(color: primaryColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Tentang Gizi",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.arrow_circle_right_outlined,
                    size: 35,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    if (_pageController.hasClients) {
                      int nextPage = (_pageController.page?.round() ?? 0) + 1;
                      if (nextPage >= daftarArtikel.length) nextPage = 0;
                      _pageController.animateToPage(
                        nextPage,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _dots(Colors.white),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _pageController,
              itemCount: daftarArtikel.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final art = daftarArtikel[index];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailArtikelScreen(artikel: art),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      image: DecorationImage(
                        image: AssetImage(art.imagePath),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      alignment: Alignment.bottomLeft,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                      child: Text(
                        art.judul,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _dots(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 15,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 4),
        const CircleAvatar(radius: 2, backgroundColor: Colors.white70),
        const SizedBox(width: 4),
        const CircleAvatar(radius: 2, backgroundColor: Colors.white70),
      ],
    );
  }

  // --- 5. BOTTOM NAVIGATION BAR (DIRECT NAVIGATOR) ---
  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const KalkulatorGiziScreen(),
            ),
          );
        } else if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RiwayatScreen(),
            ),
          );
        } else if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const KonsultasiScreen()),
          );
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Beranda"),
        BottomNavigationBarItem(icon: Icon(Icons.assignment), label: "Status"),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: "Riwayat"),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Konsultasi"),
      ],
    );
  }
}
