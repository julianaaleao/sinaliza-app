import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDgVPeGiDK1RbqAI6j0Ej6Qffc0fMigWWg",
      authDomain: "sinaliza-ee0ad.firebaseapp.com",
      projectId: "sinaliza-ee0ad",
      storageBucket: "sinaliza-ee0ad.firebasestorage.app",
      messagingSenderId: "951334663504",
      appId: "1:951334663504:web:a8f10481bb2331c6f66855",
    ),
  );
  runApp(const App());
}