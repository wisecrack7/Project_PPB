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
  final List<Map<String, dynamic>> _questions = [];

  @override
  void initState() {
    super.initState();
    _fetchQuizData();
  }

  Future<void> _fetchQuizData() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('quizzes').doc(widget.quizId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      _quizNameController.text = data['quizName'];
      _questions.addAll(List<Map<String, dynamic>>.from(data['questions'] ?? []));
      setState(() {});
    }
  }

  Future<void> _saveQuiz() async {
    await FirebaseFirestore.instance.collection('quizzes').doc(widget.quizId).update({
      'quizName': _quizNameController.text,
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

  void _addOption(int questionIndex) {
    setState(() {
      _questions[questionIndex]['options'].add(''); // Add a new empty option
    });
  }

  void _removeOption(int questionIndex, int optionIndex) {
    setState(() {
      _questions[questionIndex]['options'].removeAt(optionIndex); // Remove the specified option
    });
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
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Question ${questionIndex + 1}'),
              onChanged: (value) {
                question['question'] = value; // Update the question text
              },
              controller: TextEditingController(text: question['question']),
            ),
            const SizedBox(height: 10),
            // Options
            for (int i = 0; i < question['options'].length; i++)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(labelText: 'Option ${i + 1}'),
                      onChanged: (value) {
                        question['options'][i] = value; // Update the option text
                      },
                      controller: TextEditingController(text: question['options'][i]),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.remove),
                    onPressed: () => _removeOption(questionIndex, i), // Remove option
                  ),
                ],
              ),
            ElevatedButton(
              onPressed: () => _addOption(questionIndex), // Add option
              child: Text('Add Option'),
            ),
            // Dropdown for selecting the correct answer
            DropdownButtonFormField<int>(
              decoration: InputDecoration(labelText: 'Correct Answer'),
              value: question['correctAnswerIndex'], // Get the current correct answer index
              onChanged: (int? newValue) {
                setState(() {
                  question['correctAnswerIndex'] = newValue; // Update the correct answer index
                });
              },
              items: List.generate(
                question['options'].length,
                    (index) => DropdownMenuItem<int>(
                  value: index,
                  child: Text('Option ${index + 1}'),
                ),
              ),
              validator: (value) {
                if (value == null) {
                  return 'Please select a correct answer';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
