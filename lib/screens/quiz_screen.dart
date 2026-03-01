import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int? _selectedIndex;
  bool _isAnswerChecked = false;

  // --- DUMMY DATA KUIS ---
  // Nantinya data ini diambil secara acak dari database SQLite Anda
  final String _surahName = "Al-Fatihah";
  final String _questionAyah = "الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ"; // Ayat 2
  
  final List<Map<String, dynamic>> _options = [
    {"text": "مَالِكِ يَوْمِ الدِّينِ", "isCorrect": false}, // Ayat 4
    {"text": "الرَّحْمَٰنِ الرَّحِيمِ", "isCorrect": true}, // Ayat 3 (Benar)
    {"text": "إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ", "isCorrect": false}, // Ayat 5
  ];

  void _checkAnswer() {
    if (_selectedIndex != null) {
      setState(() {
        _isAnswerChecked = true;
      });
    }
  }

  void _nextQuestion() {
    setState(() {
      _selectedIndex = null;
      _isAnswerChecked = false;
      // TODO: Panggil fungsi untuk mengambil soal baru dari database
    });
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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- HEADER KUIS ---
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
                          _surahName,
                          style: const TextStyle(
                            color: Color(0xFF12372A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'Soal 1 / 10',
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // --- PERTANYAAN (AYAT SEBELUMNYA) ---
              const Text(
                'Lanjutkan ayat berikut:',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFF12372A).withOpacity(0.1)),
                ),
                child: Center(
                  child: Text(
                    _questionAyah,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 32,
                      color: Color(0xFF12372A),
                      height: 1.8,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // --- PILIHAN GANDA ---
              Expanded(
                child: ListView.separated(
                  itemCount: _options.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final option = _options[index];
                    final isSelected = _selectedIndex == index;
                    
                    // Menentukan warna state saat dicek
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
                                style: const TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 24,
                                  color: Color(0xFF2D2D2D),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // --- TOMBOL AKSI ---
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedIndex == null ? null : (_isAnswerChecked ? _nextQuestion : _checkAnswer),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF12372A),
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _isAnswerChecked ? 'Pertanyaan Selanjutnya' : 'Periksa Jawaban',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}