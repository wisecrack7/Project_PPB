import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:project/Home Page/student_home.dart';
import 'package:project/Home Page/teacher_home.dart'; // Ensure this import is correct
import 'package:project/Login and Register/register.dart';

class WelcomeScreen extends StatelessWidget {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> _login(BuildContext context) async {
    try {
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: usernameController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Mendapatkan detail user dari Firestore Database
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user?.uid)
          .get();

      if (userDoc.exists) {
        //Menyimpan data user ke dataLogin
        await _storeUserDataInDataLogin(userDoc, userDoc.id);

        final String role = userDoc['role'];

        if (role == 'Teacher') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  TeacherHomeView(username: userDoc['username']),
            ),
          );
        } else {
          // Mengarahkan ke StudentHomePage
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  StudentHomePage(username: userDoc['username']),
            ),
          );
        }
      } else {
        _showErrorDialog(context, 'User not found in database.');
      }
    } catch (e) {
      _showErrorDialog(context, 'Terjadi kesalahan: ${e.toString()}');
    }
  }

  Future<void> _storeUserDataInDataLogin(
      DocumentSnapshot userDoc, String userId) async {
    try {
      // Membuat dokument baru di dataLogin collection dengan userID
      await FirebaseFirestore.instance.collection('dataLogin').doc(userId).set({
        'currentId': userId,
        ...userDoc.data() as Map<String, dynamic>,
      });
      print('User data stored in dataLogin successfully.');
    } catch (e) {
      print('Failed to store user data in dataLogin: $e');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Card(
                elevation: 8,
                color: Colors.white.withOpacity(0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Welcome To JustQuiz',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: usernameController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => _login(context),
                        child: Text('Login'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => RegisterView()),
                          );
                        },
                        child: Text(
                          'Don\'t have an account? Register here',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
