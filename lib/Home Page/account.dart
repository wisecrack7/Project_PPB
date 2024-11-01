import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:project/main.dart';

class AccountPage extends StatefulWidget {
  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String username = "Loading..."; // Default value while fetching
  String role = "Loading..."; // Default value while fetching
  String userId = "Loading..."; // Default value while fetching

  @override
  void initState() {
    super.initState();
    _fetchAccountData(); // Fetch user data when the widget is initialized
  }

  Future<void> _fetchAccountData() async {
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Ensure userId is not empty
    if (currentUserId.isEmpty) {
      _setDefaultValues();
      print("No user is currently logged in.");
      return; // Exit if no user is logged in
    }

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('dataLogin') // Change to dataLogin collection
          .doc(currentUserId) // Use the current user's UID to get the document
          .get();

      print("Fetching data for user ID: $currentUserId");
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          username = data['name'] ?? 'No Name';
          role = data['role'] ?? 'No Role';
          userId = currentUserId; // Use the user ID directly from authentication
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
      username = 'No Name';
      role = 'No Role';
      userId = 'No User ID';
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
              'Name: $username',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              'Role: $role',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              'User ID: $userId',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                showTrackingDialog(context);
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

  void showTrackingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Tracking Nilai'),
        content: Text('Berikut adalah nilai Anda: ...'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    FirebaseAuth.instance.signOut(); // Sign out the user
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => MyApp()),
          (Route<dynamic> route) => false,
    );
  }
}
