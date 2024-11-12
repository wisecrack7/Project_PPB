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
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingTime <= 0) {
        _timer.cancel();
        _submitQuiz(); //otomatis submit ketika waktu habis
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                'Time: ${_formatTime(_remainingTime)}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('quizzes')
            .doc(widget.quizId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final quizData = snapshot.data!.data() as Map<String, dynamic>?;
          final questions = quizData?['questions'] as List<dynamic>? ?? [];

          return ListView.builder(
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final question = questions[index];
              final questionText =
                  question['question'] ?? 'Pertanyaan tidak tersedia';
              final options = question['options'] as List<dynamic>? ?? [];
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Q${index + 1}: $questionText',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    ...options.map((option) {
                      return RadioListTile<String>(
                        title: Text(option ?? 'Opsi tidak tersedia'),
                        value: option ?? '',
                        groupValue: answers[questionText],
                        onChanged: (value) {
                          setState(() {
                            answers[questionText] = value;
                          });
                        },
                      );
                    }).toList(),
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed: () {
            _timer.cancel(); // Menghentikan timer saat melakukan submit
            _submitQuiz();
          },
          child: Text('Submit'),
        ),
      ),
    );
  }

  void _submitQuiz() async {
    final quizDoc = await FirebaseFirestore.instance
        .collection('quizzes')
        .doc(widget.quizId)
        .get();
    final quizData = quizDoc.data() as Map<String, dynamic>?;
    final questions = quizData?['questions'] as List<dynamic>? ?? [];

    int correctAnswersCount = 0;
    int totalQuestions = questions.length;

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
