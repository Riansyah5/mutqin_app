import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../database/database_helper.dart';
import 'surah_detail_screen.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  // Fungsi untuk refresh data saat kembali dari halaman detail
  void _refreshData() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      appBar: AppBar(
        title: const Text(
          'Markah Saya',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF12372A)),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper.instance.getBookmarkedAyahs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF12372A)));
          } else if (snapshot.hasError) {
            return const Center(child: Text('Terjadi kesalahan memuat data.'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final bookmarks = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: bookmarks.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final ayah = bookmarks[index];
              return _buildBookmarkCard(ayah);
            },
          );
        },
      ),
    );
  }

  // Tampilan jika belum ada bookmark
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.bookmarkMinus, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text(
            'Belum ada markah',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ayat yang Anda tandai akan muncul di sini.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Desain Kartu Bookmark
  Widget _buildBookmarkCard(Map<String, dynamic> ayah) {
    return GestureDetector(
      onTap: () async {
        // Navigasi ke halaman detail Surah
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SurahDetailScreen(
              surahId: ayah['surah_id'],
              surahName: ayah['nama_surah'],
              surahArab: '', // Dikosongkan sementara atau bisa ambil dari tabel surah jika perlu
            ),
          ),
        );
        _refreshData(); // Refresh list jika sewaktu di dalam user menghapus bookmark
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF12372A).withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Info Surah
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC5A880).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(LucideIcons.bookmark, size: 16, color: Color(0xFFC5A880)),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${ayah['nama_surah']} : ${ayah['nomor_ayat']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF12372A), fontSize: 16),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () async {
                    await DatabaseHelper.instance.toggleBookmark(ayah['id'], 0, 0); // Hapus bookmark dengan set is_bookmarked ke 0
                    _refreshData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Markah dihapus'), duration: Duration(milliseconds: 1000)),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Teks Arab Ayat
            Text(
              ayah['teks_arab'],
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              maxLines: 2, // Batasi 2 baris agar kartu tidak terlalu panjang
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'Amiri', fontSize: 24, color: Color(0xFF2D2D2D)),
            ),
          ],
        ),
      ),
    );
  }
}