import 'dart:io';
import 'package:dio/dio.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class AudioManager {
  // Membuat Singleton agar AudioPlayer hanya ada 1 instance di seluruh aplikasi
  static final AudioManager instance = AudioManager._internal();
  AudioManager._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final Dio _dio = Dio();

  // Fungsi untuk format angka ke 3 digit (Contoh: Surah 1 -> "001", Ayat 2 -> "002")
  // Format everyayah.com menggunakan 6 digit angka: [Surah][Ayat].mp3 -> 001002.mp3
  String _formatNumber(int number) {
    return number.toString().padLeft(3, '0');
  }

  // Fungsi Utama Memutar Ayat
  Future<void> playAyahAudio(int surahId, int ayahNumber) async {
    try {
      // 1. Susun nama file
      String fileName = '${_formatNumber(surahId)}${_formatNumber(ayahNumber)}.mp3';
      
      // 2. URL Murottal (Mishary Rashid Alafasy - 128kbps)
      String url = 'https://everyayah.com/data/Alafasy_128kbps/$fileName';

      // 3. Dapatkan direktori lokal HP (Internal Storage)
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String savePath = '${appDocDir.path}/$fileName';
      File file = File(savePath);

      // Hentikan pemutaran sebelumnya jika ada
      await _audioPlayer.stop();

      // 4. Cek apakah file sudah pernah di-download (Offline Mode)
      if (await file.exists()) {
        // Mainkan langsung dari memori HP
        await _audioPlayer.setFilePath(savePath);
      } else {
        // Download file dulu, lalu simpan ke HP
        await _dio.download(url, savePath);
        await _audioPlayer.setFilePath(savePath);
      }

      // 5. Putar Audio
      await _audioPlayer.play();

    } catch (e) {
      print("Gagal memutar audio: $e");
      throw Exception("Gagal memuat audio. Pastikan internet menyala untuk unduhan pertama.");
    }
  }

  // Fungsi untuk menghentikan audio
  Future<void> stopAudio() async {
    await _audioPlayer.stop();
  }

  // Membersihkan resource jika aplikasi ditutup
  void dispose() {
    _audioPlayer.dispose();
  }
}