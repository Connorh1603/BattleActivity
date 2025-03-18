import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class ActivityDetailScreen extends StatefulWidget {
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
  _ActivityDetailScreenState createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  late String name;
  late String description;
  late String category;
  late String duration;
  late String createdTimestamp;
  String? lastEditedTimestamp; // 🔥 Neues Feld für die letzte Bearbeitung

  @override
  void initState() {
    super.initState();
    name = widget.activityName;
    description = widget.activityDescription;
    category = widget.activityCategory;
    duration = widget.activityDuration;
    createdTimestamp = widget.activityTimestamp;

    _fetchLastEditedTimestamp(); // Letzte Bearbeitung aus Firestore holen
  }

  /// 🕒 Timestamp als "vor X Minuten/Stunden" formatieren
  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "-";
    DateTime dateTime = timestamp.toDate();
    Duration difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes < 1) return "Gerade eben";
    if (difference.inMinutes < 60) return "vor ${difference.inMinutes} Minuten";
    if (difference.inHours < 24) return "vor ${difference.inHours} Stunden";
    return "am ${DateFormat('dd.MM.yyyy HH:mm').format(dateTime)}";
  }

  /// 🔥 Holt die letzte Bearbeitungszeit aus Firestore
  void _fetchLastEditedTimestamp() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('activities')
        .doc(widget.activityId)
        .get();

    if (doc.exists && doc.data() != null) {
      var data = doc.data() as Map<String, dynamic>;
      if (data.containsKey("lastEdited") && data["lastEdited"] is Timestamp) {
        setState(() {
          lastEditedTimestamp = formatTimestamp(data["lastEdited"]);
        });
      }
    }
  }

  /// 📌 Öffnet das Bearbeiten-Fenster
  void _showEditDialog() {
    TextEditingController nameController = TextEditingController(text: name);
    TextEditingController descriptionController = TextEditingController(text: description);
    ValueNotifier<String> selectedCategory = ValueNotifier<String>(category);
    int selectedHours = 0;
    int selectedMinutes = 0;

    // 🔍 Dauer aus Firestore in Stunden & Minuten aufteilen
    RegExp regExp = RegExp(r'(\d+)h\s+(\d+)min');
    Match? match = regExp.firstMatch(duration);
    if (match != null) {
      selectedHours = int.parse(match.group(1)!);
      selectedMinutes = int.parse(match.group(2)!);
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Aktivität bearbeiten"),
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
                        items: ["Lernen", "Fitness", "Entspannung"].map((String cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Text(cat),
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
                String newDuration = "${selectedHours}h ${selectedMinutes}min";
                Timestamp lastEdited = Timestamp.now(); // 🔥 Letzten Bearbeitungszeitpunkt speichern

                // 🛠️ Firestore Update
                await FirebaseFirestore.instance
                    .collection('activities')
                    .doc(widget.activityId)
                    .update({
                  "name": nameController.text,
                  "description": descriptionController.text,
                  "category": selectedCategory.value,
                  "duration": newDuration,
                  "lastEdited": lastEdited, // Speichert den letzten Bearbeitungszeitpunkt
                });

                setState(() {
                  name = nameController.text;
                  description = descriptionController.text;
                  category = selectedCategory.value;
                  duration = newDuration;
                  lastEditedTimestamp = formatTimestamp(lastEdited); // 🔥 UI aktualisieren
                });

                Navigator.pop(context);
              },
              child: const Text("Speichern"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditDialog,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text("Kategorie: $category", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text("Dauer: $duration", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text("Hinzugefügt: $createdTimestamp", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text("Bearbeitet: ${lastEditedTimestamp ?? "-"}", style: const TextStyle(fontSize: 16, color: Colors.grey)), // 🔥 Zeigt "Bearbeitet: vor X Minuten" an, falls vorhanden
            const SizedBox(height: 20),
            Text(description, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}