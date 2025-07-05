import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select Role")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: Text('Login as User'),
              onPressed: () => Navigator.pushNamed(context, '/user-login'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Login as Admin'),
              onPressed: () => Navigator.pushNamed(context, '/admin-login'),
            ),
          ],
        ),
      ),
    );
  }
}
