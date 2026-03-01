import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/splash_screen.dart';
// import 'screens/home_screen.dart';

void main() {
  // Cek jika platform adalah Desktop (Windows, Linux, atau macOS)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Inisialisasi FFI loader
    sqfliteFfiInit();
    // Ubah factory database global ke versi FFI
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MutqinApp());
}

class MutqinApp extends StatelessWidget {
  const MutqinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mutqin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8F9FA), // Off-white yang elegan
        fontFamily: 'Quicksand', // Font yang modern dan mudah dibaca
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A4D68), // Deep Navy / Emerald
          primary: const Color(0xFF0A4D68),
          secondary: const Color(0xFFD4AF37), // Metallic Gold
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: Color(0xFF0A4D68)),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}