import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:project/Home Page/account_student.dart';
import 'package:project/Quiz/view_quiz.dart';

class StudentHomePage extends StatefulWidget {
  final String username;

  StudentHomePage({required this.username});

  //Menerima parameter username untuk mengambil data dari Firestore Database
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
          ? StreamBuilder(
              stream:
                  FirebaseFirestore.instance.collection('quizzes').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                return ListView(
                  children: snapshot.data!.docs.map((document) {
                    final quizName = document['quizName'] ?? 'Unnamed Quiz';

                    //Pengecekan hasil submit ke Firestore Database
                    bool isSubmitted = false;


                    FirebaseFirestore.instance
                        .collection('submissions')
                        .where('username', isEqualTo: widget.username)
                        .where('quizId', isEqualTo: document.id)
                        .get()
                        .then((value) {
                      if (value.docs.isNotEmpty) {
                        isSubmitted = true;
                      }
                    });

                    if (isSubmitted)
                      return Container(); // Skip submitted quizzes

                    return ListTile(
                      title: Text(quizName),
                      trailing: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuizViewPage(
                                quizId: document.id,
                                username: widget.username,
                              ),
                            ),
                          ).then((_) {
                            setState(
                                () {}); // Refresh after returning from quiz
                          });
                        },
                        child: Text('Take Quiz'),
                      ),
                    );
                  }).toList(),
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
}
