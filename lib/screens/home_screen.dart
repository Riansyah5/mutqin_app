import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/surah_model.dart';
import 'surah_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Fungsi untuk me-refresh halaman saat kembali dari Detail Surah
  void _refreshData() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assalamu\'alaikum,',
              style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
            Text(
              'Hamba Allah',
              style: TextStyle(fontSize: 20, color: Color(0xFF0A4D68), fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF0A4D68)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPremiumProgressCard(context),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'Surah',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0A4D68)),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _buildSurahList(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // --- KARTU PROGRES DINAMIS ---
  Widget _buildPremiumProgressCard(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: DatabaseHelper.instance.getHafalanStats(),
      builder: (context, snapshot) {
        int mutqin = 0;
        int proses = 0;
        double persentase = 0.0;

        if (snapshot.hasData) {
          mutqin = snapshot.data!['mutqin'];
          proses = snapshot.data!['proses'];
          persentase = snapshot.data!['persentase'];
        }

        // Format persentase ke dalam string (misal: 15.5%)
        String teksPersen = (persentase * 100).toStringAsFixed(1);
        if (teksPersen.endsWith('.0')) {
          teksPersen = teksPersen.substring(0, teksPersen.length - 2); // Hilangkan .0 jika genap
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A4D68), Color(0xFF088395)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF088395).withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.pie_chart_rounded, color: Colors.white70, size: 20),
                      SizedBox(width: 8),
                      Text('Progres Hafalan', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$mutqin Ayat',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '+$proses Sedang Dihafal',
                    style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: CircularProgressIndicator(
                      value: persentase, // Menggunakan nilai riil dari database (0.0 - 1.0)
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                      strokeWidth: 6,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Text(
                    '$teksPersen%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  // --- DAFTAR SURAH ---
  Widget _buildSurahList() {
    return FutureBuilder<List<Surah>>(
      future: DatabaseHelper.instance.getAllSurah(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF0A4D68)));
        } else if (snapshot.hasError) {
          return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Data Surah tidak ditemukan.'));
        }

        final List<Surah> surahs = snapshot.data!;

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: surahs.length,
          separatorBuilder: (context, index) => Divider(
            color: Colors.grey.withOpacity(0.2),
            indent: 24,
            endIndent: 24,
            height: 1,
          ),
          itemBuilder: (context, index) {
            final surah = surahs[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              leading: _buildSurahNumberOrnamen(surah.id),
              title: Text(
                surah.namaLatin,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D2D2D)),
              ),
              subtitle: Text(
                '${surah.tempatTurun} • ${surah.jumlahAyat} Ayat',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              trailing: Text(
                surah.namaArab,
                style: const TextStyle(fontFamily: 'KFGQPC', fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0A4D68)),
                textAlign: TextAlign.right,
              ),
              onTap: () async {
                // Menunggu user kembali dari layar Detail
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SurahDetailScreen(
                      surahId: surah.id,
                      surahName: surah.namaLatin,
                      surahArab: surah.namaArab,
                    ),
                  ),
                );
                // Refresh layar Home agar persentase terbaru muncul
                _refreshData();
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSurahNumberOrnamen(int number) {
    return SizedBox(
      width: 45,
      height: 45,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: 0.785398,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4F8),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Text(number.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A4D68))),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF0A4D68),
      unselectedItemColor: Colors.grey.withOpacity(0.6),
      showSelectedLabels: true,
      showUnselectedLabels: true,
      elevation: 20,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'Mushaf'),
        BottomNavigationBarItem(icon: Icon(Icons.pie_chart_rounded), label: 'Hafalan'),
        BottomNavigationBarItem(icon: Icon(Icons.bookmark_rounded), label: 'Markah'),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
      ],
    );
  }
}