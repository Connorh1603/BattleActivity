import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  _ActivityScreenState createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  bool isDeleting = false; // Zustand für Löschmodus

  final CollectionReference activitiesCollection =
  FirebaseFirestore.instance.collection('activities');

  // Aktivität hinzufügen (öffnet Dialog)
  void _showAddActivityDialog() {
    TextEditingController nameController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    String selectedCategory = "Lernen";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Neue Aktivität hinzufügen"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Abbrechen"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty &&
                    descriptionController.text.isNotEmpty) {
                  await activitiesCollection.add({
                    "name": nameController.text,
                    "description": descriptionController.text,
                    "category": selectedCategory,
                    "timestamp": FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Hinzufügen"),
            ),
          ],
        );
      },
    );
  }

  // Aktivität löschen
  void _deleteActivity(String docId) async {
    await activitiesCollection.doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aktivitäten')),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _showAddActivityDialog,
                child: const Text("Aktivität hinzufügen"),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isDeleting = !isDeleting; // Löschmodus an/aus
                  });
                },
                child: Text(isDeleting ? "Fertig" : "Aktivität löschen"),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: activitiesCollection.orderBy("timestamp", descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var activities = snapshot.data!.docs;

                return ListView.separated(
                  itemCount: activities.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    var activity = activities[index];
                    var data = activity.data() as Map<String, dynamic>;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      transform: isDeleting
                          ? Matrix4.rotationZ(0.02) // Wackeleffekt
                          : Matrix4.identity(),
                      child: ListTile(
                        title: Text(data["name"]),
                        subtitle: Text("${data["description"]} • ${data["category"]}"),
                        leading: _getCategoryIcon(data["category"]),
                        trailing: isDeleting
                            ? IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _deleteActivity(activity.id),
                        )
                            : null,
                        onTap: isDeleting
                            ? null
                            : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ActivityDetailScreen(
                                activityId: activity.id,
                                activityName: data["name"],
                                activityDescription: data["description"],
                                activityCategory: data["category"],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
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