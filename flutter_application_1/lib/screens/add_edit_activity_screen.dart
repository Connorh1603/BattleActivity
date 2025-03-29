import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddEditActivityScreen extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final String userId;
  final DocumentSnapshot? existingDoc;

  const AddEditActivityScreen({
    super.key,
    required this.categories,
    required this.userId,
    this.existingDoc,
  });

  @override
  State<AddEditActivityScreen> createState() => _AddEditActivityScreenState();
}

class _AddEditActivityScreenState extends State<AddEditActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  String title = '';
  String description = '';
  int duration = 0;
  String? category;

  @override
  void initState() {
    super.initState();
    if (widget.existingDoc != null) {
      final data = widget.existingDoc!.data() as Map<String, dynamic>;
      title = data['title'] ?? '';
      description = data['description'] ?? '';
      duration = data['duration'] ?? 0;
      category = data['category'] ?? null;
    }
  }

  void _saveActivity() async {
    if (category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bitte wähle eine Kategorie!")),
      );
      return;
    }

    final data = {
      'title': title,
      'description': description,
      'duration': duration,
      'category': category,
      'timestamp': Timestamp.now(),
    };

    if (widget.existingDoc == null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('activities')
          .add(data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aktivität erstellt ✅")),
      );
    } else {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('activities')
          .doc(widget.existingDoc!.id)
          .update(data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aktivität aktualisiert ✅")),
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existingDoc == null ? "Neue Aktivität" : "Aktivität bearbeiten")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: title,
                decoration: const InputDecoration(labelText: "Titel"),
                onChanged: (val) => setState(() => title = val),
              ),
              TextFormField(
                initialValue: description,
                decoration: const InputDecoration(labelText: "Beschreibung"),
                onChanged: (val) => setState(() => description = val),
              ),
              TextFormField(
                initialValue: duration == 0 ? '' : duration.toString(),
                decoration: const InputDecoration(labelText: "Dauer (Minuten)"),
                keyboardType: TextInputType.number,
                onChanged: (val) => setState(() => duration = int.tryParse(val) ?? 0),
              ),
              DropdownButtonFormField(
                value: category,
                decoration: const InputDecoration(labelText: "Kategorie"),
                items: widget.categories.map((cat) => DropdownMenuItem(
                  value: cat['name'],
                  child: Row(
                    children: [
                      Icon(cat['icon'], size: 18),
                      const SizedBox(width: 8),
                      Text(cat['name'])
                    ],
                  ),
                )).toList(),
                onChanged: (val) => setState(() => category = val as String?),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                child: Text(widget.existingDoc == null ? "Speichern" : "Aktualisieren"),
                onPressed: _saveActivity,
              ),
            ],
          ),
        ),
      ),
    );
  }
}