import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:project/main.dart';

class AccountPage extends StatefulWidget {
  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String name = "Loading...";
  String role = "Loading...";

  @override
  void initState() {
    super.initState();
    _fetchAccountData();
  }

  Future<void> _fetchAccountData() async {
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null || currentUserId.isEmpty) {
      _setDefaultValues();
      print("No user is currently logged in.");
      return;
    }

    try {
      // Mengambil dokumen pengguna dari koleksi 'users' berdasarkan UID
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users') // Sesuaikan dengan nama koleksi Anda
          .doc(currentUserId)
          .get();

      print("Fetching data for user ID: $currentUserId");
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          name = data['name'] ?? 'No Name'; // Mengambil field 'name'
          role = data['role'] ?? 'No Role'; // Mengambil field 'role'
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Information',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
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
