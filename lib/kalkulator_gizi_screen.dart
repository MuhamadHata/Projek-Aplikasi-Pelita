import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'hasil_perhitungan_screen.dart';

class KalkulatorGiziScreen extends StatefulWidget {
  const KalkulatorGiziScreen({super.key});

  @override
  State<KalkulatorGiziScreen> createState() => _KalkulatorGiziScreenState();
}

class _KalkulatorGiziScreenState extends State<KalkulatorGiziScreen> {
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();
  String? _selectedGender = "Laki - laki";

  final Color primaryCyan = const Color(0xFF26D0D9);

  @override
  void initState() {
    super.initState();
    _ambilDanHitungUmur();
  }

  // --- FUNGSI BARU: AMBIL DOB & HITUNG UMUR ---
  void _ambilDanHitungUmur() {
    final user = Supabase.instance.client.auth.currentUser;
    final dobString = user?.userMetadata?['dob']; // Format: YYYY-MM-DD

    if (dobString != null && dobString.isNotEmpty) {
      try {
        DateTime birthDate = DateTime.parse(dobString);
        DateTime today = DateTime.now();

        int age = today.year - birthDate.year;

        // Cek jika belum ulang tahun di tahun ini
        if (today.month < birthDate.month ||
            (today.month == birthDate.month && today.day < birthDate.day)) {
          age--;
        }

        setState(() {
          _ageController.text = age.toString();
        });
      } catch (e) {
        debugPrint("Error parsing date: $e");
      }
    }
  }

  void _validasiInput() {
    if (_heightController.text.isEmpty ||
        _weightController.text.isEmpty ||
        _ageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Semua data wajib diisi!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    int? umur = int.tryParse(_ageController.text);

    if (umur == null || umur < 1 || umur > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Aplikasi ini khusus untuk Balita usia 1 - 5 tahun."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _showKonfirmasi();
  }

  void _showKonfirmasi() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 80,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              const Text(
                "Konfirmasi",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "apakah data yang anda masukkan sudah benar?",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        "Periksa lagi",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _simpanData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryCyan,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Ya, benar",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _simpanData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('history_gizi').insert({
        'user_id': user.id,
        'tinggi': double.parse(_heightController.text),
        'berat': double.parse(_weightController.text),
        'umur': int.parse(_ageController.text),
        'jenis_kelamin': _selectedGender,
      });

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const HasilPerhitunganScreen(),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Gagal menyimpan data: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Cek Status Gizi",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryCyan,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildInputLabel(
                    "Tinggi Badan (cm)",
                    _heightController,
                    "Contoh: 100",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInputLabel(
                    "Berat Badan (kg)",
                    _weightController,
                    "Contoh: 15",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDropdownLabel("Jenis Kelamin"),
            const SizedBox(height: 24),

            // KOLOM UMUR SEKARANG READ ONLY
            _buildInputLabel(
              "Usia (tahun)",
              _ageController,
              "Otomatis dari profil",
              isReadOnly: true, // Parameter baru
            ),

            const SizedBox(height: 10),
            const Text(
              "* Usia dihitung otomatis berdasarkan tanggal lahir Anda.",
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic),
            ),

            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryCyan,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: _validasiInput,
              child: const Text(
                "Hitung Status Gizi",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(
    String label,
    TextEditingController controller,
    String hint, {
    bool isReadOnly = false, // Tambah parameter ini
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            children: const [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: isReadOnly, // Terapkan disini
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: isReadOnly
                ? Colors.grey[200]
                : Colors.grey[100], // Warna beda jika read-only
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownLabel(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            children: const [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedGender,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.black54,
              ),
              items: [
                "Laki - laki",
                "Perempuan",
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _selectedGender = v),
            ),
          ),
        ),
      ],
    );
  }
}
