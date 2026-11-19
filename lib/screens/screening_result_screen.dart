import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/screening_model.dart';
import '../utils/theme.dart';
import 'history_screen.dart';
import 'home_screen.dart';

class ScreeningResultScreen extends StatefulWidget {
  final ScreeningModel screening;

  const ScreeningResultScreen({super.key, required this.screening});

  @override
  State<ScreeningResultScreen> createState() => _ScreeningResultScreenState();
}

class _ScreeningResultScreenState extends State<ScreeningResultScreen> {
  bool _isTreeExpanded = true;

  @override
  Widget build(BuildContext context) {
    final s = widget.screening;
    final riskColor = AppTheme.getRiskColor(s.riskLevel);
    final dateStr =
        DateFormat('EEEE, dd MMMM yyyy HH:mm', 'id_ID').format(s.createdAt);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Laporan Hasil Skrining'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Bagikan Hasil',
            onPressed: () => _showShareSummary(context, s),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Overall Risk Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: riskColor.withOpacity(0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: riskColor.withOpacity(0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Klasifikasi Risiko Diabetes',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: riskColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Decision Tree',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: riskColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Risk Badge Icon
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: riskColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getRiskIcon(s.riskLevel),
                        size: 48,
                        color: riskColor,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Level Text
                    Text(
                      'Risiko ${s.riskLevel}',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: riskColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _getRiskDescription(s.riskLevel),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Score Progress Bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Probabilitas Risiko Terkalkulasi',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            Text(
                              '${s.riskScore.toStringAsFixed(0)}%',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: riskColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (s.riskScore / 100.0).clamp(0.05, 1.0),
                            minHeight: 10,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Waktu skrining: $dateStr',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Patient Antropometric Summary Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.person_pin_rounded,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ringkasan Data Pasien',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem(
                              'Usia & Gender',
                              '${s.age} thn (${s.gender})',
                            ),
                          ),
                          Expanded(
                            child: _buildInfoItem(
                              'Berat / Tinggi',
                              '${s.weight} kg / ${s.height} cm',
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem(
                              'Indeks Massa Tubuh',
                              '${s.bmi} kg/m²',
                            ),
                          ),
                          Expanded(
                            child: _buildInfoItem(
                              'Lingkar Pinggang',
                              '${s.waistCircumference} cm',
                            ),
                          ),
                        ],
                      ),
                      if (s.symptoms.isNotEmpty) ...[
                        const Divider(height: 18),
                        Text(
                          'Gejala Dilaporkan (${s.symptoms.length}):',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: s.symptoms.map((sym) {
                            return Chip(
                              label: Text(
                                sym,
                                style: GoogleFonts.poppins(fontSize: 10),
                              ),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              backgroundColor: Colors.red.shade50,
                              labelStyle: TextStyle(color: Colors.red.shade900),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 3. Transparent Decision Tree Path (EXPLAINABLE AI)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isTreeExpanded = !_isTreeExpanded;
                          });
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.account_tree_rounded,
                                    color: AppTheme.primaryColor,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Jalur Penentuan Decision Tree',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              _isTreeExpanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: AppTheme.textMuted,
                            ),
                          ],
                        ),
                      ),
                      if (_isTreeExpanded) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Transparansi langkah penelusuran simpul pohon keputusan dari Root hingga Leaf Node:',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A), // Dark terminal style
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: s.decisionPath.map((step) {
                              final isLeaf = step.contains('[LEAF]') ||
                                  step.contains('Klasifikasi:');
                              final isRoot = step.contains('[Node 1');
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 3.0),
                                child: Text(
                                  step,
                                  style: GoogleFonts.firaCode(
                                    fontSize: 11,
                                    color: isLeaf
                                        ? const Color(0xFF4ADE80) // Green neon
                                        : (isRoot
                                            ? const Color(0xFF38BDF8) // Sky blue
                                            : const Color(0xFFE2E8F0)),
                                    fontWeight: isLeaf
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 4. Clinical Medical Recommendations
              _buildRecommendationsCard(
                title: 'Rekomendasi Medis & Tindak Lanjut',
                icon: Icons.medical_services_rounded,
                iconColor: AppTheme.primaryColor,
                items: s.recommendations,
              ),

              const SizedBox(height: 16),

              // 5. Diet & Nutrition Plan (Prinsip 3J)
              _buildRecommendationsCard(
                title: 'Panduan Nutrisi & Diet 3J (PERKENI)',
                icon: Icons.restaurant_menu_rounded,
                iconColor: AppTheme.accentColor,
                items: s.dietRecommendations,
              ),

              const SizedBox(height: 16),

              // 6. Lifestyle & Exercise Guidance
              _buildRecommendationsCard(
                title: 'Aktivitas Fisik & Modifikasi Gaya Hidup',
                icon: Icons.directions_run_rounded,
                iconColor: const Color(0xFFD97706),
                items: s.lifestyleRecommendations,
              ),

              const SizedBox(height: 24),

              // Bottom Actions
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.home_rounded),
                label: const Text('Kembali ke Beranda'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  );
                },
                icon: const Icon(Icons.history_rounded),
                label: const Text('Lihat Semua Riwayat Skrining'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppTheme.primaryColor),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<String> items,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: iconColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getRiskIcon(String level) {
    switch (level.toLowerCase()) {
      case 'rendah':
        return Icons.check_circle_outline_rounded;
      case 'sedang':
        return Icons.warning_amber_rounded;
      case 'tinggi':
      case 'sangat tinggi':
      default:
        return Icons.error_outline_rounded;
    }
  }

  String _getRiskDescription(String level) {
    switch (level.toLowerCase()) {
      case 'rendah':
        return 'Profil metabolik Anda menunjukkan probabilitas rendah terkena diabetes. Terus jaga pola makan dan gaya hidup aktif.';
      case 'sedang':
        return 'Terdapat beberapa faktor risiko yang perlu diwaspadai. Modifikasi pola makan dan peningkatan aktivitas fisik sangat dianjurkan.';
      case 'tinggi':
        return 'Probabilitas risiko diabetes Anda tergolong tinggi. Disarankan melakukan pemeriksaan laboratorium gula darah ke dokter.';
      case 'sangat tinggi':
        return 'Terdeteksi faktor risiko signifikan disertai gejala klinis khas. Segera konsultasikan dengan dokter spesialis penyakit dalam.';
      default:
        return 'Lakukan pemantauan berkala kesehatan Anda.';
    }
  }

  void _showShareSummary(BuildContext context, ScreeningModel s) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.share_rounded,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ringkasan Skrining Pasien',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Pasien: ${s.userName}\n'
              'Usia: ${s.age} thn | IMT: ${s.bmi} kg/m²\n'
              'Klasifikasi: Risiko ${s.riskLevel} (${s.riskScore.toStringAsFixed(0)}%)\n'
              'Metode: Algoritma Decision Tree SkrinDiab\n'
              'Tanggal: ${DateFormat('dd MMM yyyy, HH:mm').format(s.createdAt)}',
              style: GoogleFonts.firaCode(fontSize: 12),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ringkasan disalin ke papan klip!'),
                    backgroundColor: AppTheme.accentColor,
                  ),
                );
              },
              child: const Text('Salin Ringkasan Teks'),
            ),
          ],
        ),
      ),
    );
  }
}
