import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt_package;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_saver/file_saver.dart';
import 'package:gal/gal.dart';
import 'security_service.dart';

class StegoScreen extends StatefulWidget {
  const StegoScreen({super.key});

  @override
  State<StegoScreen> createState() => _StegoScreenState();
}

class _StegoScreenState extends State<StegoScreen> {
  int _currentTabIndex = 0; // 0 untuk Enkripsi, 1 untuk Dekripsi
  bool _isLoading = false;

  // State untuk Enkripsi
  Uint8List? _processedImageBytes;
  final TextEditingController _messageController = TextEditingController();

  // State untuk Dekripsi
  String _decodedResult = "";

  final String _internalKey = "PELITA_SECRET_KEY_2024_PROTECTION";

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // ================= LOGIKA AES & STEGANO (SAMA SEPERTI SEBELUMNYA) =================

  String _encryptAES(String plainText) {
    final key = encrypt_package.Key.fromUtf8(
        sha256.convert(utf8.encode(_internalKey)).toString().substring(0, 32));
    final iv = encrypt_package.IV.fromLength(16);
    final encrypter = encrypt_package.Encrypter(encrypt_package.AES(key));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return base64.encode(encrypted.bytes + iv.bytes);
  }

  String _decryptAES(String encryptedText) {
    try {
      final key = encrypt_package.Key.fromUtf8(sha256
          .convert(utf8.encode(_internalKey))
          .toString()
          .substring(0, 32));
      final cipherBytes = base64.decode(encryptedText);
      final iv =
          encrypt_package.IV(cipherBytes.sublist(cipherBytes.length - 16));
      final encryptedData = encrypt_package.Encrypted(
          cipherBytes.sublist(0, cipherBytes.length - 16));
      final encrypter = encrypt_package.Encrypter(encrypt_package.AES(key));
      return encrypter.decrypt(encryptedData, iv: iv);
    } catch (e) {
      return "Gagal dekripsi: Data tidak valid.";
    }
  }

  // ================= ACTION METHODS =================

  Future<void> _handleEncrypt() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || _messageController.text.isEmpty) return;

    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => _isLoading = true);

    try {
      final bytes = await pickedFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) throw "Gambar tidak didukung";

      String rawName = user.userMetadata?['full_name'] ?? "";
      String fullName =
          rawName.isNotEmpty ? SecurityService.decryptAES(rawName) : "User";

      Map<String, String> dataMap = {
        "Nama": fullName,
        "Email": user.email ?? "-",
        "Waktu enkripsi": DateTime.now().toString().substring(0, 19),
        "Pesan rahasia": _messageController.text,
      };

      String secretMsg = _encryptAES(jsonEncode(dataMap));
      var msgBytes = Uint8List.fromList(utf8.encode(secretMsg));
      var lenBytes = Uint8List(4)
        ..buffer.asByteData().setUint32(0, msgBytes.length, Endian.big);
      var allBytes = Uint8List.fromList([...lenBytes, ...msgBytes]);

      int byteIdx = 0, bitIdx = 0;
      for (var pixel in image) {
        if (byteIdx < allBytes.length) {
          int bit = (allBytes[byteIdx] >> bitIdx) & 1;
          pixel.setRgb(
              (bit == 1) ? (pixel.r.toInt() | 1) : (pixel.r.toInt() & ~1),
              pixel.g.toInt(),
              pixel.b.toInt());
          bitIdx++;
          if (bitIdx == 8) {
            bitIdx = 0;
            byteIdx++;
          }
        } else {
          break;
        }
      }

      final stegoBytes = Uint8List.fromList(img.encodePng(image));

      // Upload ke Supabase
      await Supabase.instance.client.storage.from('avatars').uploadBinary(
            'stego_files/stego_${user.id}_${DateTime.now().millisecondsSinceEpoch}.png',
            stegoBytes,
            fileOptions:
                const FileOptions(upsert: true, contentType: 'image/png'),
          );

      setState(() => _processedImageBytes = stegoBytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDecrypt() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      _isLoading = true;
      _decodedResult = "";
    });

    try {
      final bytes = await pickedFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) throw "Gambar tidak valid";

      Uint8List lenBuf = Uint8List(4);
      for (int i = 0; i < 32; i++) {
        int r = image.getPixelSafe(i % image.width, i ~/ image.width).r.toInt();
        if ((r & 1) != 0) lenBuf[i ~/ 8] |= (1 << (i % 8));
      }
      int msgLen = lenBuf.buffer.asByteData().getUint32(0, Endian.big);

      Uint8List msgBuf = Uint8List(msgLen);
      for (int i = 0; i < msgLen * 8; i++) {
        int idx = i + 32;
        int r =
            image.getPixelSafe(idx % image.width, idx ~/ image.width).r.toInt();
        if ((r & 1) != 0) msgBuf[i ~/ 8] |= (1 << (i % 8));
      }

      Map<String, dynamic> decodedMap =
          jsonDecode(_decryptAES(utf8.decode(msgBuf)));
      setState(() {
        _decodedResult = "Nama: ${decodedMap['Nama']}\n"
            "Email: ${decodedMap['Email']}\n"
            "Waktu enkripsi: ${decodedMap['Waktu enkripsi']}\n"
            "Pesan rahasia: ${decodedMap['Pesan rahasia']}";
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Data tidak ditemukan.")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ================= UI COMPONENTS =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title:
            Text(_currentTabIndex == 0 ? "Enkripsi Pesan" : "Dekripsi Pesan"),
        backgroundColor: const Color(0xFF26C6DA),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentTabIndex == 0
              ? _buildEncryptView()
              : _buildDecryptView(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) => setState(() {
          _currentTabIndex = index;
          // Reset data saat pindah tab agar bersih
          _processedImageBytes = null;
          _decodedResult = "";
          _messageController.clear();
        }),
        selectedItemColor: const Color(0xFF26C6DA),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.lock), label: "Enkripsi"),
          BottomNavigationBarItem(
              icon: Icon(Icons.lock_open), label: "Dekripsi"),
        ],
      ),
    );
  }

  // Tampilan khusus Enkripsi
  Widget _buildEncryptView() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_processedImageBytes == null) ...[
          const Text("Langkah 1: Masukkan Pesan",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            controller: _messageController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Tulis pesan rahasia di sini...",
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 20),
          const Text("Langkah 2: Pilih Gambar",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _actionBtn("Pilih Foto & Enkripsi", Icons.add_a_photo, Colors.teal,
              _handleEncrypt),
        ] else ...[
          // Jika sudah berhasil Enkripsi
          const Center(
              child: Icon(Icons.check_circle, color: Colors.green, size: 80)),
          const SizedBox(height: 10),
          const Center(
              child: Text("Enkripsi Berhasil!",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.memory(_processedImageBytes!,
                height: 200, fit: BoxFit.cover),
          ),
          const SizedBox(height: 20),
          _actionBtn("Download Hasil Enkripsi", Icons.download, Colors.blue,
              _downloadEncryptedFile),
          TextButton(
              onPressed: () => setState(() => _processedImageBytes = null),
              child: const Text("Buat Baru Lagi")),
        ],
      ],
    );
  }

  // Tampilan khusus Dekripsi
  Widget _buildDecryptView() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
            "Upload foto yang berisi pesan rahasia untuk melihat isinya.",
            textAlign: TextAlign.center),
        const SizedBox(height: 30),
        _actionBtn("Upload Foto untuk Dekripsi", Icons.image_search,
            Colors.orange, _handleDecrypt),
        if (_decodedResult.isNotEmpty) ...[
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.blueGrey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blueGrey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("DATA DITEMUKAN:",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const Divider(),
                Text(_decodedResult, style: const TextStyle(height: 1.6)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _downloadEncryptedFile() async {
    try {
      if (kIsWeb) {
        await FileSaver.instance.saveFile(
            name: "stego_img",
            bytes: _processedImageBytes,
            ext: "png",
            mimeType: MimeType.png);
      } else {
        await Gal.putImageBytes(_processedImageBytes!);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Berhasil simpan ke Galeri!")));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Gagal download: $e")));
    }
  }

  Widget _actionBtn(
      String label, IconData icon, Color color, VoidCallback action) {
    return ElevatedButton.icon(
      onPressed: action,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
          backgroundColor: color,
          minimumSize: const Size(double.infinity, 55),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
  }
}
