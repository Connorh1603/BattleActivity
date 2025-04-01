import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/archievement_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/group_screen.dart';
import 'screens/activity_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _timer = Timer(Duration(minutes: 30), () async {
        await FirebaseAuth.instance.signOut(); // Benutzer abmelden
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/'); // Zurück zur Login-Seite
        }
      });
    } else if (state == AppLifecycleState.resumed) {
      _timer?.cancel(); // Timer abbrechen, wenn die App wieder aktiv ist
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return MaterialApp(
            title: 'Gamification App',
            theme: ThemeData(primarySwatch: Colors.blue),
            initialRoute: '/profile', // Navigiere zur Profile-Seite, wenn angemeldet
            routes: {
              '/profile': (context) => const ProfileScreen(),
              '/archievement': (context) => const AchievementScreen(),
              '/group': (context) => const GroupScreen(),
              '/activity': (context) => const ActivityScreen(),
            },
          );
        } else {
          return MaterialApp(
            title: 'Gamification App',
            theme: ThemeData(primarySwatch: Colors.blue),
            initialRoute: '/', // Navigiere zur Login-Seite, wenn nicht angemeldet
            routes: {
              '/': (context) => const LoginScreen(),
              '/signup': (context) => const SignupScreen(),
            },
          );
        }
      },
    );
  }
}



