import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project/Login and Register/welcome.dart'; // Import only WelcomeScreen

//Penggunaan Firebase untuk melakukan login
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            User? user = snapshot.data;
            // Pengarahan untuk langsung ke WelcomeScreen jika sudah terautentikasi
            return user == null ? WelcomeScreen() : WelcomeScreen(); // Modify this line if needed
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
