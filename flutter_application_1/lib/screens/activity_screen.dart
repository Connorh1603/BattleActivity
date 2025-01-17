import 'package:flutter/material.dart';

class ActivityScreen extends StatelessWidget{
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Aktivitäten')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Deine Aktivitäten'),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/profile'); // Navigation zur Profilseite
              },
              child: Text('Go to Profile'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/archievement'); // Navigation zur Profilseite
              },
              child: Text('Erfolge'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/group'); // Navigation zur Profilseite
              },
              child: Text('Gruppen'),
            ),
          ],
        ),
      ),
    );
  }
}