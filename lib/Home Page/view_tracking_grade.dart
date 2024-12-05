import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ViewTrackingGrade extends StatelessWidget {
  final String username;

  ViewTrackingGrade({required this.username});

  Future<List<Map<String, dynamic>>> _fetchUserGrades() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('submissions')
        .where('username', isEqualTo: username)
        .get();

    List<Map<String, dynamic>> userGrades = [];
    for (var doc in querySnapshot.docs) {
      String quizId = doc['quizId'];

      DocumentSnapshot quizDoc = await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(quizId)
          .get();

      String quizName = quizDoc.exists ? quizDoc['quizName'] : 'Unknown Quiz';

      userGrades.add({
        'quizName': quizName,
        'score': doc['score'].toInt(),
        'timestamp': (doc['timestamp'] as Timestamp).toDate(),
      });
    }

    return userGrades;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tracking Grades for $username'),
        backgroundColor: Colors.teal,
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
            return Center(
              child: Text(
                'No grades available for $username.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            itemCount: grades.length,
            itemBuilder: (context, index) {
              final grade = grades[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.teal,
                    child: Icon(
                      Icons.assignment,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    grade['quizName'],
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade800,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 5),
                          Chip(
                            label: Text(
                              'Score: ${grade['score']}',
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.green,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time, color: Colors.grey, size: 20),
                          const SizedBox(width: 5),
                          Text(
                            'Completed: ${_formatDate(grade['timestamp'])}',
                            style: TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} "
        "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }
}
