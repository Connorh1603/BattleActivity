import 'imports.dart';
import 'package:cloud_functions/cloud_functions.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;

  Future _uploadProfilePicture(Uint8List fileBytes) async {
    try {
      final userId = _auth.currentUser?.uid;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final storageRef = _storage.ref().child('profile/$userId/profile_pictures/profile_picture.jpg');

      await storageRef.putData(fileBytes);

      final downloadUrl = await storageRef.getDownloadURL();

      await _firestore.collection('users').doc(userId).update({
        'profilePictureUrl': downloadUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile picture updated successfully!')),
      );
    } catch (e) {
      print('Error uploading profile picture: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload profile picture.')),
      );
    }
  }

  Future _pickImage() async {
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
          return;
        }

        // Datei hochladen
        await _uploadProfilePicture(fileBytes);
      } else {
        print('No file selected.');
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  

@override
Widget build(BuildContext context) {
  return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(120),
        child: Container(
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 127, 179, 68),
            boxShadow: [
              BoxShadow(
                color: Colors.grey[300] ?? Colors.grey,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, size: 30, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text('Zurück', style: TextStyle(fontSize: 20, color: Colors.white)),
                  ],
                ),
                SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmall = constraints.maxWidth < 400;
                    return Wrap(
                      alignment: WrapAlignment.spaceEvenly,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, '/archievement'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 100, 150, 60),
                            foregroundColor: Colors.white,
                            minimumSize: Size(isSmall ? 100 : 120, 40),
                          ),
                          child: Text('Erfolge', style: TextStyle(fontSize: 18)),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, '/activity'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 100, 150, 60),
                            foregroundColor: Colors.white,
                            minimumSize: Size(isSmall ? 100 : 120, 40),
                          ),
                          child: Text('Aktivitäten', style: TextStyle(fontSize: 18)),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, '/group'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 100, 150, 60),
                            foregroundColor: Colors.white,
                            minimumSize: Size(isSmall ? 100 : 120, 40),
                          ),
                          child: Text('Gruppen', style: TextStyle(fontSize: 18)),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
body: Column(
  children: [
    Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Benutzername und andere Informationen
            SizedBox(height: 20),
            Center(
              child: StreamBuilder(
                stream: _firestore.collection('users').doc(_auth.currentUser?.uid).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final data = snapshot.data!.data() as Map;
                    final url = data['profilePictureUrl'];
                    return Stack(
                      children: [
                        CircleAvatar(
                          radius: 100,
                          backgroundImage: url != null ? NetworkImage(url) : null,
                          child: url == null ? Icon(Icons.person, size: 140) : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            backgroundColor: Colors.blue,
                            radius: 20,
                            child: IconButton(
                              icon: Icon(Icons.edit, color: Colors.white),
                              onPressed: _pickImage,
                            ),
                          ),
                        ),
                      ],
                    );
                  } else if (snapshot.hasError) {
                    return Text('Error loading profile picture.');
                  } else {
                    return CircularProgressIndicator();
                  }
                },
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StreamBuilder(
                  stream: _firestore.collection('users').doc(_auth.currentUser?.uid).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(snapshot.data!.get('username'), style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold));
                    } else {
                      return Text('Loading...');
                    }
                  },
                ),
                SizedBox(width: 10),
                IconButton(icon: Icon(Icons.settings), onPressed: () => showDialog(context: context, builder: (context) => SettingsDialog())),
              ],
            ),
            SizedBox(height: 10), // Abstand zwischen Benutzername und Abmeldebutton
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Hintergrundfarbe Rot
                foregroundColor: Colors.white, // Schriftfarbe Weiß
                minimumSize: Size(150, 50), // Größe des Buttons
              ),
              child: Text('Abmelden', style: TextStyle(fontSize: 20)), // Schriftgröße erhöhen
            ),
            SizedBox(height: 20),
            // Activities-Bereich
            Container(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 127, 179, 68), // Hintergrundfarbe ändern
                borderRadius: BorderRadius.circular(10), // Ecken abrunden
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Letzte 3 Aktivitäten",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white), // Schriftfarbe Weiß
                  ),
                  SizedBox(height: 10),
                  StreamBuilder(
                    stream: _firestore
                        .collection('users')
                        .doc(_auth.currentUser?.uid)
                        .collection('activities')
                        .orderBy('timestamp', descending: true)
                        .limit(3)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        if (snapshot.data!.docs.isEmpty) {
                          return Center(child: Text("No activities found", style: TextStyle(color: Colors.white))); // Schriftfarbe Weiß
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            final activity = snapshot.data!.docs[index];
                            final imageUrl = activity.get('imageUrl');
                            return Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Bild links
                                    imageUrl != null && imageUrl.isNotEmpty
                                        ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        imageUrl,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                        : Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.image, size: 24),
                                    ),
                                    const SizedBox(width: 12),

                                    // Titel in der Mitte, Beschreibung unten
                                    Expanded(
                                      child: Container(
                                        // Höhe = Bildhöhe, damit sich alles anpasst
                                        height: 50,
                                        child: Stack(
                                          children: [
                                            // Titel (zentriert in der Höhe)
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                activity.get('title'),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            // Beschreibung unten
                                            Positioned(
                                              bottom: 0,
                                              left: 0,
                                              child: Text(
                                                activity.get('description'),
                                                style: const TextStyle(color: Colors.black),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Zeitangaben rechts
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          "Erstellt am: "
                                              "${DateTime.fromMillisecondsSinceEpoch(activity.get('timestamp')).toString().split(' ').first}",
                                          style: const TextStyle(fontSize: 12, color: Colors.black),
                                        ),
                                        Text(
                                          "Geändert am: "
                                              "${DateTime.fromMillisecondsSinceEpoch(activity.get('updatedTimestamp') ?? activity.get('timestamp')).toString().split(' ').first}",
                                          style: const TextStyle(fontSize: 12, color: Colors.black),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ); // ListView.builder
                      } else {
                        return Center(child: CircularProgressIndicator());
                      }
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Rewards-Bereich
            Container(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 127, 179, 68), // Hintergrundfarbe ändern
                borderRadius: BorderRadius.circular(10), // Ecken abrunden
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Rewards",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white), // Schriftfarbe Weiß
                  ),
                  SizedBox(height: 10),
                  StreamBuilder(
                    stream: _firestore.collection('users').doc(_auth.currentUser?.uid).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final userData = snapshot.data!.data();
                        if (userData != null && userData.containsKey('achievements')) {
                          final achievements = userData['achievements'] as List<dynamic>;
                          if (achievements.isEmpty) {
                            return Center(child: Text("No rewards found", style: TextStyle(color: Colors.white))); // Schriftfarbe Weiß
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            itemCount: achievements.length,
                            itemBuilder: (context, index) {
                              final achievement = achievements[index] as Map<String, dynamic>;
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 8.0),
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200], // Hintergrundfarbe Grau
                                  border: Border.all(color: Colors.grey), // Rahmenfarbe Grau
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      achievement['name'],
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black), // Schriftfarbe Schwarz
                                    ),
                                    Image.asset(
                                      '${achievement['badge'].toLowerCase()}.png',
                                      width: 50,
                                      height: 50,
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        } else {
                          return Center(child: Text("No rewards found", style: TextStyle(color: Colors.white))); // Schriftfarbe Weiß
                        }
                      } else {
                        return Center(child: CircularProgressIndicator());
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ],
),
  );
}
}

class SettingsDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(title: Text('Languages')),
          ListTile(
            title: Text('Profile'),
            onTap: () async {
              Navigator.of(context).pop();
              await showDialog(
                context: context,
                builder: (context) => ChangeProfileDialog(),
              );
            },
          ),
          ListTile(title: Text('Settings')),
          ExpansionTile(
            title: Text('About BattleActivity'),
            children: [
              ListTile(
                title: Text('About BattleActivity'),
                onTap: () {
                  Navigator.of(context).pop();
                  showDialog(
                    context: context,
                    builder: (context) => const AboutDialogMarkdown(),
                  );
                },
              ),
              ListTile(title: Text('Help and Support')),
              ListTile(
                title: Text('Feedback'),
                onTap: () {
                  Navigator.of(context).pop();
                  showDialog(
                    context: context,
                    builder: (context) => FeedbackDialog(),
                  );
                },
              ),
              ListTile(
                title: Text('FAQ'),
                onTap: () {
                  Navigator.of(context).pop();
                  showDialog(
                    context: context,
                    builder: (context) => const FAQDialog(),
                  );
                },
              ),
              ListTile(
                title: Text('Terms of Use'),
                onTap: () {
                  Navigator.of(context).pop();
                  showDialog(
                    context: context,
                    builder: (context) => const TermsOfUseDialog(),
                  );
                },
              ),
              ListTile(
                title: Text('Privacy Policy'),
                onTap: () {
                  Navigator.of(context).pop();
                  showDialog(
                    context: context,
                    builder: (context) => const PrivacyPolicyDialog(),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Dialog zum Profil ändern
class ChangeProfileDialog extends StatefulWidget {
  @override
  State<ChangeProfileDialog> createState() => _ChangeProfileDialogState();
}

class _ChangeProfileDialogState extends State<ChangeProfileDialog> {
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final DocumentSnapshot doc = await firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _usernameController.text = doc.get('username') ?? '';
          _firstNameController.text = doc.get('firstName') ?? '';
          _lastNameController.text = doc.get('lastName') ?? '';
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _updateProfile() async {
  try {
    final String newUsername = _usernameController.text;
    
    if (newUsername.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bitte geben Sie einen Benutzernamen ein.')),
      );
      return;
    }

    if (await _checkIfUsernameExists(newUsername)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dieser Benutzername ist bereits vergeben.')),
      );
      return;
    }

    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await firestore.collection('users').doc(user.uid).update({
        'username': newUsername,
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profil erfolgreich aktualisiert.')),
      );
      Navigator.of(context).pop(); // Schließe das Fenster
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Fehler beim Aktualisieren des Profils: $e')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.all(16), // Reduziert den Abstand zwischen dem Dialog und dem Bildschirmrand
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 300), // Setzt die maximale Breite des Dialogs
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Update Profile'),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10), // Abstand zwischen den Textfeldern
              TextField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10), // Abstand zwischen den Textfeldern
              TextField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10), 
              // Abstand zwischen dem letzten Textfeld und dem Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Abbrechen'),
                  ),
                  ElevatedButton(
                    onPressed: _updateProfile,
                    child: Text('Update'), // Button-Text auf "Update" geändert
                  )
                ]
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// About BattleActivity Dialog
class AboutDialogMarkdown extends StatefulWidget {
  const AboutDialogMarkdown({super.key});

  @override
  State<AboutDialogMarkdown> createState() => _AboutDialogMarkdownState();
}

class _AboutDialogMarkdownState extends State<AboutDialogMarkdown> {
  String _markdownText = '';

  Future<void> _loadMarkdown() async {
    try {
      final fileContent = await rootBundle.loadString('assets/about.md');
      setState(() {
        _markdownText = fileContent;
      });
    } catch (e) {
      print('Fehler beim Laden der Datei: $e');
      setState(() {
        _markdownText = 'Fehler beim Laden der Datei.';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMarkdown();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Über BattleActivity',
              ),
              const SizedBox(height: 10),
              MarkdownBody(data: _markdownText),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Schließen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Terms of Use Dialog
class TermsOfUseDialog extends StatefulWidget {
  const TermsOfUseDialog({super.key});

  @override
  State<TermsOfUseDialog> createState() => _TermsOfUseDialogState();
}

class _TermsOfUseDialogState extends State<TermsOfUseDialog> {
  String _markdownText = '';

  Future<void> _loadMarkdown() async {
    try {
      final fileContent = await rootBundle.loadString('assets/terms_of_use.md');
      setState(() {
        _markdownText = fileContent;
      });
    } catch (e) {
      print('Fehler beim Laden der Nutzungsbedingungen: $e');
      setState(() {
        _markdownText = 'Fehler beim Laden der Nutzungsbedingungen.';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMarkdown();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Nutzungsbedingungen',
              ),
              const SizedBox(height: 10),
              MarkdownBody(data: _markdownText),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Schließen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Privacy Policy Dialog
class PrivacyPolicyDialog extends StatefulWidget {
  const PrivacyPolicyDialog({super.key});

  @override
  State<PrivacyPolicyDialog> createState() => _PrivacyPolicyDialogState();
}

class _PrivacyPolicyDialogState extends State<PrivacyPolicyDialog> {
  String _markdownText = '';

  Future<void> _loadMarkdown() async {
    try {
      final fileContent =
          await rootBundle.loadString('assets/privacy_policy.md');
      setState(() {
        _markdownText = fileContent;
      });
    } catch (e) {
      print('Fehler beim Laden der Datenschutzerklärung: $e');
      setState(() {
        _markdownText = 'Fehler beim Laden der Datenschutzerklärung.';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMarkdown();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Datenschutzerklärung',
              ),
              const SizedBox(height: 10),
              MarkdownBody(data: _markdownText),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Schließen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FAQDialog extends StatefulWidget {
  const FAQDialog({super.key});

  @override
  State<FAQDialog> createState() => _FAQDialogState();
}

class _FAQDialogState extends State<FAQDialog> {
  List<Map<String, String>> _faqList = [];

  Future<void> _loadFAQ() async {
    try {
      final content = await rootBundle.loadString('assets/faq.md');
      final lines = content.split('\n');

      List<Map<String, String>> faqs = [];
      String? currentQuestion;
      StringBuffer currentAnswer = StringBuffer();

      for (var line in lines) {
        if (line.startsWith('# ')) {
          // Save previous FAQ
          if (currentQuestion != null) {
            faqs.add({
              'question': currentQuestion.trim(),
              'answer': currentAnswer.toString().trim(),
            });
            currentAnswer.clear();
          }
          currentQuestion = line.replaceFirst('# ', '');
        } else {
          currentAnswer.writeln(line);
        }
      }

      // Add last entry
      if (currentQuestion != null) {
        faqs.add({
          'question': currentQuestion.trim(),
          'answer': currentAnswer.toString().trim(),
        });
      }

      setState(() {
        _faqList = faqs;
      });
    } catch (e) {
      print('Fehler beim Laden des FAQ: $e');
      setState(() {
        _faqList = [
          {
            'question': 'Fehler',
            'answer': 'FAQ konnte nicht geladen werden.',
          }
        ];
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadFAQ();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _faqList.isEmpty
            ? const SizedBox(
          height: 150,
          child: Center(child: CircularProgressIndicator()),
        )
            : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'FAQ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _faqList.length,
                itemBuilder: (context, index) {
                  final faq = _faqList[index];
                  return ExpansionTile(
                    title: Text(
                      faq['question'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Text(faq['answer'] ?? ''),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Schließen'),
            ),
          ],
        ),
      ),
    );
  }
}

class FeedbackDialog extends StatefulWidget {
  @override
  _FeedbackDialogState createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _userNameController = TextEditingController();
  final _userEmailController = TextEditingController();
  String _userName = '';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        _userName = '${doc['firstName']} ${doc['lastName']}';
        _userEmail = doc['email'];
        _userNameController.text = _userName;
        _userEmailController.text = _userEmail;
      });
    }
  }

  Future<void> _sendFeedback() async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('sendemail');
      await callable.call({
        'name': _userNameController.text,
        'email': _userEmailController.text,
        'subject': _subjectController.text,
        'message': _messageController.text,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Feedback erfolgreich gesendet!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Senden des Feedbacks')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Feedback senden'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _userNameController,
            decoration: InputDecoration(labelText: 'Name'),
            readOnly: true, // Optional, falls nicht editierbar sein soll
          ),
          TextField(
            controller: _userEmailController,
            decoration: InputDecoration(labelText: 'E-Mail'),
            readOnly: true, // Optional, falls nicht editierbar sein soll
          ),
          TextField(
            controller: _subjectController,
            decoration: InputDecoration(labelText: 'Betreff'),
            maxLength: 50,
          ),
          TextField(
            controller: _messageController,
            decoration: InputDecoration(labelText: 'Nachricht'),
            maxLines: 5,
            maxLength: 500,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Abbrechen')),
        ElevatedButton(onPressed: _sendFeedback, child: Text('Absenden')),
      ],
    );
  }
}

//Benutzername-Überprüfung
// Überprüft, ob der Benutzername bereits existiert
Future<bool> _checkIfUsernameExists(String username) async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final QuerySnapshot querySnapshot = await firestore.collection('users').get();
  final List existingUsernames = querySnapshot.docs.map((doc) => doc.get('username')).map((e) => e as String).toList();
  
  // Überprüfe, ob der neue Benutzername bereits existiert und nicht der aktuelle Benutzername ist
  final User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final DocumentSnapshot doc = await firestore.collection('users').doc(user.uid).get();
    final currentUsername = doc.get('username');
    
    return existingUsernames.contains(username) && username != currentUsername;
  }
  
  return existingUsernames.contains(username);
}