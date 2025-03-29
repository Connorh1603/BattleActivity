// ----------------------
// activity_screen.dart
// ----------------------
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_activity_screen.dart';
import '../widgets/activity_card.dart';
import '../widgets/category_chip.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  String selectedCategory = '';
  String searchText = '';

  final List<Map<String, dynamic>> categories = [
    {'name': 'Sport', 'icon': Icons.fitness_center},
    {'name': 'Lernen', 'icon': Icons.school},
    {'name': 'Kochen', 'icon': Icons.restaurant},
    {'name': 'Musik', 'icon': Icons.music_note},
  ];

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? "dev_user";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Meine Aktivitäten"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: "Aktivität suchen...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
              onChanged: (value) {
                setState(() {
                  searchText = value.toLowerCase();
                });
              },
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((cat) => CategoryChip(
                  category: cat,
                  selected: selectedCategory == cat['name'],
                  onTap: () {
                    setState(() {
                      selectedCategory = selectedCategory == cat['name'] ? '' : cat['name'];
                    });
                  },
                )).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('activities')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final docs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final title = data['title']?.toLowerCase() ?? '';
                    final category = data['category'] ?? '';
                    return (selectedCategory.isEmpty || category == selectedCategory) &&
                        (searchText.isEmpty || title.contains(searchText));
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.hourglass_empty, size: 60),
                          SizedBox(height: 8),
                          Text("Noch keine Aktivitäten 🪄"),
                        ],
                      ),
                    );
                  }

                  return ListView(
                    children: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return ActivityCard(data: data);
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddActivityScreen(categories: categories)),
        ),
      ),
    );
  }
}