import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupScreen extends StatelessWidget {
  const GroupScreen({super.key});
  final String userId = "user123"; // Beispielhafte Nutzer-ID

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gruppen')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Deine Gruppen',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Groups') // Name der Sammlung
                    .where('members', arrayContains: userId) // Filter auf Mitglieder
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'Du bist in keiner Gruppe.',
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }

                  // Gruppen anzeigen
                  final groups = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      final groupName = group['name'] ?? 'Unbekannte Gruppe';

                      return ListTile(
                        title: Text(groupName),
                        onTap: () {
                          // Logik bei Klick auf eine Gruppe
                          print('Gruppe ausgewählt: ${group.id}');
                        },
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/profile'); // Navigation zur Profilseite
                    },
                    child: Text('Profile'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/archievement'); // Navigation zu Erfolgen
                    },
                    child: Text('Erfolge'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/activity'); // Navigation zu Aktivitäten
                    },
                    child: Text('Aktivitäten'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
