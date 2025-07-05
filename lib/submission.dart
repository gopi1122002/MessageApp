import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SubmissionTile extends StatefulWidget {
  final String docId;
  final String content;
  final String status;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onDelete;

  const SubmissionTile({
    required this.docId,
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

  Future<void> _openWhatsAppGroup() async {
    final Uri url = Uri.parse('https://chat.whatsapp.com/EhOeBRYj0VTKIfIvzRR5pj?mode=r_t');

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open WhatsApp group')),
      );
    }
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
          ElevatedButton.icon(
            icon: Icon(Icons.check, color: Colors.white),
            label: Text('Accept', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              Navigator.pop(context);
              widget.onAccept();
              await _openWhatsAppGroup();
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
        ],
      ),
    );

    // Reset icon after dialog is closed
    setState(() {
      _isDialogOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: ListTile(
        title: Text(
          '••••••••••••••',
          style: TextStyle(fontFamily: 'monospace'),
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
                    title: Text('Delete Submission'),
                    content: Text('Are you sure you want to delete this submission?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  widget.onDelete();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
