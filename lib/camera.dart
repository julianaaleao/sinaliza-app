import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'camera_stub.dart'
    if (dart.library.html) 'camera_web_impl.dart'
    if (dart.library.io) 'camera_android.dart';

import 'frases.dart';
import 'respostas.dart';
import 'theme/app_colors.dart';
import 'widgets/app_button.dart';
import 'widgets/app_logo.dart';

// Padrão: API no Railway. Para testar local:
// flutter run --dart-define=API_URL=http://127.0.0.1:8000
const String _apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'https://sinaliza-app-production.up.railway.app',
);

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

enum _Modo { frases, vogais }

enum _Servidor { conectando, pronto, offline }

String _segundos(Duration d) =>
    '${(d.inMilliseconds / 1000).toStringAsFixed(1).replaceAll('.', ',')}s';

class _CameraPageState extends State<CameraPage> {
  _Modo _modo = _Modo.frases;
  String _resultado = '';
  bool _ativo = false;
  bool _carregando = true;
  String _ultimoSalvo = '';

  // Ao abrir a tela o app chama /saude para acordar a API no Railway,
  // que pode demorar no primeiro acesso
  _Servidor _servidor = _Servidor.conectando;

  // Modo vogais: cada vez que inicia/para/troca de modo, o ciclo muda e
  // qualquer resposta de um ciclo antigo é descartada
  int _ciclo = 0;
  String _statusVogais = 'Câmera pausada';

  // Resposta que chega depois disso não vale mais: a mão já pode ter mudado.
  // Evita o "monte de letras atrasadas" quando o servidor fica lento.
  static const _atrasoMaximo = Duration(seconds: 3);

  // Modo frases: botão "Ler sinal" -> contagem -> grava ~5s -> respostas
  bool _lendoFrase = false;
  int _contagem = 0;
  String _statusFrase = 'Toque em "Ler sinal" e peça para a pessoa sinalizar';

  // Modo vogais: cada ciclo grava ~1,5s de frames e manda tudo junto para
  // a API, que reconhece a vogal e o gesto dinâmico (OI)
  static const _janela = Duration(milliseconds: 1500);
  static const _janelaFrase = Duration(seconds: 5); // igual a DURACAO_SEGUNDOS da API
  // Menos frames = servidor responde mais rápido; os modelos foram
  // treinados para funcionar com poucos frames
  static const _intervaloFrames = Duration(milliseconds: 200);

  @override
  void initState() {
    super.initState();
    _acordarServidor();
    _iniciar();
  }

  Future<void> _iniciar() async {
    await initCamera();
    if (mounted) setState(() => _carregando = false);
  }

  Future<void> _acordarServidor() async {
    try {
      final response = await http
          .get(Uri.parse('$_apiUrl/saude'))
          .timeout(const Duration(seconds: 60));
      if (!mounted) return;
      setState(() => _servidor =
          response.statusCode == 200 ? _Servidor.pronto : _Servidor.offline);
    } catch (e) {
      debugPrint('Servidor indisponível: $e');
      if (mounted) setState(() => _servidor = _Servidor.offline);
    }
  }

  void _tentarConectar() {
    setState(() => _servidor = _Servidor.conectando);
    _acordarServidor();
  }

  void _toggleCamera() {
    _ciclo++;
    setState(() {
      _ativo = !_ativo;
      _resultado = '';
      _statusVogais = _ativo ? 'Lendo a mão...' : 'Câmera pausada';
    });
    _ultimoSalvo = '';
    if (_ativo) _loop(_ciclo);
  }

  Future<void> _loop(int ciclo) async {
    // Um pedido por vez: só captura o próximo depois que o anterior respondeu
    while (_ativo && mounted && ciclo == _ciclo) {
      await _capturarEEnviar(ciclo);
    }
  }

  void _trocarModo(_Modo modo) {
    if (_lendoFrase || modo == _modo) return;
    _ciclo++;
    setState(() {
      _ativo = false;
      _resultado = '';
      _statusVogais = 'Câmera pausada';
      _modo = modo;
    });
    _ultimoSalvo = '';
  }

  Future<void> _lerFrase() async {
    setState(() => _lendoFrase = true);
    try {
      for (var i = 3; i > 0; i--) {
        if (!mounted) return;
        setState(() {
          _contagem = i;
          _statusFrase = 'Prepare...';
        });
        await Future.delayed(const Duration(seconds: 1));
      }
      if (!mounted) return;
      setState(() {
        _contagem = 0;
        _statusFrase = 'Lendo o sinal...';
      });

      final imagens = <String>[];
      final tempos = <int>[];
      final relogio = Stopwatch()..start();
      while (relogio.elapsed < _janelaFrase) {
        final base64Img = await capturarFrame();
        if (base64Img != null) {
          imagens.add(base64Img);
          tempos.add(relogio.elapsedMilliseconds);
        }
        await Future.delayed(_intervaloFrames);
      }
      if (!mounted) return;
      if (imagens.isEmpty) {
        setState(() => _statusFrase = 'A câmera não respondeu. Tente de novo.');
        return;
      }

      setState(() => _statusFrase = 'Analisando...');
      final espera = Stopwatch()..start();
      final response = await http
          .post(
            Uri.parse('$_apiUrl/reconhecer_frase'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'imagens': imagens, 'tempos_ms': tempos}),
          )
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;

      if (response.statusCode == 503) {
        setState(() => _statusFrase = 'O modelo de frases ainda não foi treinado.');
        return;
      }
      if (response.statusCode != 200) {
        setState(() => _statusFrase = 'Erro na API (${response.statusCode}). Tente de novo.');
        return;
      }

      final data = jsonDecode(response.body);
      final frase = fraseDoId(data['frase'] as String? ?? '');
      if (data['detectado'] != true) {
        setState(() => _statusFrase = 'Não vi as mãos. Tente de novo.');
        return;
      }
      if (frase == null) {
        setState(() => _statusFrase = 'Não reconheci a frase. Tente de novo.');
        return;
      }

      setState(() {
        _resultado = frase.texto;
        _statusFrase =
            'Analisado em ${_segundos(espera.elapsed)} · toque em "Ler sinal" para a próxima';
      });
      _salvarNoFirestore(frase.texto);
      setState(() => _lendoFrase = false);

      final lerDeNovo = await mostrarRespostas(context, frase);
      if (lerDeNovo && mounted) await _lerFrase();
    } on TimeoutException {
      if (mounted) {
        setState(() => _statusFrase = 'O servidor demorou demais. Tente de novo.');
      }
    } catch (e) {
      debugPrint('Erro: $e');
      if (mounted) {
        setState(() => _statusFrase = 'Sem conexão com a API. Tente de novo.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _lendoFrase = false;
          _contagem = 0;
        });
      }
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

  Future<void> _capturarEEnviar(int ciclo) async {
    if (!mounted) return;
    bool valeAinda() => mounted && _ativo && ciclo == _ciclo;
    try {
      final imagens = <String>[];
      final tempos = <int>[];
      final relogio = Stopwatch()..start();
      while (relogio.elapsed < _janela && valeAinda()) {
        final base64Img = await capturarFrame();
        if (base64Img != null) {
          imagens.add(base64Img);
          tempos.add(relogio.elapsedMilliseconds);
        }
        await Future.delayed(_intervaloFrames);
      }
      if (imagens.isEmpty || !valeAinda()) {
        await Future.delayed(const Duration(milliseconds: 500));
        return;
      }

      setState(() => _statusVogais = 'Analisando...');
      final espera = Stopwatch()..start();
      final response = await http
          .post(
            Uri.parse('$_apiUrl/reconhecer_sequencia'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'imagens': imagens, 'tempos_ms': tempos}),
          )
          .timeout(const Duration(seconds: 10));

      if (!valeAinda()) return;

      // Resposta atrasada: descarta em vez de mostrar uma letra velha
      if (espera.elapsed > _atrasoMaximo) {
        setState(() => _statusVogais =
            'Servidor lento (${_segundos(espera.elapsed)}): resultado descartado');
        return;
      }

      if (response.statusCode != 200) {
        setState(() => _statusVogais = 'Erro na API (${response.statusCode})');
        return;
      }

      final data = jsonDecode(response.body);
      final detectado = data['detectado'] as bool? ?? false;
      final resultado = data['resultado'] as String? ?? '';

      if (detectado && resultado.isNotEmpty) {
        setState(() {
          _resultado = resultado;
          _statusVogais = 'Resposta em ${_segundos(espera.elapsed)}';
        });
        if (resultado != _ultimoSalvo) {
          _ultimoSalvo = resultado;
          await _salvarNoFirestore(resultado);
        }
      } else {
        setState(() => _statusVogais =
            'Mão não detectada · ${_segundos(espera.elapsed)}');
      }
    } on TimeoutException {
      if (valeAinda()) {
        setState(() => _statusVogais = 'O servidor não respondeu, tentando de novo...');
      }
    } catch (e) {
      debugPrint('Erro: $e');
      if (valeAinda()) {
        setState(() => _statusVogais = 'Sem conexão com o servidor, tentando de novo...');
      }
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  @override
  void dispose() {
    _ativo = false;
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
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        buildCameraView(),
                        if (_contagem > 0)
                          Center(
                            child: Text(
                              '$_contagem',
                              style: theme.textTheme.displayLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 120,
                                shadows: const [
                                  Shadow(blurRadius: 16, color: Colors.black54),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),

          // Modo
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
            child: SegmentedButton<_Modo>(
              segments: const [
                ButtonSegment(value: _Modo.frases, label: Text('Frases')),
                ButtonSegment(value: _Modo.vogais, label: Text('Vogais')),
              ],
              selected: {_modo},
              showSelectedIcon: false,
              onSelectionChanged: _lendoFrase
                  ? null
                  : (selecao) => _trocarModo(selecao.first),
            ),
          ),

          // Resultado
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            color: AppColors.background,
            child: Column(
              children: [
                Text(
                  _resultado.isEmpty ? '—' : _resultado,
                  textAlign: TextAlign.center,
                  style: (_modo == _Modo.frases
                          ? theme.textTheme.headlineMedium
                          : theme.textTheme.displayLarge)
                      ?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _resultado.isEmpty
                        ? AppColors.border
                        : AppColors.primary,
                    letterSpacing: _modo == _Modo.frases ? 0 : 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _modo == _Modo.frases ? _statusFrase : _statusVogais,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary.withOpacity(0.6),
                    letterSpacing: 0.2,
                  ),
                ),
                if (_servidor == _Servidor.conectando)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Conectando ao servidor...',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                if (_servidor == _Servidor.offline)
                  TextButton(
                    onPressed: _tentarConectar,
                    child: const Text(
                      'Servidor fora do ar · tocar para tentar de novo',
                      style: TextStyle(color: AppColors.error),
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
            child: _modo == _Modo.frases
                ? AppGradientButton(
                    label: 'Ler sinal',
                    isLoading: _lendoFrase,
                    onPressed: _carregando || _servidor != _Servidor.pronto
                        ? null
                        : _lerFrase,
                  )
                : _ativo
                    ? AppSecondaryButton(
                        label: 'Parar reconhecimento',
                        onPressed: _toggleCamera,
                      )
                    : AppGradientButton(
                        label: 'Iniciar reconhecimento',
                        onPressed: _carregando || _servidor != _Servidor.pronto
                            ? null
                            : _toggleCamera,
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
                        '${item['letra'].length > 1 ? 'Sinal' : 'Vogal'}: ${item['letra']}',
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