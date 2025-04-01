import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/screens/group_detail_screen.dart';

class GroupScreen extends StatelessWidget {
  const GroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                                    username: username,
                                    userId : userId,
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
                ElevatedButton(
                  onPressed: () {
                    _showCreateGroupDialog(context, userId);
                  },
                  child: Text('Gruppe erstellen'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _showJoinGroupDialog(context, userId);
                  },
                  child: Text('Gruppe beitreten'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context, String userId) {
    final TextEditingController nameController = TextEditingController();
    String? selectedCategory;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Neue Gruppe erstellen"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: "Gruppenname"),
                  ),
                  FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance.collection('Categories').get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return CircularProgressIndicator();
                      List<String> categories = snapshot.data!.docs.map((doc) => doc.id).toList();
                      return DropdownButton<String>(
                        value: selectedCategory,
                        hint: Text("Kategorie auswählen"),
                        isExpanded: true,
                        items: categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCategory = value;
                          });
                        },
                      );
                    },
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
                    _createGroup(nameController.text, selectedCategory ?? "Kein Typ", userId);
                    Navigator.pop(context);
                  },
                  child: Text("Erstellen"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showJoinGroupDialog(BuildContext context, String userId) {
    final TextEditingController groupIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Gruppe beitreten"),
          content: TextField(
            controller: groupIdController,
            decoration: InputDecoration(labelText: "Gruppen-ID"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Abbrechen"),
            ),
            ElevatedButton(
              onPressed: () async {
                final groupId = groupIdController.text.trim();
                if (groupId.isNotEmpty) {
                  final groupRef = FirebaseFirestore.instance.collection('Groups').doc(groupId);
                  final groupSnap = await groupRef.get();

                  if (groupSnap.exists) {
                    await groupRef.update({
                      'members': FieldValue.arrayUnion([userId]),
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gruppe beigetreten.")));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gruppe nicht gefunden.")));
                  }
                }
              },
              child: Text("Beitreten"),
            ),
          ],
        );
      },
    );
  }


  void _createGroup(String name, String type, String userId) {
    if (name.isEmpty || type.isEmpty) return;

    FirebaseFirestore.instance.collection('Groups').add({
      'name': name,
      'typ': type,
      'members': [userId],
      'admin': userId,
    }).then((value) {
      print("Gruppe erstellt mit ID: ${value.id}");
    }).catchError((error) {
      print("Fehler beim Erstellen der Gruppe: $error");
    });
  }
}
