import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';
import '../models/user_model.dart';
import 'database_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  bool _isGuestMode = false;
  UserModel? _cachedProfile;

  bool get isGuest => _isGuestMode;

  User? get currentUser => SupabaseConfig.client.auth.currentUser;

  bool get isAuthenticated => currentUser != null || _isGuestMode;

  String get currentUserId {
    if (_isGuestMode) return 'guest_user_id';
    return currentUser?.id ?? '';
  }

  String get currentUserEmail {
    if (_isGuestMode) return 'tamu@skrindiab.id';
    return currentUser?.email ?? '';
  }

  String get currentUserName {
    if (_isGuestMode) return 'Pengguna Tamu';
    if (_cachedProfile != null && _cachedProfile!.fullName.isNotEmpty) {
      return _cachedProfile!.fullName;
    }
    final metaName = currentUser?.userMetadata?['full_name']?.toString();
    if (metaName != null && metaName.isNotEmpty) return metaName;
    if (currentUser?.email != null) {
      return currentUser!.email!.split('@').first;
    }
    return 'Pasien SkrinDiab';
  }

  UserModel? get cachedProfile => _cachedProfile;

  /// Inisialisasi status sesi saat app dibuka
  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _isGuestMode = prefs.getBool('is_guest_mode') ?? false;

    if (!_isGuestMode && currentUser != null) {
      try {
        _cachedProfile = await DatabaseService().getUserProfile(currentUser!.id);
      } catch (e) {
        debugPrint('Could not load user profile: $e');
      }
    }
  }

  /// Pendaftaran Akun Baru
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? gender,
    DateTime? birthDate,
  }) async {
    _isGuestMode = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_guest_mode', false);

    try {
      final response = await SupabaseConfig.client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          'phone': phone?.trim(),
          'gender': gender,
        },
      );

      final user = response.user;
      if (user != null) {
        final newUserModel = UserModel(
          id: user.id,
          email: email.trim(),
          fullName: fullName.trim(),
          gender: gender,
          phone: phone?.trim(),
          birthDate: birthDate,
          createdAt: DateTime.now(),
        );

        _cachedProfile = newUserModel;

        // Simpan ke database users
        try {
          await DatabaseService().saveUserProfile(newUserModel);
        } catch (dbError) {
          debugPrint('Notice on saving user profile to DB: $dbError');
        }
      }

      return response;
    } on AuthException catch (e) {
      throw _mapAuthError(e.message);
    } catch (e) {
      throw 'Terjadi kesalahan saat pendaftaran: ${e.toString()}';
    }
  }

  /// Masuk dengan Akun Terdaftar
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    _isGuestMode = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_guest_mode', false);

    try {
      final response = await SupabaseConfig.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user != null) {
        try {
          _cachedProfile = await DatabaseService().getUserProfile(response.user!.id);
        } catch (e) {
          debugPrint('Notice on fetching profile: $e');
        }
      }

      return response;
    } on AuthException catch (e) {
      throw _mapAuthError(e.message);
    } catch (e) {
      throw 'Gagal masuk: ${e.toString()}';
    }
  }

  /// Mode Tamu / Demo untuk pengujian cepat tanpa register
  Future<void> signInAsGuest() async {
    _isGuestMode = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_guest_mode', true);

    _cachedProfile = UserModel(
      id: 'guest_user_id',
      email: 'tamu@skrindiab.id',
      fullName: 'Pengguna Tamu',
      gender: 'Laki-laki',
      phone: '081234567890',
      birthDate: DateTime(1985, 5, 20),
      createdAt: DateTime.now(),
    );
  }

  /// Keluar / Logout
  Future<void> signOut() async {
    _isGuestMode = false;
    _cachedProfile = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_guest_mode');

    try {
      await SupabaseConfig.client.auth.signOut();
    } catch (e) {
      debugPrint('Signout notice: $e');
    }
  }

  /// Terjemahan pesan error Supabase ke Bahasa Indonesia yang ramah pengguna
  String _mapAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials')) {
      return 'Email atau kata sandi salah. Silakan periksa kembali.';
    } else if (lower.contains('user already registered') ||
        lower.contains('already exists')) {
      return 'Email ini sudah terdaftar. Silakan langsung masuk atau gunakan email lain.';
    } else if (lower.contains('password should be at least')) {
      return 'Kata sandi minimal harus terdiri dari 6 karakter.';
    } else if (lower.contains('email not confirmed')) {
      return 'Email Anda belum dikonfirmasi. Periksa kotak masuk atau spam email Anda.';
    } else if (lower.contains('network') || lower.contains('timeout')) {
      return 'Koneksi internet bermasalah. Periksa jaringan Anda dan coba lagi.';
    }
    return message;
  }
}
