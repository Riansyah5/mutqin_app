class Ayah {
  final int id;
  final int surahId;
  final int nomorAyat;
  final String teksArab;
  final String terjemahan;
  final int statusHafalan; // 0: Belum, 1: Proses, 2: Lancar

  Ayah({
    required this.id,
    required this.surahId,
    required this.nomorAyat,
    required this.teksArab,
    required this.terjemahan,
    this.statusHafalan = 0, // Default belum dihafal
  });

  factory Ayah.fromMap(Map<String, dynamic> map) {
    return Ayah(
      id: map['id'],
      surahId: map['surah_id'],
      nomorAyat: map['nomor_ayat'],
      teksArab: map['teks_arab'],
      terjemahan: map['terjemahan'],
      statusHafalan: map['status_hafalan'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'surah_id': surahId,
      'nomor_ayat': nomorAyat,
      'teks_arab': teksArab,
      'terjemahan': terjemahan,
      'status_hafalan': statusHafalan,
    };
  }
}