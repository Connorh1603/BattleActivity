// profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

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
    appBar: AppBar(
      title: Text('Profile'),
    ),
    body: Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.blue, // Hintergrundfarbe
          ),
          child: TabBar(
            tabs: [
              Tab(text: 'Achievements'),
              Tab(text: 'Groups'),
              Tab(text: 'Activities'),
            ],
          ),
        ),
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
                SizedBox(height: 20),
                // Activities-Bereich
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Letzte 3 Aktivitäten", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                              return Center(child: Text("No activities found"));
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
                                  child: ListTile(
                                    leading: imageUrl != null && imageUrl.isNotEmpty
                                        ? Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                                        : Container(
                                            width: 50,
                                            height: 50,
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.image, size: 24),
                                          ),
                                    title: Text(activity.get('title'), style: TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text(activity.get('description')),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Erstellt am: ${DateTime.fromMillisecondsSinceEpoch(activity.get('timestamp')).toString().split(' ').first}",
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        Text(
                                          "Geändert am: ${DateTime.fromMillisecondsSinceEpoch(activity.get('updatedTimestamp') ?? activity.get('timestamp')).toString().split(' ').first}",
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
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
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Rewards", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      StreamBuilder(
                        stream: _firestore.collection('rewards').where('userId', isEqualTo: _auth.currentUser?.uid).snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            if (snapshot.data!.docs.isEmpty) {
                              return Center(child: Text("No rewards found"));
                            }
                            return ListView.builder(
                              shrinkWrap: true,
                              itemCount: snapshot.data!.docs.length,
                              itemBuilder: (context, index) {
                                final reward = snapshot.data!.docs[index];
                                return ListTile(
                                  title: Text(reward.get('name')),
                                  subtitle: Text(reward.get('description')),
                                  trailing: Text("${reward.get('points')} Points"),
                                );
                              },
                            );
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
          ListTile(title: Text('Profile')),
          ListTile(title: Text('Settings')),
          ExpansionTile(
            title: Text('About BattleActivity'),
            children: [
              ListTile(title: Text('About BattleActivity')),
              ListTile(title: Text('Help and Support')),
              ListTile(title: Text('Feedback')),
              ListTile(title: Text('Frequently asked questions')),
              ListTile(title: Text('Terms of Use')),
              ListTile(title: Text('Privacy Policy')),
            ],
          ),
        ],
      ),
    );
  }
}
