import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class KonsultasiScreen extends StatefulWidget {
  const KonsultasiScreen({super.key});

  @override
  State<KonsultasiScreen> createState() => _KonsultasiScreenState();
}

class _KonsultasiScreenState extends State<KonsultasiScreen> {
  final Color primaryColor = const Color(0xFF26D0D9);
  final Color secondaryColor = const Color(0xFF00ACC1);

  // 🔑 API Key Google Gemini (Dimuat aman dari SharedPreferences / ApiConfig)
  String _geminiApiKey = "";

  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  GenerativeModel? _model;
  ChatSession? _chatSession;

  @override
  void initState() {
    super.initState();
    _messages.add({
      "role": "bot",
      "text":
          "Halo! Saya asisten gizi Pelita 👋\nAda yang bisa saya bantu hari ini?",
      "time": DateFormat('HH:mm').format(DateTime.now()),
    });

    _loadAndInitGemini();
  }

  Future<void> _loadAndInitGemini() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString('gemini_api_key');

    // Bersihkan jika key tersimpan kosong
    if (savedKey != null && savedKey.trim().isEmpty) {
      await prefs.remove('gemini_api_key');
    }

    final activeKey = prefs.getString('gemini_api_key');
    if (activeKey != null && activeKey.trim().isNotEmpty) {
      _geminiApiKey = activeKey.trim();
    } else if (ApiConfig.defaultGeminiApiKey.trim().isNotEmpty) {
      _geminiApiKey = ApiConfig.defaultGeminiApiKey.trim();
    }

    if (_geminiApiKey.isNotEmpty) {
      _initGemini(_geminiApiKey);
    }
  }

  void _initGemini(String apiKey) {
    try {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        systemInstruction: Content.system(
          "Kamu adalah ahli gizi profesional untuk balita pada aplikasi Pelita. "
          "Jawab dengan ramah, santun, dan empati tanpa menggunakan simbol markdown rumit seperti bullet list panjang atau heading tebal. "
          "Gunakan bahasa Indonesia sederhana yang mudah dipahami orang tua balita. Maksimal 2 paragraf pendek.",
        ),
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 350,
        ),
      );
      _chatSession = _model?.startChat();
    } catch (e) {
      debugPrint("Error inisialisasi Gemini: $e");
    }
  }

  void _showApiKeyDialog() {
    final keyController = TextEditingController(text: _geminiApiKey);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.key_rounded, color: primaryColor),
            const SizedBox(width: 8),
            const Text("Atur API Key Gemini", style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Masukkan Google Gemini API Key Anda. Kunci ini disimpan secara aman di perangkat Anda:",
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: keyController,
              decoration: InputDecoration(
                hintText: "Tempel API Key di sini...",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "💡 Dapatkan API Key gratis di:\naistudio.google.com/app/apikey",
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newKey = keyController.text.trim();
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('gemini_api_key', newKey);

              setState(() {
                _geminiApiKey = newKey;
              });

              if (newKey.isNotEmpty) {
                _initGemini(newKey);
              }

              if (ctx.mounted) Navigator.pop(ctx);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("API Key Gemini berhasil disimpan!"),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty || _isLoading) return;

    if (_geminiApiKey.isEmpty) {
      _showError(
        "API Key Gemini belum disetel. Silakan klik ikon kunci (🔑) di pojok kanan atas untuk memasukkan API Key baru Anda.",
      );
      _showApiKeyDialog();
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
      final errStr = e.toString();
      if (errStr.contains("leaked") ||
          errStr.contains("403") ||
          errStr.contains("PERMISSION_DENIED") ||
          errStr.contains("API_KEY_INVALID")) {
        _showError(
          "Kunci API Gemini terblokir atau dilaporkan bocor oleh Google (Error 403).\n\n"
          "Solusi Cepat:\n"
          "1. Buka https://aistudio.google.com/app/apikey\n"
          "2. Klik 'Create API key' (Gratis)\n"
          "3. Klik ikon kunci (🔑) di kanan atas layar ini lalu tempel kunci baru.",
        );
      } else {
        _showError("Gagal menghubungi Gemini AI: $e");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          IconButton(
            icon: const Icon(Icons.key_rounded, color: Colors.white),
            tooltip: "Atur API Key Gemini",
            onPressed: _showApiKeyDialog,
          ),
        ],
      ),
      body: Column(
        children: [
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
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
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
            msg["time"],
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
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 30),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
