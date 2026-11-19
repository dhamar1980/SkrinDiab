import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/screening_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/decision_tree_service.dart';
import '../utils/theme.dart';
import 'screening_result_screen.dart';

class ScreeningFormScreen extends StatefulWidget {
  const ScreeningFormScreen({super.key});

  @override
  State<ScreeningFormScreen> createState() => _ScreeningFormScreenState();
}

class _ScreeningFormScreenState extends State<ScreeningFormScreen> {
  int _currentStep = 0;
  final _step1Key = GlobalKey<FormState>();

  // Step 1 Controllers
  final _ageController = TextEditingController(text: '42');
  final _weightController = TextEditingController(text: '70');
  final _heightController = TextEditingController(text: '168');
  final _waistController = TextEditingController(text: '86');
  String _gender = 'Laki-laki';

  // Step 2 Variables
  bool _physicalActivity = false; // >= 30 min/day
  bool _dietFruitsVeg = true; // eats daily
  bool _hypertensionHistory = false;
  bool _highGlucoseHistory = false;
  String _familyDiabetesHistory = 'none'; // 'none', 'second_degree', 'first_degree'

  // Step 3 Variables: Symptoms
  final Map<String, bool> _symptomsMap = {
    'Sering haus berlebihan (Polidipsia)': false,
    'Sering buang air kecil di malam hari (Poliuria)': false,
    'Cepat lapar dan nafsu makan meningkat (Polifagia)': false,
    'Penurunan berat badan tanpa sebab jelas': false,
    'Cepat lelah, lemas, atau sering mengantuk': false,
    'Penglihatan sering terasa buram atau kabur': false,
    'Sering kesemutan atau kebas pada tangan/kaki': false,
    'Luka goresan/lecet yang lambat sembuh': false,
  };

  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    final profile = AuthService().cachedProfile;
    if (profile != null) {
      if (profile.gender != null && profile.gender!.isNotEmpty) {
        _gender = profile.gender!;
      }
      if (profile.birthDate != null) {
        final age = DateTime.now().year - profile.birthDate!.year;
        _ageController.text = age.toString();
      }
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _waistController.dispose();
    super.dispose();
  }

  double get _currentBMI {
    final w = double.tryParse(_weightController.text) ?? 0;
    final h = double.tryParse(_heightController.text) ?? 0;
    return DecisionTreeService.calculateBMI(w, h);
  }

  String get _currentBMICategory =>
      DecisionTreeService.getBMICategory(_currentBMI);

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_step1Key.currentState!.validate()) return;
    }
    setState(() {
      _currentStep++;
    });
  }

  void _prevStep() {
    setState(() {
      if (_currentStep > 0) _currentStep--;
    });
  }

  Future<void> _processScreening() async {
    setState(() => _isAnalyzing = true);

    try {
      final age = int.tryParse(_ageController.text) ?? 30;
      final weight = double.tryParse(_weightController.text) ?? 60.0;
      final height = double.tryParse(_heightController.text) ?? 165.0;
      final waist = double.tryParse(_waistController.text) ?? 80.0;

      final selectedSymptoms = _symptomsMap.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      // 1. Eksekusi Algoritma Decision Tree
      final dtResult = DecisionTreeService.evaluateDiabetesRisk(
        age: age,
        gender: _gender,
        weight: weight,
        height: height,
        waistCircumference: waist,
        physicalActivity: _physicalActivity,
        dietFruitsVeg: _dietFruitsVeg,
        hypertensionHistory: _hypertensionHistory,
        highGlucoseHistory: _highGlucoseHistory,
        familyDiabetesHistory: _familyDiabetesHistory,
        symptoms: selectedSymptoms,
      );

      // 2. Buat Model Skrining
      final screeningId =
          'sc_${DateTime.now().millisecondsSinceEpoch}_${(1000 + DateTime.now().microsecond % 9000)}';
      final newScreening = ScreeningModel(
        id: screeningId,
        userId: AuthService().currentUserId,
        userName: AuthService().currentUserName,
        age: age,
        gender: _gender,
        weight: weight,
        height: height,
        bmi: dtResult.bmi,
        waistCircumference: waist,
        physicalActivity: _physicalActivity,
        dietFruitsVeg: _dietFruitsVeg,
        hypertensionHistory: _hypertensionHistory,
        highGlucoseHistory: _highGlucoseHistory,
        familyDiabetesHistory: _familyDiabetesHistory,
        symptoms: selectedSymptoms,
        riskLevel: dtResult.riskLevel,
        riskScore: dtResult.riskScore,
        decisionPath: dtResult.decisionPath,
        recommendations: dtResult.recommendations,
        dietRecommendations: dtResult.dietRecommendations,
        lifestyleRecommendations: dtResult.lifestyleRecommendations,
        createdAt: DateTime.now(),
      );

      // 3. Simpan ke Database Service (Supabase + Local Cache)
      await DatabaseService().saveScreening(newScreening);

      if (!mounted) return;

      // 4. Buka Layar Hasil Skrining
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ScreeningResultScreen(screening: newScreening),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kendala analisis: $e'),
          backgroundColor: AppTheme.riskHigh,
        ),
      );
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Kuesioner Skrining Diabetes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step Progress Bar
            _buildStepIndicator(),

            // Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18.0, vertical: 14.0),
                child: _buildCurrentStepContent(),
              ),
            ),

            // Bottom Navigation Buttons
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          _buildStepNode(0, 'Antropometri', Icons.fitness_center_rounded),
          _buildStepDivider(0),
          _buildStepNode(1, 'Gaya Hidup', Icons.favorite_border_rounded),
          _buildStepDivider(1),
          _buildStepNode(2, 'Gejala Klinis', Icons.medical_services_outlined),
        ],
      ),
    );
  }

  Widget _buildStepNode(int index, String title, IconData icon) {
    final isActive = _currentStep == index;
    final isDone = _currentStep > index;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDone
                  ? AppTheme.accentColor
                  : (isActive ? AppTheme.primaryColor : const Color(0xFFE2E8F0)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDone ? Icons.check : icon,
              size: 18,
              color: isActive || isDone ? Colors.white : AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? AppTheme.primaryColor : AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepDivider(int index) {
    final isDone = _currentStep > index;
    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: isDone ? AppTheme.accentColor : const Color(0xFFE2E8F0),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Antropometri();
      case 1:
        return _buildStep2Lifestyle();
      case 2:
        return _buildStep3Symptoms();
      default:
        return const SizedBox.shrink();
    }
  }

  // ================= STEP 1: ANTROPOMETRI =================
  Widget _buildStep1Antropometri() {
    return Form(
      key: _step1Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader(
            'Data Fisik & Antropometri',
            'Parameter fisik digunakan untuk menghitung Indeks Massa Tubuh (IMT) dan risiko obesitas sentral.',
          ),
          const SizedBox(height: 14),

          // Card Gender
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jenis Kelamin Pasien',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildGenderChoice('Laki-laki', Icons.male_rounded),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child:
                            _buildGenderChoice('Perempuan', Icons.female_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Usia
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Usia Pasien (Tahun)',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Risiko naik di usia >= 45',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.poppins(fontSize: 15),
                    decoration: const InputDecoration(
                      hintText: 'Contoh: 45',
                      suffixText: 'Tahun',
                      prefixIcon: Icon(
                        Icons.cake_outlined,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    validator: (val) {
                      final n = int.tryParse(val ?? '');
                      if (n == null || n < 5 || n > 120) {
                        return 'Masukkan usia yang valid (5-120 tahun)';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Berat Badan & Tinggi Badan
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Berat & Tinggi Badan',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _weightController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          style: GoogleFonts.poppins(fontSize: 14),
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Berat Badan',
                            suffixText: 'kg',
                          ),
                          validator: (val) {
                            final n = double.tryParse(val ?? '');
                            if (n == null || n < 20 || n > 300) {
                              return 'BB 20-300 kg';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _heightController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          style: GoogleFonts.poppins(fontSize: 14),
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Tinggi Badan',
                            suffixText: 'cm',
                          ),
                          validator: (val) {
                            final n = double.tryParse(val ?? '');
                            if (n == null || n < 60 || n > 250) {
                              return 'TB 60-250 cm';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Live BMI Preview Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.speed_rounded,
                              size: 18,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'IMT: $_currentBMI kg/m²',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _currentBMICategory,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _currentBMI >= 25.0
                                ? AppTheme.riskHigh
                                : (_currentBMI >= 23.0
                                    ? AppTheme.riskModerate
                                    : AppTheme.riskLow),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Lingkar Pinggang
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Lingkar Pinggang',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _gender == 'Laki-laki'
                            ? 'Normal: < 90 cm'
                            : 'Normal: < 80 cm',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _waistController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.poppins(fontSize: 15),
                    decoration: const InputDecoration(
                      hintText: 'Contoh: 85',
                      suffixText: 'cm',
                      prefixIcon: Icon(
                        Icons.straighten_rounded,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    validator: (val) {
                      final n = double.tryParse(val ?? '');
                      if (n == null || n < 30 || n > 250) {
                        return 'Lingkar pinggang tidak valid (30-250 cm)';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderChoice(String label, IconData icon) {
    final isSelected = _gender == label;
    return InkWell(
      onTap: () => setState(() => _gender = label),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= STEP 2: GAYA HIDUP & RIWAYAT =================
  Widget _buildStep2Lifestyle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          'Gaya Hidup & Riwayat Medis',
          'Faktor lingkungan dan genetik merupakan cabang penting dalam penentuan simpul Decision Tree.',
        ),
        const SizedBox(height: 14),

        // Aktivitas Fisik
        _buildSwitchCard(
          title: 'Aktivitas Fisik Rutin (>= 30 menit/hari)',
          subtitle:
              'Melakukan jalan cepat, olahraga aerobik, atau kerja fisik aktif minimal 30 menit setiap hari.',
          value: _physicalActivity,
          icon: Icons.directions_run_rounded,
          onChanged: (val) => setState(() => _physicalActivity = val),
        ),
        const SizedBox(height: 12),

        // Konsumsi Sayur & Buah
        _buildSwitchCard(
          title: 'Konsumsi Buah & Sayur Setiap Hari',
          subtitle:
              'Mengkonsumsi minimal 2-3 porsi sayuran atau buah-buahan segar setiap hari.',
          value: _dietFruitsVeg,
          icon: Icons.eco_outlined,
          onChanged: (val) => setState(() => _dietFruitsVeg = val),
        ),
        const SizedBox(height: 12),

        // Riwayat Hipertensi
        _buildSwitchCard(
          title: 'Riwayat Hipertensi / Tekanan Darah Tinggi',
          subtitle:
              'Pernah didiagnosis tekanan darah >= 140/90 mmHg atau mengonsumsi obat antihipertensi secara rutin.',
          value: _hypertensionHistory,
          icon: Icons.monitor_heart_outlined,
          onChanged: (val) => setState(() => _hypertensionHistory = val),
        ),
        const SizedBox(height: 12),

        // Riwayat Gula Darah Tinggi
        _buildSwitchCard(
          title: 'Pernah Memiliki Riwayat Gula Darah Tinggi',
          subtitle:
              'Pernah ditemukan gula darah di atas normal saat MCU, sakit, atau selama masa kehamilan (Gestasional).',
          value: _highGlucoseHistory,
          icon: Icons.bloodtype_outlined,
          onChanged: (val) => setState(() => _highGlucoseHistory = val),
        ),
        const SizedBox(height: 12),

        // Riwayat Keluarga
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.family_restroom_rounded,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Riwayat Diabetes dalam Keluarga',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Apakah ada anggota keluarga sedarah yang menderita diabetes?',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildFamilyRadio(
                  value: 'none',
                  label: 'Tidak ada riwayat keluarga',
                  subLabel: 'Tidak ada keluarga kandung yang didiagnosis diabetes',
                ),
                _buildFamilyRadio(
                  value: 'second_degree',
                  label: 'Keluarga Tingkat Dua',
                  subLabel: 'Kakek, nenek, paman, bibi, atau sepupu',
                ),
                _buildFamilyRadio(
                  value: 'first_degree',
                  label: 'Keluarga Tingkat Pertama (Risiko Tinggi)',
                  subLabel: 'Orang tua kandung, saudara kandung, atau anak kandung',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchCard({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: value
                ? AppTheme.primaryColor.withOpacity(0.12)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: value ? AppTheme.primaryColor : AppTheme.textMuted,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
        activeColor: AppTheme.primaryColor,
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildFamilyRadio({
    required String value,
    required String label,
    required String subLabel,
  }) {
    final isSelected = _familyDiabetesHistory == value;
    return InkWell(
      onTap: () => setState(() => _familyDiabetesHistory = value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _familyDiabetesHistory,
              activeColor: AppTheme.primaryColor,
              onChanged: (val) =>
                  setState(() => _familyDiabetesHistory = val ?? 'none'),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= STEP 3: GEJALA KLINIS =================
  Widget _buildStep3Symptoms() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          'Evaluasi Gejala Klinis (4P & Penyerta)',
          'Pilih gejala yang Anda rasakan dalam beberapa minggu terakhir. Ini adalah data masukan simpul akhir algoritma Decision Tree.',
        ),
        const SizedBox(height: 14),

        // Info Gejala
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Jika tidak merasakan salah satu gejala di bawah, Anda dapat melewatinya dan langsung menekan tombol Analisis.',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: _symptomsMap.keys.map((symptom) {
                final isChecked = _symptomsMap[symptom] ?? false;
                return CheckboxListTile(
                  title: Text(
                    symptom,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: isChecked ? FontWeight.w600 : FontWeight.normal,
                      color: isChecked
                          ? AppTheme.primaryColor
                          : AppTheme.textPrimary,
                    ),
                  ),
                  value: isChecked,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (val) {
                    setState(() {
                      _symptomsMap[symptom] = val ?? false;
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppTheme.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: _isAnalyzing ? null : _prevStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                child: Text(
                  'Kembali',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isAnalyzing
                  ? null
                  : (_currentStep == 2 ? _processScreening : _nextStep),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isAnalyzing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentStep == 2
                              ? 'Analisis Decision Tree'
                              : 'Lanjut',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          _currentStep == 2
                              ? Icons.insights_rounded
                              : Icons.arrow_forward_rounded,
                          size: 18,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
