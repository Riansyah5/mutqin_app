import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../database/database_helper.dart';
import '../models/surah_model.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int? _selectedIndex;
  bool _isAnswerChecked = false;
  int _score = 0;
  int _questionCount = 1;
  
  Map<String, dynamic>? _quizData;
  bool _isLoading = true;

  // --- PEMBOLEH UBAH FILTER ---
  List<Surah> _allSurahs = [];
  List<int> _selectedSurahIds = []; // Kosong bermaksud semua surah dipilih

  @override
  void initState() {
    super.initState();
    _loadSurahData();
    _loadNewQuestion();
  }

  // Muat senarai surah untuk menu filter
  Future<void> _loadSurahData() async {
    final surahs = await DatabaseHelper.instance.getAllSurah();
    setState(() {
      _allSurahs = surahs;
    });
  }

  // Muat pertanyaan baru dengan memasukkan filter
  Future<void> _loadNewQuestion() async {
    setState(() {
      _isLoading = true;
      _selectedIndex = null;
      _isAnswerChecked = false;
    });

    // Masukkan senarai ID Surah yang telah dipilih pengguna
    final data = await DatabaseHelper.instance.generateQuiz(
      selectedSurahIds: _selectedSurahIds.isEmpty ? null : _selectedSurahIds,
    );

    setState(() {
      _quizData = data;
      _isLoading = false;
    });
  }

  // Menunjukkan Modal Bottom Sheet untuk Filter Surah
  void _showFilterSheet() {
    // Buat salinan sementara supaya pengguna boleh batal pilihan tanpa mengubah yang asal
    List<int> tempSelectedIds = List.from(_selectedSurahIds);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih Surah Ujian',
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold, 
                      color: Color(0xFF12372A)
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Pilih satu atau lebih surah yang ingin diuji.'),
                  const SizedBox(height: 16),
                  
                  // Senarai Surah
                  Expanded(
                    child: ListView.builder(
                      itemCount: _allSurahs.length,
                      itemBuilder: (context, index) {
                        final surah = _allSurahs[index];
                        final isSelected = tempSelectedIds.contains(surah.id);

                        return CheckboxListTile(
                          activeColor: const Color(0xFFC5A880),
                          title: Text(surah.namaLatin, style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text('${surah.jumlahAyat} Ayat', style: const TextStyle(fontSize: 12)),
                          value: isSelected,
                          onChanged: (bool? value) {
                            setModalState(() {
                              if (value == true) {
                                tempSelectedIds.add(surah.id);
                              } else {
                                tempSelectedIds.remove(surah.id);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  
                  // Butang Terapkan Filter
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF12372A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        Navigator.pop(context); // Tutup sheet
                        setState(() {
                          _selectedSurahIds = tempSelectedIds; // Terapkan pilihan
                          _score = 0; // Reset markah
                          _questionCount = 1; // Reset nombor pertanyaan
                        });
                        _loadNewQuestion(); // Muat ulang pertanyaan berdasarkan saringan baru
                      },
                      child: const Text('Terapkan & Mula Semula', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _checkAnswer() {
    if (_selectedIndex != null) {
      setState(() {
        _isAnswerChecked = true;
        if (_quizData!['options'][_selectedIndex!]['isCorrect']) {
          _score += 10;
        }
      });
    }
  }

  void _nextQuestion() {
    setState(() {
      _questionCount++;
    });
    _loadNewQuestion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      appBar: AppBar(
        title: const Text(
          'Ujian Hafalan',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF12372A)),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // BUTANG FILTER DI POJOK KANAN
          IconButton(
            icon: Stack(
              children: [
                const Icon(LucideIcons.filter, color: Color(0xFF12372A)),
                if (_selectedSurahIds.isNotEmpty) // Tunjuk titik merah jika filter aktif
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 10, height: 10,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    ),
                  )
              ],
            ),
            onPressed: _showFilterSheet,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF12372A)))
        : _quizData == null 
            ? const Center(child: Text('Gagal memuat pertanyaan. Coba periksa jaringan anda.'))
            : _buildQuizContent(),
    );
  }

  Widget _buildQuizContent() {
    final options = _quizData!['options'] as List<dynamic>;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- AREA SCROLLABLE (SOAL & JAWAPAN) ---
            // Dibungkus dengan Expanded dan SingleChildScrollView agar boleh digulir
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(), // Efek pantulan yang elegan
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- HEADER SOALAN & SKOR ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF12372A).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.bookOpen, size: 16, color: Color(0xFF12372A)),
                              const SizedBox(width: 8),
                              Text(
                                _quizData!['surah_name'],
                                style: const TextStyle(color: Color(0xFF12372A), fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Soalan $_questionCount', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                            Text('Skor: $_score', style: const TextStyle(color: Color(0xFFC5A880), fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // --- PERTANYAAN ---
                    const Text('Lanjutkan ayat berikut:', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(24), // Padding disesuaikan sedikit agar lebih lega
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
                        ],
                        border: Border.all(color: const Color(0xFF12372A).withOpacity(0.1)),
                      ),
                      child: Center(
                        child: Text(
                          _quizData!['question_ayah'],
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          // Ukuran font diturunkan sedikit (dari 32 ke 28) agar lebih aman untuk ayat panjang
                          style: const TextStyle(fontFamily: 'KFGQPC', fontSize: 28, color: Color(0xFF12372A), height: 1.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- PILIHAN JAWAPAN ---
                    // Tidak lagi menggunakan Expanded di sini, tapi shrinkWrap: true
                    ListView.separated(
                      shrinkWrap: true, // Memaksa ListView menyesuaikan tinggi dengan isinya
                      physics: const NeverScrollableScrollPhysics(), // Mematikan scroll internal ListView
                      itemCount: options.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final option = options[index];
                        final isSelected = _selectedIndex == index;
                        
                        Color borderColor = isSelected ? const Color(0xFFC5A880) : Colors.grey.withOpacity(0.2);
                        Color bgColor = isSelected ? const Color(0xFFC5A880).withOpacity(0.1) : Colors.white;
                        Widget? trailingIcon;

                        if (_isAnswerChecked) {
                          if (option['isCorrect']) {
                            borderColor = Colors.green;
                            bgColor = Colors.green.withOpacity(0.1);
                            trailingIcon = const Icon(LucideIcons.checkCircle2, color: Colors.green);
                          } else if (isSelected && !option['isCorrect']) {
                            borderColor = Colors.red;
                            bgColor = Colors.red.withOpacity(0.1);
                            trailingIcon = const Icon(LucideIcons.xCircle, color: Colors.red);
                          }
                        }

                        return GestureDetector(
                          onTap: _isAnswerChecked ? null : () {
                            setState(() {
                              _selectedIndex = index;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: borderColor, width: isSelected || (_isAnswerChecked && option['isCorrect']) ? 2 : 1),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (trailingIcon != null) trailingIcon else const SizedBox(width: 24),
                                Expanded(
                                  child: Text(
                                    option['text'],
                                    textAlign: TextAlign.right,
                                    textDirection: TextDirection.rtl,
                                    style: const TextStyle(fontFamily: 'KFGQPC', fontSize: 24, color: Color(0xFF2D2D2D)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24), // Jarak lega sebelum tombol
                  ],
                ),
              ),
            ),

            // --- BUTANG TINDAKAN (Terkunci di bawah) ---
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _selectedIndex == null ? null : (_isAnswerChecked ? _nextQuestion : _checkAnswer),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF12372A),
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  _isAnswerChecked ? 'Pertanyaan Selanjutnya' : 'Periksa Jawaban',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}