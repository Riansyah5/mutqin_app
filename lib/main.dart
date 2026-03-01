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
        scaffoldBackgroundColor: const Color(0xFFFDFDFD), // Clean White
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF12372A), // Aesthetic Forest Green
          primary: const Color(0xFF12372A),
          secondary: const Color(0xFFC5A880), // Muted Gold / Sand
        ),
      ),
      home: const SplashScreen(),
    );
  }
}