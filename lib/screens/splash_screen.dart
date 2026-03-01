import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _statusText = 'Menyiapkan Data...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  // Fungsi untuk menjalankan inisialisasi di latar belakang
  Future<void> _initializeApp() async {
    try {
      // 1. Inisialisasi Database dan jalankan Seeding (Parsing JSON)
      setState(() {
        _statusText = 'Menyiapkan Mushaf Al-Qur\'an...';
      });
      await DatabaseHelper.instance.database; // Memastikan DB terbuat
      await DatabaseHelper.instance.seedDatabase(); // Memasukkan JSON jika DB kosong

      // Beri sedikit jeda agar transisi lebih halus (opsional)
      await Future.delayed(const Duration(seconds: 1));

      // 2. Pindah ke HomeScreen dan hapus SplashScreen dari tumpukan navigasi
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      // Jika terjadi error (misal file JSON tidak ditemukan)
      setState(() {
        _statusText = 'Terjadi kesalahan saat memuat data.';
      });
      debugPrint('Error init database: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Menggunakan background navy premium kita
      backgroundColor: const Color(0xFF0A4D68),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Aplikasi (Sementara menggunakan Icon, nanti bisa diganti gambar/logo asli)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 80,
                color: Color(0xFFD4AF37), // Warna Emas (Gold)
              ),
            ),
            const SizedBox(height: 24),
            
            // Nama Aplikasi
            const Text(
              'MUTQIN',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            
            // Tagline
            const Text(
              'Aplikasi Hafalan Al-Qur\'an',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 48),
            
            // Loading Indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
            ),
            const SizedBox(height: 16),
            
            // Teks Status (Berubah sesuai proses)
            Text(
              _statusText,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}