import 'package:flutter/material.dart';

class ActivityDetailScreen extends StatelessWidget {
  final String activityId;
  final String activityName;
  final String activityDescription;
  final String activityCategory;
  final String activityDuration;
  final String activityTimestamp;

  const ActivityDetailScreen({
    super.key,
    required this.activityId,
    required this.activityName,
    required this.activityDescription,
    required this.activityCategory,
    required this.activityDuration,
    required this.activityTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(activityName)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              activityName,
              style: Theme.of(context).textTheme.headlineSmall, // 🔥 Fix für Flutter 3+
            ),
            const SizedBox(height: 10),
            Text("Kategorie: $activityCategory", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text("Dauer: $activityDuration", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text("Hinzugefügt: $activityTimestamp", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            Text(
              activityDescription,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Zurück'),
            ),
          ],
        ),
      ),
    );
  }
}