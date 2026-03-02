import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../database/database_helper.dart';
import '../models/ayah_model.dart';
import '../services/audio_manager.dart';

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
  // 1. Ganti Future dengan List biasa agar UI bisa di-update secara instan
  List<Ayah> _ayahs = [];
  bool _isLoading = true;
  
  // State untuk Audio Player
  int? _playingAyahNumber;
  LoopMode _currentLoopMode = LoopMode.off;

  @override
  void initState() {
    super.initState();
    _loadAyahsData();
  }

  // Muat data sekali saat layar dibuka
  Future<void> _loadAyahsData() async {
    final data = await DatabaseHelper.instance.getAyahsBySurah(widget.surahId);
    setState(() {
      _ayahs = data;
      _isLoading = false;
    });
  }

  // Fungsi Update Markah secara Instan
  Future<void> _toggleBookmarkStatus(int index) async {
    final ayat = _ayahs[index];
    int nextStatus = ayat.isBookmarked == 1 ? 0 : 1;
    
    // Update ke UI langsung (Instan)
    setState(() {
      _ayahs[index] = Ayah(
        id: ayat.id, surahId: ayat.surahId, nomorAyat: ayat.nomorAyat,
        juz: ayat.juz, teksArab: ayat.teksArab, teksLatin: ayat.teksLatin,
        terjemahan: ayat.terjemahan, statusHafalan: ayat.statusHafalan,
        isBookmarked: nextStatus, // Nilai baru
      );
    });

    // Simpan ke SQLite di latar belakang
    await DatabaseHelper.instance.toggleBookmark(ayat.id, nextStatus, nextStatus == 1 ? 1 : 0); // Update status bookmark di database

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(nextStatus == 1 ? 'Ayat ditambahkan ke Markah' : 'Markah dihapus'),
        duration: const Duration(milliseconds: 1000),
        backgroundColor: nextStatus == 1 ? const Color(0xFFC5A880) : const Color(0xFF12372A),
      ));
    }
  }

  // Fungsi Update Hafalan secara Instan
  Future<void> _toggleHafalanStatus(int index) async {
    final ayat = _ayahs[index];
    int nextStatus = (ayat.statusHafalan + 1) % 3;
    
    // Update ke UI langsung
    setState(() {
      _ayahs[index] = Ayah(
        id: ayat.id, surahId: ayat.surahId, nomorAyat: ayat.nomorAyat,
        juz: ayat.juz, teksArab: ayat.teksArab, teksLatin: ayat.teksLatin,
        terjemahan: ayat.terjemahan, statusHafalan: nextStatus, // Nilai baru
        isBookmarked: ayat.isBookmarked, 
      );
    });

    // Simpan ke SQLite
    await DatabaseHelper.instance.updateStatusHafalan(ayat.id, nextStatus);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      appBar: AppBar(
        title: Text(widget.surahName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF12372A))),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF12372A)))
          : Column(
              children: [
                _buildSurahHeader(),
                Expanded(child: _buildAyatList()),
              ],
            ),
      bottomNavigationBar: _playingAyahNumber != null ? _buildMiniAudioPlayer() : null,
    );
  }

  Widget _buildSurahHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF12372A), Color(0xFF1A4D3E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF12372A).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Text(widget.surahArab, style: const TextStyle(fontFamily: 'Amiri', fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
          if (widget.surahId != 9) ...[
            const SizedBox(height: 8),
            const Divider(color: Colors.white24, thickness: 1, height: 30),
            const Text('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ', style: TextStyle(fontFamily: 'Amiri', fontSize: 28, color: Colors.white)),
          ]
        ],
      ),
    );
  }

  Widget _buildAyatList() {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: _ayahs.length,
      separatorBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Divider(color: Colors.grey.withOpacity(0.2)),
      ),
      itemBuilder: (context, index) {
        return _buildAyatItem(index, _ayahs[index]);
      },
    );
  }

  Widget _buildAyatItem(int index, Ayah ayat) {
    // Menentukan warna hafalan
    Color statusColor = ayat.statusHafalan == 2 ? Colors.green : (ayat.statusHafalan == 1 ? const Color(0xFFC5A880) : Colors.grey);
    IconData statusIcon = ayat.statusHafalan == 2 ? Icons.check_circle : (ayat.statusHafalan == 1 ? Icons.timelapse : Icons.check_circle_outline);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 35, height: 35,
                decoration: BoxDecoration(color: const Color(0xFFF0F4F8), borderRadius: BorderRadius.circular(20)),
                child: Center(child: Text(ayat.nomorAyat.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF12372A)))),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(_playingAyahNumber == ayat.nomorAyat ? Icons.volume_up : Icons.play_circle_outline, 
                    color: _playingAyahNumber == ayat.nomorAyat ? const Color(0xFFC5A880) : const Color(0xFF1A4D3E)),
                    onPressed: () async {
                      setState(() { _playingAyahNumber = ayat.nomorAyat; });
                      try {
                        await AudioManager.instance.playAyahAudio(widget.surahId, ayat.nomorAyat, loopMode: _currentLoopMode);
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal memutar audio.'), backgroundColor: Colors.red));
                      }
                    },
                  ),
                  // TOMBOL MARKAH YANG SUDAH INSTAN
                  IconButton(
                    icon: Icon(
                      ayat.isBookmarked == 1 ? Icons.bookmark : Icons.bookmark_border, 
                      color: ayat.isBookmarked == 1 ? const Color(0xFFC5A880) : const Color(0xFF1A4D3E), // Gold jika ditandai
                      size: 26,
                    ),
                    onPressed: () => _toggleBookmarkStatus(index),
                  ),
                  IconButton(
                    icon: Icon(statusIcon, color: statusColor),
                    onPressed: () => _toggleHafalanStatus(index),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Text(
            ayat.teksArab,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontFamily: 'Amiri', fontSize: 28, height: 1.8, color: Color(0xFF2D2D2D)),
          ),
          const SizedBox(height: 16),
          
          // TEKS LATIN (BARU DITAMBAHKAN)
          Text(
            ayat.teksLatin,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1A4D3E), fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),

          Text(
            ayat.terjemahan,
            style: const TextStyle(fontSize: 14, color: Color(0xFF5A5A5A), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniAudioPlayer() {
    // ... (Kode Mini Audio Player tetap sama persis seperti sebelumnya)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFF12372A), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -5))]),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sedang diputar', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text('${widget.surahName} - Ayat $_playingAyahNumber', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(_currentLoopMode == LoopMode.one ? Icons.repeat_one : Icons.repeat, color: _currentLoopMode == LoopMode.one ? const Color(0xFFC5A880) : Colors.white70),
                  onPressed: () async {
                    setState(() { _currentLoopMode = _currentLoopMode == LoopMode.off ? LoopMode.one : LoopMode.off; });
                    await AudioManager.instance.audioPlayer.setLoopMode(_currentLoopMode);
                  },
                ),
                StreamBuilder<PlayerState>(
                  stream: AudioManager.instance.audioPlayer.playerStateStream,
                  builder: (context, snapshot) {
                    final state = snapshot.data;
                    if (state?.processingState == ProcessingState.loading || state?.processingState == ProcessingState.buffering) {
                      return const Padding(padding: EdgeInsets.all(8.0), child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Color(0xFFC5A880), strokeWidth: 3)));
                    } else if (state?.playing != true) {
                      return IconButton(icon: const Icon(Icons.play_arrow, color: Colors.white, size: 32), onPressed: AudioManager.instance.resumeAudio);
                    } else if (state?.processingState != ProcessingState.completed) {
                      return IconButton(icon: const Icon(Icons.pause, color: Colors.white, size: 32), onPressed: AudioManager.instance.pauseAudio);
                    } else {
                      return IconButton(icon: const Icon(Icons.replay, color: Colors.white, size: 32), onPressed: () => AudioManager.instance.audioPlayer.seek(Duration.zero));
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () async {
                    await AudioManager.instance.stopAudio();
                    setState(() { _playingAyahNumber = null; });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}