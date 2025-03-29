import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/screens/group_detail_screen.dart';

class GroupScreen extends StatelessWidget {
  const GroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dynamisch die aktuelle Benutzer-ID holen
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String userId = currentUser?.uid ?? 'Unbekannt';

    return Scaffold(
      appBar: AppBar(title: Text('Gruppen')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("Benutzer nicht gefunden"));
          }

          // Benutzername aus dem Dokument holen
          final String username = snapshot.data!.get('username') ?? 'Unbekannter Nutzer';

          return Center(
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
                        .collection('Groups')
                        .where('members', arrayContains: userId)
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
                                  builder: (context) => GroupDetailScreen(
                                    groupId: group.id,
                                    username: username,  // Benutzername übergeben
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
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          _showCreateGroupDialog(context, userId);
                        },
                        child: Text('Gruppe erstellen'),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          _showJoinGroupDialog(context, userId);
                        },
                        child: Text('Gruppe beitreten'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Dialog zum Erstellen einer neuen Gruppe
  void _showCreateGroupDialog(BuildContext context, String userId) {
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
                _createGroup(nameController.text, typeController.text, userId);
                Navigator.pop(context);
              },
              child: Text("Erstellen"),
            ),
          ],
        );
      },
    );
  }

  /// Neue Gruppe erstellen
  void _createGroup(String name, String type, String userId) {
    if (name.isEmpty || type.isEmpty) return;

    FirebaseFirestore.instance.collection('Groups').add({
      'name': name,
      'typ': type,
      'members': [userId],
      'admin': userId,
    }).then((value) {
      print("Gruppe erstellt mit ID: ${value.id}");
      _checkAndCreateActivity(type, userId);
    }).catchError((error) {
      print("Fehler beim Erstellen der Gruppe: $error");
    });
  }

  /// Aktivität prüfen und ggf. erstellen
  void _checkAndCreateActivity(String type, String userId) async {
    final activitiesRef = FirebaseFirestore.instance.collection('Activities');
    QuerySnapshot existingActivities = await activitiesRef.where('typ', isEqualTo: type).get();

    if (existingActivities.docs.isEmpty) {
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

  /// Dialog zum Beitreten einer Gruppe über die Gruppen-ID
  void _showJoinGroupDialog(BuildContext context, String userId) {
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
                _joinGroup(idController.text, userId);
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
  void _joinGroup(String groupId, String userId) async {
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
        _checkAndCreateActivity(groupType, userId);
      }).catchError((error) {
        print("Fehler beim Beitreten der Gruppe: $error");
      });
    } else {
      print("Gruppe mit dieser ID existiert nicht.");
    }
  }
}
