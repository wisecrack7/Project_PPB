import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class QuizViewPage extends StatefulWidget {
  final String quizId;
  final String username;

  QuizViewPage({required this.quizId, required this.username});

  @override
  _QuizViewPageState createState() => _QuizViewPageState();
}

class _QuizViewPageState extends State<QuizViewPage> {
  Map<String, dynamic> answers = {};
  late Timer _timer;
  int _remainingTime = 0;

  final int questionsPerPage = 5;
  int currentPage = 0;
  List<dynamic> questions = [];

  @override
  void initState() {
    super.initState();
    _fetchQuizData();
  }

  Future<void> _fetchQuizData() async {
    final quizDoc = await FirebaseFirestore.instance
        .collection('quizzes')
        .doc(widget.quizId)
        .get();
    final quizData = quizDoc.data() as Map<String, dynamic>?;

    if (quizData != null && quizData.containsKey('timerDuration')) {
      _remainingTime = quizData['timerDuration'] * 60;
      _startTimer();
    } else {
      print("Durasi waktu tidak ditemukan atau data quiz kosong.");
    }

    setState(() {
      questions = quizData?['questions'] as List<dynamic>? ?? [];
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingTime <= 0) {
        _timer.cancel();
        _submitQuiz(); // otomatis submit ketika waktu habis
      } else {
        setState(() {
          _remainingTime--;
        });
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  List<dynamic> _getPaginatedQuestions() {
    final startIndex = currentPage * questionsPerPage;
    final endIndex =
    (startIndex + questionsPerPage).clamp(0, questions.length);
    return questions.sublist(startIndex, endIndex);
  }

  @override
  Widget build(BuildContext context) {
    final paginatedQuestions = _getPaginatedQuestions();

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                'Time: ${_formatTime(_remainingTime)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _remainingTime <= 30 ? Colors.red : Colors.black, // Timer berubah jadi merah jika waktu <= 30 detik
                ),
              ),
            ),
          ),
        ],
      ),
      body: questions.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: paginatedQuestions.length,
        itemBuilder: (context, index) {
          final question = paginatedQuestions[index];
          final questionText =
              question['question'] ?? 'Pertanyaan tidak tersedia';
          final options = question['options'] as List<dynamic>? ?? [];
          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(
                vertical: 8.0, horizontal: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Q${currentPage * questionsPerPage + index + 1}: $questionText',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...options.map((option) {
                    return RadioListTile<String>(
                      title: Text(
                        option ?? 'Opsi tidak tersedia',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      value: option ?? '',
                      groupValue: answers[questionText],
                      activeColor: Colors.green,
                      onChanged: (value) {
                        setState(() {
                          answers[questionText] = value;
                        });
                      },
                    );
                  }).toList(),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (currentPage > 0)
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    currentPage--;
                  });
                },
                icon: Icon(Icons.arrow_back),
                label: Text('Back'),
              ),
            if ((currentPage + 1) * questionsPerPage < questions.length)
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    currentPage++;
                  });
                },
                icon: Icon(Icons.arrow_forward),
                label: Text('Next'),
              ),
            if ((currentPage + 1) * questionsPerPage >= questions.length)
              ElevatedButton.icon(
                onPressed: () {
                  _timer.cancel(); // Menghentikan timer saat melakukan submit
                  _submitQuiz();
                },
                icon: Icon(Icons.check),
                label: Text('Submit'),
              ),
          ],
        ),
      ),
    );
  }

  void _submitQuiz() async {
    final totalQuestions = questions.length;
    int correctAnswersCount = 0;

    for (var question in questions) {
      final questionText = question['question'];
      final correctAnswerIndex = question['correctAnswerIndex'];
      final correctAnswer = question['options'][correctAnswerIndex];

      if (answers[questionText] == correctAnswer) {
        correctAnswersCount++;
      }
    }

    final score = (correctAnswersCount / totalQuestions) * 100;

    await FirebaseFirestore.instance.collection('submissions').add({
      'quizId': widget.quizId,
      'studentAnswers': answers,
      'score': score,
      'timestamp': FieldValue.serverTimestamp(),
      'username': widget.username,
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quiz Disubmit'),
        content: Text('Skor Anda: ${score.toStringAsFixed(2)}%'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
