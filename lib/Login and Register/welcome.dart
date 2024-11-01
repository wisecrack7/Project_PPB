import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:project/Home Page/student_home.dart';
import 'package:project/Login and Register/register.dart';
import 'package:project/Home Page/teacher_home.dart';

class WelcomeScreen extends StatelessWidget {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> _login(BuildContext context) async {
    try {
      // Retrieve users from Firestore where email or username matches
      QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: usernameController.text.trim())
          .where('password', isEqualTo: passwordController.text.trim())
          .get();

      // If no matches, try with username
      if (userQuery.docs.isEmpty) {
        userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: usernameController.text.trim())
            .where('password', isEqualTo: passwordController.text.trim())
            .get();
      }

      // Debug print
      print('Username/Email: ${usernameController.text.trim()}');
      print('Password: ${passwordController.text.trim()}');
      print('Number of matching documents: ${userQuery.docs.length}');

      // Check if a matching user document exists
      if (userQuery.docs.isNotEmpty) {
        final userDoc = userQuery.docs.first;
        final String role = userDoc['role'];
        final String userId = userDoc.id; // Get the UserID

        // Store user data in the dataLogin collection
        await _storeUserDataInDataLogin(userDoc, userId);

        // Navigate based on role
        if (role.toLowerCase() == 'teacher') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    TeacherHomeView(username: userDoc['username'])),
          );
        } else if (role.toLowerCase() == 'student') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => StudentHomePage()),
          );
        } else {
          _showErrorDialog(context, 'Invalid role.');
        }
      } else {
        _showErrorDialog(context, 'Invalid email/username or password.');
      }
    } catch (e) {
      _showErrorDialog(context, 'An error occurred: ${e.toString()}');
    }
  }

  Future<void> _storeUserDataInDataLogin(DocumentSnapshot userDoc, String userId) async {
    try {
      // Create a new document in dataLogin collection with UserID as the document ID
      await FirebaseFirestore.instance.collection('dataLogin').doc(userId).set({
        'currentId': userId,
        ...userDoc.data() as Map<String, dynamic>, // Include all user data
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
                          labelText: 'Email or Username',
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
