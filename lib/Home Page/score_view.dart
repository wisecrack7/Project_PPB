import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScoreViewPage extends StatelessWidget {
  final String quizId;

  ScoreViewPage({required this.quizId});

  @override
  Widget build(BuildContext context) {
    print("Quiz ID received: $quizId"); // Log untuk cek quizId

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scores for Quiz'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('submissions')
              .where('quizId', isEqualTo: quizId)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              print("No data found for quizId: $quizId"); // Log jika data tidak ditemukan
              return const Center(
                child: Text('No submissions found for this quiz.'),
              );
            }

            final submissions = snapshot.data!.docs;
            print("Found ${submissions.length} submissions for quizId: $quizId"); // Log jumlah data
            for (var doc in submissions) {
              print("Submission data: ${doc.data()}"); // Log isi data
            }

            return ListView.builder(
              itemCount: submissions.length,
              itemBuilder: (context, index) {
                final data = submissions[index].data() as Map<String, dynamic>;
                final username = data['username'] ?? 'Unknown';
                final score = data['score'] ?? 0;
                final timestamp = data['timestamp'] != null
                    ? (data['timestamp'] as Timestamp).toDate()
                    : null;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        username.isNotEmpty ? username[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.blue,
                    ),
                    title: Text(username),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Score: $score'),
                        if (timestamp != null)
                          Text(
                            'Completed: ${_formatDate(timestamp)}',
                            style: const TextStyle(fontSize: 12),
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
    );
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} "
        "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }
}
