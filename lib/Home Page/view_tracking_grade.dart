import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ViewTrackingGrade extends StatelessWidget {
  final String username;

  //Dibutuhkan data username untuk menampilkan data dari Firestore Database
  ViewTrackingGrade({required this.username});

  //Mengambil data grade dari Firestore Database
  Future<List<Map<String, dynamic>>> _fetchUserGrades() async {
    //Mengambil data yang spesifik berdasarkan username
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('submissions')
        .where('username', isEqualTo: username)
        .get();

    //Menampilkan data QuizId, score,dan waktu pengerjaanya
    return querySnapshot.docs.map((doc) {
      return {
        'quizId': doc['quizId'],
        'score': doc['score'],
        'timestamp': (doc['timestamp'] as Timestamp).toDate(),
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tracking Grades for $username'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchUserGrades(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading grades.'));
          }
          final grades = snapshot.data ?? [];
          if (grades.isEmpty) {
            return Center(child: Text('No grades available for $username.'));
          }
          return ListView.builder(
            itemCount: grades.length,
            itemBuilder: (context, index) {
              final grade = grades[index];
              return ListTile(
                title: Text('Quiz ID: ${grade['quizId']}'),
                subtitle: Text('Score: ${grade['score']}%'),
                trailing: Text(
                  '${grade['timestamp']}',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
