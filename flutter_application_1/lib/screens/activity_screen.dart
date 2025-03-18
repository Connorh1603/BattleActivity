import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/screens/activity_detail_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  _ActivityScreenState createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> with SingleTickerProviderStateMixin {
  bool isDeleting = false;
  late AnimationController _animationController;
  final CollectionReference activitiesCollection =
  FirebaseFirestore.instance.collection('activities');

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      lowerBound: -0.03,
      upperBound: 0.03,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // 🕒 Timestamp als "vor X Minuten/Stunden" formatieren
  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "Kein Datum";
    DateTime dateTime = timestamp.toDate();
    Duration difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes < 1) return "Gerade eben";
    if (difference.inMinutes < 60) return "vor ${difference.inMinutes} Minuten";
    if (difference.inHours < 24) return "vor ${difference.inHours} Stunden";
    return "am ${DateFormat('dd.MM.yyyy HH:mm').format(dateTime)}";
  }

  // 📌 Popup für neue Aktivität mit Apple-Timer
  void _showAddActivityDialog() {
    if (isDeleting) return; // 🔥 Blockiert das Hinzufügen im Löschmodus

    TextEditingController nameController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    ValueNotifier<String> selectedCategory = ValueNotifier<String>("Lernen");
    int selectedHours = 0;
    int selectedMinutes = 30;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Neue Aktivität hinzufügen"),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
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

                  // 🎛️ Apple-Style Timer für Dauer
                  SizedBox(
                    height: 100,
                    child: CupertinoTimerPicker(
                      mode: CupertinoTimerPickerMode.hm,
                      initialTimerDuration: Duration(hours: selectedHours, minutes: selectedMinutes),
                      onTimerDurationChanged: (Duration newDuration) {
                        selectedHours = newDuration.inHours;
                        selectedMinutes = newDuration.inMinutes % 60;
                      },
                    ),
                  ),

                  const SizedBox(height: 10),
                  ValueListenableBuilder<String>(
                    valueListenable: selectedCategory,
                    builder: (context, value, child) {
                      return DropdownButton<String>(
                        value: value,
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
                        onChanged: (newValue) {
                          selectedCategory.value = newValue!;
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
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
                    "category": selectedCategory.value,
                    "duration": "${selectedHours}h ${selectedMinutes}min",
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

  // 🔥 Aktivität löschen
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
              // 🔥 "Aktivität hinzufügen" wird ausgegraut, wenn im Löschmodus
              ElevatedButton(
                onPressed: isDeleting ? null : _showAddActivityDialog,
                child: const Text("Aktivität hinzufügen"),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isDeleting = !isDeleting;
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

                    // Timestamp formatieren
                    Timestamp? timestamp = data["timestamp"] as Timestamp?;
                    String formattedTime = formatTimestamp(timestamp);

                    return ListTile(
                      leading: _getCategoryIcon(data["category"]),
                      title: Text(data["name"]),
                      subtitle: Text(
                          "${data["description"]} • ${data["category"]}\nDauer: ${data["duration"]}\nHinzugefügt: $formattedTime"),
                      trailing: isDeleting
                          ? IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _deleteActivity(activity.id),
                      )
                          : null,
                      // 🔥 Klick öffnet Detailseite (außer im Löschmodus)
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
                              activityDuration: data["duration"],
                              activityTimestamp: formattedTime,
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