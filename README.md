# 🕯️ Pelita - Aplikasi Pemantauan & Konsultasi Status Gizi Balita

<p align="center">
  <img src="Asset/Logo/logo.png" alt="Logo Pelita" width="140"/>
</p>

<p align="center">
  <strong>Solusi Cerdas Pemantauan Nutrisi, Deteksi Dini Stunting, dan Konsultasi Gizi Balita Berbasis AI</strong>
</p>

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.41-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.11-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"></a>
  <a href="https://supabase.com"><img src="https://img.shields.io/badge/Supabase-Database%20%26%20Auth-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" alt="Supabase"></a>
  <a href="https://ai.google.dev"><img src="https://img.shields.io/badge/Google%20Gemini-1.5%20Flash-4285F4?style=for-the-badge&logo=google&logoColor=white" alt="Gemini AI"></a>
  <a href="https://www.figma.com/design/FhsV4fWjx3VstlG7Kd2fjh/Pelita?node-id=2052-1969"><img src="https://img.shields.io/badge/Figma-UI%2FUX%20Design-F24E1E?style=for-the-badge&logo=figma&logoColor=white" alt="Figma"></a>
</p>

---

## 📖 Tentang Aplikasi
**Pelita** adalah aplikasi kesehatan *mobile* komprehensif yang dirancang untuk membantu para orang tua dan tenaga kesehatan dalam memantau tumbuh kembang dan status gizi balita. Dengan integrasi kecerdasan buatan (**Google Gemini 1.5 Flash**), sistem database *cloud* (**Supabase**), serta perlindungan data mutakhir (**AES-256 & Steganografi LSB**), Pelita hadir sebagai asisten gizi pribadi yang aman, akurat, dan mudah digunakan kapan saja.

---

## ✨ Fitur-Fitur Utama

### 1. 🤖 Konsultasi Gizi AI Interaktif (Google Gemini 1.5 Flash)
* **Asisten Virtual 24/7:** Berdiskusi dan konsultasi seputar pola makan anak, MPASI bergizi, menu harian, hingga tips penanganan anak susah makan (*Picky Eater*).
* **Jawaban Khusus & Ramah:** Dirancang dengan persona ahli gizi balita yang komunikatif, hangat, dan memberikan jawaban berbasis ilmu kesehatan yang mudah dipahami orang tua.
* **Tampilan Adaptif:** Antarmuka obrolan responsif terhadap tinggi layar, *safe area* navigasi sistem Android, dan penyesuaian otomatis saat keyboard virtual muncul.

### 2. 📊 Kalkulator Status Gizi & Antropometri Balita
* **Perhitungan Akurat:** Mengkalkulasi Indeks Massa Tubuh (IMT), Berat Badan Ideal (BBI), dan Kebutuhan Energi Harian berdasarkan tinggi badan, berat badan, umur, dan jenis kelamin balita.
* **Klasifikasi Status Gizi:** Menampilkan hasil evaluasi status gizi (Gizi Buruk, Gizi Kurang, Gizi Baik/Normal, Berisiko Gizi Lebih, Obesitas).
* **Rekomendasi Terarah:** Menyajikan saran tindakan medis dan nutrisi praktis sesuai hasil perhitungan balita.

### 3. 🕒 Riwayat Perkembangan Cloud (Supabase PostgreSQL)
* **Penyimpanan Terintegrasi:** Setiap hasil perhitungan tersimpan otomatis secara *real-time* ke tabel cloud Supabase (`history_gizi`).
* **Grafik & Rekam Jejak:** Orang tua dapat melihat histori penimbangan dan perkembangan berat/tinggi badan balita dari waktu ke waktu secara kronologis.

### 4. 🔐 Keamanan Tingkat Tinggi (Kriptografi AES-256 & Steganografi LSB)
* **Enkripsi AES-256:** Data sensitif pengguna (seperti nama lengkap dan profil pengguna) dienkripsi secara simetris sebelum dikirim atau disimpan di database untuk melindungi privasi.
* **Steganografi Citra Digital (LSB):** Fitur khusus pengamanan pesan rahasia yang disisipkan ke dalam saluran warna biru citra PNG (*Least Significant Bit*) secara kasat mata, serta dilengkapi modul ekstraksi/dekripsi pesan.

### 5. ⚡ Autentikasi Modern & Auto-Login
* **Supabase Auth:** Registrasi dan login pengguna yang aman dengan validasi kekuatan kata sandi.
* **Session Persistence (Auto-Login):** Aplikasi mendeteksi sesi login aktif secara otomatis di memori lokal perangkat, sehingga pengguna langsung masuk ke Beranda tanpa harus login ulang setiap kali membuka aplikasi.

---

## 🖼️ Tampilan Antarmuka Aplikasi

| Layar Pembuka | Beranda (Home) | Kalkulator Gizi |
| :---: | :---: | :---: |
| ![Layar Pembuka](./figma%20pelita/Layar%20Pembuka.png) | ![Home](./figma%20pelita/Home.png) | ![Kalkulator Gizi](./figma%20pelita/Kalkulator%20Gizi%201.png) |

| Konsultasi AI | Hasil Analisis Gizi | Riwayat Pertumbuhan |
| :---: | :---: | :---: |
| ![Konsultasi](./figma%20pelita/Konsultasi.png) | ![Hasil Perhitungan](./figma%20pelita/Hasil%20Perhitungan%20Kalkulator%20Gizi.png) | ![Riwayat](./figma%20pelita/Riwayat.png) |

| Profil Pengguna | Onboarding | Keamanan Akun |
| :---: | :---: | :---: |
| ![Profil](./figma%20pelita/Profil.png) | ![Onboarding](./figma%20pelita/03%20-%20A%20-%20Onboarding.png) | ![Pengelola Password](./figma%20pelita/Pengelola%20Password.png) |

---

## 🛠️ Arsitektur & Teknologi

* **Framework Utama:** [Flutter](https://flutter.dev) (Dart SDK v3.11+)
* **Desain UI/UX:** Material Design 3 dengan palet warna Teal & Cyan ramah anak
* **Cloud Database & Backend:** [Supabase](https://supabase.com)
  * Supabase Authentication & Session Storage
  * PostgreSQL Database with Row Level Security (RLS)
  * Storage Buckets untuk penyimpanan aset avatar/stego
* **Artificial Intelligence:** [Google Generative AI SDK](https://pub.dev/packages/google_generative_ai) (Gemini 1.5 Flash)
* **Kriptografi & Keamanan:** `encrypt` (AES-256-CBC with PKCS7), `image` (LSB Bitmap processing)
* **Akses Galeri & Media:** `image_picker` & `gal`

---

## 📁 Struktur Direktori Utama

```text
Aplikasi Pelita/
├── android/               # Konfigurasi native Android & AndroidManifest
├── Asset/                 # Aset gambar lokal, ilustrasi onboarding, dan logo
├── figma pelita/          # Tangkapan layar desain mockup UI/UX
├── lib/                   # Kode sumber utama Flutter (Dart)
│   ├── main.dart                  # Titik masuk aplikasi, inisialisasi Supabase & auto-login
│   ├── home_screen.dart           # Dashboard beranda, artikel gizi, & navigasi utama
│   ├── kalkulator_gizi_screen.dart# Input antropometri & kalkulator gizi balita
│   ├── hasil_perhitungan_screen.dart # Tampilan kartu analisis IMT, BBI, Energi
│   ├── detail_hasil_screen.dart   # Penjelasan detail rekomendasi gizi
│   ├── riwayat.dart               # Tampilan histori gizi dari Supabase
│   ├── konsultasi_screen.dart     # Antarmuka Chatbot AI (Google Gemini 1.5 Flash)
│   ├── security_service.dart      # Modul enkripsi AES-256 & Steganografi LSB
│   ├── stego_screen.dart          # Halaman interaktif enkripsi/dekripsi gambar stego
│   ├── login_screen.dart          # Form autentikasi masuk pengguna
│   ├── register_screen.dart       # Form pendaftaran akun baru
│   ├── profile.dart               # Profil pengguna & menu logout
│   ├── edit_profile_page.dart     # Pembaruan informasi profil
│   ├── change_password_page.dart  # Penggantian kata sandi
│   └── onboarding_screen.dart     # Pengenalan fitur aplikasi untuk pengguna baru
├── pubspec.yaml           # Konfigurasi dependensi dan registrasi aset
└── README.md              # Dokumentasi lengkap proyek
```

---

## 🚀 Panduan Menjalankan Proyek

### Prasyarat
1. **Flutter SDK:** Versi 3.24 atau lebih tinggi
2. **Java Development Kit:** JDK 17 (misal: Eclipse Adoptium Temurin 17)
3. **Android Studio / VS Code** dengan ekstensi Flutter & Dart

### Langkah Instalasi
1. **Clone repositori:**
   ```bash
   git clone https://github.com/MuhamadHata/Projek-Aplikasi-Pelita.git
   cd Projek-Aplikasi-Pelita
   ```

2. **Unduh dependensi paket:**
   ```bash
   flutter pub get
   ```

3. **Jalankan aplikasi di perangkat / emulator:**
   ```bash
   flutter run
   ```

4. **Kompilasi menjadi APK Release:**
   ```bash
   flutter build apk
   ```
   *File APK siap pakai akan berada di folder `build/app/outputs/flutter-apk/app-release.apk`.*

---

## 👤 Pengembang (Author)

**Muhamad Hata**  
*Mobile Application Developer & Informatics Engineering Student*  
* 🐙 GitHub: [@MuhamadHata](https://github.com/MuhamadHata)
* 🎨 Desain Figma: [Figma Project Pelita](https://www.figma.com/design/FhsV4fWjx3VstlG7Kd2fjh/Pelita?node-id=2052-1969)

---
<p align="center">
  Dibuat dengan ❤️ untuk mendukung pemantauan gizi optimal dan pencegahan stunting pada balita Indonesia.
</p>
