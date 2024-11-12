import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditQuizPage extends StatefulWidget {
  final String quizId;

  EditQuizPage({required this.quizId});

  @override
  _EditQuizPageState createState() => _EditQuizPageState();
}

class _EditQuizPageState extends State<EditQuizPage> {
  final TextEditingController _quizNameController = TextEditingController();
  final TextEditingController _timerController = TextEditingController();
  List<Map<String, dynamic>> _questions = [];

  @override
  void initState() {
    super.initState();
    _fetchQuizData();
  }

  Future<void> _fetchQuizData() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('quizzes')
        .doc(widget.quizId)
        .get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      _quizNameController.text = data['quizName'];
      _timerController.text = (data['timerDuration'] ?? '').toString();
      _questions = List<Map<String, dynamic>>.from(data['questions'] ?? []);
      setState(() {});
    }
  }

  Future<void> _saveQuiz() async {
    await FirebaseFirestore.instance
        .collection('quizzes')
        .doc(widget.quizId)
        .update({
      'quizName': _quizNameController.text,
      'timerDuration': int.tryParse(_timerController.text) ?? 0,
      'questions': _questions,
    });
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quiz Updated'),
        content: const Text('The quiz has been successfully updated!'),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Quiz'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _quizNameController,
              decoration: InputDecoration(labelText: 'Quiz Name'),
            ),
            TextField(
              controller: _timerController,
              decoration: InputDecoration(labelText: 'Timer Duration (in seconds)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  return _buildQuestionForm(index);
                },
              ),
            ),
            ElevatedButton(
              onPressed: _saveQuiz,
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionForm(int questionIndex) {
    final question = _questions[questionIndex];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Question ${questionIndex + 1}'),
            TextField(
              decoration: InputDecoration(labelText: 'Question Text'),
              onChanged: (value) {
                setState(() {
                  _questions[questionIndex]['question'] = value;
                });
              },
              controller: TextEditingController(text: question['question']),
            ),
            const SizedBox(height: 10),
            for (int i = 0; i < (question['options']?.length ?? 0); i++)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(labelText: 'Option ${i + 1}'),
                      onChanged: (value) {
                        setState(() {
                          _questions[questionIndex]['options'][i] = value;
                        });
                      },
                      controller: TextEditingController(text: question['options'][i]),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () {
                      setState(() {
                        _questions[questionIndex]['options'].removeAt(i);
                      });
                    },
                  ),
                ],
              ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _questions[questionIndex]['options'] = [
                    ..._questions[questionIndex]['options'] ?? [],
                    ''
                  ];
                });
              },
              child: const Text('Add Option'),
            ),
            DropdownButtonFormField<int>(
              decoration: InputDecoration(labelText: 'Correct Answer Index'),
              value: question['correctAnswerIndex'],
              items: List.generate(
                question['options'].length,
                    (i) => DropdownMenuItem(
                  value: i,
                  child: Text('Option ${i + 1}'),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _questions[questionIndex]['correctAnswerIndex'] = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
