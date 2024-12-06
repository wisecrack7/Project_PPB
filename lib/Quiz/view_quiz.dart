import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:project/Home%20Page/student_home.dart';

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

  bool allowBack = false;
  int currentQuestionIndex = 0;

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

    if (quizData != null) {
      setState(() {
        allowBack = quizData['allowBack'] ?? false;
        questions = quizData['questions'] as List<dynamic>? ?? [];
      });

      final submissionDoc = await FirebaseFirestore.instance
          .collection('submissions')
          .doc('${widget.username}_${widget.quizId}')
          .get();

      if (submissionDoc.exists) {
        final data = submissionDoc.data()!;
        final startTime = (data['startTime'] as Timestamp).toDate();
        final durationMinutes = quizData['timerDuration'] ?? 0;

        final currentTime = DateTime.now();
        final elapsedSeconds = currentTime.difference(startTime).inSeconds;
        final remainingSeconds = durationMinutes * 60 - elapsedSeconds;

        setState(() {
          _remainingTime = remainingSeconds > 0 ? remainingSeconds : 0;
        });

        if (_remainingTime > 0) {
          _startTimer();
        } else {
          _timeUp();
        }
      } else {
        final startTime = DateTime.now();
        final durationMinutes = quizData['timerDuration'] ?? 0;

        await FirebaseFirestore.instance
            .collection('submissions')
            .doc('${widget.username}_${widget.quizId}')
            .set({
          'startTime': startTime,
          'quizId': widget.quizId,
          'username': widget.username,
        });

        setState(() {
          _remainingTime = durationMinutes * 60;
        });

        if (_remainingTime > 0) {
          _startTimer();
        }
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingTime <= 0) {
        _timer.cancel();
        _timeUp();
      } else {
        setState(() {
          _remainingTime--;
        });
      }
    });
  }

  void _timeUp() async {
    _submitQuiz();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Quiz'),
          backgroundColor: Colors.teal,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final questionsPerPage = 3;
    final totalPages = (questions.length / questionsPerPage).ceil();

    final startIndex = currentQuestionIndex * questionsPerPage;
    final endIndex = ((currentQuestionIndex + 1) * questionsPerPage)
        .clamp(0, questions.length);

    final currentQuestions = startIndex < questions.length
        ? questions.sublist(startIndex, endIndex)
        : [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz'),
        backgroundColor: Colors.teal,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                'Time: ${_formatTime(_remainingTime)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _remainingTime <= 30 ? Colors.red : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: currentQuestions.length,
        itemBuilder: (context, index) {
          return _buildQuestionCard(currentQuestions[index],
              startIndex + index); // Ensure correct question numbering
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Page ${currentQuestionIndex + 1} of $totalPages',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade700,
              ),
            ),
            Row(
              mainAxisAlignment: allowBack
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.end,
              children: [
                if (allowBack && currentQuestionIndex > 0)
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        currentQuestionIndex--;
                      });
                    },
                    icon: Icon(Icons.arrow_back),
                    label: Text('Previous'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade300,
                    ),
                  ),
                if (currentQuestionIndex < totalPages - 1)
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        currentQuestionIndex++;
                      });
                    },
                    icon: Icon(Icons.arrow_forward),
                    label: Text('Next'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade300,
                    ),
                  ),
                if (currentQuestionIndex == totalPages - 1)
                  ElevatedButton.icon(
                    onPressed: _submitQuiz,
                    icon: Icon(Icons.check),
                    label: Text('Submit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(dynamic question, int index) {
    final questionText = question['question'] ?? 'No question available';
    final options = question['options'] as List<dynamic>? ?? [];

    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Q${index + 1}: $questionText',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.teal.shade700,
              ),
            ),
            const SizedBox(height: 10),
            ...options.map((option) {
              return RadioListTile<String>(
                title: Text(
                  option,
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                value: option,
                groupValue: answers[questionText],
                activeColor: Colors.teal,
                onChanged: (value) {
                  setState(() {
                    answers[questionText] = value;
                  });
                },
              );
            }).toList(),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    answers.remove(questionText);
                  });
                },
                icon: Icon(Icons.clear, color: Colors.red),
                label:
                Text('Clear Answer', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  void _submitQuiz() async {
    int correctAnswersCount = 0;

    for (var question in questions) {
      final correctAnswer = question['options'][question['correctAnswerIndex']];
      if (answers[question['question']] == correctAnswer) {
        correctAnswersCount++;
      }
    }

    final score = (correctAnswersCount / questions.length) * 100;
    final submissionDocId = '${widget.username}_${widget.quizId}';

    try {
      await FirebaseFirestore.instance
          .collection('submissions')
          .doc(submissionDocId)
          .set({
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
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          StudentHomePage(username: widget.username)),
                      (route) => false,
                );
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error submitting quiz: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting quiz. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
