class DecisionTreeResult {
  final String riskLevel; // 'Rendah', 'Sedang', 'Tinggi', 'Sangat Tinggi'
  final double riskScore; // 0.0 - 100.0 %
  final double bmi;
  final String bmiCategory;
  final bool hasCentralObesity;
  final List<String> decisionPath;
  final List<String> recommendations;
  final List<String> dietRecommendations;
  final List<String> lifestyleRecommendations;

  DecisionTreeResult({
    required this.riskLevel,
    required this.riskScore,
    required this.bmi,
    required this.bmiCategory,
    required this.hasCentralObesity,
    required this.decisionPath,
    required this.recommendations,
    required this.dietRecommendations,
    required this.lifestyleRecommendations,
  });
}

class DecisionTreeService {
  /// Menghitung Indeks Massa Tubuh (IMT)
  static double calculateBMI(double weightKg, double heightCm) {
    if (heightCm <= 0) return 0.0;
    final heightMeter = heightCm / 100.0;
    final bmi = weightKg / (heightMeter * heightMeter);
    return double.parse(bmi.toStringAsFixed(1));
  }

  /// Kategori IMT standar Asia-Pasifik (WHO / Kemenkes RI)
  static String getBMICategory(double bmi) {
    if (bmi < 18.5) {
      return 'Berat Badan Kurang (Underweight)';
    } else if (bmi < 23.0) {
      return 'Berat Badan Normal';
    } else if (bmi < 25.0) {
      return 'Kelebihan Berat Badan (Overweight)';
    } else {
      return 'Obesitas';
    }
  }

  /// Evaluasi Obesitas Sentral berdasarkan Lingkar Pinggang (PERKENI)
  /// Pria >= 90 cm, Wanita >= 80 cm
  static bool checkCentralObesity(String gender, double waistCircumference) {
    final isMale = gender.toLowerCase().contains('laki') ||
        gender.toLowerCase() == 'pria' ||
        gender.toLowerCase() == 'male';
    if (isMale) {
      return waistCircumference >= 90.0;
    } else {
      return waistCircumference >= 80.0;
    }
  }

  /// Algoritma Klasifikasi Decision Tree untuk Skrining Risiko Diabetes
  static DecisionTreeResult evaluateDiabetesRisk({
    required int age,
    required String gender,
    required double weight,
    required double height,
    required double waistCircumference,
    required bool physicalActivity,
    required bool dietFruitsVeg,
    required bool hypertensionHistory,
    required bool highGlucoseHistory,
    required String familyDiabetesHistory, // 'none', 'second_degree', 'first_degree'
    required List<String> symptoms,
  }) {
    final bmi = calculateBMI(weight, height);
    final bmiCategory = getBMICategory(bmi);
    final centralObesity = checkCentralObesity(gender, waistCircumference);

    final List<String> path = [];
    String riskLevel = 'Rendah';
    double score = 10.0;

    // Hitung gejala khas (4P: Poliuria, Polidipsia, Polifagia, Penurunan BB & Gejala Penyerta)
    int classicSymptomsCount = 0;
    for (final s in symptoms) {
      final lower = s.toLowerCase();
      if (lower.contains('haus') ||
          lower.contains('polidipsia') ||
          lower.contains('kencing') ||
          lower.contains('buang air kecil') ||
          lower.contains('poliuria') ||
          lower.contains('lapar') ||
          lower.contains('polifagia') ||
          lower.contains('penurunan') ||
          lower.contains('lelah') ||
          lower.contains('kesemutan') ||
          lower.contains('kebas') ||
          lower.contains('kabur') ||
          lower.contains('buram') ||
          lower.contains('luka')) {
        classicSymptomsCount++;
      }
    }

    path.add('🌲 [Node 1 - Root] Mengevaluasi Riwayat Gula Darah Tinggi...');

    // === CABANG 1: RIWAYAT GULA DARAH TINGGI / HIPERGLIKEMIA ===
    if (highGlucoseHistory) {
      path.add('├─ ➔ Riwayat Gula Darah Tinggi: YA (Faktor Risiko Mayor Terdeteksi)');
      path.add('│  [Node 2A] Mengevaluasi Gejala Khas Diabetes (Ditemukan $classicSymptomsCount gejala)');

      if (classicSymptomsCount >= 2) {
        path.add('│  ├─ ➔ Gejala Khas >= 2 terdeteksi (Polidipsia, Poliuria, Polifagia, dll.)');
        path.add('│  └─ 🎯 [LEAF] Klasifikasi: RISIKO SANGAT TINGGI');
        riskLevel = 'Sangat Tinggi';
        score = 88.0 + (classicSymptomsCount * 2.5).clamp(0.0, 10.0);
      } else {
        path.add('│  ├─ ➔ Gejala Khas < 2');
        path.add('│  [Node 3A] Mengevaluasi Usia (Usia: $age tahun) dan IMT (IMT: $bmi)');
        if (age >= 45 || bmi >= 25.0 || centralObesity) {
          path.add('│  ├─ ➔ Pasien berusia >= 45 tahun ATAU Obesitas (IMT >= 25 / Obesitas Sentral)');
          path.add('│  └─ 🎯 [LEAF] Klasifikasi: RISIKO TINGGI');
          riskLevel = 'Tinggi';
          score = 76.0 + (age >= 45 ? 6.0 : 0.0) + (bmi >= 25.0 ? 5.0 : 0.0);
        } else {
          path.add('│  ├─ ➔ Pasien berusia < 45 tahun & IMT bukan kategori obesitas');
          path.add('│  └─ 🎯 [LEAF] Klasifikasi: RISIKO SEDANG');
          riskLevel = 'Sedang';
          score = 58.0;
        }
      }
    }
    // === CABANG 2: TIDAK ADA RIWAYAT GULA DARAH TINGGI ===
    else {
      path.add('├─ ➔ Riwayat Gula Darah Tinggi: TIDAK');
      path.add('│  [Node 2B] Mengevaluasi Indeks Massa Tubuh (IMT: $bmi - $bmiCategory)');

      // Sub-cabang 2.1: OBESITAS (IMT >= 25.0)
      if (bmi >= 25.0) {
        path.add('│  ├─ ➔ Kategori IMT: OBESITAS (>= 25.0 kg/m²)');
        path.add('│  [Node 3B1] Mengevaluasi Riwayat Diabetes dalam Keluarga...');

        if (familyDiabetesHistory == 'first_degree') {
          path.add('│  │  ├─ ➔ Riwayat Keluarga Tingkat 1 (Orang Tua / Saudara Kandung: Positif)');
          path.add('│  │  [Node 4A] Mengevaluasi Usia ($age thn) & Hipertensi (${hypertensionHistory ? 'Ya' : 'Tidak'})');

          if (age >= 45 || hypertensionHistory || centralObesity) {
            path.add('│  │  ├─ ➔ Memenuhi kriteria risiko tinggi (Usia >= 45, Hipertensi, atau Obesitas Sentral)');
            path.add('│  │  └─ 🎯 [LEAF] Klasifikasi: RISIKO TINGGI');
            riskLevel = 'Tinggi';
            score = 74.0 + (age >= 45 ? 6.0 : 0.0) + (hypertensionHistory ? 4.0 : 0.0);
          } else {
            path.add('│  │  ├─ ➔ Usia < 45 tahun tanpa hipertensi');
            path.add('│  │  └─ 🎯 [LEAF] Klasifikasi: RISIKO SEDANG');
            riskLevel = 'Sedang';
            score = 62.0;
          }
        } else {
          path.add('│  │  ├─ ➔ Riwayat Keluarga: Tingkat 2 atau Tidak Ada');
          path.add('│  │  [Node 4B] Mengevaluasi Obesitas Sentral & Tekanan Darah...');

          if (centralObesity && hypertensionHistory) {
            path.add('│  │  ├─ ➔ Mengalami Obesitas Sentral DAN Hipertensi');
            path.add('│  │  └─ 🎯 [LEAF] Klasifikasi: RISIKO SEDANG');
            riskLevel = 'Sedang';
            score = 64.0;
          } else {
            path.add('│  │  ├─ ➔ Faktor komorbid terbatas');
            path.add('│  │  └─ 🎯 [LEAF] Klasifikasi: RISIKO SEDANG');
            riskLevel = 'Sedang';
            score = 48.0 + (centralObesity ? 6.0 : 0.0);
          }
        }
      }
      // Sub-cabang 2.2: OVERWEIGHT (IMT 23.0 - 24.9)
      else if (bmi >= 23.0) {
        path.add('│  ├─ ➔ Kategori IMT: OVERWEIGHT (23.0 - 24.9 kg/m²)');
        path.add('│  [Node 3B2] Mengevaluasi Usia Pasien ($age tahun)...');

        if (age >= 45) {
          path.add('│  │  ├─ ➔ Usia >= 45 tahun (Faktor Usia Meningkat)');
          path.add('│  │  [Node 4C] Cek Riwayat Keluarga / Hipertensi...');
          if (familyDiabetesHistory != 'none' || hypertensionHistory || centralObesity) {
            path.add('│  │  ├─ ➔ Memiliki riwayat keluarga, hipertensi, atau obesitas sentral');
            path.add('│  │  └─ 🎯 [LEAF] Klasifikasi: RISIKO SEDANG');
            riskLevel = 'Sedang';
            score = 54.0;
          } else {
            path.add('│  │  ├─ ➔ Tanpa riwayat keluarga atau hipertensi');
            path.add('│  │  └─ 🎯 [LEAF] Klasifikasi: RISIKO RINGAN-SEDANG');
            riskLevel = 'Sedang';
            score = 40.0;
          }
        } else {
          path.add('│  │  ├─ ➔ Usia < 45 tahun');
          path.add('│  │  [Node 4D] Mengevaluasi Gaya Hidup (Aktivitas Fisik & Diet)...');
          if (!physicalActivity && !dietFruitsVeg) {
            path.add('│  │  ├─ ➔ Gaya Hidup Sedenter & Kurang Konsumsi Serat Harian');
            path.add('│  │  └─ 🎯 [LEAF] Klasifikasi: RISIKO SEDANG');
            riskLevel = 'Sedang';
            score = 38.0;
          } else {
            path.add('│  │  ├─ ➔ Gaya hidup aktif terkontrol');
            path.add('│  │  └─ 🎯 [LEAF] Klasifikasi: RISIKO RENDAH');
            riskLevel = 'Rendah';
            score = 24.0;
          }
        }
      }
      // Sub-cabang 2.3: NORMAL / UNDERWEIGHT (IMT < 23.0)
      else {
        path.add('│  ├─ ➔ Kategori IMT: NORMAL / RENDAH (< 23.0 kg/m²)');
        path.add('│  [Node 3B3] Mengevaluasi Usia Pasien ($age tahun)...');

        if (age >= 45) {
          path.add('│  │  ├─ ➔ Usia >= 45 tahun');
          path.add('│  │  [Node 4E] Cek Riwayat Keluarga...');
          if (familyDiabetesHistory == 'first_degree') {
            path.add('│  │  ├─ ➔ Memiliki riwayat keluarga tingkat 1');
            path.add('│  │  └─ 🎯 [LEAF] Klasifikasi: RISIKO SEDANG');
            riskLevel = 'Sedang';
            score = 42.0;
          } else {
            path.add('│  │  ├─ ➔ Riwayat keluarga tingkat 2 atau nihil');
            path.add('│  │  └─ 🎯 [LEAF] Klasifikasi: RISIKO RENDAH');
            riskLevel = 'Rendah';
            score = 22.0;
          }
        } else {
          path.add('│  │  ├─ ➔ Usia < 45 tahun');
          path.add('│  │  [Node 4F] Mengevaluasi Komorbid & Gejala...');
          if (classicSymptomsCount >= 2 || (hypertensionHistory && familyDiabetesHistory != 'none')) {
            path.add('│  │  ├─ ➔ Ditemukan gejala klinis atau komorbid hipertensi + riwayat keluarga');
            path.add('│  │  └─ 🎯 [LEAF] Klasifikasi: RISIKO SEDANG');
            riskLevel = 'Sedang';
            score = 36.0;
          } else {
            path.add('│  │  ├─ ➔ Profil metabolik dalam batas optimal');
            path.add('│  │  └─ 🎯 [LEAF] Klasifikasi: RISIKO RENDAH');
            riskLevel = 'Rendah';
            score = 12.0;
          }
        }
      }
    }

    // Koreksi jika ada gejala aktif yang signifikan
    if (classicSymptomsCount >= 3 && riskLevel == 'Rendah') {
      riskLevel = 'Sedang';
      score = 45.0;
      path.add('ℹ️ Penyesuaian Klinis: Ditemukan >= 3 gejala klasik diabetes, dinaikkan ke Risiko Sedang.');
    }

    // Bangun rekomendasi medis klinis, diet, dan gaya hidup
    final recommendations = _generateRecommendations(riskLevel, age, bmi, highGlucoseHistory);
    final dietRecommendations = _generateDietRecommendations(riskLevel, bmi);
    final lifestyleRecommendations = _generateLifestyleRecommendations(riskLevel, physicalActivity);

    return DecisionTreeResult(
      riskLevel: riskLevel,
      riskScore: double.parse(score.clamp(5.0, 98.0).toStringAsFixed(1)),
      bmi: bmi,
      bmiCategory: bmiCategory,
      hasCentralObesity: centralObesity,
      decisionPath: path,
      recommendations: recommendations,
      dietRecommendations: dietRecommendations,
      lifestyleRecommendations: lifestyleRecommendations,
    );
  }

  static List<String> _generateRecommendations(
      String riskLevel, int age, double bmi, bool highGlucose) {
    switch (riskLevel) {
      case 'Sangat Tinggi':
        return [
          'Segera jadwalkan konsultasi tatap muka atau telemedicine dengan Dokter Spesialis Penyakit Dalam (Sp.PD).',
          'Lakukan pemeriksaan laboratorium segera: Gula Darah Puasa (GDP), Gula Darah 2 Jam PP, dan HbA1c.',
          'Waspadai komplikasi akut diabetes jika mengalami pusing berputar, napas berbau buah/asam, atau lemas ekstrem.',
          'Jangan menunda pemeriksaan medis ke Fasilitas Kesehatan Tingkat Pertama (Puskesmas/Klinik).',
        ];
      case 'Tinggi':
        return [
          'Konsultasikan hasil skrining ini dengan dokter umum atau klinik faskes primer terdekat dalam 1-2 minggu ke depan.',
          'Lakukan tes skrining laboratorium berkala (GDP dan Tes Toleransi Glukosa Oral / TTGO).',
          'Pantau gejala khas seperti poliuria (sering kencing) dan polidipsia (sering haus).',
          'Mulai intervensi gaya hidup intensif untuk mencegah transisi dari prediabetes ke diabetes melitus tipe 2.',
        ];
      case 'Sedang':
        return [
          'Lakukan pemeriksaan gula darah berkala minimal 6 bulan hingga 1 tahun sekali.',
          'Konsultasikan dengan ahli gizi untuk rencana diet seimbang dan penurunan berat badan jika IMT di atas normal.',
          'Tingkatkan aktivitas fisik harian dan kurangi waktu duduk/sedenter.',
          'Ulangi skrining risiko diabetes di aplikasi SkrinDiab secara teratur setiap 3-6 bulan.',
        ];
      case 'Rendah':
      default:
        return [
          'Pertahankan pola hidup sehat dan berat badan ideal saat ini.',
          'Lakukan pemeriksaan kesehatan rutin (Medical Check Up) tahunan.',
          'Lakukan skrining risiko ulang di SkrinDiab minimal 1 tahun sekali atau jika ada perubahan berat badan/gaya hidup.',
          'Tetap aktif bergerak dan terapkan pola makan bergizi seimbang.',
        ];
    }
  }

  static List<String> _generateDietRecommendations(String riskLevel, double bmi) {
    final list = <String>[
      'Prinsip 3J (Jadwal, Jumlah, Jenis) sesuai pedoman PERKENI:',
      'Jadwal: Makan teratur 3 kali makan utama dan 2 kali camilan sehat pada jam yang sama.',
      'Jenis: Perbanyak karbohidrat kompleks berserat tinggi (beras merah, oat, quinoa) dan batasi karbohidrat sederhana.',
      'Hindari konsumsi minuman manis kemasan, boba, sirup, dan soda bergula.',
      'Perbanyak sayuran berdaun hijau, brokoli, wortel, dan buah utuh dengan indeks glikemik rendah (apel, pir, beri).',
    ];

    if (bmi >= 25.0) {
      list.add('Targetkan defisit kalori terukur (500 kkal/hari) untuk menurunkan 5-10% berat badan dalam 3-6 bulan.');
    }

    if (riskLevel == 'Tinggi' || riskLevel == 'Sangat Tinggi') {
      list.add('Batasi asupan garam/natrium (< 1 sendok teh per hari) dan lemak jenuh (gorengan, santan kental).');
    }

    return list;
  }

  static List<String> _generateLifestyleRecommendations(
      String riskLevel, bool physicalActivity) {
    return [
      'Aktivitas Fisik: Lakukan olahraga aerobik intensitas sedang minimal 150 menit per minggu (30 menit, 5 hari/minggu) seperti jalan cepat, senam, berenang, atau bersepeda.',
      'Latihan Beban/Resistensi: Lakukan 2-3 kali seminggu untuk meningkatkan sensitivitas insulin otot rangka.',
      'Hindari perilaku sedenter: Berdiri dan lakukan peregangan setiap 30 menit duduk terus-menerus.',
      'Tidur yang Cukup: Usahakan tidur berkualitas 7-8 jam per malam untuk menjaga regulasi hormon kortisol dan insulin.',
      'Kelola Stres: Praktikkan relaksasi pernapasan dalam, yoga, atau meditasi.',
      'Hindari merokok dan batasi paparan asap rokok secara aktif maupun pasif.',
    ];
  }
}
