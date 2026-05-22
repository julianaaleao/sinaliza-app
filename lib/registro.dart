import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final txtNome = TextEditingController();
  final txtEmail = TextEditingController();
  final txtSenha = TextEditingController();

  bool darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          darkMode ? const Color(0xFF121212) : Colors.white,

      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(20),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // Botão tema
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      darkMode = !darkMode;
                    });
                  },
                  icon: Icon(
                    darkMode
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    color:
                        darkMode ? Colors.amber : Colors.deepPurple,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Criar conta',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: darkMode
                      ? Colors.white
                      : Colors.deepPurple,
                ),
              ),

              const SizedBox(height: 24),

              TextField(
                controller: txtNome,
                style: TextStyle(
                  color: darkMode ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor:
                      darkMode ? Colors.grey[900] : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelText: 'Nome',
                  labelStyle: TextStyle(
                    color:
                        darkMode ? Colors.white70 : Colors.black54,
                  ),
                  prefixIcon: Icon(
                    Icons.person_outlined,
                    color:
                        darkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: txtEmail,
                style: TextStyle(
                  color: darkMode ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor:
                      darkMode ? Colors.grey[900] : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelText: 'E-mail',
                  labelStyle: TextStyle(
                    color:
                        darkMode ? Colors.white70 : Colors.black54,
                  ),
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color:
                        darkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: txtSenha,
                obscureText: true,
                style: TextStyle(
                  color: darkMode ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor:
                      darkMode ? Colors.grey[900] : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelText: 'Senha',
                  labelStyle: TextStyle(
                    color:
                        darkMode ? Colors.white70 : Colors.black54,
                  ),
                  prefixIcon: Icon(
                    Icons.password_outlined,
                    color:
                        darkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () async {
                  try {
                    await FirebaseAuth.instance
                        .createUserWithEmailAndPassword(
                      email: txtEmail.text.trim(),
                      password: txtSenha.text.trim(),
                    );

                    await FirebaseAuth.instance.currentUser
                        ?.updateDisplayName(
                      txtNome.text.trim(),
                    );

                    Navigator.of(context)
                      ..pop()
                      ..pushReplacementNamed('/camera');

                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Erro ao criar conta. Tente novamente!',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },

                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),

                child: const Text('Registrar'),
              ),

              TextButton(
                onPressed: () => Navigator.pop(context),

                child: Text(
                  'Voltar',
                  style: TextStyle(
                    color: darkMode
                        ? Colors.white70
                        : Colors.deepPurple,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
