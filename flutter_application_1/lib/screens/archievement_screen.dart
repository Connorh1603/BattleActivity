import 'package:flutter/material.dart';

class ArchievementScreen extends StatelessWidget {
  const ArchievementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Erfolge'),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/profile'); // Navigation zur Profilseite
              },
              child: Text('Go to Profile'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/activity'); // Navigation zur Profilseite
              },
              child: Text('Aktivitäten'),
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
