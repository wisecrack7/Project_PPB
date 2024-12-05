import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CreateQuizPage extends StatefulWidget {
  final String username;

  CreateQuizPage({required this.username});

  @override
  _CreateQuizPageState createState() => _CreateQuizPageState();
}

class _CreateQuizPageState extends State<CreateQuizPage> {
  final _formKey = GlobalKey<FormState>();
  final _quizNameController = TextEditingController();
  final _timerController = TextEditingController();
  List<Map<String, dynamic>> questions = [];
  bool allowBack = false;

  void _addQuestion() {
    setState(() {
      questions.add({
        'type': 'Multiple Choice',
        'question': '',
        'options': [],
        'correctAnswerIndex': null,
      });
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      questions.removeAt(index);
    });
  }

  void _addOption(int questionIndex) {
    setState(() {
      questions[questionIndex]['options'].add('');
    });
  }

  Future<int> _getNextQuizId() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('quizzes').get();
    int maxId = 0;

    for (var doc in snapshot.docs) {
      int quizId = (doc.data() as Map<String, dynamic>)['quizID'] ?? 0;
      if (quizId > maxId) {
        maxId = quizId;
      }
    }

    return maxId + 1;
  }

  Future<void> _saveQuiz() async {
    if (_formKey.currentState?.validate() ?? false) {
      int quizId = await _getNextQuizId();
      final int timerDuration = int.tryParse(_timerController.text) ?? 0;

      final quizData = {
        'quizID': quizId,
        'quizName': _quizNameController.text,
        'timerDuration': timerDuration,
        'questions': questions,
        'creatorUsername': widget.username,
        'allowBack': allowBack,
      };

      await FirebaseFirestore.instance.collection('quizzes').add(quizData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quiz saved successfully!')),
      );
      _quizNameController.clear();
      _timerController.clear();
      setState(() {
        questions.clear();
        allowBack = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Quiz'),
        backgroundColor: Color(0xFF4CAF50),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10),
                TextFormField(
                  controller: _quizNameController,
                  decoration: InputDecoration(
                    labelText: 'Quiz Name',
                    border: OutlineInputBorder(),
                    helperText: 'Enter the name of the quiz.',
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter quiz name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                TextFormField(
                  controller: _timerController,
                  decoration: InputDecoration(
                    labelText: 'Timer Duration (in minutes)',
                    border: OutlineInputBorder(),
                    helperText: 'Enter the timer duration for the quiz.',
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        int.tryParse(value) == null) {
                      return 'Please enter a valid timer duration';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),
                // Allow Back Switch
                SwitchListTile(
                  title: Text('Allow Back'),
                  subtitle: Text(
                      'Allow participants to go back to previous questions'),
                  value: allowBack,
                  onChanged: (bool value) {
                    setState(() {
                      allowBack = value;
                    });
                  },
                  activeColor: Color(0xFF4CAF50),
                ),
                SizedBox(height: 24),
                // Questions Section
                Text(
                  'Questions',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                // Dynamic List of Questions
                for (int index = 0; index < questions.length; index++)
                  Card(
                    elevation: 3,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Question ${index + 1}',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeQuestion(index),
                              ),
                            ],
                          ),
                          TextFormField(
                            initialValue: questions[index]['question'],
                            decoration: InputDecoration(
                              labelText: 'Enter the question',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.grey[200],
                            ),
                            onChanged: (value) {
                              questions[index]['question'] = value;
                            },
                          ),
                          SizedBox(height: 8),
                          // Options for the Question
                          Text(
                            'Options',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          for (int i = 0;
                              i < questions[index]['options'].length;
                              i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: questions[index]['options']
                                          [i],
                                      decoration: InputDecoration(
                                        labelText: 'Option ${i + 1}',
                                        border: OutlineInputBorder(),
                                        filled: true,
                                        fillColor: Colors.grey[200],
                                      ),
                                      onChanged: (value) {
                                        questions[index]['options'][i] = value;
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.remove_circle,
                                        color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        questions[index]['options'].removeAt(i);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          // Add Option Button
                          ElevatedButton.icon(
                            onPressed: () => _addOption(index),
                            icon: Icon(Icons.add),
                            label: Text('Add Option'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent),
                          ),
                          SizedBox(height: 10),
                          // Dropdown for Correct Answer
                          DropdownButtonFormField<int>(
                            decoration: InputDecoration(
                              labelText: 'Correct Answer',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.grey[200],
                            ),
                            value: questions[index]['correctAnswerIndex'],
                            onChanged: (int? newValue) {
                              setState(() {
                                questions[index]['correctAnswerIndex'] =
                                    newValue;
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
                  ),
                SizedBox(height: 16),
                // Add Question Button
                ElevatedButton.icon(
                  onPressed: _addQuestion,
                  icon: Icon(Icons.add_circle),
                  label: Text('Add Question'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent),
                ),
                SizedBox(height: 16),
                // Save Quiz Button
                ElevatedButton.icon(
                  onPressed: _saveQuiz,
                  icon: Icon(Icons.save),
                  label: Text('Save Quiz'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4CAF50)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
