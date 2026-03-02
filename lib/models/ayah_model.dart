class Ayah {
  final int id;
  final int surahId;
  final int nomorAyat;
  final int juz;
  final String teksArab;
  final String teksLatin;
  final String terjemahan;
  final int statusHafalan;
  final int isBookmarked;

  Ayah({
    required this.id,
    required this.surahId,
    required this.nomorAyat,
    required this.juz,
    required this.teksArab,
    required this.teksLatin,
    required this.terjemahan,
    this.statusHafalan = 0,
    this.isBookmarked = 0,
  });

  factory Ayah.fromMap(Map<String, dynamic> map) {
    return Ayah(
      id: map['id'],
      surahId: map['surah_id'],
      nomorAyat: map['nomor_ayat'],
      juz: map['juz'],
      teksArab: map['teks_arab'],
      teksLatin: map['teks_latin'],
      terjemahan: map['terjemahan'],
      statusHafalan: map['status_hafalan'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'surah_id': surahId,
      'nomor_ayat': nomorAyat,
      'juz': juz,
      'teks_arab': teksArab,
      'teks_latin': teksLatin,
      'terjemahan': terjemahan,
      'status_hafalan': statusHafalan,
      'is_bookmarked': isBookmarked,
    };
  }
}