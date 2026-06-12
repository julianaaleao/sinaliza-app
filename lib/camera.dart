import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'camera_stub.dart'
    if (dart.library.html) 'camera_web_impl.dart'
    if (dart.library.io) 'camera_android.dart';

import 'theme/app_colors.dart';
import 'widgets/app_button.dart';
import 'widgets/app_logo.dart';

const String _ip = 'sinaliza-app-production.up.railway.app';

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
      debugPrint('Erro ao salvar: $e');
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
          setState(() => _resultado = letra);
          await _salvarNoFirestore(letra);
        }
      }
    } catch (e) {
      debugPrint('Erro: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const AppLogo(size: 28, withBackground: false, white: true),
        actions: [
          IconButton(
            tooltip: 'Histórico',
            onPressed: () {
              final usuario = FirebaseAuth.instance.currentUser;
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => _HistoricoModal(uid: usuario?.uid),
              );
            },
            icon: const Icon(Icons.history_rounded),
          ),
          IconButton(
            tooltip: 'Sair',
            onPressed: () async {
              final confirmar = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Text(
                    'Sair da conta',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  content: Text(
                    'Tem certeza que deseja sair?',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        'Sair',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (confirmar == true) {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          // Câmera
          Expanded(
            flex: 5,
            child: _carregando
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  )
                : ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    child: buildCameraView(),
                  ),
          ),

          // Resultado
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
            color: AppColors.background,
            child: Column(
              children: [
                Text(
                  _resultado.isEmpty ? '—' : _resultado,
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _resultado.isEmpty
                        ? AppColors.border
                        : AppColors.primary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _ativo ? 'Detectando...' : 'Câmera pausada',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary.withOpacity(0.6),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),

          // Botão
          Padding(
            padding: EdgeInsets.fromLTRB(
              32,
              0,
              32,
              28 + MediaQuery.of(context).padding.bottom,
            ),
            child: _ativo
                ? AppSecondaryButton(
                    label: 'Parar reconhecimento',
                    onPressed: _carregando ? null : _toggleCamera,
                  )
                : AppGradientButton(
                    label: 'Iniciar reconhecimento',
                    onPressed: _carregando ? null : _toggleCamera,
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
    final theme = Theme.of(context);

    return Container(
      height: 420,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Histórico',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
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
                  return Center(
                    child: Text(
                      'Nenhuma tradução ainda.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary.withOpacity(0.6),
                      ),
                    ),
                  );
                }
                final docs = snapshot.data!.docs;
                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => Divider(
                    color: AppColors.border.withOpacity(0.5),
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final item = docs[index].data() as Map<String, dynamic>;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary,
                        radius: 20,
                        child: Text(
                          item['letra'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      title: Text(
                        'Vogal: ${item['letra']}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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