import 'package:flutter/material.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Data konten onboarding sesuai gambar
  final List<Map<String, String>> _onboardingData = [
    {
      "title": "Perhitungan Gizi",
      "desc":
          "Mengetahui Indeks Massa Tubuh (IMT) serta kebutuhan gizi harian secara mudah, cepat, dan akurat.",
      "icon": "Asset/onboarding/onboarding1.png",
    },
    {
      "title": "Cek Status Gizi",
      "desc":
          "Membantu mengetahui status gizi Anda berdasarkan hasil perhitungan, sehingga dapat memantau kondisi tubuh dengan lebih baik.",
      "icon": "Asset/onboarding/onboarding2.png",
    },
    {
      "title": "Cek Riwayat",
      "desc":
          "Melihat riwayat hasil perhitungan gizi sebelumnya untuk memantau perubahan dan perkembangan kondisi tubuh dari waktu ke waktu.",
      "icon": "Asset/onboarding/onboarding3.png",
    },
  ];

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF26D0D9);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Tombol Skip di pojok kanan atas
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Skip ",
                      style: TextStyle(color: primaryColor, fontSize: 16),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: primaryColor,
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) => SingleChildScrollView(
                  // 1. TAMBAHKAN INI agar konten bisa di-scroll jika kepanjangan
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40.0,
                      vertical: 20.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 2. Gunakan LayoutBuilder atau ukuran yang lebih kecil untuk gambar
                        Container(
                          height: MediaQuery.of(context).size.height *
                              0.3, // Ukuran 30% dari tinggi layar
                          width: MediaQuery.of(context).size.height * 0.3,
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            index == 0
                                ? Icons.add_moderator
                                : (index == 1
                                    ? Icons.assignment
                                    : Icons.history),
                            size: MediaQuery.of(context).size.height *
                                0.15, // Icon menyesuaikan layar
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 30), // Perkecil jarak
                        Text(
                          _onboardingData[index]["title"]!,
                          style: const TextStyle(
                            fontSize:
                                24, // Sedikit perkecil font jika masih overflow
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          _onboardingData[index]["desc"]!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Indikator Titik (Dots)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _onboardingData.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(right: 8),
                  height: 10,
                  width: _currentPage == index ? 25 : 10,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? primaryColor
                        : primaryColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Tombol Berikutnya / Mulai
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _onboardingData.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.ease,
                      );
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    _currentPage == _onboardingData.length - 1
                        ? "Mulai"
                        : "Berikutnya",
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
