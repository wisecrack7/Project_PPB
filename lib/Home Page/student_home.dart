import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:project/Home Page/account_student.dart';
import 'package:project/Quiz/view_quiz.dart';

class StudentHomePage extends StatefulWidget {
  final String username;

  StudentHomePage({required this.username});

  @override
  _StudentHomePageState createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Home'),
      ),
      body: _currentIndex == 0
          ? FutureBuilder<List<String>>(
              future: _fetchCompletedQuizzes(widget.username),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error fetching completed quizzes'));
                }

                List<String> completedQuizzes = snapshot.data ?? [];

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('quizzes')
                      .snapshots(),
                  builder: (context, quizSnapshot) {
                    if (!quizSnapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final quizzes = quizSnapshot.data!.docs;

                    return ListView(
                      children: quizzes.map((document) {
                        final quizName = document['quizName'] ?? 'Unnamed Quiz';
                        final quizId = document.id;

                        // Skip quizzes that have already been completed
                        if (completedQuizzes.contains(quizId)) {
                          return Container();
                        }

                        return ListTile(
                          title: Text(quizName),
                          trailing: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => QuizViewPage(
                                    quizId: quizId,
                                    username: widget.username,
                                  ),
                                ),
                              ).then((_) {
                                setState(() {});
                              });
                            },
                            child: Text('Take Quiz'),
                          ),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            )
          : AccountStudentPage(username: widget.username),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Account',
          ),
        ],
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Future<List<String>> _fetchCompletedQuizzes(String username) async {
    try {
      QuerySnapshot submissions = await FirebaseFirestore.instance
          .collection('submissions')
          .where('username', isEqualTo: username)
          .get();

      // Ekstrak Quiz dari ID pada submissions
      List<String> completedQuizzes =
          submissions.docs.map((doc) => doc['quizId'] as String).toList();

      return completedQuizzes;
    } catch (e) {
      print('Error fetching completed quizzes: $e');
      return [];
    }
  }
}
