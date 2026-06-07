import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'camera_stub.dart'
    if (dart.library.html) 'camera_web_impl.dart'
    if (dart.library.io) 'camera_android.dart';

// Mude só este IP quando trocar de rede
const String _ip = 'sinaliza-api.azurewebsites.net';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  String _resultado = '';
  bool _ativo = false;
  bool _carregando = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    await initCamera();
    if (mounted) setState(() => _carregando = false);
  }

  void _toggleCamera() {
    setState(() => _ativo = !_ativo);
    if (_ativo) {
      _timer = Timer.periodic(
          const Duration(seconds: 2), (_) => _capturarEEnviar());
    } else {
      _timer?.cancel();
      setState(() => _resultado = '');
    }
  }

  Future<void> _salvarNoFirestore(String letra) async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) return;
    try {
      await FirebaseFirestore.instance.collection('historico').add({
        'uid': usuario.uid,
        'letra': letra,
        'data': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erro ao salvar: $e');
    }
  }

  Future<void> _capturarEEnviar() async {
    if (!mounted) return;
    try {
      final base64Img = await capturarFrame(null, null);
      if (base64Img == null) return;

      final response = await http.post(
        Uri.parse('https://$_ip/reconhecer'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'imagem': base64Img}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final detectado = data['detectado'] as bool? ?? false;
        final letra = data['letra'] as String? ?? '';

        if (detectado && letra.isNotEmpty) {
          setState(() {
            _resultado = letra;
          });
          await _salvarNoFirestore(letra);
        }
      }
    } catch (e) {
      print('Erro: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SINALIZA'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              final usuario = FirebaseAuth.instance.currentUser;
              showModalBottomSheet(
                context: context,
                builder: (context) => _HistoricoModal(uid: usuario?.uid),
              );
            },
            icon: const Icon(Icons.history),
          ),
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : buildCameraView(),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: Colors.deepPurple.shade50,
            child: Column(
              children: [
                Text(
                  _resultado.isEmpty ? '...' : _resultado,
                  style: const TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                Text(
                  _ativo ? 'Detectando...' : 'Câmera pausada',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              onPressed: _carregando ? null : _toggleCamera,
              icon: Icon(_ativo ? Icons.stop : Icons.play_arrow),
              label: Text(_ativo ? 'Parar' : 'Iniciar reconhecimento'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: _ativo ? Colors.red : Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoricoModal extends StatelessWidget {
  final String? uid;
  const _HistoricoModal({this.uid});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Histórico',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('historico')
                  .where('uid', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Nenhuma tradução ainda!'));
                }
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final item =
                        docs[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.deepPurple,
                        child: Text(
                          item['letra'],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text('Vogal: ${item['letra']}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}