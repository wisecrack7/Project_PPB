import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:project/Home Page/view_tracking_grade.dart'; // Ensure the import path is correct
import 'package:project/main.dart';

class AccountStudentPage extends StatefulWidget {
  final String username;

  //Menerima parameter username untuk mengambil data dari Firestore Database
  AccountStudentPage({required this.username});

  @override
  _AccountStudentPageState createState() => _AccountStudentPageState();
}

class _AccountStudentPageState extends State<AccountStudentPage> {
  //Default saat memuat data
  String name = "Loading...";
  String role = "Loading...";

  //Mengambil data dari Firestore Database
  @override
  void initState() {
    super.initState();
    _fetchAccountData();
  }

  //Mengambil data pengguna dari Firestore Database
  Future<void> _fetchAccountData() async {
    //Mendapatkan UID pengguna yang sedang login pada aplikasi
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (currentUserId.isEmpty) {
      _setDefaultValues();
      print("No user is currently logged in.");
      return;
    }
    //Mengambil dokumen pengguna dari dataLogin
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('dataLogin')
          .doc(currentUserId)
          .get();

      print("Fetching data for user ID: $currentUserId");
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          name = data['name'] ?? 'No Name';
          role = data['role'] ?? 'No Role';
        });
        print("Fetched data: $data");
      } else {
        _setDefaultValues();
        print("Document does not exist for user ID: $currentUserId");
      }
    } catch (e) {
      print("Error fetching account data: $e");
      _setDefaultValues();
    }
  }

  void _setDefaultValues() {
    setState(() {
      name = 'No Name';
      role = 'No Role';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Account Page',
            style: TextStyle(fontSize: 20),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Name: $name',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              'Role: $role',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ViewTrackingGrade(username: widget.username),
                  ),
                );
              },
              child: Text('View Tracking Nilai'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: () {
                _logout(context);
              },
              child: Text('Logout'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _logout(BuildContext context) {
    FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => MyApp()),
      (Route<dynamic> route) => false,
    );
  }
}
