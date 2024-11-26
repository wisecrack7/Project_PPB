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
        title: Text('Student Dashboard'),
        backgroundColor: Colors.blueAccent,
        elevation: 4.0,
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
                child: Text(
                  'Error fetching quizzes',
                  style: TextStyle(color: Colors.red),
                ));
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

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView(
                  children: quizzes.map((document) {
                    final quizName = document['quizName'] ?? 'Unnamed Quiz';
                    final quizId = document.id;

                    bool isCompleted =
                    completedQuizzes.contains(quizId);

                    return Card(
                      elevation: 5.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isCompleted
                              ? Colors.green
                              : Colors.blueAccent,
                          child: Icon(
                            isCompleted
                                ? Icons.check_circle
                                : Icons.quiz,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          quizName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: isCompleted
                            ? Text(
                          'Completed',
                          style: TextStyle(
                              color: Colors.green,
                              fontStyle: FontStyle.italic),
                        )
                            : Text(
                          'Not Attempted',
                          style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic),
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            backgroundColor: isCompleted
                                ? Colors.grey
                                : Colors.blueAccent,
                          ),
                          onPressed: isCompleted
                              ? null
                              : () async {
                            final startQuiz =
                            await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Confirmation'),
                                content: Text(
                                    'Are you sure you want to start this quiz?'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context,
                                          false);
                                    },
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context, true);
                                    },
                                    child: Text('Start'),
                                  ),
                                ],
                              ),
                            );

                            if (startQuiz == true) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      QuizViewPage(
                                        quizId: quizId,
                                        username: widget.username,
                                      ),
                                ),
                              ).then((_) {
                                setState(() {});
                              });
                            }
                          },
                          child: Text(
                            isCompleted ? 'Done' : 'Take Quiz',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
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
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: false,
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

      // Extract Quiz IDs from submissions
      List<String> completedQuizzes =
      submissions.docs.map((doc) => doc['quizId'] as String).toList();

      return completedQuizzes;
    } catch (e) {
      print('Error fetching completed quizzes: $e');
      return [];
    }
  }
}
