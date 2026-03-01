import 'dart:io';
import 'package:dio/dio.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class AudioManager {
  static final AudioManager instance = AudioManager._internal();
  AudioManager._internal();

  // Ubah menjadi public agar UI bisa mendengarkan status pemutaran
  final AudioPlayer audioPlayer = AudioPlayer();
  final Dio _dio = Dio();

  String _formatNumber(int number) {
    return number.toString().padLeft(3, '0');
  }

  // Fungsi memutar dengan opsi looping bawaan just_audio
  Future<void> playAyahAudio(int surahId, int ayahNumber, {LoopMode loopMode = LoopMode.off}) async {
    try {
      String fileName = '${_formatNumber(surahId)}${_formatNumber(ayahNumber)}.mp3';
      String url = 'https://everyayah.com/data/Alafasy_128kbps/$fileName';

      Directory appDocDir = await getApplicationDocumentsDirectory();
      String savePath = '${appDocDir.path}/$fileName';
      File file = File(savePath);

      await audioPlayer.stop();

      if (await file.exists()) {
        await audioPlayer.setFilePath(savePath);
      } else {
        await _dio.download(url, savePath);
        await audioPlayer.setFilePath(savePath);
      }

      // Atur mode pengulangan (Looping)
      await audioPlayer.setLoopMode(loopMode);
      await audioPlayer.play();

    } catch (e) {
      print("Gagal memutar audio: $e");
      throw Exception("Gagal memuat audio.");
    }
  }

  Future<void> pauseAudio() async {
    await audioPlayer.pause();
  }

  Future<void> resumeAudio() async {
    await audioPlayer.play();
  }

  Future<void> stopAudio() async {
    await audioPlayer.stop();
  }

  void dispose() {
    audioPlayer.dispose();
  }
}