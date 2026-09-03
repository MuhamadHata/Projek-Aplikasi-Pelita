import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';

class SecurityService {
  // --- BAGIAN 1: KRIPTOGRAFI (AES) ---
  
  // Kunci Rahasia (Harus 32 karakter fix)
  static final _key = encrypt.Key.fromUtf8('KunciRahasiaPelitaUntukSkripsiOk'); 
  static final _iv = encrypt.IV.fromLength(16);
  static final _encrypter = encrypt.Encrypter(encrypt.AES(_key));

  // Fungsi Enkripsi (Teks Biasa -> Teks Acak)
  static String encryptAES(String plainText) {
    try {
      return _encrypter.encrypt(plainText, iv: _iv).base64;
    } catch (e) {
      return plainText; // Jika error, kembalikan teks asli (fail-safe)
    }
  }

  // Fungsi Dekripsi (Teks Acak -> Teks Biasa)
  static String decryptAES(String encryptedText) {
    try {
      return _encrypter.decrypt64(encryptedText, iv: _iv);
    } catch (e) {
      return encryptedText; // Jika bukan teks terenkripsi, kembalikan aslinya
    }
  }

  // --- BAGIAN 2: STEGANOGRAFI (LSB Sederhana) ---
  
  // Menyisipkan pesan ke gambar
  static Future<List<int>?> hideMessageInImage(File imageFile, String message) async {
    try {
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) return null;

      // Ubah ukuran gambar agar proses cepat (PENTING UNTUK HP KENTANG)
      if (image.width > 800) {
        image = img.copyResize(image, width: 800);
      }

      // Encode pesan ke biner + terminator karakter (biar tau kapan stop)
      message += "0"; 
      List<int> binaryMsg = [];
      for (var code in message.runes) {
        for (int i = 0; i < 8; i++) {
          binaryMsg.add((code >> i) & 1);
        }
      }

      int msgIndex = 0;
      
      // Loop pixel gambar
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          if (msgIndex < binaryMsg.length) {
            img.Pixel pixel = image.getPixel(x, y);
            
            // Ambil komponen biru (Blue) dan ubah bit terakhirnya
            int b = pixel.b.toInt();
            // Logika LSB: Kosongkan bit terakhir, lalu isi dengan bit pesan
            b = (b & 0xFE) | binaryMsg[msgIndex];
            
            // Simpan pixel baru
            image.setPixel(x, y, img.ColorRgba8(pixel.r.toInt(), pixel.g.toInt(), b, pixel.a.toInt()));
            msgIndex++;
          } else {
            break;
          }
        }
      }
      
      return img.encodePng(image); // Harus PNG agar tidak rusak kompresi
    } catch (e) {
      debugPrint("Error Stego: $e");
      return null;
    }
  }
}