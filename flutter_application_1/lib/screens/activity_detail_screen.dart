// ----------------------
// activity_detail_screen.dart (fixed)
// ----------------------
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_edit_activity_screen.dart';
import '../widgets/delete_dialog.dart';

class ActivityDetailScreen extends StatelessWidget {
  final DocumentSnapshot doc;
  final String userId;
  final List<Map<String, dynamic>> categories;

  const ActivityDetailScreen({super.key, required this.doc, required this.userId, required this.categories});

  void _deleteActivity(BuildContext context) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => const DeleteDialog(),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('activities')
          .doc(doc.id)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aktivität gelöscht 🗑️")),
      );
      Navigator.pop(context);
    }
  }

  void _editActivity(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditActivityScreen(
          userId: userId,
          existingDoc: doc,
          categories: categories,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Aktivitätsdetails"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteActivity(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['title'] ?? '',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text("Kategorie: ${data['category']}"),
            Text("Dauer: ${data['duration']} Minuten"),
            if ((data['description'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text("Beschreibung:", style: TextStyle(fontWeight: FontWeight.bold)),
              Text(data['description'] ?? ''),
            ],
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text("Bearbeiten"),
              onPressed: () => _editActivity(context),
            )
          ],
        ),
      ),
    );
  }
}