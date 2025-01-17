import 'package:flutter/material.dart';
// Importiere Firebase-Pakete
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_application_1/screens/activity_screen.dart';
import 'firebase_options.dart'; // Diese Datei wurde durch `flutterfire configure` generiert
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/archievement_screen.dart';
import 'screens/group_screen.dart';


void main() async {
  // WidgetsFlutterBinding sorgt dafür, dass Widgets initialisiert werden können
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase initialisieren
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gamification App',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(), // Startseite
        '/archievement': (context) => ArchievementScreen(), // Erfolgsseite, Seite nach Login
        '/profile': (context) => ProfileScreen(), // Profilseite
        '/group': (context) => GroupScreen(), //Gruppenseite
        '/activity': (context) => ActivityScreen(), //Aktivitätenseite
      },
    );
  }
}