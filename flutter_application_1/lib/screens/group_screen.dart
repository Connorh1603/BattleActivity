import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/screens/group_detail_screen.dart';

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
                      final groupType = group['typ'] ?? 'Kein Typ';

                      return ListTile(
                        title: Text(groupName),
                        subtitle: Text(groupType),
                        onTap: () {
                            Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GroupDetailScreen(groupId: group.id),
                            ),
                          );
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
                      Navigator.pushNamed(context, '/profile');
                    },
                    child: Text('Profile'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/archievement');
                    },
                    child: Text('Erfolge'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/activity');
                    },
                    child: Text('Aktivitäten'),
                  ),
                  SizedBox(height: 20), // Abstand
                  ElevatedButton(
                    onPressed: () {
                      _showCreateGroupDialog(context);
                    },
                    child: Text('Gruppe erstellen'),
                  ),
                  SizedBox(height: 10), // Abstand
                  ElevatedButton(
                    onPressed: () {
                      _showJoinGroupDialog(context);
                    },
                    child: Text('Gruppe beitreten'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog zum Erstellen einer neuen Gruppe
  void _showCreateGroupDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController typeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Neue Gruppe erstellen"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: "Gruppenname"),
              ),
              TextField(
                controller: typeController,
                decoration: InputDecoration(labelText: "Gruppentyp"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Abbrechen"),
            ),
            ElevatedButton(
              onPressed: () {
                _createGroup(nameController.text, typeController.text);
                Navigator.pop(context);
              },
              child: Text("Erstellen"),
            ),
          ],
        );
      },
    );
  }

  /// Fügt eine neue Gruppe zur Firebase-Datenbank hinzu
  void _createGroup(String name, String type) {
    if (name.isEmpty || type.isEmpty) return;

    FirebaseFirestore.instance.collection('Groups').add({
      'name': name,
      'typ': type,
      'members': [userId], // Nutzer wird direkt als Mitglied hinzugefügt
    }).then((value) {
      print("Gruppe erstellt mit ID: ${value.id}");

      // 🔍 Prüfen, ob es bereits eine Aktivität mit diesem Typ gibt
      _checkAndCreateActivity(type);
    }).catchError((error) {
      print("Fehler beim Erstellen der Gruppe: $error");
    });
  }


  /// Dialog zum Beitreten einer Gruppe über die Gruppen-ID
  void _showJoinGroupDialog(BuildContext context) {
    final TextEditingController idController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Gruppe beitreten"),
          content: TextField(
            controller: idController,
            decoration: InputDecoration(labelText: "Gruppen-ID eingeben"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Abbrechen"),
            ),
            ElevatedButton(
              onPressed: () {
                _joinGroup(idController.text);
                Navigator.pop(context);
              },
              child: Text("Beitreten"),
            ),
          ],
        );
      },
    );
  }

  /// Fügt den aktuellen Nutzer einer bestehenden Gruppe hinzu
  void _joinGroup(String groupId) async {
    if (groupId.isEmpty) return;

    DocumentReference groupRef = FirebaseFirestore.instance.collection('Groups').doc(groupId);

    // Prüfe, ob die Gruppe existiert
    DocumentSnapshot groupSnapshot = await groupRef.get();

    if (groupSnapshot.exists) {
      final String groupType = groupSnapshot['typ'] ?? '';

      // Füge den Nutzer zur Mitgliederliste hinzu
      groupRef.update({
        'members': FieldValue.arrayUnion([userId]),
      }).then((_) {
        print("Erfolgreich der Gruppe beigetreten!");

        // 🔍 Prüfen, ob es bereits eine Aktivität mit diesem Typ gibt
        _checkAndCreateActivity(groupType);
      }).catchError((error) {
        print("Fehler beim Beitreten der Gruppe: $error");
      });
    } else {
      print("Gruppe mit dieser ID existiert nicht.");
    }
  }

  void _checkAndCreateActivity(String type) async {
  final activitiesRef = FirebaseFirestore.instance.collection('Activities');

  // 🔍 Prüfen, ob es bereits eine Aktivität mit diesem Typ gibt
  QuerySnapshot existingActivities = await activitiesRef.where('typ', isEqualTo: type).get();

  if (existingActivities.docs.isEmpty) {
    // 📌 Keine Aktivität gefunden → Erstelle eine neue
    activitiesRef.add({
      'typ': type,
      'user': userId,
      'valueMonthly': 0,
      'valueFull': 0,
    }).then((value) {
      print("Neue Aktivität erstellt mit ID: ${value.id}");
    }).catchError((error) {
      print("Fehler beim Erstellen der Aktivität: $error");
    });
  } else {
    print("Aktivität für Typ '$type' existiert bereits.");
  }
}


  
}
