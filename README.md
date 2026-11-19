# SkrinDiab - Telemedicine Mobile Skrining Risiko Diabetes (Decision Tree)

Aplikasi mobile telemedicine lengkap berbasis **Flutter** dan **Supabase Backend** yang dirancang untuk skrining deteksi dini risiko penyakit **Diabetes Melitus Tipe 2** menggunakan **Algoritma Decision Tree (Pohon Keputusan)** berbasis pedoman klinis **PERKENI (Perkumpulan Endokrinologi Indonesia)** dan **Kemenkes RI**.

---

## 📱 Fitur Utama Aplikasi

1. **Autentikasi & Profil Pasien (Supabase Auth)**
   - Registrasi pasien baru lengkap dengan data demografi (Nama, Email, Telepon, Gender, Tanggal Lahir).
   - Masuk (Login) dengan email & password terdaftar.
   - **Mode Demo / Tamu (Guest Mode)**: Uji coba aplikasi secara instan tanpa perlu mendaftar email baru.
   - Sesi tersimpan aman (Persistence) menggunakan `shared_preferences`.

2. **Skrining Klinis Cerdas (Decision Tree)**
   - **Langkah 1 (Antropometri):** Usia, Jenis Kelamin, Berat Badan, Tinggi Badan (otomatis kalkulasi IMT Asia-Pasifik secara live), dan Lingkar Pinggang (evaluasi obesitas sentral).
   - **Langkah 2 (Gaya Hidup & Genetik):** Aktivitas fisik harian, konsumsi serat harian, riwayat hipertensi, riwayat gula darah tinggi, dan riwayat diabetes keluarga (Tingkat 1 / Tingkat 2 / Tidak ada).
   - **Langkah 3 (Gejala Klinis 4P):** Evaluasi gejala khas (Polidipsia/haus, Poliuria/kencing malam, Polifagia/lapar, penurunan berat badan drastis, kebas/kesemutan, penglihatan buram).

3. **Laporan Hasil & Explainable AI (Jalur Pohon Keputusan)**
   - Tingkat Risiko: **Rendah**, **Sedang**, **Tinggi**, atau **Sangat Tinggi**.
   - Indikator persentase probabilitas risiko.
   - **Jalur Penelusuran Pohon Keputusan (Decision Tree Trace):** Menampilkan transparansi penalaran AI simpul demi simpul dari Root Node hingga Leaf Node.
   - **Rekomendasi Medis Spesifik:** Panduan pemeriksaan lab (GDP, HbA1c, TTGO) dan rujukan dokter spesialis penyakit dalam (Sp.PD).
   - **Panduan Gizi Medis 3J (PERKENI):** Jadwal, Jumlah (kalori), dan Jenis makanan rendah indeks glikemik.
   - **Panduan Aktivitas Fisik:** Target aerobik mingguan dan latihan resistensi.

4. **Riwayat Skrining (Database & Offline Caching)**
   - Penyimpanan riwayat ke tabel Supabase PostgreSQL `screenings`.
   - Fallback offline caching dengan SharedPreferences sehingga data tetap aman dan tersimpan.
   - Filter riwayat berdasarkan tingkat risiko dan hapus riwayat.

5. **Pusat Edukasi Diabetes Telemedicine**
   - Artikel medis komprehensif terverifikasi PERKENI: Dasar Diabetes, Gejala 4P, Diet 3J, Olahraga, serta Penjelasan Algoritma Decision Tree.
   - Fitur pencarian artikel interaktif.

---

## 📁 Struktur Folder Proyek

```
lib/
├── main.dart                          # Inisialisasi app, locale id_ID, ScreenUtil & Theme
├── supabase_config.dart               # Konfigurasi Supabase Client & URL/Anon Key
├── screens/
│   ├── splash_screen.dart             # Splash screen dengan logo animasi & auth check
│   ├── login_screen.dart              # Form login pasien + Mode Demo Tamu
│   ├── register_screen.dart           # Form registrasi lengkap pasien
│   ├── home_screen.dart               # Dashboard utama telemedicine
│   ├── screening_form_screen.dart     # Kuesioner skrining 3 tahap
│   ├── screening_result_screen.dart   # Laporan hasil skrining & Decision Tree Trace
│   ├── history_screen.dart            # Riwayat skrining pasien dengan filter
│   └── education_screen.dart          # Pusat edukasi medis & panduan pola hidup
├── services/
│   ├── auth_service.dart              # Layanan autentikasi Supabase & session
│   ├── database_service.dart          # Layanan CRUD Supabase + Local Cache
│   └── decision_tree_service.dart     # Engine Algoritma Decision Tree & kalkulator klinis
├── models/
│   ├── user_model.dart                # Model data pengguna/pasien
│   └── screening_model.dart           # Model data hasil skrining
└── utils/
    └── theme.dart                     # Tema Biru Medis (#0D47A1), Poppins, Button & Card
```

---

## 🛠️ Konfigurasi Supabase & Database Setup

File skrip database lengkap telah disediakan di file `supabase_schema.sql`.

Untuk mengaktifkan tabel di Supabase Dashboard:
1. Buka dashboard proyek Supabase Anda: [https://supabase.com/dashboard/project/oaqcioychodxtuniipib](https://supabase.com/dashboard/project/oaqcioychodxtuniipib)
2. Buka menu **SQL Editor** pada navigasi sebelah kiri.
3. Buka file `supabase_schema.sql` pada proyek ini, salin seluruh isinya dan jalankan (**Run**).
4. Skrip ini akan membuat tabel `users` dan `screenings`, mengaktifkan Row Level Security (RLS), membuat indeks performa, serta memasukkan data demo awal.

---

## 🚀 Cara Menjalankan Aplikasi

1. Ambil dependensi:
   ```bash
   flutter pub get
   ```

2. Jalankan analisis statis & unit tests:
   ```bash
   flutter analyze
   flutter test
   ```

3. Jalankan aplikasi pada emulator atau perangkat fisik:
   ```bash
   flutter run
   ```
