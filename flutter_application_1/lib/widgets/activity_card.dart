// ----------------------
// activity_card.dart (Web + Mobile Ready, Polished)
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
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: (data['imageUrl'] ?? '').isNotEmpty
                ? Image.network(
              data['imageUrl'],
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            )
                : Container(
              width: 50,
              height: 50,
              color: Colors.grey[300],
              child: const Icon(Icons.image, size: 24),
            ),
          ),
          title: Text(
            data['title'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
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