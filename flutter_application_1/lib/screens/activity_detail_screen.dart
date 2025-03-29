import 'package:flutter/material.dart';

class ActivityDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const ActivityDetailScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Aktivitätsdetails"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['title'],
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.category),
                const SizedBox(width: 8),
                Text(data['category']),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.access_time),
                const SizedBox(width: 8),
                Text("${data['duration']} Minuten"),
              ],
            ),
            const SizedBox(height: 10),
            if ((data['description'] ?? "").isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Beschreibung", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(data['description']),
                ],
              ),
            const SizedBox(height: 20),
            Text(
              "Erstellt am: ${DateTime.fromMillisecondsSinceEpoch(data['timestamp'].millisecondsSinceEpoch).toLocal()}",
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}