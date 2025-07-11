import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserScreen extends StatefulWidget {
  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final _controller = TextEditingController();
  final _auth = FirebaseAuth.instance;
  User? _currentUser;
  String? _phoneNumber;
  String? _userName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _currentUser = _auth.currentUser;
      if (_currentUser != null) {
        await _fetchUserData(_currentUser!.uid);
        setState(() {});
      }
    });
  }

  Future<void> _fetchUserData(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _userName = data['username'] ?? 'Unknown';
        _phoneNumber = data['mobile'] ?? '';
        print('Fetched phone: $_phoneNumber');
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _submitContent() async {
    if (_controller.text.trim().isEmpty) return;

    await FirebaseFirestore.instance.collection('submissions').add({
      'content': _controller.text.trim(),
      'timestamp': Timestamp.now(),
      'status': 'pending',
      'phone': _phoneNumber ?? '',
      'username': _userName ?? 'Unknown',
    });

    _controller.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Submitted successfully')),
    );
  }

  Future<void> _editContent(String docId, String oldContent) async {
    final editController = TextEditingController(text: oldContent);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Submission', style: TextStyle(color: Colors.blue)),
        content: SizedBox(
          height: 200,
          width: 350,
          child: TextField(
            controller: editController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(hintText: 'Edit your content here'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('submissions')
                    .doc(docId)
                    .update({'content': editController.text});
                Navigator.pop(context);
              } catch (e) {
                print('Edit error: $e');
              }
            },
            child: Text('Save', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteContent(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete', style: TextStyle(color: Colors.blue)),
        content: Text('Are you sure you want to delete this submission?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('submissions').doc(docId).delete();
        setState(() {});
      } catch (e) {
        print('Delete error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _userName?.isNotEmpty == true ? _userName! : (_phoneNumber ?? 'User');

    return Scaffold(
      appBar: AppBar(
        // leading: IconButton(
        //   icon: Icon(Icons.arrow_back, color: Colors.white),
        //   onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
        // ),
        title: Text('User Dashboard', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),

      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text('Welcome, $displayName', style: TextStyle(fontSize: 16)),
            Text(
              'Welcome, $displayName 😊',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter Content',
                labelStyle: TextStyle(color: Colors.blue),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
              ),
              maxLines: 10,
              minLines: 5,
              keyboardType: TextInputType.multiline,
            ),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _submitContent,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                child: Text('Submit', style: TextStyle(color: Colors.blue)),
              ),
            ),
            SizedBox(height: 20),
            Text('Your Submissions:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Expanded(
              child: (_phoneNumber == null || _phoneNumber!.isEmpty)
                  ? Center(child: CircularProgressIndicator())
                  : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('submissions')
                    .where('phone', isEqualTo: _phoneNumber)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    print('StreamBuilder error: ${snapshot.error}');
                    return Center(child: Text('Something went wrong.'));
                  }

                  if (!snapshot.hasData || snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return Center(child: Text('No submissions yet.'));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final content = doc['content'] ?? '';

                      return Card(
                        child: ListTile(
                          title: Text(
                            content.length > 100
                                ? '${content.substring(0, 100)}...'
                                : content,
                          ),
                          subtitle: Text("Status: ${doc['status']}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editContent(doc.id, content),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteContent(doc.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
