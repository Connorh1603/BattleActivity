// ----------------------
// activity_card.dart (fixed)
// ----------------------
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/activity_detail_screen.dart';

class ActivityCard extends StatelessWidget {
  final DocumentSnapshot doc;
  final String userId;

  const ActivityCard({super.key, required this.doc, required this.userId});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ActivityDetailScreen(
              doc: doc,
              userId: userId,
              categories: const [
                {'name': 'Sport', 'icon': Icons.fitness_center},
                {'name': 'Lernen', 'icon': Icons.school},
                {'name': 'Kochen', 'icon': Icons.restaurant},
                {'name': 'Musik', 'icon': Icons.music_note},
              ],
            ),
          ),
        );
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: const Icon(Icons.check_circle_outline),
          title: Text(data['title'] ?? ''),
          subtitle: Text("${data['category']} • ${data['duration']} min"),
          trailing: Text(
            DateTime.fromMillisecondsSinceEpoch(data['timestamp'].millisecondsSinceEpoch)
                .toLocal()
                .toString()
                .substring(0, 16),
            style: const TextStyle(fontSize: 10),
          ),
        ),
      ),
    );
  }
}