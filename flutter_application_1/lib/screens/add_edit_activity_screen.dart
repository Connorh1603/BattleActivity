// ----------------------
// FINAL Upload Fix (Web + Mobile)
// ----------------------
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class AddEditActivityScreen extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final String userId;
  final DocumentSnapshot? existingDoc;

  const AddEditActivityScreen({
    super.key,
    required this.categories,
    required this.userId,
    this.existingDoc,
  });

  @override
  State<AddEditActivityScreen> createState() => _AddEditActivityScreenState();
}

class _AddEditActivityScreenState extends State<AddEditActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  String title = '';
  String description = '';
  int duration = 0;
  String? category;
  Uint8List? _fileBytes;
  String? _fileName;
  String? _imageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingDoc != null) {
      final data = widget.existingDoc!.data() as Map<String, dynamic>;
      title = data['title'] ?? '';
      description = data['description'] ?? '';
      duration = data['duration'] ?? 0;
      category = data['category'] ?? null;
      _imageUrl = data['imageUrl'];
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (result != null && result.files.first.bytes != null) {
      final fileName = result.files.first.name;
      final extension = fileName.split('.').last.toLowerCase();

      if (extension != 'jpg' && extension != 'jpeg' && extension != 'png') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nur JPG und PNG erlaubt'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _fileBytes = result.files.first.bytes;
        _fileName = fileName;
      });
    }
  }

  Future<String?> _uploadImage(String activityId) async {
    if (_fileBytes == null) return _imageUrl;
    setState(() => _isUploading = true);

    final extension = _fileName!.split('.').last.toLowerCase();
    String contentType = 'image/jpeg';
    if (extension == 'png') contentType = 'image/png';
    if (extension == 'jpeg') contentType = 'image/jpeg';
    if (extension == 'jpg') contentType = 'image/jpeg';

    final ref = FirebaseStorage.instance
        .ref('activities/${widget.userId}/$activityId/image.$extension');

    final uploadTask = ref.putData(
      _fileBytes!,
      SettableMetadata(contentType: contentType),
    );

    await uploadTask.whenComplete(() {});
    setState(() => _isUploading = false);
    return await ref.getDownloadURL();
  }

  void _saveActivity() async {
    if (category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bitte wähle eine Kategorie!")),
      );
      return;
    }

    final activitiesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('activities');

    if (widget.existingDoc == null) {
      final newDoc = await activitiesRef.add({
        'title': title,
        'description': description,
        'duration': duration,
        'category': category,
        'timestamp': Timestamp.now(),
      });
      final imageUrl = await _uploadImage(newDoc.id);
      if (imageUrl != null) {
        await newDoc.update({'imageUrl': imageUrl});
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aktivität erstellt ✅")));
    } else {
      await activitiesRef.doc(widget.existingDoc!.id).update({
        'title': title,
        'description': description,
        'duration': duration,
        'category': category,
        'timestamp': Timestamp.now(),
      });
      final imageUrl = await _uploadImage(widget.existingDoc!.id);
      if (imageUrl != null) {
        await activitiesRef.doc(widget.existingDoc!.id).update({'imageUrl': imageUrl});
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aktivität aktualisiert ✅")));
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existingDoc == null ? "Neue Aktivität" : "Aktivität bearbeiten")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: title,
                decoration: const InputDecoration(labelText: "Titel"),
                onChanged: (val) => setState(() => title = val),
              ),
              TextFormField(
                initialValue: description,
                decoration: const InputDecoration(labelText: "Beschreibung"),
                onChanged: (val) => setState(() => description = val),
              ),
              TextFormField(
                initialValue: duration == 0 ? '' : duration.toString(),
                decoration: const InputDecoration(labelText: "Dauer (Minuten)"),
                keyboardType: TextInputType.number,
                onChanged: (val) => setState(() => duration = int.tryParse(val) ?? 0),
              ),
              DropdownButtonFormField(
                value: category,
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
              if (_fileBytes != null)
                Image.memory(_fileBytes!, height: 150, fit: BoxFit.cover)
              else if ((_imageUrl ?? '').isNotEmpty)
                Image.network(_imageUrl!, height: 150, fit: BoxFit.cover)
              else
                const Text("Kein Bild ausgewählt"),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.image),
                label: const Text("Bild auswählen"),
                onPressed: _pickImage,
              ),
              const SizedBox(height: 20),
              if (_isUploading) const Center(child: CircularProgressIndicator()),
              if (!_isUploading)
                ElevatedButton(
                  child: Text(widget.existingDoc == null ? "Speichern" : "Aktualisieren"),
                  onPressed: _saveActivity,
                ),
            ],
          ),
        ),
      ),
    );
  }
}