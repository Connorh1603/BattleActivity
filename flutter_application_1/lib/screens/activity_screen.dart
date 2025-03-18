import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'activity_detail_screen.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  _ActivityScreenState createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String selectedCategory = "Lernen";

  final CollectionReference activitiesCollection =
  FirebaseFirestore.instance.collection('activities');

  void _addActivity() async {
    if (nameController.text.isNotEmpty && descriptionController.text.isNotEmpty) {
      await activitiesCollection.add({
        "name": nameController.text,
        "description": descriptionController.text,
        "category": selectedCategory,
        "timestamp": FieldValue.serverTimestamp(),
      });

      nameController.clear();
      descriptionController.clear();
    }
  }

  void _deleteActivity(String docId) async {
    await activitiesCollection.doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aktivitäten')),
      body: Column(
        children: [
          Padding(
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
                    return DropdownMenuItem(value: category, child: Text(category));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _addActivity,
                  child: const Text("Aktivität hinzufügen"),
                ),
              ],
            ),
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

                    return ListTile(
                      title: Text(data["name"]),
                      subtitle: Text("${data["description"]} • ${data["category"]}"),
                      leading: _getCategoryIcon(data["category"]),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteActivity(activity.id),
                      ),
                      onTap: () {
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