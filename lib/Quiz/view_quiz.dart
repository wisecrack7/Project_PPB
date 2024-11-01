import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuizViewPage extends StatefulWidget {
  final String quizId;
  QuizViewPage({required this.quizId});

  @override
  _QuizViewPageState createState() => _QuizViewPageState();
}

class _QuizViewPageState extends State<QuizViewPage> {
  Map<String, dynamic> answers = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('quizzes').doc(widget.quizId).get(),
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
              final questionText = question['question'] ?? 'No question text';
              final options = question['options'] as List<dynamic>? ?? [];

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Q${index + 1}: $questionText',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

  void _submitQuiz() async {
    final quizDoc = await FirebaseFirestore.instance.collection('quizzes').doc(widget.quizId).get();
    final quizData = quizDoc.data() as Map<String, dynamic>?;
    final questions = quizData?['questions'] as List<dynamic>? ?? [];

    int correctAnswersCount = 0;
    int totalQuestions = questions.length;

    for (var question in questions) {
      final questionText = question['question'];
      final correctAnswerIndex = question['correctAnswerIndex'];
      final correctAnswer = question['options'][correctAnswerIndex];

      // Check if student's answer is correct
      if (answers[questionText] == correctAnswer) {
        correctAnswersCount++;
      }
    }

    // Calculate the score as a percentage
    final score = (correctAnswersCount / totalQuestions) * 100;

    // Save the submission to Firestore
    await FirebaseFirestore.instance.collection('submissions').add({
      'quizId': widget.quizId,
      'studentAnswers': answers,
      'score': score,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Show feedback to the student
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quiz Submitted'),
        content: Text('Your score: ${score.toStringAsFixed(2)}%'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to previous screen
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
