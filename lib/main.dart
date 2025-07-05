import 'package:flutter/material.dart';
// Import your screens
import 'auth_screen.dart';
import 'admin.dart';
import 'user.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MessageApp',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      initialRoute: '/', // Start at login
      routes: {
        '/': (context) => AuthScreen(),
        '/admin': (context) => AdminScreen(),
        '/user': (context) => UserScreen(), // create this if you haven't yet
        '/login': (context) => AuthScreen(), // alias if you want
      },
    );
  }
}
