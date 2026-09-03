import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DetailHasilScreen extends StatelessWidget {
  final String tipeHasil;
  final Map<String, dynamic>? dataRiwayat;

  const DetailHasilScreen({
    super.key,
    required this.tipeHasil,
    this.dataRiwayat,
  });

  final Color primaryCyan = const Color(0xFF26D0D9);

  Future<Map<String, dynamic>> _fetchData() async {
    if (dataRiwayat != null) return dataRiwayat!;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception("User belum login");
    }

    return await Supabase.instance.client
        .from('history_gizi')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(1)
        .single();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _getTitle(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryCyan,
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Data tidak ditemukan"));
          }
          return _buildSpecificUI(snapshot.data!);
        },
      ),
    );
  }

  String _getTitle() {
    switch (tipeHasil) {
      case "imt":
        return "IMT Anak";
      case "bbi":
        return "Berat Badan Ideal";
      case "energi":
        return "Kebutuhan Energi";
      case "kesimpulan":
        return "Kesimpulan Gizi";
      default:
        return "Detail Analisis";
    }
  }

  Widget _buildSpecificUI(Map data) {
    double tb = (data['tinggi'] as num).toDouble(); // cm
    double bb = (data['berat'] as num).toDouble(); // kg
    int umur = (data['umur'] as num).toInt(); // tahun

    // ===============================
    // 1. IMT ANAK (WHO – IMT/U)
    // ===============================
    double imt = bb / ((tb / 100) * (tb / 100));

    String statusIMT;
    if (imt < 14) {
      statusIMT = "Gizi Kurang";
    } else if (imt < 18) {
      statusIMT = "Gizi Normal";
    } else if (imt < 20) {
      statusIMT = "Gizi Lebih";
    } else {
      statusIMT = "Obesitas";
    }

    // ===============================
    // 2. BBI (WHO – BB/U)
    // ===============================
    double bbi = (umur * 2) + 8;

    // ===============================
    // 3. KEBUTUHAN ENERGI (WHO / FAO)
    // ===============================
    double energiPerKg = umur <= 3 ? 95 : 85;
    double energi = bb * energiPerKg;

    double protein = (energi * 0.15) / 4;
    double lemak = (energi * 0.30) / 9;
    double karbo = (energi * 0.55) / 4;

    // ===============================
    // 4. KESIMPULAN
    // ===============================
    String kesimpulanBB;
    if (bb < bbi * 0.9) {
      kesimpulanBB = "berat badan kurang dari ideal";
    } else if (bb <= bbi * 1.1) {
      kesimpulanBB = "berat badan sesuai ideal";
    } else {
      kesimpulanBB = "berat badan melebihi ideal";
    }

    // ===============================
    // OUTPUT UI
    // ===============================
    if (tipeHasil == "imt") {
      return _pageLayout(
        "Indeks Massa Tubuh Anak (IMT/U)",
        imt.toStringAsFixed(1),
        statusIMT,
        "Indeks Massa Tubuh (IMT) digunakan untuk menilai status gizi anak "
            "dengan membandingkan berat badan dan tinggi badan berdasarkan umur. "
            "Hasil ini mengacu pada standar pertumbuhan WHO (IMT menurut umur). "
            "Nilai IMT membantu mengidentifikasi apakah anak mengalami gizi kurang, "
            "gizi normal, gizi lebih, atau obesitas sehingga dapat dilakukan "
            "pemantauan dan intervensi gizi yang tepat sejak dini.",
      );
    }

    if (tipeHasil == "bbi") {
      return _pageLayout(
        "Berat Badan Ideal Anak",
        "${bbi.toStringAsFixed(1)} kg",
        "Berat Badan Ideal",
        "Berat Badan Ideal (BBI) merupakan perkiraan berat badan yang sesuai "
            "dengan umur anak berdasarkan referensi pertumbuhan WHO. "
            "Nilai ini digunakan sebagai acuan untuk menilai apakah berat badan anak "
            "sudah sesuai, kurang, atau berlebih dibandingkan dengan standar usianya. "
            "Pemantauan berat badan ideal penting untuk mendukung pertumbuhan "
            "dan perkembangan anak secara optimal.",
      );
    }

    if (tipeHasil == "energi") {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader("${energi.toStringAsFixed(0)} kkal"),
            const Text(
              "Kebutuhan energi harian merupakan jumlah energi yang dibutuhkan "
              "anak setiap hari untuk mendukung aktivitas fisik, metabolisme tubuh, "
              "serta proses pertumbuhan dan perkembangan. Perhitungan ini "
              "mengacu pada rekomendasi WHO/FAO berdasarkan umur dan berat badan.",
              style: TextStyle(fontSize: 15, height: 1.6, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            _row("Protein", "${protein.toStringAsFixed(0)} g"),
            _row("Lemak", "${lemak.toStringAsFixed(0)} g"),
            _row("Karbohidrat", "${karbo.toStringAsFixed(0)} g"),
            const SizedBox(height: 20),
            const Text(
              "Pembagian zat gizi makro ini bertujuan untuk memastikan "
              "asupan nutrisi seimbang. Protein berperan dalam pembentukan "
              "dan perbaikan jaringan tubuh, lemak sebagai sumber energi cadangan, "
              "serta karbohidrat sebagai sumber energi utama anak.",
              style: TextStyle(fontSize: 15, height: 1.6, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (tipeHasil == "kesimpulan") {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _cardInfo(
              "Status Gizi Anak",
              statusIMT,
              "Nilai IMT: ${imt.toStringAsFixed(1)}",
            ),
            const SizedBox(height: 24),
            Text(
              "Berdasarkan hasil analisis status gizi, anak berada pada kategori "
              "$statusIMT. Secara umum, kondisi ini menunjukkan bahwa "
              "$kesimpulanBB. Berat badan ideal anak pada usia $umur tahun "
              "diperkirakan sebesar ${bbi.toStringAsFixed(1)} kg.\n\n"
              "Selain itu, kebutuhan energi harian anak diperkirakan sekitar "
              "${energi.toStringAsFixed(0)} kkal per hari. Pemenuhan kebutuhan "
              "energi dan zat gizi yang seimbang sangat penting untuk mendukung "
              "pertumbuhan fisik, perkembangan kognitif, serta menjaga daya tahan "
              "tubuh anak.\n\n"
              "Disarankan untuk terus memantau pola makan, aktivitas fisik, "
              "dan pertumbuhan anak secara berkala agar status gizi tetap optimal.",
              textAlign: TextAlign.justify,
              style: const TextStyle(fontSize: 15, height: 1.7),
            ),
          ],
        ),
      );
    }

    return const Center(child: Text("Data tidak tersedia"));
  }

  Widget _buildHeader(String v) {
    return Column(
      children: [
        Text(v,
            style: TextStyle(
                fontSize: 42, fontWeight: FontWeight.bold, color: primaryCyan)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _row(String l, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: const TextStyle(fontSize: 16)),
          Text(v,
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: primaryCyan)),
        ],
      ),
    );
  }

  Widget _pageLayout(String l, String v, String s, String d) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l, style: const TextStyle(color: Colors.grey)),
            Text(v,
                style: TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    color: primaryCyan)),
            Text(s,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            Text(d,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _cardInfo(String t, String s, String v) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryCyan,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(t, style: const TextStyle(color: Colors.white70)),
          Text(s,
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Text(v, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
