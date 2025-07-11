import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'submission.dart'; // your SubmissionTile widget

class SubmissionHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Submission History', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.blue,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white,size: 28,),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'Accepted'),
              Tab(text: 'Rejected'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildSubmissionsList('accepted', Colors.green),
            _buildSubmissionsList('rejected', Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionsList(String status, Color color) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('submissions')
          .where('status', isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text('No $status submissions', style: TextStyle(color: color)),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return SubmissionTile(
              docId: docs[index].id,
              username: data['username'] ?? 'Unknown',
              content: data['content'] ?? '',
              status: status,
              onAccept: () {}, // Disabled
              onReject: () {}, // Disabled
              onDelete: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('submissions')
                      .doc(docs[index].id)
                      .delete();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Submission deleted')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e')),
                  );
                }
              },
// Optional
            );
          },
        );
      },
    );
  }
}
