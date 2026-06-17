# EarthCare 🌍

EarthCare adalah aplikasi pelaporan lingkungan berbasis mobile yang memberdayakan masyarakat untuk melaporkan masalah lingkungan (seperti tumpukan sampah liar, sungai tercemar, pohon tumbang, dll.) dan memungkinkan pihak berwenang untuk menangani masalah tersebut dengan cepat dan efisien.

Aplikasi ini dibangun menggunakan **Flutter** dan **Supabase**.

## 🚀 Fitur Utama

Aplikasi ini memiliki tiga peran utama (*role*), masing-masing dengan fitur yang disesuaikan:

### 1. Warga (Masyarakat Umum)
- **Pelaporan Masalah**: Melaporkan masalah lingkungan terdekat lengkap dengan foto, kategori, dan deskripsi.
- **Peta Interaktif (Map)**: Melihat titik-titik laporan masalah lingkungan di sekitar dengan indikator warna berdasarkan status dan urgensi (Kritis, Aktif, Diproses, Teratasi).
- **Lacak Laporan**: Memantau status laporan secara *real-time* (Diterima -> Diverifikasi -> Ditugaskan -> Diproses -> Selesai).
- **Notifikasi**: Mendapatkan notifikasi status terbaru mengenai laporan yang dibuat.

### 2. Petugas (Officer)
- **Manajemen Tugas**: Menerima tugas penanganan masalah dari Admin.
- **Update Status**: Memperbarui progres penanganan laporan di lapangan.
- **Peta Tugas**: Melihat peta yang difilter khusus untuk menampilkan laporan yang hanya ditugaskan kepada petugas tersebut.

### 3. Admin
- **Verifikasi Laporan**: Memverifikasi laporan yang masuk dari masyarakat.
- **Distribusi Tugas**: Menugaskan laporan yang sudah diverifikasi kepada petugas lapangan (Officer) terkait.
- **Manajemen Pengguna & Petugas**: Mengatur akun pengguna dan peran di dalam sistem.

## 🛠️ Teknologi yang Digunakan
- **Frontend**: Flutter (Dart)
- **State Management**: Riverpod
- **Routing**: GoRouter
- **Maps**: Flutter Map (OpenStreetMap)
- **Backend / Database**: Supabase & Custom Express.js API

## ⚙️ Cara Menjalankan Aplikasi Lokal

1. **Clone repository ini**:
   ```bash
   git clone https://github.com/FahrezaAdam/earthcare-app.git
   cd earth_care
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Konfigurasi Environment Variables**:
   Pastikan Anda sudah mengatur endpoint API yang mengarah ke backend EarthCare di `.env` atau *constants* yang sesuai.

4. **Jalankan aplikasi**:
   ```bash
   flutter run
   ```

## 🤝 Berkontribusi
Kami sangat menyambut kontribusi! Jika Anda menemukan *bug* atau ingin menambahkan fitur baru, silakan buat *Pull Request* atau buka *Issue*.

---
Dibuat untuk menjaga lingkungan kita bersama! 🌳♻️
