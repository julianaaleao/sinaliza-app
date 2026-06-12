import 'package:flutter/material.dart';
import 'login.dart';
import 'registro.dart';
import 'camera.dart';
import 'welcome.dart';
import 'profile.dart';
import 'theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SINALIZA',
      theme: AppTheme.lightTheme(),
      routes: {
        '/login': (context) => LoginPage(),
        '/registro': (context) => RegistroPage(),
        '/welcome': (context) => const WelcomePage(),
        '/camera': (context) => const CameraPage(),
        '/perfil': (context) => const ProfilePage(),
      },
      initialRoute: '/login',
    );
  }
}