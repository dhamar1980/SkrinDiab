import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/screening_model.dart';
import '../models/user_model.dart';
import '../supabase_config.dart';

class EducationArticle {
  final String id;
  final String title;
  final String category;
  final String summary;
  final String content;
  final String author;
  final String readTime;
  final String iconName;

  EducationArticle({
    required this.id,
    required this.title,
    required this.category,
    required this.summary,
    required this.content,
    required this.author,
    required this.readTime,
    required this.iconName,
  });
}

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  SupabaseClient get _client => SupabaseConfig.client;

  static const String _localScreeningsKey = 'local_screenings_cache';
  static const String _localUserKey = 'local_user_cache_';

  /// Menyimpan hasil skrining ke Supabase dan Local Cache
  Future<bool> saveScreening(ScreeningModel screening) async {
    bool savedToSupabase = false;

    // 1. Coba simpan ke Supabase screenings table
    try {
      final data = screening.toMap();
      await _client.from('screenings').upsert(data);
      savedToSupabase = true;
      debugPrint('Screening successfully saved to Supabase');
    } catch (e) {
      debugPrint('Warning: Could not save to Supabase screenings: $e');
    }

    // 2. Selalu simpan juga ke local cache (offline persistence & fallback)
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingJson = prefs.getStringList(_localScreeningsKey) ?? [];
      existingJson.insert(0, screening.toJson());
      await prefs.setStringList(_localScreeningsKey, existingJson);
    } catch (e) {
      debugPrint('Warning saving to local cache: $e');
    }

    return savedToSupabase;
  }

  /// Mengambil daftar riwayat skrining pasien
  Future<List<ScreeningModel>> getScreenings(String userId) async {
    final List<ScreeningModel> result = [];

    // 1. Ambil dari Supabase jika ada
    try {
      final response = await _client
          .from('screenings')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      for (final item in data) {
        result.add(ScreeningModel.fromMap(item as Map<String, dynamic>));
      }
    } catch (e) {
      debugPrint('Could not fetch screenings from Supabase: $e');
    }

    // 2. Ambil dari local cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final localList = prefs.getStringList(_localScreeningsKey) ?? [];

      for (final jsonStr in localList) {
        final screening = ScreeningModel.fromJson(jsonStr);
        // Jika userId cocok atau guest, dan belum ada di result
        if ((screening.userId == userId || userId == 'guest_user_id') &&
            !result.any((s) => s.id == screening.id)) {
          result.add(screening);
        }
      }
    } catch (e) {
      debugPrint('Error reading local screenings cache: $e');
    }

    // Urutkan berdasarkan tanggal terbaru
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  /// Menghapus satu data skrining
  Future<bool> deleteScreening(String screeningId) async {
    try {
      await _client.from('screenings').delete().eq('id', screeningId);
    } catch (e) {
      debugPrint('Error deleting from Supabase: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final localList = prefs.getStringList(_localScreeningsKey) ?? [];
      final updatedList = localList.where((item) {
        final decoded = jsonDecode(item);
        return decoded['id'] != screeningId;
      }).toList();
      await prefs.setStringList(_localScreeningsKey, updatedList);
      return true;
    } catch (e) {
      debugPrint('Error deleting from local cache: $e');
      return false;
    }
  }

  /// Menyimpan profil pengguna
  Future<void> saveUserProfile(UserModel user) async {
    try {
      await _client.from('users').upsert(user.toMap());
    } catch (e) {
      debugPrint('Error saving user profile to Supabase: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_localUserKey${user.id}', user.toJson());
    } catch (e) {
      debugPrint('Error saving user profile locally: $e');
    }
  }

  /// Mengambil profil pengguna
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        return UserModel.fromMap(response);
      }
    } catch (e) {
      debugPrint('Error fetching user profile from Supabase: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('$_localUserKey$userId');
      if (cached != null) {
        return UserModel.fromJson(cached);
      }
    } catch (e) {
      debugPrint('Error fetching local user profile: $e');
    }

    return null;
  }

  /// Data Edukasi Telemedicine Diabetes Standar PERKENI & Kemenkes RI
  List<EducationArticle> getEducationArticles() {
    return [
      EducationArticle(
        id: 'edu_1',
        title: 'Mengenal Diabetes Melitus & Faktor Risikonya',
        category: 'Dasar Diabetes',
        summary:
            'Diabetes Melitus adalah penyakit metabolik kronis yang ditandai dengan tingginya kadar gula darah (glukosa).',
        content: '''
Diabetes Melitus (DM) adalah penyakit gangguan metabolik menahun yang ditandai dengan kadar glukosa darah melebihi batas normal (hiperglikemia).

Tipe Diabetes Utama:
1. Diabetes Melitus Tipe 1: Kerusakan autoimun sel beta pankreas yang menyebabkan defisiensi insulin absolut. Sering terjadi pada anak-anak atau usia muda.
2. Diabetes Melitus Tipe 2: Resistensi insulin disertai defisiensi sekresi insulin relatif. Mencakup lebih dari 90% kasus diabetes di seluruh dunia dan sangat terkait dengan gaya hidup, obesitas, dan faktor genetik.
3. Diabetes Gestasional: Diabetes yang pertama kali didiagnosis selama masa kehamilan.

Faktor Risiko yang Tidak Dapat Dimodifikasi:
• Usia >= 45 tahun
• Riwayat keluarga dengan diabetes (orang tua atau saudara kandung)
• Riwayat melahirkan bayi dengan berat badan lahir > 4 kg
• Riwayat diabetes gestasional

Faktor Risiko yang Dapat Dimodifikasi:
• Obesitas dan kelebihan berat badan (IMT >= 23 kg/m² untuk populasi Asia)
• Obesitas sentral (lingkar pinggang pria >= 90 cm, wanita >= 80 cm)
• Kurangnya aktivitas fisik (< 150 menit/minggu)
• Hipertensi (tekanan darah >= 140/90 mmHg)
• Pola makan tinggi kalori, tinggi lemak jenuh, dan rendah serat.
''',
        author: 'Tim Medis SkrinDiab & PERKENI',
        readTime: '4 menit baca',
        iconName: 'info',
      ),
      EducationArticle(
        id: 'edu_2',
        title: 'Waspadai Gejala Khas 4P Diabetes Melitus',
        category: 'Gejala Klinis',
        summary:
            'Gejala klasik diabetes dikenal dengan 4P: Poliuria, Polidipsia, Polifagia, dan Penurunan berat badan tanpa sebab jelas.',
        content: '''
Banyak penderita diabetes tipe 2 tidak menyadari kondisi mereka pada tahap awal (The Silent Killer). Namun, saat gula darah tinggi terus-menerus, tubuh akan menunjukkan gejala khas "4P":

1. Poliuria (Sering Buang Air Kecil)
Ginjal menyaring kelebihan glukosa ke dalam urine, yang menarik banyak air keluar dari tubuh. Pasien sering terbangun beberapa kali di malam hari untuk buang air kecil.

2. Polidipsia (Sering Merasa Sangat Haus)
Akibat kehilangan banyak cairan melalui urine, tubuh mengalami dehidrasi ringan sehingga otak memicu rasa haus yang terus-menerus meskipun sudah banyak minum.

3. Polifagia (Cepat Merasa Lapar)
Karena glukosa tidak dapat masuk ke dalam sel tubuh akibat resistensi insulin, sel-sel tubuh "kelaparan" energi dan mengirimkan sinyal rasa lapar berlebihan.

4. Penurunan Berat Badan Drastis Tanpa Sebab Jelas
Meskipun penderita makan lebih banyak, tubuh membakar simpanan otot dan lemak untuk menghasilkan energi pengganti glukosa.

Gejala Tambahan Lainnya:
• Cepat merasa lelah dan lemas sepanjang hari
• Penglihatan kabur akibat perubahan lensa mata karena fluktuasi cairan
• Luka atau goresan yang sangat lama sembuh
• Sering kesemutan atau kebas pada telapak kaki dan ujung jari tangan (neuropati diabetik)
• Sering mengalami infeksi jamur atau gatal pada area kulit dan kelamin.
''',
        author: 'Spesialis Penyakit Dalam (Sp.PD)',
        readTime: '3 menit baca',
        iconName: 'warning',
      ),
      EducationArticle(
        id: 'edu_3',
        title: 'Panduan Pola Makan 3J untuk Pencegahan Diabetes',
        category: 'Nutrisi & Diet',
        summary:
            'Penerapan aturan 3J (Jadwal, Jumlah, Jenis) merupakan pilar utama manajemen gizi medis rekomendasi PERKENI.',
        content: '''
Manajemen gizi medis untuk pencegahan dan pengendalian diabetes berfokus pada 3 pilar: Jadwal, Jumlah, dan Jenis (3J).

1. JADWAL MAKAN TERATUR
• Terdiri dari 3 kali makan utama (sarapan, makan siang, makan malam) dan 2-3 kali camilan sehat di antara waktu makan utama.
• Rentang antar jadwal makan berkisar 3-4 jam.
• Jangan melewatkan waktu makan karena dapat memicu lonjakan nafsu makan berlebih atau fluktuasi gula darah.

2. JUMLAH (PORSI KALORI)
• Sesuaikan kebutuhan kalori harian berdasarkan jenis kelamin, berat badan ideal, dan tingkat aktivitas fisik.
• Gunakan panduan piring "T" dari Kemenkes:
  - 1/2 piring berisi sayuran non-tepung dan buah rendah gula.
  - 1/4 piring berisi sumber karbohidrat kompleks (nasi merah, kentang rebus, ubi).
  - 1/4 piring berisi lauk sumber protein rendah lemak (ikan, tahu, tempe, dada ayam tanpa kulit).

3. JENIS MAKANAN (KUALITAS GLIKEMIK)
• Prioritaskan makanan dengan Indeks Glikemik (IG) Rendah (< 55): beras merah, oatmeal, roti gandum utuh, apel, pir, brokoli, kacang-kacangan.
• Batasi makanan dengan IG Tinggi (> 70): nasi putih dalam porsi besar, roti tawar putih, semangka, minuman manis, madu berlebih.
• Hindari lemak trans dan batasi lemak jenuh (gorengan, jeroan, santan berulang).
• Batasi asupan natrium / garam tidak lebih dari 1 sendok teh (2.000 mg) per hari.
''',
        author: 'Ahli Gizi Klinis (Nutrisionis)',
        readTime: '5 menit baca',
        iconName: 'restaurant',
      ),
      EducationArticle(
        id: 'edu_4',
        title: 'Pentingnya Aktivitas Fisik & Latihan Terstruktur',
        category: 'Gaya Hidup',
        summary:
            'Olahraga aerobik dan latihan beban rutin mampu meningkatkan sensitivitas insulin hingga 48 jam pasca latihan.',
        content: '''
Aktivitas fisik teratur adalah salah satu pilar pengobatan dan pencegahan diabetes paling ampuh tanpa obat.

Manfaat Aktivitas Fisik:
• Membantu sel otot menyerap glukosa darah secara langsung tanpa bergantung pada insulin.
• Menurunkan resistensi insulin dan meningkatkan efektivitas hormon insulin tubuh.
• Membantu menurunkan berat badan dan lingkar pinggang.
• Menjaga tekanan darah dan profil kolesterol (HDL naik, LDL & Trigliserida turun).

Rekomendasi Latihan (Standar PERKENI & WHO):
1. Latihan Aerobik:
   - Durasi: Minimal 150 menit per minggu (misalnya 30 menit sehari, 5 hari dalam seminggu).
   - Intensitas: Sedang (moderate intensity) di mana Anda masih bisa berbicara tetapi tidak bisa bernyanyi saat berolahraga.
   - Pilihan: Jalan cepat, senam aerobik, bersepeda santai, renang.
   - Jangan ada jeda tanpa latihan lebih dari 2 hari berturut-turut.

2. Latihan Resistensi / Penguatan Otot:
   - Frekuensi: 2-3 kali seminggu pada hari yang tidak berurutan.
   - Pilihan: Push-up dinding, squat, latihan dengan dumbbell ringan atau resistance band.
   - Massa otot yang terlatih bertindak sebagai tempat penyerapan glukosa terbesar dalam tubuh.

Tips Praktis Bagi Pemula:
• Mulailah secara bertahap (10-15 menit per sesi jika belum terbiasa).
• Selalu lakukan pemanasan 5 menit dan pendinginan 5 menit.
• Gunakan alas kaki yang empuk dan nyaman untuk melindungi kaki.
• Cukupi hidrasi sebelum, selama, dan sesudah berolahraga.
''',
        author: 'Spesialis Kedokteran Olahraga',
        readTime: '4 menit baca',
        iconName: 'fitness',
      ),
      EducationArticle(
        id: 'edu_5',
        title: 'Bagaimana Decision Tree Bekerja pada SkrinDiab',
        category: 'Teknologi Medis',
        summary:
            'Transparansi algoritma Decision Tree dalam melakukan klasifikasi risiko penyakit secara berbasis bukti (evidence-based).',
        content: '''
Aplikasi SkrinDiab menggunakan Algoritma Decision Tree (Pohon Keputusan) untuk mengklasifikasikan risiko diabetes seorang individu.

Mengapa Decision Tree Sangat Cocok untuk Skrining Medis?
1. Transparansi & Explainability: Berbeda dengan model "black-box" (seperti Deep Neural Network), Decision Tree menghasilkan alur penentuan keputusan yang jelas langkah demi langkah dari Root Node hingga Leaf Node. Dokter dan pasien dapat memverifikasi alasan di balik setiap hasil klasifikasi.
2. Sesuai Panduan Klinis (Clinical Practice Guidelines): Struktur percabangan IF-THEN meniru penalaran diagnostik dokter spesialis penyakit dalam sesuai konsensus PERKENI dan skor risiko internasional (FINDRISC).

Struktur Node pada SkrinDiab:
• Root Node (Akar): Evaluasi riwayat hiperglikemia / toleransi glukosa terganggu sebelumnya.
• Internal Nodes (Percabangan):
  - Node Antropometri: Indeks Massa Tubuh (IMT) dan Obesitas Sentral (Lingkar Pinggang).
  - Node Demografi: Usia pasien (< 45 vs >= 45 tahun).
  - Node Genetik: Riwayat diabetes dalam keluarga (Tingkat 1 vs Tingkat 2 vs Tidak Ada).
  - Node Komorbid: Riwayat hipertensi dan pengobatan tensi.
  - Node Gaya Hidup: Kebiasaan aktivitas fisik dan asupan serat harian.
  - Node Gejala: Frekuensi dan keberadaan gejala khas 4P.
• Leaf Nodes (Daun / Keputusan Akhir):
  - Risiko Rendah: Pasien memiliki profil metabolik baik dengan risiko minimal.
  - Risiko Sedang: Terdapat 1 atau 2 faktor risiko yang memerlukan perbaikan pola hidup.
  - Risiko Tinggi: Terdapat kombinasi faktor risiko kuat, disarankan pemeriksaan laboratorium.
  - Risiko Sangat Tinggi: Riwayat hiperglikemia dengan gejala aktif, memerlukan konsultasi medis segera.
''',
        author: 'Tim Riset AI & Telemedicine SkrinDiab',
        readTime: '4 menit baca',
        iconName: 'psychology',
      ),
    ];
  }
}
