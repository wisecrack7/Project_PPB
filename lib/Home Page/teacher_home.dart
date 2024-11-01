import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/Quiz/create_quiz.dart';
import 'package:project/Quiz/edit_quiz.dart';
import 'package:project/Home Page/account.dart'; // Import the AccountPage

class TeacherHomeView extends StatefulWidget {
  final String username;

  TeacherHomeView({required this.username});

  @override
  _TeacherHomeViewState createState() => _TeacherHomeViewState();
}

class _TeacherHomeViewState extends State<TeacherHomeView> {
  int _selectedIndex = 0; // To track the selected index

  Future<List<Map<String, dynamic>>> _fetchQuizzes() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('quizzes').get();
    List<Map<String, dynamic>> quizzes = snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      };
    }).toList();
    return quizzes;
  }

  Future<void> _deleteQuiz(String quizId) async {
    try {
      await FirebaseFirestore.instance.collection('quizzes').doc(quizId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quiz deleted successfully!')),
      );
      setState(() {}); // Trigger a rebuild to refresh the quiz list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting quiz: $e')),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update selected index
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Home')),
      body: _selectedIndex == 0
          ? _buildHomeContent()
          : _selectedIndex == 1
          ? _buildCreateContent()
          : AccountPage(), // Navigate to AccountPage when Account is selected
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.create),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Account',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildHomeContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text('Hi, ${widget.username}'),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchQuizzes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final quizzes = snapshot.data ?? [];
                if (quizzes.isEmpty) {
                  return Center(child: Text('No quizzes available.'));
                }

                return ListView.builder(
                  itemCount: quizzes.length,
                  itemBuilder: (context, index) {
                    final quiz = quizzes[index];
                    final title = quiz['quizName'] ?? 'No Title';
                    final questionCount = quiz['questions']?.length ?? 0;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(title),
                        subtitle: Text('Questions: $questionCount'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditQuizPage(quizId: quiz['id']),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: Text('Delete Quiz'),
                                      content: Text('Are you sure you want to delete this quiz?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            _deleteQuiz(quiz['id']);
                                            Navigator.of(context).pop();
                                          },
                                          child: Text('Delete'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateContent() {
    return CreateQuizPage();
  }
}
