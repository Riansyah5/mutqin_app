import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'home_screen.dart';
import 'quiz_screen.dart'; // Placeholder untuk halaman Hafalan

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Daftar halaman untuk setiap menu tab
  final List<Widget> _screens = [
    const HomeScreen(),
    const QuizScreen(),  // Placeholder untuk halaman Hafalan, Markah, dan Profil
    const Center(child: Text('Halaman Markah', style: TextStyle(fontFamily: 'Poppins'))),  // Placeholder
    const Center(child: Text('Halaman Profil', style: TextStyle(fontFamily: 'Poppins'))),   // Placeholder
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD), // Off-white super bersih
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withOpacity(0.05), // Shadow sangat halus
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: GNav(
              rippleColor: Colors.grey[300]!,
              hoverColor: Colors.grey[100]!,
              gap: 8, // Jarak ikon ke teks
              activeColor: const Color(0xFF12372A), // Forest Green
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400), // Animasi super smooth
              tabBackgroundColor: const Color(0xFF12372A).withOpacity(0.08), // Latar pill-shape saat aktif
              color: Colors.grey.withOpacity(0.6), // Warna ikon saat tidak aktif
              tabs: const [
                GButton(icon: LucideIcons.bookOpen, text: 'Mushaf'),
                GButton(icon: LucideIcons.target, text: 'Hafalan'),
                GButton(icon: LucideIcons.bookmark, text: 'Markah'),
                GButton(icon: LucideIcons.user, text: 'Profil'),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}