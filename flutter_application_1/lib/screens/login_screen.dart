import 'imports.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _lastActiveKey = 'lastActiveTime';

  static Future<void> updateLastActiveTime() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(_lastActiveKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<int?> getLastActiveTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastActiveKey);
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _resetEmailController = TextEditingController();

  Future<void> _checkSession() async {
    final lastActiveTime = await SessionManager.getLastActiveTime();
    if (lastActiveTime != null) {
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final timeDiff = (currentTime - lastActiveTime) / 1000; // Sekunden
      if (timeDiff > 360) {
        await FirebaseAuth.instance.signOut();
        // Benutzer wurde abgemeldet
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose();
    super.dispose();
  }

  Future<void> _initializeGoogleSignIn() async {
    if (kIsWeb) {
      // Initialisiere GoogleSignIn explizit mit der Web-Client-ID
      GoogleSignInPlatform.instance.initWithParams(
        const SignInInitParameters(
          clientId: '712873519787-2haf5r93a82upjh2q34h1che81fgflsv.apps.googleusercontent.com ',
          serverClientId: '712873519787-2haf5r93a82upjh2q34h1che81fgflsv.apps.googleusercontent.com ',
        ),
      );
    }
  }
  //Google Sign-In für Web
  Future _signInWithGoogle() async {
  try {
    if (kIsWeb) {
      // Initialisiere GoogleSignIn für Web
      await _initializeGoogleSignIn();

      final GoogleSignIn googleSignIn = GoogleSignIn();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in cancelled by user')),
        );
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      // Überprüfe, ob die E-Mail-Adresse bereits existiert
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (user.emailVerified) {
          // Generiere einen Standard-Benutzernamen
          final String username = 'user_${user.uid.substring(0, 8)}';

          // Überprüfe, ob der Benutzer bereits in Firestore existiert
          final FirebaseFirestore firestore = FirebaseFirestore.instance;
          final DocumentSnapshot doc = await firestore.collection('users').doc(user.uid).get();
          if (!doc.exists) {
            // Benutzer in Firestore anlegen
            await firestore.collection('users').doc(user.uid).set({
              'firstName': '', // Leere Zeichenfolge für Firstname
              'lastName': '', // Leere Zeichenfolge für Lastname
              'username': username,
              'email': user.email,
              'profilePictureUrl': '',
            });
          }

          Navigator.pushNamed(context, '/archievement');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please verify your email address.')),
          );
        }
      }
    } else {
      // Mobile Implementierung bleibt unverändert
      final GoogleSignIn googleSignIn = GoogleSignIn();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in cancelled by user')),
        );
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      // Überprüfe, ob die E-Mail-Adresse bereits existiert
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (user.emailVerified) {
          // Generiere einen Standard-Benutzernamen
          final String username = 'user_${user.uid.substring(0, 8)}';

          // Überprüfe, ob der Benutzer bereits in Firestore existiert
          final FirebaseFirestore firestore = FirebaseFirestore.instance;
          final DocumentSnapshot doc = await firestore.collection('users').doc(user.uid).get();
          if (!doc.exists) {
            // Benutzer in Firestore anlegen
            await firestore.collection('users').doc(user.uid).set({
              'firstName': '', // Leere Zeichenfolge für Firstname
              'lastName': '', // Leere Zeichenfolge für Lastname
              'username': username,
              'email': user.email,
              'profilePictureUrl': '',
            });
          }

          Navigator.pushNamed(context, '/archievement');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please verify your email address.')),
          );
        }
      }
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Google sign-in failed: $e')),
    );
  }
}

  Future<void> _loginWithUsernameAndPassword() async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final QuerySnapshot querySnapshot = await firestore.collection('users').get();

      // Map usernames to emails
      final Map<String, String> usernameToEmail = {
        for (var doc in querySnapshot.docs) doc.get('username'): doc.get('email')
      };

      final String? email = usernameToEmail[_usernameController.text];

      if (email == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Username not found.')),
        );
        return;
      }

      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: _passwordController.text,
      );

      if (userCredential.user?.emailVerified ?? false) {
        Navigator.pushNamed(context, '/profile');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please verify your email address before logging in.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed! Please check your credentials.')),
      );
    }
  }

  Future<void> _resetPassword() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Password'),
        content: TextField(
          controller: _resetEmailController,
          decoration: InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: _resetEmailController.text);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('A password reset email has been sent to your address.')),
                );
                Navigator.of(context).pop();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error resetting password: $e')),
                );
              }
            },
            child: Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  SessionManager.updateLastActiveTime();
  return Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Image.asset(
              'assets/BattleActivity_Logo.png',
              width: 350, // Breite des Logos
              height: 350, // Höhe des Logos
            ),
            SizedBox(height: 20), // Abstand nach dem Logo
            Card(
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (value) => _loginWithUsernameAndPassword(),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      onSubmitted: (value) => _loginWithUsernameAndPassword(),
                    ),
                    TextButton(
                      onPressed: _resetPassword,
                      child: Text('Forgot Password'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
  onPressed: _loginWithUsernameAndPassword,
  style: ElevatedButton.styleFrom(
    minimumSize: Size(150, 50), // Größe des Buttons
    backgroundColor: Color.fromARGB(255, 127, 179, 68), // Hintergrundfarbe
    foregroundColor: Colors.white, // Schriftfarbe
  ),
  child: Text(
    'Login',
    style: TextStyle(fontSize: 20), // Schriftgröße
  ),
),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: kIsWeb ? _signInWithGoogle : _signInWithGoogle,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/google_logo.png', height: 24),
                  SizedBox(width: 10),
                  Text('Login with Google'),
                ],
              ),
            ),
            SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/signup'),
              child: Text('No account yet? Sign up here'),
            ),
          ],
        ),
      ),
    ),
  );
}
}