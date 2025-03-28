import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  File? _image;

  Future<void> _pickImage() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
      if (photo != null) {
        setState(() {
          _image = File(photo.path);
        });
        await _saveImageLocally(_image!);
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _saveImageLocally(File imageFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/profile_picture.jpg';

    await imageFile.copy(filePath);
  }

  Future<File?> _loadImageLocally() async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/profile_picture.jpg';

    if (await File(filePath).exists()) {
      return File(filePath);
    } else {
      return null;
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
          SizedBox(height: 20),
          Center(
            child: Stack(
              children: [
                FutureBuilder(
                  future: _loadImageLocally(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return CircleAvatar(
                        radius: 80,
                        backgroundImage: FileImage(snapshot.data!),
                        child: null,
                      );
                    } else {
                      return CircleAvatar(
                        radius: 80,
                        child: Icon(Icons.person, size: 120),
                      );
                    }
                  },
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
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StreamBuilder<DocumentSnapshot>(
                stream: _firestore.collection('users').doc(_auth.currentUser?.uid).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text(
                      snapshot.data!.get('username'),
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                    );
                  } else {
                    return Text('Loading...');
                  }
                },
              ),
              SizedBox(width: 10),
              IconButton(
                icon: Icon(Icons.settings),
                onPressed: () => showDialog(context: context, builder: (context) => SettingsDialog()),
              ),
            ],
          ),
          Spacer(),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Activities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        StreamBuilder<QuerySnapshot>(
                          stream: _firestore.collection('activities').where('userId', isEqualTo: _auth.currentUser?.uid).snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              if (snapshot.data!.docs.isEmpty) {
                                return Center(child: Text('No activities found.'));
                              }
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: snapshot.data!.docs.length,
                                itemBuilder: (context, index) {
                                  final activity = snapshot.data!.docs[index];
                                  return ListTile(
                                    title: Text(activity.get('name'), style: TextStyle(fontSize: 16)),
                                    subtitle: Text(activity.get('description')),
                                    trailing: Text(activity.get('duration')),
                                  );
                                },
                              );
                            } else if (snapshot.hasError) {
                              return Center(child: Text('Error loading activities'));
                            } else {
                              return Center(child: CircularProgressIndicator());
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rewards', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        Center(child: Text('Coming soon...')),
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
