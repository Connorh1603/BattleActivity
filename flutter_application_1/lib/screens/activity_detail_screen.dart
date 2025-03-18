import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityDetailScreen extends StatefulWidget {
  final String activityId;
  final String activityName;
  final String activityDescription;
  final String activityCategory;

  const ActivityDetailScreen({
    super.key,
    required this.activityId,
    required this.activityName,
    required this.activityDescription,
    required this.activityCategory,
  });

  @override
  _ActivityDetailScreenState createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late String selectedCategory;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.activityName);
    descriptionController = TextEditingController(text: widget.activityDescription);
    selectedCategory = widget.activityCategory;
  }

  void _updateActivity() async {
    await FirebaseFirestore.instance.collection('activities').doc(widget.activityId).update({
      "name": nameController.text,
      "description": descriptionController.text,
      "category": selectedCategory,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.activityName)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Aktivität"),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: "Beschreibung"),
            ),
            const SizedBox(height: 10),
            DropdownButton<String>(
              value: selectedCategory,
              items: ["Lernen", "Fitness", "Entspannung"].map((String category) {
                return DropdownMenuItem(
                  value: category,
                  child: Row(
                    children: [
                      _getCategoryIcon(category),
                      const SizedBox(width: 10),
                      Text(category),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateActivity,
              child: const Text("Speichern"),
            ),
          ],
        ),
      ),
    );
  }

  Icon _getCategoryIcon(String category) {
    switch (category) {
      case "Lernen":
        return const Icon(Icons.book, color: Colors.blue);
      case "Fitness":
        return const Icon(Icons.fitness_center, color: Colors.red);
      case "Entspannung":
        return const Icon(Icons.self_improvement, color: Colors.green);
      default:
        return const Icon(Icons.category, color: Colors.grey);
    }
  }
}