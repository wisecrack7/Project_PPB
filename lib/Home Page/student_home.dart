import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/Quiz/view_quiz.dart';

class StudentHomePage extends StatefulWidget {
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
        stream: FirebaseFirestore.instance.collection('quizzes').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: snapshot.data!.docs.map((document) {
              final quizName = document['quizName'] ?? 'Unnamed Quiz'; // Retrieve quiz name
              return ListTile(
                title: Text(quizName), // Display quiz name
                trailing: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuizViewPage(
                          quizId: document.id,
                        ),
                      ),
                    );
                  },
                  child: Text('Take Quiz'),
                ),
              );
            }).toList(),
          );
        },
      )
          : Center(
        child: Text("Account Page"), // Placeholder for Account Page
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
        onTap: (int index) {
          setState(() {
            _currentIndex = index; // Switch between Home and Account pages
          });
        },
      ),
    );
  }
}
