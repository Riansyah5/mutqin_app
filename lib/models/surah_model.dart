class Surah {
  final int id;
  final String namaLatin;
  final String namaArab;
  final int jumlahAyat;
  final String tempatTurun;

  Surah({
    required this.id,
    required this.namaLatin,
    required this.namaArab,
    required this.jumlahAyat,
    required this.tempatTurun,
  });

  // Mengubah dari Map (Database) ke Object
  factory Surah.fromMap(Map<String, dynamic> map) {
    return Surah(
      id: map['id'],
      namaLatin: map['nama_latin'],
      namaArab: map['nama_arab'],
      jumlahAyat: map['jumlah_ayat'],
      tempatTurun: map['tempat_turun'],
    );
  }

  // Mengubah Object ke Map (Untuk insert ke Database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama_latin': namaLatin,
      'nama_arab': namaArab,
      'jumlah_ayat': jumlahAyat,
      'tempat_turun': tempatTurun,
    };
  }
}