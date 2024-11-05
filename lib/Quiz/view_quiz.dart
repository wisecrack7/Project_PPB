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
  //Menyimpan jawaban yang dipilih oleh Student ke Firestore Database
  Map<String, dynamic> answers = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz'),
      ),
      //Melakukan pengambilan data quiz dari Firestore Database untuk ditampilkan dalam sesi quiz berdasarkan quiz yang dipilih
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('quizzes')
            .doc(widget.quizId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          //Melakukan pengambilan data soal dan jawaban untuk disimpan ke Firestore Database
          final quizData = snapshot.data!.data() as Map<String, dynamic>?;
          final questions = quizData?['questions'] as List<dynamic>? ?? [];

          //Menampilkan Pertanyaan dan Opsi Jawaban
          return ListView.builder(
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final question = questions[index];
              final questionText = question['question'] ?? 'No question text';
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
                        title: Text(option ?? 'No option text'),
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
      //Tombol Submit untuk menyimpan data ke Firestore Database
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed: () {
            _submitQuiz();
          },
          child: Text('Submit'),
        ),
      ),
    );
  }

  //Menyimpan Quiz dan Menghitung Score
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

    //Memasukan data kepada Firestore Database pada collection submissions
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
        title: Text('Quiz Submitted'),
        content: Text('Your score: ${score.toStringAsFixed(2)}%'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.popUntil(context,
                  (route) => route.isFirst); // Return to StudentHomePage
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
