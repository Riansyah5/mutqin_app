import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/surah_model.dart';
import '../models/ayah_model.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mutqin_quran.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Buka database, jika belum ada akan memanggil _createDB
    return await openDatabase(
      path, 
      version: 1, 
      onCreate: _createDB
    );
  }

  Future _createDB(Database db, int version) async {
    // 1. Buat Tabel Surah (Menyesuaikan keys dari JSON baru)
    await db.execute('''
      CREATE TABLE surah (
        id INTEGER PRIMARY KEY,
        nama_latin TEXT NOT NULL,
        nama_arab TEXT NOT NULL,
        arti TEXT,
        jumlah_ayat INTEGER NOT NULL,
        tempat_turun TEXT NOT NULL
      )
    ''');

    // 2. Buat Tabel Ayat (Menambahkan latin dan juz)
    await db.execute('''
      CREATE TABLE ayah (
        id INTEGER PRIMARY KEY,
        surah_id INTEGER NOT NULL,
        nomor_ayat INTEGER NOT NULL,
        juz INTEGER NOT NULL,
        teks_arab TEXT NOT NULL,
        teks_latin TEXT,
        terjemahan TEXT NOT NULL,
        status_hafalan INTEGER DEFAULT 0,
        FOREIGN KEY (surah_id) REFERENCES surah (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- FUNGSI CRUD (Create, Read, Update, Delete) ---

  // Mengambil daftar semua Surah
  Future<List<Surah>> getAllSurah() async {
    final db = await instance.database;
    final result = await db.query('surah', orderBy: 'id ASC');
    return result.map((json) => Surah.fromMap(json)).toList();
  }

  // Mengambil ayat berdasarkan ID Surah
  Future<List<Ayah>> getAyahsBySurah(int surahId) async {
    final db = await instance.database;
    final result = await db.query(
      'ayah',
      where: 'surah_id = ?',
      whereArgs: [surahId],
      orderBy: 'nomor_ayat ASC',
    );
    return result.map((json) => Ayah.fromMap(json)).toList();
  }

  // Update status hafalan sebuah ayat (Untuk fitur Checklist)
  Future<int> updateStatusHafalan(int ayahId, int newStatus) async {
    final db = await instance.database;
    return await db.update(
      'ayah',
      {'status_hafalan': newStatus},
      where: 'id = ?',
      whereArgs: [ayahId],
    );
  }

  // --- FUNGSI STATISTIK HAFALAN ---
  
  Future<Map<String, dynamic>> getHafalanStats() async {
    final db = await instance.database;

    // 1. Hitung Total Seluruh Ayat di Database
    final totalResult = await db.rawQuery('SELECT COUNT(*) FROM ayah');
    final int totalAyat = Sqflite.firstIntValue(totalResult) ?? 0;

    // 2. Hitung Ayat yang sudah Mutqin (Lancar / Status 2)
    final mutqinResult = await db.rawQuery('SELECT COUNT(*) FROM ayah WHERE status_hafalan = 2');
    final int mutqinAyat = Sqflite.firstIntValue(mutqinResult) ?? 0;

    // 3. Hitung Ayat yang sedang diproses (Status 1)
    final prosesResult = await db.rawQuery('SELECT COUNT(*) FROM ayah WHERE status_hafalan = 1');
    final int prosesAyat = Sqflite.firstIntValue(prosesResult) ?? 0;

    // Hindari pembagian dengan nol jika database masih kosong
    double persentase = totalAyat > 0 ? (mutqinAyat / totalAyat) : 0.0;

    return {
      'total': totalAyat,
      'mutqin': mutqinAyat,
      'proses': prosesAyat,
      'persentase': persentase, // Dalam bentuk desimal (0.0 - 1.0)
    };
  }

  /// --- FUNGSI KUIS SAMBUNG AYAT (DENGAN FILTER) ---
  
  // Tambah parameter pilihan selectedSurahIds
  Future<Map<String, dynamic>?> generateQuiz({List<int>? selectedSurahIds}) async {
    final db = await instance.database;

    String surahFilter = '';
    List<dynamic> args = [];

    // Jika pengguna memilih surah tertentu, masukkan ke dalam query SQL
    if (selectedSurahIds != null && selectedSurahIds.isNotEmpty) {
      String placeholders = List.filled(selectedSurahIds.length, '?').join(',');
      surahFilter = 'AND a.surah_id IN ($placeholders)';
      args.addAll(selectedSurahIds);
    }

    // 1. Ambil 1 ayat rawak sebagai soalan (tertakluk kepada filter jika ada)
    final List<Map<String, dynamic>> soalResult = await db.rawQuery('''
      SELECT a.*, s.nama_latin as nama_surah 
      FROM ayah a 
      JOIN surah s ON a.surah_id = s.id 
      WHERE a.nomor_ayat < s.jumlah_ayat $surahFilter
      ORDER BY RANDOM() 
      LIMIT 1
    ''', args);

    if (soalResult.isEmpty) return null; // Jika tiada data

    final soal = soalResult.first;
    final int surahId = soal['surah_id'];
    final int nomorAyat = soal['nomor_ayat'];
    final String namaSurah = soal['nama_surah'];

    // 2. Ambil Jawapan Betul (Ayat seterusnya: nomor_ayat + 1)
    final List<Map<String, dynamic>> benarResult = await db.query(
      'ayah',
      where: 'surah_id = ? AND nomor_ayat = ?',
      whereArgs: [surahId, nomorAyat + 1],
    );
    
    if (benarResult.isEmpty) return null;
    final jawapanBetul = benarResult.first;

    // 3. Ambil 2 Jawapan Salah (Ayat rawak sebagai pengeliru dari seluruh Al-Quran)
    final List<Map<String, dynamic>> salahResult = await db.rawQuery('''
      SELECT teks_arab FROM ayah 
      WHERE id != ? 
      ORDER BY RANDOM() 
      LIMIT 2
    ''', [jawapanBetul['id']]);

    // 4. Susun Pilihan Jawapan (1 Betul + 2 Salah)
    List<Map<String, dynamic>> options = [
      {"text": jawapanBetul['teks_arab'], "isCorrect": true},
      {"text": salahResult[0]['teks_arab'], "isCorrect": false},
      {"text": salahResult[1]['teks_arab'], "isCorrect": false},
    ];

    // 5. Rawakkan kedudukan pilihan
    options.shuffle();

    return {
      'surah_name': namaSurah,
      'question_ayah': soal['teks_arab'],
      'question_number': nomorAyat,
      'options': options,
    };
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
  
  // --- FUNGSI PARSER JSON (Dari 114 File Terpisah) ---
  Future<void> seedDatabase() async {
    final db = await instance.database;

    // Cek apakah database sudah ada isinya
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM surah')
    );
    
    if (count != null && count > 0) {
      print("Database sudah terisi, skip proses seeding.");
      return; 
    }

    print("Memulai parsing 114 file JSON Kemenag...");

    // Gunakan Batch agar proses insert tetap secepat kilat
    Batch batch = db.batch();

    // Looping dari Surah 1 (Al-Fatihah) sampai 114 (An-Nas)
    for (int i = 1; i <= 114; i++) {
      try {
        // 1. Baca file JSON berdasarkan nomor urut surah
        final String response = await rootBundle.loadString('assets/data/$i.json');
        final List<dynamic> data = json.decode(response);

        if (data.isEmpty) continue; // Lewati jika file kosong

        // 2. Ambil informasi Surah (Cukup ambil dari ayat pertama saja, data[0])
        final firstAyah = data[0];
        batch.insert('surah', {
          'id': firstAyah['surah']['id'],
          'nama_latin': firstAyah['surah']['latin'].toString().trim(),
          'nama_arab': firstAyah['surah']['arabic'].toString().trim(),
          'arti': firstAyah['surah']['translation'],
          'jumlah_ayat': firstAyah['surah']['num_ayah'],
          'tempat_turun': firstAyah['surah']['location'],
        });

        // 3. Masukkan semua ayat yang ada di dalam file tersebut
        for (var item in data) {
          batch.insert('ayah', {
            'id': item['id'], // ID unik bawaan JSON
            'surah_id': item['surah_id'],
            'nomor_ayat': item['ayah'],
            'juz': item['juz'],
            'teks_arab': item['arabic'],
            'teks_latin': item['latin'],
            'terjemahan': item['translation'],
            'status_hafalan': 0, // Default: belum dihafal
          });
        }
      } catch (e) {
        print("Error saat membaca file $i.json: $e");
        // Jika file 1.json sampai 114.json belum lengkap, ini akan memberi tahu Anda file mana yang kurang
      }
    }

    // 4. Eksekusi semua perintah insert ke SQLite sekaligus
    await batch.commit(noResult: true);
    print("Seeding database dari 114 file berhasil!");
  }
  
}