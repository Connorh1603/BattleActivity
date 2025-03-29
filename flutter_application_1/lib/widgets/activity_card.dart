import 'package:flutter/material.dart';
import '../screens/activity_detail_screen.dart';

class ActivityCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const ActivityCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActivityDetailScreen(data: data),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: const Icon(Icons.check_circle_outline),
          title: Text(data['title']),
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