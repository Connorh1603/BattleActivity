import 'package:flutter/material.dart';

class CategoryChip extends StatelessWidget {
  final Map<String, dynamic> category;
  final bool selected;
  final VoidCallback onTap;

  const CategoryChip({super.key, required this.category, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(category['name']),
        avatar: Icon(category['icon'], size: 16),
        backgroundColor: selected ? Colors.blueAccent : Colors.grey[300],
      ),
    );
  }
}