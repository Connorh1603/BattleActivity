// ----------------------
// add_activity_screen.dart
// ----------------------
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddActivityScreen extends StatefulWidget {
  final List<Map<String, dynamic>> categories;

  const AddActivityScreen({super.key, required this.categories});

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  String title = '';
  String description = '';
  int duration = 0;
  String? category;

  void _saveActivity() async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? "dev_user";

    if (category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bitte wähle eine Kategorie!")),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('activities')
        .add({
      'title': title,
      'description': description,
      'duration': duration,
      'category': category,
      'timestamp': Timestamp.now(),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Neue Aktivität")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: "Titel"),
                onChanged: (val) => setState(() => title = val),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Beschreibung"),
                onChanged: (val) => setState(() => description = val),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Dauer (Minuten)"),
                keyboardType: TextInputType.number,
                onChanged: (val) => setState(() => duration = int.tryParse(val) ?? 0),
              ),
              DropdownButtonFormField(
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
                child: const Text("Speichern"),
                onPressed: _saveActivity,
              ),
            ],
          ),
        ),
      ),
    );
  }
}