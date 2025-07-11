import 'package:flutter/material.dart';
import 'package:flutter/services.dart';  // for Clipboard
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubmissionTile extends StatefulWidget {
  final String docId;
  final String username;
  final String content;
  final String status;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onDelete;

  const SubmissionTile({
    required this.docId,
    required this.username,
    required this.content,
    required this.status,
    required this.onAccept,
    required this.onReject,
    required this.onDelete,
    super.key,
  });

  @override
  _SubmissionTileState createState() => _SubmissionTileState();
}

class _SubmissionTileState extends State<SubmissionTile> {
  bool _isDialogOpen = false;

  Future<void> _openWhatsAppGroupAndCopyMessage(String message) async {
    final Uri whatsappGroupUrl = Uri.parse("https://chat.whatsapp.com/EhOeBRYj0VTKIfIvzRR5pj");

    // Copy the message text to clipboard
    await Clipboard.setData(ClipboardData(text: message));

    // Try to launch the WhatsApp group link
    if (!await launchUrl(whatsappGroupUrl, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open WhatsApp group link')),
      );
      return;
    }

    // Show snackbar telling user message copied
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Message copied to clipboard.',
          maxLines: 2,
        ),
      ),
    );
  }

  void _showPopupDialog() async {
    setState(() {
      _isDialogOpen = true;
    });

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('User Message'),
        content: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    widget.content,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Status: ',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    TextSpan(
                      text: '${widget.status[0].toUpperCase()}${widget.status.substring(1)}',
                      style: TextStyle(
                        color: widget.status == 'accepted'
                            ? Colors.green
                            : widget.status == 'rejected'
                            ? Colors.red
                            : Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (widget.status == 'pending') ...[
            ElevatedButton.icon(
              icon: Icon(Icons.check, color: Colors.white),
              label: Text('Accept', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                Navigator.pop(context);
                widget.onAccept();
                await _openWhatsAppGroupAndCopyMessage(widget.content);
              },
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.close, color: Colors.white),
              label: Text('Reject', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                widget.onReject();
              },
            ),
          ]
        ],

      ),
    );

    setState(() {
      _isDialogOpen = false;
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: ListTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.username,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 4),
            Text(
              widget.content.length > 15
                  ? '${widget.content.substring(0, 15)}...'
                  : widget.content,
              style: TextStyle(fontFamily: 'monospace'),
            ),
          ],
        ),
        subtitle: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Status: ',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              TextSpan(
                text: '${widget.status[0].toUpperCase()}${widget.status.substring(1)}',
                style: TextStyle(
                  color: widget.status == 'accepted'
                      ? Colors.green
                      : widget.status == 'rejected'
                      ? Colors.red
                      : Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                _isDialogOpen ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              tooltip: 'View message',
              onPressed: _showPopupDialog,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'Clear/Delete',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Delete Submission', style: TextStyle(color: Colors.blue)),
                    content: Text('Are you sure you want to delete this submission?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Cancel', style: TextStyle(color: Colors.black)),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.redAccent,
                        ),
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('submissions')
                        .doc(widget.docId)
                        .delete();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Submission deleted')),
                    );

                    // Optional callback to parent
                    widget.onDelete();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete: $e')),
                    );
                  }
                }
              },
            ),

          ],
        ),
      ),
    );
  }

}
