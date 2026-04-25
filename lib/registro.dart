import 'package:flutter/material.dart';

class RegistroPage extends StatelessWidget {
  final txtNome = TextEditingController();
  final txtEmail = TextEditingController();
  final txtSenha = TextEditingController();

  RegistroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: EdgeInsets.all(20),
        child: Column(
          spacing: 16,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Criar conta',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: txtNome,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Nome',
                prefixIcon: Icon(Icons.person_outlined),
              ),
            ),
            TextField(
              controller: txtEmail,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            TextField(
              controller: txtSenha,
              obscureText: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Senha',
                prefixIcon: Icon(Icons.password_outlined),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context)
                  ..pop()
                  ..pushReplacementNamed('/camera');
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: Text('Registrar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }
}