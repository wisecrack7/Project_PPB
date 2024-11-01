import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateQuizPage extends StatefulWidget {
  @override
  _CreateQuizPageState createState() => _CreateQuizPageState();
}

class _CreateQuizPageState extends State<CreateQuizPage> {
  final _formKey = GlobalKey<FormState>();
  final _quizNameController = TextEditingController();
  List<Map<String, dynamic>> questions = [];

  void _addQuestion() {
    setState(() {
      questions.add({
        'type': 'Multiple Choice', // Default to Multiple Choice
        'question': '',
        'options': [],
        'correctAnswerIndex': null, // Store the index of the correct answer
      });
    });
  }

  void _addOption(int questionIndex) {
    setState(() {
      questions[questionIndex]['options'].add(''); // Add an empty option
    });
  }

  Future<int> _getNextQuizId() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('quizzes').get();
    int maxId = 0;

    for (var doc in snapshot.docs) {
      int quizId = (doc.data() as Map<String, dynamic>)['quizID'] ?? 0;
      if (quizId > maxId) {
        maxId = quizId; // Find the maximum quizID
      }
    }

    return maxId + 1; // Return the next available quizID
  }

  Future<void> _saveQuiz() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Get the next quiz ID
      int quizId = await _getNextQuizId();

      final quizData = {
        'quizID': quizId, // Include the quiz ID
        'quizName': _quizNameController.text,
        'questions': questions,
      };

      // Save to Firestore
      await FirebaseFirestore.instance.collection('quizzes').doc(quizId.toString()).set(quizData);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Quiz saved successfully!')));
      _quizNameController.clear();
      setState(() {
        questions.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _quizNameController,
                decoration: InputDecoration(labelText: 'Quiz Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter quiz name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _addQuestion,
                child: Text('Add Question'),
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Question Type: ${questions[index]['type']}'),
                            TextFormField(
                              decoration: InputDecoration(labelText: 'Question'),
                              onChanged: (value) {
                                questions[index]['question'] = value;
                              },
                            ),
                            // Display multiple choice options
                            for (int i = 0; i < questions[index]['options'].length; i++)
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      decoration: InputDecoration(labelText: 'Option ${i + 1}'),
                                      onChanged: (value) {
                                        questions[index]['options'][i] = value;
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.remove),
                                    onPressed: () {
                                      setState(() {
                                        questions[index]['options'].removeAt(i);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ElevatedButton(
                              onPressed: () => _addOption(index), // Add options correctly
                              child: Text('Add Option'),
                            ),
                            DropdownButtonFormField<int>(
                              decoration: InputDecoration(labelText: 'Select Correct Answer'),
                              value: questions[index]['correctAnswerIndex'],
                              onChanged: (int? newValue) {
                                setState(() {
                                  questions[index]['correctAnswerIndex'] = newValue; // Store the index
                                });
                              },
                              items: List.generate(
                                questions[index]['options'].length,
                                    (i) => DropdownMenuItem<int>(
                                  value: i,
                                  child: Text('Option ${i + 1}'),
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
                  },
                ),
              ),
              ElevatedButton(
                onPressed: _saveQuiz,
                child: Text('Save Quiz'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
