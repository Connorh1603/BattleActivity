import 'package:flutter/material.dart';

class DeleteDialog extends StatelessWidget {
  const DeleteDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Aktivität löschen?"),
      content: const Text("Möchtest du diese Aktivität wirklich löschen?"),
      actions: [
        TextButton(
          child: const Text("Abbrechen"),
          onPressed: () => Navigator.pop(context, false),
        ),
        TextButton(
          child: const Text("Löschen", style: TextStyle(color: Colors.red)),
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
  }
}