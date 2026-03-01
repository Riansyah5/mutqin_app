import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/ayah_model.dart';
import '../services/audio_manager.dart'; // <--- Tambahkan baris ini

class SurahDetailScreen extends StatefulWidget {
  final int surahId;
  final String surahName;
  final String surahArab;

  const SurahDetailScreen({
    super.key,
    required this.surahId,
    required this.surahName,
    required this.surahArab,
  });

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  late Future<List<Ayah>> _ayahsFuture;

  @override
  void initState() {
    super.initState();
    _loadAyahs(); // Memuat data ayat saat layar pertama kali dibuka
  }

  // Fungsi untuk mengambil data dari SQLite
  void _loadAyahs() {
    _ayahsFuture = DatabaseHelper.instance.getAyahsBySurah(widget.surahId);
  }

  // Fungsi untuk mengubah status hafalan (0: Belum, 1: Proses, 2: Lancar)
  Future<void> _toggleHafalanStatus(Ayah ayat) async {
    int nextStatus = (ayat.statusHafalan + 1) % 3; // Siklus: 0 -> 1 -> 2 -> 0
    await DatabaseHelper.instance.updateStatusHafalan(ayat.id, nextStatus);
    
    // Perbarui UI setelah data di database berubah
    setState(() {
      _loadAyahs();
    });
    
    // Tampilkan pesan kecil (Snackbar)
    if (!mounted) return;
    String pesan = nextStatus == 2 ? 'Alhamdulillah, ayat ditandai Lancar' 
                 : nextStatus == 1 ? 'Ayat ditandai Sedang Dihafal' 
                 : 'Tanda hafalan dihapus';
                 
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        duration: const Duration(seconds: 1),
        backgroundColor: nextStatus == 2 ? Colors.green : const Color(0xFF088395),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.surahName,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A4D68)),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF0A4D68)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSurahHeader(),
          Expanded(
            child: _buildAyatList(),
          ),
        ],
      ),
    );
  }

  // Header Surah (Bismillah)
  Widget _buildSurahHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A4D68), Color(0xFF088395)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF088395).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            widget.surahArab, // Diambil dari database
            style: const TextStyle(
              fontFamily: 'KFGQPC',
              fontSize: 32,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // Bismillah hanya tampil jika bukan Surah At-Taubah (ID 9)
          if (widget.surahId != 9) ...[
            const Divider(color: Colors.white24, thickness: 1, height: 30),
            const Text(
              'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
              style: TextStyle(
                fontFamily: 'KFGQPC',
                fontSize: 28,
                color: Colors.white,
              ),
            ),
          ]
        ],
      ),
    );
  }

  // Daftar Ayat menggunakan FutureBuilder
  Widget _buildAyatList() {
    return FutureBuilder<List<Ayah>>(
      future: _ayahsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF0A4D68)));
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Ayat tidak ditemukan.'));
        }

        final List<Ayah> ayahs = snapshot.data!;

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: ayahs.length,
          separatorBuilder: (context, index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: Colors.grey.withOpacity(0.2)),
          ),
          itemBuilder: (context, index) {
            return _buildAyatItem(ayahs[index]);
          },
        );
      },
    );
  }

  // UI per Ayat
  Widget _buildAyatItem(Ayah ayat) {
    // Menentukan warna dan ikon berdasarkan status hafalan
    Color statusColor;
    IconData statusIcon;
    
    if (ayat.statusHafalan == 2) {
      statusColor = Colors.green; // Mutqin / Lancar
      statusIcon = Icons.check_circle;
    } else if (ayat.statusHafalan == 1) {
      statusColor = const Color(0xFFD4AF37); // Gold - Proses Menghafal
      statusIcon = Icons.timelapse;
    } else {
      statusColor = Colors.grey; // Belum dihafal
      statusIcon = Icons.check_circle_outline;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Baris Aksi (Nomor Ayat & Tombol Interaksi)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    ayat.nomorAyat.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A4D68)),
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.play_circle_outline, color: Color(0xFF088395)),
                    onPressed: () async {
                      // Menampilkan pesan bahwa audio sedang diproses
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Memuat murottal...'),
                          duration: Duration(milliseconds: 1000),
                        ),
                      );

                      try {
                        // Memanggil AudioManager
                        await AudioManager.instance.playAyahAudio(
                          widget.surahId, 
                          ayat.nomorAyat
                        );
                      } catch (e) {
                        // Tampilkan error jika gagal download/putar
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Gagal memutar audio. Cek koneksi internet Anda.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(statusIcon, color: statusColor),
                    onPressed: () => _toggleHafalanStatus(ayat),
                    tooltip: 'Tandai Hafalan',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Teks Arab
          Text(
            ayat.teksArab,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontFamily: 'KFGQPC',
              fontSize: 28,
              height: 1.8,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 16),
          
          // Teks Terjemahan
          Text(
            ayat.terjemahan,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF5A5A5A),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}