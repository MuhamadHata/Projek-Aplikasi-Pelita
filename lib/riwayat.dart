import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'detail_hasil_screen.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final supabase = Supabase.instance.client;

  // Mengambil data riwayat
  Future<List<Map<String, dynamic>>> _fetchRiwayat() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final response = await supabase
        .from('history_gizi')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // FIX: Fungsi Hapus yang lebih kuat
  Future<void> _deleteData(int id) async {
    try {
      // Menggunakan .eq() biasanya lebih stabil daripada .match()
      await supabase.from('history_gizi').delete().eq('id', id);

      // Refresh data di UI
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Data riwayat berhasil dihapus"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error saat menghapus: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal menghapus: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper untuk menentukan warna berdasarkan status gizi
  Color _getStatusColor(double imt) {
    if (imt < 18.5) return Colors.orange; // Kurus
    if (imt < 23) return const Color(0xFF26D0D9); // Normal (Cyan)
    if (imt < 25) return Colors.deepOrangeAccent; // Kelebihan
    return Colors.red; // Obesitas
  }

  String _getStatus(double imt) {
    if (imt < 18.5) return "Kurus";
    if (imt < 23) return "Normal";
    if (imt < 25) return "Kelebihan";
    return "Obesitas";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: const Text(
          "Riwayat Analisis",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF26D0D9),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchRiwayat(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Gagal memuat riwayat gizi"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "Belum ada riwayat.\nSilakan hitung gizi Anda.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final listRiwayat = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: listRiwayat.length,
            itemBuilder: (context, index) {
              final item = listRiwayat[index];
              double tinggi = (item['tinggi'] as num).toDouble();
              double berat = (item['berat'] as num).toDouble();
              double imt = berat / ((tinggi / 100) * (tinggi / 100));

              DateTime dt = DateTime.parse(item['created_at']).toLocal();
              String formatWaktu = DateFormat('dd MMM yyyy • HH:mm').format(dt);

              // Ambil warna status
              Color statusColor = _getStatusColor(imt);

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailHasilScreen(
                          tipeHasil: "kesimpulan",
                          dataRiwayat: item,
                        ),
                      ),
                    );
                  },
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.assignment_outlined, color: statusColor),
                  ),
                  title: Text(
                    formatWaktu,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "IMT: ${imt.toStringAsFixed(1)} (${_getStatus(imt)})",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: statusColor, // Warna teks dinamis
                          ),
                        ),
                        Text(
                          "${berat.toStringAsFixed(1)} kg | ${tinggi.toStringAsFixed(0)} cm",
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    onPressed: () => _showConfirmDialog(item['id']),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showConfirmDialog(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Riwayat?"),
        content: const Text("Data ini akan hilang permanen dari database."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteData(id);
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
