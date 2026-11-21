import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'servicos/ajustes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
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
  } else {
    await Firebase.initializeApp();
  }
  await Ajustes.instancia.carregar();
  _travarRetratoNoCelular();
  runApp(const App());
}

// Celular fica em retrato; tablet aceita retrato e paisagem
void _travarRetratoNoCelular() {
  if (kIsWeb) return;
  final tela = PlatformDispatcher.instance.views.first;
  final menorLado = tela.physicalSize.shortestSide / tela.devicePixelRatio;
  if (menorLado < 600) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }
}