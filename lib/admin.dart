import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'submission.dart';
import 'SubmissionHistory.dart';// Your SubmissionTile widget

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  Future<void> _sendToWhatsApp(String content) async {
    final number = "1234567890"; // Replace with actual number
    final msg = Uri.encodeComponent(content);
    final url = "https://wa.me/$number?text=$msg";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('sending message')),
      );
    }
  }

  Future<void> _acceptSubmission(String docId, String content) async {
    await FirebaseFirestore.instance
        .collection('submissions')
        .doc(docId)
        .update({'status': 'accepted'});

    await _sendToWhatsApp("Accepted: $content");
  }

  Future<void> _rejectSubmission(String docId) async {
    await FirebaseFirestore.instance
        .collection('submissions')
        .doc(docId)
        .update({'status': 'rejected'});
  }

  Future<void> _deleteSubmission(String docId) async {
    await FirebaseFirestore.instance
        .collection('submissions')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white,size: 28,),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
          title: Text(
            'Admin Dashboard',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Colors.blue,
          actions: [
            IconButton(
              icon: Icon(Icons.history, color: Colors.white),
              tooltip: 'View History',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SubmissionHistoryScreen()),
                );
              },
            )
          ],
        ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('submissions')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          return ListView(
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return SubmissionTile(
                docId: doc.id,
                username: data['username'] ?? 'unknown',
                content: data['content'] ?? '',
                status: data['status'] ?? 'pending',
                onAccept: () => _acceptSubmission(doc.id, data['content']),
                onReject: () => _rejectSubmission(doc.id),
                onDelete: () => _deleteSubmission(doc.id),
              );
            }).toList(),
          );
        },
      )
    );
  }
}
