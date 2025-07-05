import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserScreen extends StatefulWidget {
  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final _controller = TextEditingController();

  Future<void> _submitContent() async {
    if (_controller.text.trim().isNotEmpty) {
      await FirebaseFirestore.instance.collection('submissions').add({
        'content': _controller.text.trim(),
        'timestamp': Timestamp.now(),
        'status': 'pending',
      });
      _controller.clear();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Submitted successfully')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back,color: Colors.white),
          onPressed: () {
            // Navigate to login page (replace '/login' with your route)
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),
        title: Text('User Dashboard',
        style: TextStyle(color: Colors.white),
      ),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),

      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(height: 50),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter Content',
                labelStyle: TextStyle(color: Colors.blue),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),  // blue border when not focused
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2),  // blue border when focused
                ),
              ),
              maxLines: 10,
              minLines: 5,
              keyboardType: TextInputType.multiline,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitContent,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
              ),
              child: Text(
                'Submit',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),

    );
  }
}
