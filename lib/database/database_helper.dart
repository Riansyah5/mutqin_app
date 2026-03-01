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
    // 1. Buat Tabel Surah
    await db.execute('''
      CREATE TABLE surah (
        id INTEGER PRIMARY KEY,
        nama_latin TEXT NOT NULL,
        nama_arab TEXT NOT NULL,
        jumlah_ayat INTEGER NOT NULL,
        tempat_turun TEXT NOT NULL
      )
    ''');

    // 2. Buat Tabel Ayat (Gabungan teks Qur'an dan Progres Hafalan)
    await db.execute('''
      CREATE TABLE ayah (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        surah_id INTEGER NOT NULL,
        nomor_ayat INTEGER NOT NULL,
        teks_arab TEXT NOT NULL,
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

  Future close() async {
    final db = await instance.database;
    db.close();
  }

  // --- FUNGSI PARSER JSON (Seeding Database) ---
  
  Future<void> seedDatabase() async {
    final db = await instance.database;

    // 1. Cek apakah database sudah ada isinya
    // Jika sudah ada, hentikan proses agar tidak terjadi duplikasi data setiap aplikasi dibuka
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM surah')
    );
    
    if (count != null && count > 0) {
      print("Database sudah terisi, skip proses seeding.");
      return; 
    }

    print("Memulai parsing JSON dan seeding ke SQLite...");

    // 2. Baca file JSON dari assets
    final String response = await rootBundle.loadString('assets/data/quran.json');
    final List<dynamic> data = json.decode(response);

    // 3. Gunakan Batch untuk performa tinggi (Insert ribuan data sekaligus)
    Batch batch = db.batch();

    for (var surah in data) {
      // Masukkan data Surah ke batch
      batch.insert('surah', {
        'id': surah['id'],
        'nama_latin': surah['nama_latin'],
        'nama_arab': surah['nama_arab'],
        'jumlah_ayat': surah['jumlah_ayat'],
        'tempat_turun': surah['tempat_turun'],
      });

      // Masukkan data Ayat ke batch
      for (var ayat in surah['ayat']) {
        batch.insert('ayah', {
          'surah_id': surah['id'], // Relasi ke ID Surah di atas
          'nomor_ayat': ayat['nomor_ayat'],
          'teks_arab': ayat['teks_arab'],
          'terjemahan': ayat['terjemahan'],
          'status_hafalan': 0, // Default: belum dihafal
        });
      }
    }

    // 4. Eksekusi semua perintah insert sekaligus
    await batch.commit(noResult: true);
    print("Seeding database berhasil!");
  }
}