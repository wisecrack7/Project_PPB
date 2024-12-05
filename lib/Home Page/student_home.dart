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
  String searchQuery = "";
  bool isSearching = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 0
          ? AppBar(
              title: isSearching
                  ? TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search quizzes...',
                        border: InputBorder.none,
                      ),
                      style: TextStyle(color: Colors.white),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                    )
                  : Text('JustQuiz'),
              backgroundColor: Colors.teal.shade400,
              actions: [
                IconButton(
                  icon: Icon(isSearching ? Icons.close : Icons.search),
                  onPressed: () {
                    setState(() {
                      if (isSearching) {
                        isSearching = false;
                        searchQuery = "";
                      } else {
                        isSearching = true;
                      }
                    });
                  },
                ),
              ],
            )
          : null,
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 500),
        child: _currentIndex == 0
            ? FutureBuilder<Map<String, dynamic>>(
                future: _fetchCompletedQuizzesWithScores(widget.username),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error fetching quizzes',
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  Map<String, dynamic> completedQuizzes = snapshot.data ?? {};

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('quizzes')
                        .snapshots(),
                    builder: (context, quizSnapshot) {
                      if (!quizSnapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      final quizzes = quizSnapshot.data!.docs
                          .where((quiz) =>
                              quiz['quizName']
                                  ?.toLowerCase()
                                  .contains(searchQuery.toLowerCase()) ??
                              true)
                          .toList();

                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListView.builder(
                          itemCount: quizzes.length,
                          itemBuilder: (context, index) {
                            final document = quizzes[index];
                            final quizName =
                                document['quizName'] ?? 'Unnamed Quiz';
                            final quizId = document.id;

                            bool isCompleted =
                                completedQuizzes.containsKey(quizId);
                            String? score = isCompleted
                                ? completedQuizzes[quizId].toString()
                                : null;

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 12.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                              elevation: 4.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isCompleted
                                        ? [
                                            Colors.green.shade100,
                                            Colors.green.shade300
                                          ]
                                        : [
                                            Colors.teal.shade50,
                                            Colors.teal.shade100
                                          ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isCompleted
                                        ? Colors.green.shade400
                                        : Colors.teal.shade400,
                                    child: Icon(
                                      isCompleted
                                          ? Icons.check_circle_rounded
                                          : Icons.quiz_rounded,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(
                                    quizName,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3C3C3C),
                                    ),
                                  ),
                                  subtitle: isCompleted
                                      ? Text(
                                          'Score : ${score != null ? (double.tryParse(score) ?? 0).toInt() : 0}',

                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey.shade700,
                                          ),
                                        )
                                      : Text(
                                          'Not Attempted',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                  trailing: AnimatedSwitcher(
                                    duration: Duration(milliseconds: 300),
                                    child: isCompleted
                                        ? Icon(
                                            Icons.done,
                                            color: Colors.white,
                                            size: 28,
                                          )
                                        : ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12.0),
                                              ),
                                              backgroundColor:
                                                  Colors.teal.shade400,
                                              elevation: 3,
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 16.0,
                                                  vertical: 8.0),
                                            ),
                                            onPressed: () async {
                                              final startQuiz =
                                                  await showDialog<bool>(
                                                context: context,
                                                builder: (context) =>
                                                    AlertDialog(
                                                  title: Text('Confirmation'),
                                                  content: Text(
                                                      'Are you sure you want to start this quiz?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(
                                                            context, false);
                                                      },
                                                      child: Text('Cancel'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(
                                                            context, true);
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
                                              'Take Quiz',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              )
            : AccountStudentPage(username: widget.username),
      ),
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
        selectedItemColor: Colors.teal.shade400,
        unselectedItemColor: Colors.grey.shade600,
        backgroundColor: Colors.white,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchCompletedQuizzesWithScores(
      String username) async {
    try {
      QuerySnapshot submissions = await FirebaseFirestore.instance
          .collection('submissions')
          .where('username', isEqualTo: username)
          .get();

      Map<String, dynamic> completedQuizzes = {
        for (var doc in submissions.docs) doc['quizId']: doc['score']
      };

      return completedQuizzes;
    } catch (e) {
      print('Error fetching completed quizzes and scores: $e');
      return {};
    }
  }
}
