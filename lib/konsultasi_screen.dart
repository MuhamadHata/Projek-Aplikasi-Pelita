import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'api_config.dart';

class KonsultasiScreen extends StatefulWidget {
  const KonsultasiScreen({super.key});

  @override
  State<KonsultasiScreen> createState() => _KonsultasiScreenState();
}

class _KonsultasiScreenState extends State<KonsultasiScreen> {
  final Color primaryColor = const Color(0xFF26D0D9);
  final Color secondaryColor = const Color(0xFF00ACC1);

  String _geminiApiKey = "";

  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  GenerativeModel? _model;
  ChatSession? _chatSession;

  // Data riwayat gizi terakhir user
  String _riwayatContext = "";

  // Manajemen Riwayat Sesi Konsultasi
  List<Map<String, dynamic>> _savedSessions = [];
  String? _currentSessionId;
  String _currentSessionTitle = "";

  @override
  void initState() {
    super.initState();
    _initInitialMessage();
    _loadAndInitGemini();
    _loadSavedSessions();
  }

  void _initInitialMessage() {
    _messages.clear();
    _messages.add({
      "role": "bot",
      "text":
          "Halo! Saya asisten gizi Pelita 👋\nAda yang bisa saya bantu hari ini?",
      "time": DateFormat('HH:mm').format(DateTime.now()),
    });
  }

  Future<void> _loadAndInitGemini() async {
    // 1. Ambil riwayat gizi terakhir dari Supabase
    await _fetchLatestRiwayat();

    // 2. Load API Key dari konfigurasi internal
    if (ApiConfig.defaultGeminiApiKey.trim().isNotEmpty) {
      _geminiApiKey = ApiConfig.defaultGeminiApiKey.trim();
      _initGemini(_geminiApiKey);
    }
  }

  /// Mengambil riwayat gizi terakhir user dari Supabase
  Future<void> _fetchLatestRiwayat() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('history_gizi')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(5);

      final List<Map<String, dynamic>> data =
          List<Map<String, dynamic>>.from(response);

      if (data.isEmpty) {
        _riwayatContext =
            "User belum pernah melakukan pengecekan status gizi.";
        return;
      }

      // Format data riwayat menjadi teks konteks
      StringBuffer sb = StringBuffer();
      sb.writeln("Berikut adalah riwayat pengecekan gizi terakhir user:");

      for (int i = 0; i < data.length; i++) {
        final item = data[i];
        double tinggi = (item['tinggi'] as num).toDouble();
        double berat = (item['berat'] as num).toDouble();
        int umur = (item['umur'] as num).toInt();
        String jk = item['jenis_kelamin'] ?? "-";
        String waktu = item['created_at'] ?? "-";

        // Hitung IMT
        double imt = berat / ((tinggi / 100) * (tinggi / 100));
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

        // Hitung BBI
        double bbi = (umur * 2) + 8;

        // Hitung Kebutuhan Energi
        double energiPerKg = umur <= 3 ? 95 : 85;
        double energi = berat * energiPerKg;

        try {
          DateTime dt = DateTime.parse(waktu).toLocal();
          waktu = DateFormat('dd MMM yyyy, HH:mm').format(dt);
        } catch (_) {}

        sb.writeln(
          "\n--- Riwayat ${i + 1} (${i == 0 ? 'Terakhir' : 'Sebelumnya'}) ---"
          "\nWaktu: $waktu"
          "\nJenis Kelamin: $jk"
          "\nUsia: $umur tahun"
          "\nTinggi Badan: ${tinggi.toStringAsFixed(1)} cm"
          "\nBerat Badan: ${berat.toStringAsFixed(1)} kg"
          "\nIMT: ${imt.toStringAsFixed(1)} ($statusIMT)"
          "\nBerat Badan Ideal: ${bbi.toStringAsFixed(1)} kg"
          "\nKebutuhan Energi: ${energi.toStringAsFixed(0)} kkal/hari",
        );
      }

      _riwayatContext = sb.toString();
    } catch (e) {
      debugPrint("Error fetch riwayat untuk chatbot: $e");
      _riwayatContext = "Gagal mengambil data riwayat gizi user.";
    }
  }

  void _initGemini(String apiKey, {List<Content>? initialHistory}) {
    try {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        systemInstruction: Content.system(
          "Kamu adalah ahli gizi profesional khusus balita (usia 1-5 tahun) pada aplikasi Pelita. "
          "ATURAN KETAT yang WAJIB dipatuhi:\n"
          "1. Kamu HANYA boleh menjawab pertanyaan seputar gizi, nutrisi, makanan, tumbuh kembang, dan kesehatan balita.\n"
          "2. Jika user bertanya di luar topik gizi dan kesehatan balita (misalnya matematika, teknologi, hiburan, politik, dll), "
          "TOLAK dengan sopan. Contoh: 'Maaf, saya hanya bisa membantu seputar gizi dan kesehatan balita ya 😊'\n"
          "3. Jawab dengan ramah, santun, dan empati. Gunakan bahasa Indonesia sederhana yang mudah dipahami orang tua balita.\n"
          "4. Jangan gunakan simbol markdown rumit. Maksimal 2-3 paragraf pendek.\n"
          "5. Jika user bertanya tentang hasil perhitungan atau riwayat gizinya, gunakan data riwayat di bawah ini sebagai referensi.\n\n"
          "--- DATA RIWAYAT GIZI USER ---\n"
          "$_riwayatContext\n"
          "--- AKHIR DATA RIWAYAT ---\n\n"
          "Gunakan data di atas untuk memberikan jawaban yang personal dan relevan. "
          "Misalnya jika user bertanya 'bagaimana status gizi anak saya?', jawab berdasarkan data IMT terakhir. "
          "Jika user bertanya soal rekomendasi makanan, sesuaikan dengan kebutuhan energi dan status gizi dari data.",
        ),
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 500,
        ),
      );

      _chatSession = _model?.startChat(history: initialHistory);
    } catch (e) {
      debugPrint("Error inisialisasi Gemini: $e");
    }
  }

  // --- MANAJEMEN RIWAYAT SESI CHAT ---

  String _getStorageKey() {
    final user = Supabase.instance.client.auth.currentUser;
    final uid = user?.id ?? 'guest';
    return 'konsultasi_chat_sessions_$uid';
  }

  Future<void> _loadSavedSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_getStorageKey());
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw);
        setState(() {
          _savedSessions =
              decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      }
    } catch (e) {
      debugPrint("Error load saved sessions: $e");
    }
  }

  Future<void> _saveCurrentSession() async {
    final userMessages = _messages.where((m) => m['role'] == 'user').toList();
    if (userMessages.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentSessionId == null) {
        _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
        final firstMsg =
            userMessages.first['text'] as String? ?? 'Konsultasi Gizi';
        _currentSessionTitle = firstMsg.length > 40
            ? '${firstMsg.substring(0, 40)}...'
            : firstMsg;
      }

      final nowFormatted =
          DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());

      final sessionData = {
        'id': _currentSessionId,
        'title': _currentSessionTitle,
        'date': nowFormatted,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'messages': _messages,
      };

      final index =
          _savedSessions.indexWhere((s) => s['id'] == _currentSessionId);
      if (index != -1) {
        _savedSessions[index] = sessionData;
      } else {
        _savedSessions.insert(0, sessionData);
      }

      if (_savedSessions.length > 50) {
        _savedSessions = _savedSessions.sublist(0, 50);
      }

      await prefs.setString(_getStorageKey(), jsonEncode(_savedSessions));
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Error saving session: $e");
    }
  }

  void _startNewChat() {
    setState(() {
      _currentSessionId = null;
      _currentSessionTitle = "";
      _chatController.clear();
      _initInitialMessage();
    });

    if (_geminiApiKey.isNotEmpty) {
      _initGemini(_geminiApiKey);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Memulai sesi konsultasi baru"),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _openSession(Map<String, dynamic> session) {
    setState(() {
      _currentSessionId = session['id'];
      _currentSessionTitle = session['title'] ?? 'Konsultasi Gizi';
      final rawMsgs = session['messages'] as List<dynamic>? ?? [];
      _messages.clear();
      for (var m in rawMsgs) {
        _messages.add(Map<String, dynamic>.from(m));
      }
    });

    // Reconstruct Gemini history for continuity
    if (_geminiApiKey.isNotEmpty) {
      List<Content> history = [];
      for (var msg in _messages) {
        if (msg['isError'] == true) continue;
        if (msg['role'] == 'user') {
          history.add(Content.text(msg['text'] ?? ''));
        } else if (msg['role'] == 'bot' && msg['text'] != null) {
          if (msg['text'] !=
              "Halo! Saya asisten gizi Pelita 👋\nAda yang bisa saya bantu hari ini?") {
            history.add(Content.model([TextPart(msg['text'])]));
          }
        }
      }
      _initGemini(_geminiApiKey, initialHistory: history.isNotEmpty ? history : null);
    }

    _scrollToBottom();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Membuka riwayat: ${_currentSessionTitle.isEmpty ? 'Konsultasi' : _currentSessionTitle}"),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteSession(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _savedSessions.removeWhere((s) => s['id'] == sessionId);
        if (_currentSessionId == sessionId) {
          _startNewChat();
        }
      });
      await prefs.setString(_getStorageKey(), jsonEncode(_savedSessions));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Riwayat konsultasi berhasil dihapus"),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error deleting session: $e");
    }
  }

  Future<void> _clearAllHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _savedSessions.clear();
        _startNewChat();
      });
      await prefs.remove(_getStorageKey());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Semua riwayat konsultasi telah dihapus"),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error clearing all history: $e");
    }
  }

  void _showHistoryBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.history_rounded, color: primaryColor, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Riwayat Konsultasi",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        if (_savedSessions.isNotEmpty)
                          TextButton.icon(
                            onPressed: () {
                              _confirmClearAllDialog(ctx);
                            },
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            label: const Text(
                              "Hapus Semua",
                              style: TextStyle(color: Colors.red, fontSize: 13),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // History list / Empty state
                  Expanded(
                    child: _savedSessions.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 64,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    "Belum Ada Riwayat Konsultasi",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Pertanyaan dan konsultasi Anda dengan asisten gizi akan tersimpan otomatis di sini.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: _savedSessions.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final session = _savedSessions[index];
                              final isCurrent = session['id'] == _currentSessionId;
                              final rawMsgs = session['messages'] as List<dynamic>? ?? [];
                              final msgCount = rawMsgs.length;

                              return InkWell(
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _openSession(session);
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? primaryColor.withValues(alpha: 0.08)
                                        : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isCurrent
                                          ? primaryColor
                                          : Colors.grey.shade200,
                                      width: isCurrent ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isCurrent
                                              ? primaryColor
                                              : Colors.grey.shade200,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.question_answer_rounded,
                                          color: isCurrent ? Colors.white : Colors.grey.shade700,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    session['title'] ?? 'Konsultasi Gizi',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: isCurrent
                                                          ? primaryColor
                                                          : Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                                if (isCurrent)
                                                  Container(
                                                    margin: const EdgeInsets.only(left: 6),
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: primaryColor,
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: const Text(
                                                      "Aktif",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(Icons.access_time_rounded, size: 13, color: Colors.grey.shade500),
                                                const SizedBox(width: 4),
                                                Text(
                                                  session['date'] ?? '-',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Icon(Icons.chat_outlined, size: 13, color: Colors.grey.shade500),
                                                const SizedBox(width: 4),
                                                Text(
                                                  "$msgCount pesan",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline, color: Colors.grey.shade400, size: 20),
                                        onPressed: () {
                                          _confirmDeleteDialog(
                                            ctx,
                                            session['id'],
                                            session['title'] ?? 'Konsultasi',
                                            () {
                                              setModalState(() {});
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // Bottom Action: New Chat
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _startNewChat();
                          },
                          icon: const Icon(Icons.add_rounded),
                          label: const Text(
                            "Mulai Konsultasi Baru",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteDialog(
    BuildContext modalCtx,
    String sessionId,
    String title,
    VoidCallback onDeleted,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Hapus Riwayat?"),
        content: Text(
          "Apakah Anda yakin ingin menghapus riwayat '$title'?",
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteSession(sessionId);
              onDeleted();
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }

  void _confirmClearAllDialog(BuildContext modalCtx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Hapus Semua Riwayat?"),
        content: const Text(
          "Semua riwayat konsultasi akan dihapus permanen. Tindakan ini tidak dapat dibatalkan.",
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(modalCtx);
              _clearAllHistory();
            },
            child: const Text("Hapus Semua"),
          ),
        ],
      ),
    );
  }

  // --- KIRIM PESAN & CHAT BOT ---

  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty || _isLoading) return;

    if (_geminiApiKey.isEmpty) {
      _showError(
        "Layanan konsultasi sedang tidak tersedia. Silakan coba lagi nanti.",
      );
      return;
    }

    setState(() {
      _messages.add({
        "role": "user",
        "text": text,
        "time": DateFormat('HH:mm').format(DateTime.now()),
      });
      _isLoading = true;
    });

    _chatController.clear();
    _scrollToBottom();

    try {
      if (_chatSession == null) {
        _initGemini(_geminiApiKey);
      }

      final response = await _chatSession?.sendMessage(Content.text(text));
      final reply = response?.text;

      if (reply != null && reply.trim().isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _messages.add({
            "role": "bot",
            "text": reply.trim(),
            "time": DateFormat('HH:mm').format(DateTime.now()),
          });
        });
      } else {
        _showError("AI tidak memberikan respon, silakan coba lagi.");
      }
    } catch (e) {
      debugPrint("Gemini error detail: $e");
      final errStr = e.toString();
      if (errStr.contains("leaked") ||
          errStr.contains("403") ||
          errStr.contains("PERMISSION_DENIED") ||
          errStr.contains("API_KEY_INVALID")) {
        _showError(
          "Layanan konsultasi sedang mengalami gangguan. Silakan coba lagi nanti.",
        );
      } else if (errStr.contains("429") ||
          errStr.contains("prepayment") ||
          errStr.contains("RESOURCE_EXHAUSTED")) {
        _showError(
          "Layanan konsultasi sedang sibuk. Silakan coba lagi dalam beberapa menit.",
        );
      } else {
        _showError(
          "Gagal terhubung ke layanan konsultasi. Periksa koneksi internet Anda dan coba lagi.",
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _saveCurrentSession();
      }
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String msg) {
    setState(() {
      _messages.add({
        "role": "bot",
        "text": msg,
        "time": DateFormat('HH:mm').format(DateTime.now()),
        "isError": true,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Konsultasi Gizi",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Tombol Riwayat Chat
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.history_rounded, color: Colors.white, size: 26),
                tooltip: "Riwayat Konsultasi",
                onPressed: _showHistoryBottomSheet,
              ),
              if (_savedSessions.isNotEmpty)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          // Tombol Chat Baru
          IconButton(
            icon: const Icon(Icons.add_comment_outlined, color: Colors.white, size: 24),
            tooltip: "Konsultasi Baru",
            onPressed: _startNewChat,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Banner jika sedang melihat riwayat
          if (_currentSessionTitle.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: primaryColor.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(Icons.history_edu_rounded, size: 18, color: primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Topik: $_currentSessionTitle",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _startNewChat,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        "Chat Baru",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: secondaryColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildChatBubble(_messages[index]);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text(
                "Pelita sedang mengetik...",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> msg) {
    final bool isUser = msg["role"] == "user";
    final bool isError = msg["isError"] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: isError
                  ? Colors.red.shade50
                  : (isUser ? const Color(0xFFE8F8FA) : Colors.white),
              border: isUser
                  ? null
                  : Border.all(
                      color: isError ? Colors.red : primaryColor,
                      width: 1.4,
                    ),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 0),
                bottomRight: Radius.circular(isUser ? 0 : 20),
              ),
            ),
            child: Text(
              msg["text"],
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: isError ? Colors.red.shade800 : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            msg["time"] ?? "",
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primaryColor, secondaryColor]),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    controller: _chatController,
                    textInputAction: TextInputAction.send,
                    decoration: const InputDecoration(
                      hintText: "Tanya seputar gizi...",
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 30),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
