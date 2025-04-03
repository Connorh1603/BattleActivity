import 'imports.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;

  String searchText = '';
  String sortBy = 'date_desc'; // Standard: Nach Datum (Neueste zuerst)
  String filterByCategory = ''; // Kein Filter standardmäßig

  Future _createOrUpdateActivity({
    String? activityId,
    required String title,
    required String description,
    required int duration,
    required String category,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final activitiesRef = _firestore.collection('users').doc(userId).collection('activities');
      DocumentReference activityRef;

      if (activityId == null) {
        activityRef = activitiesRef.doc();
        final activityData = {
          'title': title,
          'description': description,
          'duration': duration,
          'category': category,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'updatedTimestamp': null,
          'userId': userId,
          'imageUrl': '',
          'groupIds': [],
        };

        if (fileBytes != null && fileName != null) {
          final storageRef = _storage.ref().child('profile/$userId/activity_pictures/${activityRef.id}');
          await storageRef.putData(fileBytes);
          final downloadUrl = await storageRef.getDownloadURL();
          activityData['imageUrl'] = downloadUrl;
        }

        await activityRef.set(activityData);
      } else {
        activityRef = activitiesRef.doc(activityId);
        final activityData = {
          'title': title,
          'description': description,
          'duration': duration,
          'category': category,
          'userId': userId,
          'imageUrl': '',
          'groupIds': [],
        };

        if (fileBytes != null && fileName != null) {
          final storageRef = _storage.ref().child('profile/$userId/activity_pictures/$activityId');
          try {
            await storageRef.delete();
          } catch (e) {
            print('Bild existiert nicht, daher wird es nicht gelöscht.');
          }

          await storageRef.putData(fileBytes);
          final downloadUrl = await storageRef.getDownloadURL();
          activityData['imageUrl'] = downloadUrl;
        }

        activityData['updatedTimestamp'] = DateTime.now().millisecondsSinceEpoch;
        await activityRef.update(activityData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(activityId == null ? 'Aktivität erstellt!' : 'Aktivität aktualisiert!')),
      );
    } catch (e) {
      print('Error creating or updating activity: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Speichern der Aktivität: $e')),
      );
    }
  }

  Future _ensureFolderExists(String userId) async {
    final storageRef = _storage.ref().child('profile/$userId/activity_pictures');
    try {
      await storageRef.listAll();
    } catch (e) {
      // Der Ordner existiert nicht, daher erstellen wir ihn
      await storageRef.putString('.keep');
      print('Ordner erstellt: profile/$userId/activity_pictures');
    }
  }

  Future _deleteActivity(String activityId) async {
    try {
      final userId = _auth.currentUser?.uid;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final activitiesRef = _firestore.collection('users').doc(userId).collection('activities');
      final activityRef = activitiesRef.doc(activityId);

      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Aktivität löschen"),
            content: const Text("Sind Sie sicher, dass Sie diese Aktivität löschen möchten?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Abbrechen"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final activityData = await activityRef.get();

                  if (activityData.exists) {
                    final data = activityData.data() as Map;

                    final imageUrl = data['imageUrl'];

                    if (imageUrl != null && imageUrl.isNotEmpty) {
                      await _storage.refFromURL(imageUrl).delete();
                    }

                    await activityRef.delete();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Aktivität gelöscht!')),
                    );

                    Navigator.pop(context);
                  }
                },
                child: const Text("Löschen"),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error deleting activity: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Löschen der Aktivität: $e')),
      );
    }
  }

  Future<Uint8List?> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null) {
        Uint8List fileBytes = result.files.first.bytes!;
        String fileName = result.files.first.name;

        // Dateierweiterung extrahieren und validieren
        String fileExtension = fileName.split('.').last.toLowerCase();

        if (fileExtension == 'jpeg') {
          fileExtension = 'jpg'; // Behandle JPEG als JPG
        }

        if (fileExtension != 'jpg' && fileExtension != 'png') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unsupported file format. Only JPG and PNG are allowed.'),
              backgroundColor: Colors.red,
            ),
          );
          return null;
        }

        return fileBytes;
      } else {
        print('No file selected.');
        return null;
      }
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  Future<void> _showAddEditDialog({String? activityId, Map<String, dynamic>? existingData}) async {
    final _formKey = GlobalKey<FormState>();
    String title = existingData?['title'] ?? '';
    String description = existingData?['description'] ?? '';
    int duration = existingData?['duration'] ?? 0;
    String category = existingData?['category'] ?? '';
    Uint8List? fileBytes;
    String? fileName;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(activityId == null ? "Neue Aktivität" : "Aktivität bearbeiten"),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    TextFormField(
      initialValue: title,
      decoration: const InputDecoration(labelText: "Titel*"),
      validator: (val) => val?.isEmpty ?? true ? "Bitte Titel eingeben" : null,
      onChanged: (val) => title = val,
    ),
    TextFormField(
      initialValue: description,
      decoration: const InputDecoration(labelText: "Beschreibung (optional)"),
      onChanged: (val) => description = val,
    ),
    TextFormField(
      initialValue: duration == 0 ? '' : duration.toString(),
      decoration: const InputDecoration(labelText: "Dauer (Minuten)*"),
      keyboardType: TextInputType.number,
      validator: (val) => val?.isEmpty ?? true ? "Bitte Dauer eingeben" : null,
      onChanged: (val) => duration = int.tryParse(val) ?? 0,
    ),
    DropdownButtonFormField<String>(
      value: category.isEmpty ? null : category,
      decoration: const InputDecoration(labelText: "Kategorie*"),
      validator: (val) => val == null || val.isEmpty ? "Bitte Kategorie auswählen" : null,
      items:
          ['Sport', 'Lernen', 'Kochen', 'Musik'].map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
      onChanged: (val) => category = val!,
    ),
    const SizedBox(height: 10),
    TextButton.icon(
      icon: const Icon(Icons.image),
      label: const Text("Bild auswählen"),
      onPressed: () async {
        final bytes = await _pickImage();
        if (bytes != null) {
          fileBytes = bytes;
          fileName = 'activity_image.jpg';
        }
      },
    ),
  ],
),
            ),
          ),
          actions: [
            TextButton(child: const Text("Abbrechen"), onPressed: () => Navigator.pop(context)),
            ElevatedButton(
              child:
      Text(activityId == null ? "Speichern" : "Aktualisieren"),
  onPressed:
      () async {
    if (_formKey.currentState!.validate()) {
      await _createOrUpdateActivity(
        activityId: activityId,
        title: title,
        description: description,
        duration: duration,
        category: category,
        fileBytes: fileBytes,
        fileName: fileName,
      );
      Navigator.pop(context);
    }
  },
),
          ],
        );
      },
    );
  }

 Future<void> _showActivityDetails(String activityId) async {
  final userId = _auth.currentUser?.uid;
  if (userId == null) {
    throw Exception('User not logged in');
  }

  final activityRef = _firestore.collection('users').doc(userId).collection('activities').doc(activityId);
  final activityData = await activityRef.get();

  if (activityData.exists) {
    final data = activityData.data() as Map;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(data['title']),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(data['description']),
              Text("Kategorie: ${data['category']}"),
              Text("Dauer: ${data['duration']} Minuten"),
              Text("Zuletzt geändert am: ${DateTime.fromMillisecondsSinceEpoch(data['updatedTimestamp'] ?? data['timestamp']).toString().split(' ').first} ${DateTime.fromMillisecondsSinceEpoch(data['updatedTimestamp'] ?? data['timestamp']).hour.toString().padLeft(2, '0')}:${DateTime.fromMillisecondsSinceEpoch(data['updatedTimestamp'] ?? data['timestamp']).minute.toString().padLeft(2, '0')}:${DateTime.fromMillisecondsSinceEpoch(data['updatedTimestamp'] ?? data['timestamp']).second.toString().padLeft(2, '0')}"),
              if (data['imageUrl'] != null && data['imageUrl'].isNotEmpty)
                Image.network(
                  data['imageUrl'],
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Schließen"),
            ),
          ],
        );
      },
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Aktivität nicht gefunden.")),
    );
  }
}

  @override
Widget build(BuildContext context) {
  final userId = _auth.currentUser?.uid;

  if (userId == null) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Meine Aktivitäten"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Bitte anmelden, um Aktivitäten zu sehen."),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _auth.signInWithEmailAndPassword(email: "example@example.com", password: "password123");
              },
              child: const Text("Anmelden"),
            ),
          ],
        ),
      ),
    );
  }

  return Scaffold(
    appBar: PreferredSize(
      preferredSize: Size.fromHeight(70), // Höhe der AppBar erhöhen
      child: Container(
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 127, 179, 68), // Hintergrundfarbe Grün
          boxShadow: [
            BoxShadow(
              color: Colors.grey[300] ?? Colors.grey, // Schattenfarbe
              blurRadius: 5, // Schattenradius
              offset: Offset(0, 2), // Schattenposition
            ),
          ],
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)), // Ecken der Navigationsleiste abrunden
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, size: 30, color: Colors.white), // Zurück-Button weiß
                  onPressed: () => Navigator.pop(context),
                ),
                Text('Zurück', style: TextStyle(fontSize: 20, color: Colors.white)), // Zurück-Text weiß
              ],
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/archievement'); // Navigiere zur Archivments-Seite
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 100, 150, 60), // Hintergrundfarbe dunkleres Grün
                          foregroundColor: Colors.white, // Schriftfarbe Weiß
                        ),
                        child:
                            Text('Erfolge', style: TextStyle(fontSize: 20)), // Schriftgröße erhöhen
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/group'); // Navigiere zur Gruppen-Seite
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 100, 150, 60), // Hintergrundfarbe dunkleres Grün
                          foregroundColor: Colors.white, // Schriftfarbe Weiß
                        ),
                        child:
                            Text('Gruppen', style: TextStyle(fontSize: 20)), // Schriftgröße erhöhen
                      ),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/profile'); // Navigiere zur Profil-Seite
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 100, 150, 60), // Hintergrundfarbe dunkleres Grün
                        foregroundColor: Colors.white, // Schriftfarbe Weiß
                      ),
                      child:
                          Text('Profil', style: TextStyle(fontSize: 20)), // Schriftgröße erhöhen
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              PopupMenuButton(
                icon: const Icon(Icons.filter_list),
                onSelected: (value) {
                  setState(() {
                    if (value.startsWith('category_')) {
                      filterByCategory = value.replaceFirst('category_', '');
                    } else {
                      sortBy = value;
                    }
                  });
                },
                itemBuilder: (context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem(value: 'date_desc', child: Text("Datum (Neueste zuerst)")),
                  const PopupMenuItem(value: 'date_asc', child: Text("Datum (Älteste zuerst)")),
                  const PopupMenuItem(value: 'title_asc', child: Text("Titel (A-Z)")),
                  const PopupMenuItem(value: 'title_desc', child: Text("Titel (Z-A)")),
                  const PopupMenuItem(value: 'duration_desc', child: Text("Dauer (Längste zuerst)")),
                  const PopupMenuItem(value: 'duration_asc', child: Text("Dauer (Kürzeste zuerst)")),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'category_Sport', child: Text("Kategorie: Sport")),
                  const PopupMenuItem(value: 'category_Lernen', child: Text("Kategorie: Lernen")),
                  const PopupMenuItem(value: 'category_Kochen', child: Text("Kategorie: Kochen")),
                  const PopupMenuItem(value: 'category_Musik', child: Text("Kategorie: Musik")),
                  const PopupMenuItem(value: 'category_', child: Text("Alle Kategorien")), // Zurücksetzen
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: "Aktivität suchen...",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchText = value.toLowerCase();
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder(
            stream: _firestore.collection('users').doc(userId).collection('activities').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: Text("Keine Aktivitäten vorhanden."));
              }

              final activitiesList = snapshot.data!.docs.map((doc) {
                return {
                  'id': doc.id,
                  ...doc.data() as Map,
                };
              }).toList();

              // Filtere Aktivitäten basierend auf Suchtext und Kategorie
              final filteredActivities = activitiesList.where((activity) {
                final title = activity['title']?.toString().toLowerCase() ?? '';
                final category = activity['category']?.toString() ?? '';

                final matchesSearch = searchText.isEmpty || title.contains(searchText);
                final matchesCategory = filterByCategory.isEmpty || category == filterByCategory;

                return matchesSearch && matchesCategory;
              }).toList();

              // Sortiere die Aktivitäten basierend auf der ausgewählten Option
              filteredActivities.sort((a, b) {
                switch (sortBy) {
                  case 'date_asc':
                    return a['timestamp'].compareTo(b['timestamp']);
                  case 'date_desc':
                    return b['timestamp'].compareTo(a['timestamp']);
                  case 'title_asc':
                    return (a['title'] ?? '').toLowerCase().compareTo((b['title'] ?? '').toLowerCase());
                  case 'title_desc':
                    return (b['title'] ?? '').toLowerCase().compareTo((a['title'] ?? '').toLowerCase());
                  case 'duration_asc':
                    return a['duration'].compareTo(b['duration']);
                  case 'duration_desc':
                    return b['duration'].compareTo(a['duration']);
                  default:
                    return 0;
                }
              });

              if (filteredActivities.isEmpty) {
                return const Center(child: Text("Keine passenden Aktivitäten gefunden."));
              }

              return ListView.builder(
                itemCount: filteredActivities.length,
                itemBuilder: (context, index) {
                  final activity = filteredActivities[index];
                  return GestureDetector(
                    onTap: () => _showActivityDetails(activity['id']),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: (activity['imageUrl'] ?? '').isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return Dialog(
                                          child: InteractiveViewer(
                                            child: Image.network(
                                              activity['imageUrl'],
                                              fit: BoxFit.contain, // Zeigt das gesamte Bild an
                                              width: MediaQuery.of(context).size.width * 0.8, // Breite auf 80% des Bildschirms setzen
                                              height: MediaQuery.of(context).size.height * 0.6, // Höhe auf 60% des Bildschirms setzen
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  child: Image.network(
                                    activity['imageUrl'],
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image, size: 24),
                                ),
                        ),
                        title: Text(activity['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${activity['category']} • ${activity['duration']} min"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Erstellt am: ${DateTime.fromMillisecondsSinceEpoch(activity['timestamp']).toString().split(' ').first}",
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showAddEditDialog(activityId: activity['id'], existingData: activity.cast()),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteActivity(activity['id']),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.more_vert),
                              onPressed: () async {
                                await showDialog(
                                  context: context,
                                  builder: (context) {
                                    return GroupSelectionDialog(
                                      activityId: activity['id'],
                                      firestore: _firestore,
                                      auth: _auth,
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      child: const Icon(Icons.add),
      onPressed: () => _showAddEditDialog(),
    ),
  );
}
}

//Gruppenauswahldialog
class GroupSelectionDialog extends StatefulWidget {
  final String activityId;
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  const GroupSelectionDialog({
    super.key,
    required this.activityId,
    required this.firestore,
    required this.auth,
  });

  @override
  State<GroupSelectionDialog> createState() => _GroupSelectionDialogState();
}

class _GroupSelectionDialogState extends State<GroupSelectionDialog> {
  List<String> _selectedGroupIds = [];
  List<String> _availableGroupIds = [];
  List<String> _availableGroupNames = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableGroups();
  }

  Future<void> _loadAvailableGroups() async {
    final userId = widget.auth.currentUser?.uid;
    if (userId == null) return;

    final groupsRef = widget.firestore.collection('Groups');
    final querySnapshot = await groupsRef.where('members', arrayContains: userId).get();

    final activityRef = widget.firestore
        .collection('users')
        .doc(userId)
        .collection('activities')
        .doc(widget.activityId);
    final activitySnapshot = await activityRef.get();

    List<String> existingGroupIds = [];
    if (activitySnapshot.exists) {
      final data = activitySnapshot.data() as Map<String, dynamic>;
      existingGroupIds = List<String>.from(data['groupIds'] ?? []);
    }

    setState(() {
      _availableGroupIds = querySnapshot.docs.map((doc) => doc.id).toList();
      _availableGroupNames = querySnapshot.docs.map((doc) => doc.get('name') as String).toList();
      _selectedGroupIds = existingGroupIds;
    });
    }


  Future<void> _saveGroupSelection() async {
    final activityRef = widget.firestore
        .collection('users')
        .doc(widget.auth.currentUser?.uid)
        .collection('activities')
        .doc(widget.activityId);

    final docSnapshot = await activityRef.get();
    if (docSnapshot.exists) {
      final data = docSnapshot.data() as Map;
      final updatedGroupIds = _selectedGroupIds;

      await activityRef.update({
        'groupIds': updatedGroupIds,
      });
    } else {
      await activityRef.set({
        'groupIds': _selectedGroupIds,
      });
    }

    // Dialog schließen nach erfolgreichem Speichern
    if (mounted) Navigator.pop(context);
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Gruppen auswählen'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: _availableGroupIds.map((groupId) {
          final groupName = _availableGroupNames[_availableGroupIds.indexOf(groupId)];
          return CheckboxListTile(
            title: Text(groupName),
            value: _selectedGroupIds.contains(groupId),
            onChanged: (value) {
              setState(() {
                if (value ?? false) {
                  _selectedGroupIds.add(groupId);
                } else {
                  _selectedGroupIds.remove(groupId);
                }
              });
            },
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _saveGroupSelection,
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}



