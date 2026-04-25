import 'package:flutter/material.dart';
import 'login.dart';
import 'registro.dart';
import 'camera.dart';
import 'historico.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SINALIZA',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
      ),
      routes: {
        '/login': (context) => LoginPage(),
        '/registro': (context) => RegistroPage(),
        '/camera': (context) => CameraPage(),
        '/historico': (context) => HistoricoPage(),
      },
      initialRoute: '/login',
    );
  }
}