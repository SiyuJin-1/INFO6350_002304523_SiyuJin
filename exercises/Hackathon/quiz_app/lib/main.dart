import 'package:flutter/material.dart';
import 'quiz_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('FIREBASE PROJECT: ${DefaultFirebaseOptions.currentPlatform.projectId}');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _signingIn = false;

  Future<void> _signInWithGoogle() async {
    if (_signingIn) return;
    setState(() => _signingIn = true);
    try {
      final gUser = await GoogleSignIn().signIn();
      if (gUser == null) return;
      final gAuth = await gUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google 登录失败: $e')),
      );
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  Future<void> _signOut() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = snap.data;
        if (user == null) {
          return Scaffold(
            backgroundColor: Colors.indigo.shade50,
            appBar: AppBar(
              title: const Text('Welcome to Quiz App'),
              centerTitle: true,
            ),
            body: Center(
              child: Card(
                elevation: 4,
                margin: const EdgeInsets.all(24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        'Sign in to start your quiz!',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.login),
                          label: Text(_signingIn ? 'Signing in...' : 'Sign in with Google'),
                          onPressed: _signingIn ? null : _signInWithGoogle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // ✅ 登录成功后进入主页
        return HomePage(onLogout: _signOut, user: user);
      },
    );
  }
}

class HomePage extends StatelessWidget {
  final User user;
  final VoidCallback onLogout;

  const HomePage({super.key, required this.user, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Quizzes'),
        actions: [
          if (user.photoURL != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(backgroundImage: NetworkImage(user.photoURL!)),
            ),
          IconButton(
            tooltip: 'Logout',
            onPressed: onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('quizzes').snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No quizzes available.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final quiz = docs[i].data() as Map<String, dynamic>;
              final quizId = docs[i].id;
              final title = quiz['title'] ?? 'Untitled Quiz';
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizPage(quizId: quizId, title: title),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
