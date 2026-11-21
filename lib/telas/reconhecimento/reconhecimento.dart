// Reconhecimento: UMA tela com a máquina de estados das telas 07 a 15
// (e 10, 20, 32). Celular: câmera em cima e painel azul embaixo.
// Tablet em paisagem (≥ 768 px): câmera à esquerda e painel Conversa de
// 384 px à direita (telas 21 e 22).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../camera_stub.dart'
    if (dart.library.html) '../../camera_web_impl.dart'
    if (dart.library.io) '../../camera_android.dart';
import '../../frases.dart';
import '../../servicos/ajustes.dart';
import '../../servicos/api.dart';
import '../../servicos/conversas.dart';
import '../../theme/tokens.dart';
import '../../ui/botoes.dart';
import '../../ui/componentes.dart';
import '../../ui/icones.dart';
import '../../ui/sobreposicoes.dart';
import '../rotas.dart';
import '../video_resposta.dart';
import 'cena_camera.dart';

enum Modo { frases, vogais }

enum Estado {
  pronto, // 07 / 14
  contagem, // 08
  lendo, // 09
  naoReconhecido, // 10
  reconhecido, // 11
  conversa, // 13
  letraReconhecida, // 15
}

enum Servidor { conectando, pronto, offline }

class ReconhecimentoPage extends StatefulWidget {
  const ReconhecimentoPage({super.key});

  @override
  State<ReconhecimentoPage> createState() => _ReconhecimentoPageState();
}

class _ReconhecimentoPageState extends State<ReconhecimentoPage>
    with WidgetsBindingObserver {
  final _ajustes = Ajustes.instancia;
  final _sessao = SessaoAtual();

  Modo _modo = Modo.frases;
  Estado _estado = Estado.pronto;
  Servidor _servidor = Servidor.conectando;

  // Cada leitura tem um ciclo; cancelar ou sair invalida o ciclo atual
  int _ciclo = 0;
  int _contagem = 0;
  double _progresso = 0;
  bool _analisando = false;

  Frase? _frase;
  double? _confianca;
  bool _substituir = false; // "Outra resposta" troca a última resposta

  String? _letra;
  final List<String> _palavra = [];

  bool _cameraPronta = false;
  Timer? _verificador;

  final _focoFrase = FocusNode();
  final List<FocusNode> _focosRespostas = [];

  bool get _lendoAgora =>
      _estado == Estado.contagem || _estado == Estado.lendo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _iniciarCamera();
    _verificarServidor(primeira: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ciclo++;
    _verificador?.cancel();
    _focoFrase.dispose();
    for (final f in _focosRespostas) {
      f.dispose();
    }
    pararCamera();
    super.dispose();
  }

  // App em segundo plano: para a câmera. Ao voltar: estado idle, a
  // conversa permanece.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _ciclo++;
      pararCamera();
      if (mounted) setState(() => _cameraPronta = false);
    } else if (state == AppLifecycleState.resumed && !_cameraPronta) {
      if (_estado != Estado.reconhecido) {
        setState(() => _estado = _base());
      }
      _iniciarCamera();
    }
  }

  Future<void> _iniciarCamera() async {
    await initCamera(frontal: _ajustes.cameraFrontal);
    if (mounted) setState(() => _cameraPronta = true);
  }

  Future<void> _alternarCamera() async {
    _ajustes.definirCameraFrontal(!_ajustes.cameraFrontal);
    setState(() => _cameraPronta = false);
    await _iniciarCamera();
  }

  // ---------- Servidor / conexão (tela 20) ----------

  Future<void> _verificarServidor({bool primeira = false}) async {
    if (!primeira && mounted) setState(() => _servidor = Servidor.conectando);
    final ok = await Api.saude(
        limite: Duration(seconds: primeira ? 60 : 10));
    if (!mounted) return;
    setState(() => _servidor = ok ? Servidor.pronto : Servidor.offline);
    if (ok) {
      _verificador?.cancel();
      _verificador = null;
    } else {
      _vigiarConexao();
    }
  }

  // Sem conexão: verifica a rede a cada 5 s em segundo plano
  void _vigiarConexao() {
    _verificador ??= Timer.periodic(const Duration(seconds: 5), (_) async {
      final ok = await Api.saude(limite: const Duration(seconds: 4));
      if (!mounted || !ok) return;
      _verificador?.cancel();
      _verificador = null;
      setState(() => _servidor = Servidor.pronto);
    });
  }

  void _ficouOffline() {
    _ciclo++;
    setState(() {
      _servidor = Servidor.offline;
      _estado = _base();
    });
    _anunciar('Sem conexão com a internet');
    _vigiarConexao();
  }

  // ---------- Máquina de estados ----------

  Estado _base() {
    if (_modo == Modo.frases && !_sessao.vazia) return Estado.conversa;
    return Estado.pronto;
  }

  void _anunciar(String msg) {
    if (!mounted) return;
    SemanticsService.sendAnnouncement(
        View.of(context), msg, TextDirection.ltr);
  }

  Future<void> _vibrarErro() async {
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 140));
    HapticFeedback.heavyImpact();
  }

  Future<void> _lerSinal() async {
    if (_servidor != Servidor.pronto || !_cameraPronta) return;
    final ciclo = ++_ciclo;
    HapticFeedback.lightImpact();
    _sessao.tocar();

    final n = _ajustes.contagemSegundos;
    if (n > 0) {
      setState(() => _estado = Estado.contagem);
      for (var i = n; i > 0; i--) {
        if (ciclo != _ciclo || !mounted) return;
        setState(() => _contagem = i);
        _anunciar('Contando $i');
        HapticFeedback.lightImpact();
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    if (ciclo != _ciclo || !mounted) return;
    await _ler(ciclo);
  }

  Future<void> _ler(int ciclo) async {
    setState(() {
      _estado = Estado.lendo;
      _progresso = 0;
      _analisando = false;
    });
    _anunciar('Lendo sinal');

    final janela = _modo == Modo.frases ? janelaFrase : janelaVogal;
    final imagens = <String>[];
    final tempos = <int>[];
    final relogio = Stopwatch()..start();
    while (relogio.elapsed < janela) {
      if (ciclo != _ciclo || !mounted) return;
      final img = await capturarFrame();
      if (img != null) {
        imagens.add(img);
        tempos.add(relogio.elapsedMilliseconds);
      }
      if (mounted) {
        setState(() => _progresso =
            (relogio.elapsedMilliseconds / janela.inMilliseconds)
                .clamp(0, 1));
      }
      await Future.delayed(intervaloFrames);
    }
    if (ciclo != _ciclo || !mounted) return;
    if (imagens.isEmpty) return _falhou();

    setState(() {
      _analisando = true;
      _progresso = 1;
    });
    try {
      if (_modo == Modo.frases) {
        final r = await Api.reconhecerFrase(imagens, tempos);
        if (ciclo != _ciclo || !mounted) return;
        final frase = fraseDoId(r.fraseId);
        final conf = r.confianca;
        if (!r.maosDetectadas || frase == null || (conf != null && conf < .55)) {
          return _falhou();
        }
        _reconheceu(frase, conf);
      } else {
        final r = await Api.reconhecerVogal(imagens, tempos);
        if (ciclo != _ciclo || !mounted) return;
        if (!r.maosDetectadas || r.resultado.isEmpty) return _falhou();
        _letraReconhecida(r.resultado);
      }
    } on SemConexao {
      if (ciclo == _ciclo && mounted) _ficouOffline();
    } on TimeoutException {
      if (ciclo == _ciclo && mounted) _falhou();
    } on ErroApi catch (e) {
      debugPrint('Erro na API: ${e.status}');
      if (ciclo == _ciclo && mounted) _falhou();
    } catch (e) {
      debugPrint('Erro: $e');
      if (ciclo == _ciclo && mounted) _falhou();
    } finally {
      if (mounted) setState(() => _analisando = false);
    }
  }

  void _falhou() {
    setState(() => _estado = Estado.naoReconhecido);
    _anunciar('Não consegui entender o sinal');
    _vibrarErro();
  }

  void _reconheceu(Frase frase, double? conf) {
    HapticFeedback.mediumImpact();
    setState(() {
      _frase = frase;
      _confianca = conf;
      _substituir = false;
      _estado = Estado.reconhecido;
    });
    _anunciar('Frase reconhecida: ${frase.texto}');
    // Foco do leitor de tela vai para a frase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focoFrase.requestFocus();
    });
  }

  void _letraReconhecida(String letra) {
    HapticFeedback.mediumImpact();
    setState(() {
      _letra = letra;
      _palavra.add(letra);
      _estado = Estado.letraReconhecida;
    });
    _anunciar('Letra reconhecida: $letra');
  }

  void _cancelar() {
    _ciclo++;
    setState(() => _estado = _base());
  }

  void _trocarModo(Modo m) {
    if (_lendoAgora || m == _modo) return;
    _ciclo++;
    setState(() {
      _modo = m;
      _estado = _base();
    });
  }

  FocusNode _focoResposta(int i) {
    while (_focosRespostas.length <= i) {
      _focosRespostas.add(FocusNode());
    }
    return _focosRespostas[i];
  }

  Future<void> _escolherResposta(Resposta resposta, int indice,
      {required bool tablet}) async {
    final frase = _frase;
    if (frase == null) return;
    final r = await mostrarVideoResposta(
      context,
      texto: resposta.texto,
      gif: proximoGif(resposta),
      modal: tablet,
    );
    if (!mounted) return;
    if (r == ResultadoVideo.fechado) {
      // Volta às respostas; foco na resposta tocada
      _focoResposta(indice).requestFocus();
      return;
    }
    final salvar = _ajustes.salvarHistorico;
    if (_substituir) {
      await _sessao.trocarUltimaResposta(resposta.texto, salvar);
    } else {
      await _sessao.adicionarTroca(frase.texto, frase.id, resposta.texto, salvar);
    }
    if (!mounted) return;
    setState(() {
      _substituir = false;
      _estado = Estado.conversa;
    });
  }

  void _outraResposta() {
    final ultima = _sessao.mensagens.lastWhere((m) => m.surda,
        orElse: () => Mensagem(surda: true, texto: ''));
    final frase = fraseDoId(ultima.fraseId ?? '');
    if (frase == null) return;
    setState(() {
      _frase = frase;
      _confianca = null;
      _substituir = true;
      _estado = Estado.reconhecido;
    });
  }

  // Só reproduz o vídeo, sem alterar a conversa
  Future<void> _verDeNovo(Mensagem m, {required bool tablet}) async {
    final resposta = respostaDaMensagem(m);
    if (resposta == null) return;
    await mostrarVideoResposta(context,
        texto: resposta.texto, gif: proximoGif(resposta), modal: tablet);
  }

  void _encerrar() {
    _sessao.encerrar();
    setState(() => _estado = Estado.pronto);
  }

  void _apagarLetra() {
    if (_palavra.isEmpty) return;
    setState(() {
      _palavra.removeLast();
      if (_palavra.isEmpty) _estado = Estado.pronto;
    });
  }

  void _limparPalavra() => setState(() {
        _palavra.clear();
        _letra = null;
        _estado = Estado.pronto;
      });

  // Voltar do sistema: em estados de leitura funciona como Cancelar
  bool get _voltarCancela =>
      _estado == Estado.contagem ||
      _estado == Estado.lendo ||
      _estado == Estado.naoReconhecido ||
      _estado == Estado.reconhecido;

  // ---------- Interface ----------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_voltarCancela,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancelar();
      },
      child: Scaffold(
        backgroundColor: Cores.brandDark,
        body: LayoutBuilder(builder: (context, c) {
          final tablet = c.maxWidth >= 768 && c.maxWidth > c.maxHeight;
          if (tablet) return _layoutTablet(c);
          final celular = _estado == Estado.conversa
              ? _layoutConversa()
              : _layoutCelular(c);
          // Tablet em retrato: layout do celular centralizado (máx. 480)
          if (c.maxWidth > 480) {
            return ColoredBox(
              color: Cores.night,
              child: Center(
                child: SizedBox(width: 480, child: celular),
              ),
            );
          }
          return celular;
        }),
      ),
    );
  }

  Widget _barraTopo({bool grande = false}) {
    return Row(
      children: [
        LogoQuadro(
            tamanho: grande ? 46 : 42, raio: grande ? 15 : 14, sombra: false),
        const SizedBox(width: 10),
        Text('Sinaliza',
            style: Texto.bric(grande ? 24 : 22, grande ? 24 : 22,
                cor: Colors.white, espacamento: -.01)),
        const Spacer(),
        BotaoIcone(
          icone: Icone.historico,
          rotulo: 'Histórico',
          onPressed: () => Navigator.pushNamed(context, Rotas.historico),
        ),
        const SizedBox(width: 8),
        BotaoIcone(
          icone: Icone.usuario,
          rotulo: 'Perfil e ajustes',
          onPressed: () => Navigator.pushNamed(context, Rotas.ajustes),
        ),
      ],
    );
  }

  Color get _corMoldura => switch (_estado) {
        Estado.lendo => Cores.sky,
        Estado.naoReconhecido => Cores.danger,
        Estado.letraReconhecida => Cores.success,
        _ => Colors.white,
      };

  double get _escurecer => switch (_estado) {
        Estado.reconhecido => .6,
        Estado.contagem || Estado.letraReconhecida => .2,
        _ => _servidor == Servidor.offline ? .35 : 0,
      };

  Widget _camera() {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
            decoration: BoxDecoration(gradient: Gradientes.cenaCamera)),
        if (_cameraPronta)
          Semantics(
            label: 'Imagem da câmera',
            image: true,
            child: buildCameraView(),
          ),
        IgnorePointer(
          child: AnimatedContainer(
            duration: Movimento.sheet,
            color: Cores.noite(_escurecer),
          ),
        ),
      ],
    );
  }

  // Sobreposições do centro da câmera (moldura, contagem, varredura)
  Widget _sobreposicoesMoldura() {
    return Stack(
      fit: StackFit.expand,
      children: [
        MolduraCamera(cor: _corMoldura),
        if (_estado == Estado.lendo) const LinhaVarredura(),
      ],
    );
  }

  Widget _pilulaTopo() {
    switch (_estado) {
      case Estado.pronto:
        return PilulaVidro(
          child: Text(_modo == Modo.frases
              ? 'Peça para a pessoa sinalizar dentro da moldura'
              : 'Mostre uma vogal: A, E, I, O ou U'),
        );
      case Estado.naoReconhecido:
        return PilulaVidro(
          fundo: Cores.danger.withValues(alpha: .9),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Ico(Icone.alerta, tamanho: 16, cor: Colors.white),
              SizedBox(width: 8),
              Text('Não identificado'),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _pilulaLendo() => PilulaVidro(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Cores.capture,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Cores.capture, blurRadius: 10)],
              ),
            ),
            const SizedBox(width: 8),
            Text('Lendo',
                style: Texto.fig(13, 18,
                    peso: FontWeight.w800, cor: Colors.white)),
          ],
        ),
      );

  Widget _contagemCentro() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnelContagem(numero: _contagem),
          const SizedBox(height: 16),
          PilulaVidro(
            child: Text('A pessoa pode começar a sinalizar',
                style: Texto.fig(14, 20,
                    peso: FontWeight.w700, cor: Colors.white)),
          ),
        ],
      );

  // ----- Celular: câmera + painel inferior -----
  Widget _layoutCelular(BoxConstraints c) {
    final seguro = MediaQuery.paddingOf(context);
    final h = c.maxHeight;
    final vogais = _modo == Modo.vogais;
    // Medidas do quadro de 844 px de altura, ajustadas à tela
    final fundoCamera = h - 164;
    final topoMoldura = seguro.top + (vogais ? 146 : 128);
    final baseMoldura = fundoCamera - (vogais ? 210 : 178);
    final lateral = vogais ? 70.0 : 36.0;

    return Stack(
      children: [
        Positioned(
            left: 0, right: 0, top: 0, height: fundoCamera, child: _camera()),
        Positioned(
          left: lateral,
          right: lateral,
          top: topoMoldura,
          height: (baseMoldura - topoMoldura).clamp(120, 600),
          child: _sobreposicoesMoldura(),
        ),
        // Barra superior (vidro escuro em degradê)
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(16, seguro.top + 4, 16, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Cores.noite(.75), Cores.noite(0)],
              ),
            ),
            child: _barraTopo(),
          ),
        ),
        if (_servidor == Servidor.offline)
          Positioned(
            left: 16,
            right: 16,
            top: seguro.top + 72,
            child: const BannerAviso(
              titulo: 'Sem conexão com a internet',
              texto:
                  'O reconhecimento de sinais precisa de internet. Conecte-se para continuar.',
            ),
          )
        else if (_estado == Estado.lendo)
          Positioned(left: 16, top: seguro.top + 78, child: _pilulaLendo())
        else
          Positioned(
            left: 16,
            right: 16,
            top: seguro.top + 72,
            child: Center(child: _pilulaTopo()),
          ),
        if (_estado == Estado.contagem)
          Positioned(
            left: 0,
            right: 0,
            top: topoMoldura,
            height: (baseMoldura - topoMoldura).clamp(260, 600),
            child: Center(child: _contagemCentro()),
          ),
        if (_estado == Estado.pronto && _servidor != Servidor.offline)
          Positioned(
            right: 16,
            top: baseMoldura + 38,
            child: _botaoAlternar(),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _estado == Estado.reconhecido
              ? _sheetRespostas(h)
              : _painelEscuro(),
        ),
      ],
    );
  }

  Widget _botaoAlternar() => BotaoIcone(
        icone: Icone.alternarCamera,
        rotulo: 'Alternar câmera',
        onPressed: _alternarCamera,
        fundo: Cores.branco(.18),
        borda: Border.all(color: Cores.branco(.25)),
      );

  Widget _painelEscuro() {
    final seguro = MediaQuery.paddingOf(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 244),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 30 + seguro.bottom),
      decoration: const BoxDecoration(
        gradient: Gradientes.painel,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(Raios.painel)),
        boxShadow: Sombras.painel,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Alca(),
          ..._conteudoPainel(escuro: true),
        ],
      ),
    );
  }

  // Conteúdo do painel por estado. escuro = painel azul do celular;
  // claro = painel lateral do tablet.
  List<Widget> _conteudoPainel({required bool escuro}) {
    final corTexto = escuro ? Colors.white : Cores.text;
    final corApoio = escuro ? Cores.branco(.85) : Cores.textMuted;
    final tipoCancelar = escuro ? TipoBotao.vidro : TipoBotao.secundario;
    Widget apoio(Widget t) => Semantics(
          liveRegion: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: DefaultTextStyle(
              style: Texto.fig(14, 20, peso: FontWeight.w600, cor: corApoio),
              textAlign: TextAlign.center,
              child: t,
            ),
          ),
        );
    final offline = _servidor == Servidor.offline;

    if (offline &&
        (_estado == Estado.pronto || _estado == Estado.conversa)) {
      return [
        _Abas(modo: _modo, ativo: false, escuro: escuro, onTroca: _trocarModo),
        const SizedBox(height: 14),
        Botao(_modo == Modo.frases ? 'Ler sinal' : 'Ler letra',
            icone: _modo == Modo.frases ? Icone.scan : Icone.letra,
            tipo: TipoBotao.amarelo,
            sobreEscuro: escuro,
            onPressed: null),
        const SizedBox(height: 8),
        Botao('Tentar novamente',
            tipo: tipoCancelar,
            icone: Icone.repetir,
            altura: 52,
            carregando: _servidor == Servidor.conectando,
            onPressed: () => _verificarServidor()),
      ];
    }

    switch (_estado) {
      case Estado.pronto:
      case Estado.conversa:
        final conectando = _servidor == Servidor.conectando;
        final frases = _modo == Modo.frases;
        return [
          _Abas(modo: _modo, ativo: true, escuro: escuro, onTroca: _trocarModo),
          if (!frases && _palavra.isNotEmpty) ...[
            const SizedBox(height: 14),
            _palavraAteAgora(escuro: escuro, comApagar: true),
          ],
          apoio(conectando
              ? const Text('Conectando ao servidor…')
              : frases
                  ? const Text.rich(TextSpan(children: [
                      TextSpan(text: 'Toque em '),
                      TextSpan(
                          text: 'Ler sinal',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      TextSpan(text: ' e a contagem começa.'),
                    ]))
                  : const Text(
                      'O Sinaliza lê uma letra por vez e monta a palavra.')),
          Botao(
            frases ? 'Ler sinal' : 'Ler letra',
            icone: frases ? Icone.scan : Icone.letra,
            tipo: TipoBotao.amarelo,
            sobreEscuro: escuro,
            vibrar: true,
            onPressed: conectando || !_cameraPronta ? null : _lerSinal,
          ),
        ];

      case Estado.contagem:
        return [
          _Abas(modo: _modo, ativo: false, escuro: escuro, onTroca: _trocarModo),
          apoio(const Text('Prepare-se…')),
          Botao('Cancelar', tipo: tipoCancelar, altura: 60, onPressed: _cancelar),
        ];

      case Estado.lendo:
        return [
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const PontosLeitura(),
                Semantics(
                  liveRegion: true,
                  child: Text('Lendo o sinal…',
                      style: Texto.bric(22, 28, cor: corTexto)),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _analisando ? null : _progresso,
              minHeight: 8,
              color: Cores.capture,
              backgroundColor: escuro ? Cores.branco(.18) : Cores.ice,
            ),
          ),
          apoio(const Text('Mantenha as mãos dentro da moldura.')),
          Botao('Cancelar', tipo: tipoCancelar, onPressed: _cancelar),
        ];

      case Estado.naoReconhecido:
        return [
          Row(
            children: [
              const QuadradoIcone(
                  icone: Icone.alerta,
                  tamanho: 52,
                  tamanhoIcone: 26,
                  fundo: Cores.danger,
                  cor: Colors.white),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: Text('Não consegui entender o sinal',
                          style: Texto.bric(21, 26, cor: corTexto)),
                    ),
                    Text('Vamos tentar de novo com estas dicas:',
                        style: Texto.fig(14, 20,
                            peso: FontWeight.w600,
                            cor: escuro ? Cores.branco(.8) : Cores.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: escuro ? Cores.branco(.09) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: escuro ? null : Border.all(color: Cores.line, width: 1.5),
            ),
            child: Column(
              children: [
                _dica(Icone.mao, 'Deixe as duas mãos dentro da moldura', escuro),
                const SizedBox(height: 10),
                _dica(Icone.sol, 'Procure um local bem iluminado', escuro),
                const SizedBox(height: 10),
                _dica(Icone.velocidade,
                    'Peça para sinalizar um pouco mais devagar', escuro),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Botao('Tentar de novo',
              tipo: TipoBotao.amarelo,
              icone: Icone.repetir,
              vibrar: true,
              onPressed: _lerSinal),
        ];

      case Estado.letraReconhecida:
        return [
          _Abas(modo: _modo, ativo: true, escuro: escuro, onTroca: _trocarModo),
          const SizedBox(height: 16),
          Row(
            children: [
              _QuadradoLetra(
                  key: ValueKey(_palavra.length), letra: _letra ?? ''),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ChipStatus('Letra reconhecida',
                        papel: Papel.seguro, icone: Icone.check),
                    const SizedBox(height: 6),
                    Text(
                        (_letra ?? '').length == 1
                            ? 'Vogal $_letra'
                            : 'Sinal $_letra',
                        style: Texto.bric(24, 28, cor: corTexto)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _palavraAteAgora(escuro: escuro, comApagar: true),
          const SizedBox(height: 18),
          Botao('Ler próxima letra',
              tipo: TipoBotao.amarelo,
              icone: Icone.letra,
              vibrar: true,
              onPressed: _servidor == Servidor.pronto ? _lerSinal : null),
          const SizedBox(height: 6),
          // Sobre o painel escuro o botão fantasma fica branco
          if (escuro)
            _BotaoTextoBranco('Limpar palavra', _limparPalavra)
          else
            Botao('Limpar palavra',
                tipo: TipoBotao.fantasma,
                altura: 46,
                onPressed: _limparPalavra),
        ];

      case Estado.reconhecido:
        return const [];
    }
  }

  Widget _dica(Icone icone, String texto, bool escuro) => Row(
        children: [
          QuadradoIcone(
            icone: icone,
            tamanho: 36,
            tamanhoIcone: 20,
            fundo: escuro
                ? Cores.capture.withValues(alpha: .2)
                : Cores.captureSoft,
            cor: escuro ? Cores.capture : Cores.captureSoftText,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(texto,
                style: Texto.fig(15, 20,
                    peso: FontWeight.w700,
                    cor: escuro ? Colors.white : Cores.text)),
          ),
        ],
      );

  Widget _palavraAteAgora({required bool escuro, required bool comApagar}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PALAVRA ATÉ AGORA',
            style: Texto.fig(12, 16,
                peso: FontWeight.w800,
                cor: escuro ? Cores.branco(.75) : Cores.textMuted)
                .copyWith(letterSpacing: .72)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Semantics(
                label: 'Palavra até agora: ${_palavra.join()}',
                excludeSemantics: true,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var i = 0; i < _palavra.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _ChipLetra(
                            letra: _palavra[i],
                            ultima: i == _palavra.length - 1,
                            escuro: escuro,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (comApagar)
              Semantics(
                button: true,
                label: 'Apagar última letra',
                excludeSemantics: true,
                child: Material(
                  color: escuro ? Cores.branco(.14) : Cores.ice,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _palavra.isEmpty ? null : _apagarLetra,
                    child: SizedBox(
                      height: 48,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Center(
                          child: Text('Apagar',
                              style: Texto.fig(14, 18,
                                  peso: FontWeight.w800,
                                  cor: escuro ? Colors.white : Cores.brand)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ----- Sheet claro com a frase e as respostas (11) -----
  Widget _sheetRespostas(double alturaTela) {
    final seguro = MediaQuery.paddingOf(context);
    return Container(
      constraints: BoxConstraints(
          maxHeight: (alturaTela * 620 / 844).clamp(420, alturaTela - 100)),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 22 + seguro.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(Raios.painel)),
        boxShadow: Sombras.painelClaro,
      ),
      child: _TweenEntrada(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Alca(clara: true),
            Flexible(child: _listaRespostas(tablet: false)),
            const SizedBox(height: 8),
            _botaoLerDeNovo(),
          ],
        ),
      ),
    );
  }

  Widget _listaRespostas({required bool tablet}) {
    final frase = _frase;
    if (frase == null) return const SizedBox.shrink();
    final c = _confianca;
    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      children: [
        CartaoFrase(
          frase: frase.texto,
          confirmar: c != null && c >= .55 && c < .75,
          foco: _focoFrase,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 10),
          child: Text('RESPONDER EM LIBRAS',
              style: Texto.fig(13, 18,
                      peso: FontWeight.w800, cor: Cores.textMuted)
                  .copyWith(letterSpacing: .78)),
        ),
        for (var i = 0; i < frase.respostas.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CartaoResposta(
              texto: frase.respostas[i].texto,
              indice: i,
              foco: _focoResposta(i),
              onTap: () =>
                  _escolherResposta(frase.respostas[i], i, tablet: tablet),
            ),
          ),
      ],
    );
  }

  Widget _botaoLerDeNovo() => Botao(
        'Não é essa frase? Ler de novo',
        tipo: TipoBotao.fantasma,
        icone: Icone.repetir,
        altura: 52,
        onPressed: _servidor == Servidor.pronto ? _lerSinal : null,
      );

  // ----- Conversa no celular (13) -----
  Widget _layoutConversa() {
    final seguro = MediaQuery.paddingOf(context);
    return ColoredBox(
      color: Cores.bg,
      child: Column(
        children: [
          SizedBox(
            height: seguro.top + 50 + 130 + 12,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: seguro.top + 64,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(36)),
                    child: Stack(
                      children: [
                        const Positioned.fill(
                            child: FundoMarca(circulos: false)),
                        Padding(
                          padding:
                              EdgeInsets.fromLTRB(16, seguro.top + 4, 16, 0),
                          child: _barraTopo(),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: seguro.top + 50,
                  height: 130,
                  child: _cameraPequena(),
                ),
              ],
            ),
          ),
          Expanded(child: _listaBaloes(tablet: false)),
          Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 30 + seguro.bottom),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                    color: Color(0x24052B7C),
                    blurRadius: 30,
                    offset: Offset(0, -10))
              ],
            ),
            child: _acoesConversa(),
          ),
        ],
      ),
    );
  }

  Widget _cameraPequena() {
    final offline = _servidor == Servidor.offline;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
              color: Color(0x4D020F33), blurRadius: 32, offset: Offset(0, 16))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _camera(),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: MolduraCamera(cor: Colors.white, canto: 36),
          ),
          Positioned(
            left: 10,
            bottom: 10,
            child: PilulaVidro(
              fundo: Cores.branco(.2),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: offline ? Cores.danger : Cores.success,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(offline ? 'Sem conexão' : 'Câmera pronta',
                      style: Texto.fig(12, 16,
                          peso: FontWeight.w800, cor: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _listaBaloes({required bool tablet}) {
    final msgs = _sessao.mensagens;
    final ultimaResposta = msgs.lastIndexWhere((m) => !m.surda);
    return ListView.separated(
      reverse: true,
      padding: EdgeInsets.fromLTRB(tablet ? 0 : 20, 12, tablet ? 0 : 20, 12),
      itemCount: msgs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, i) {
        final idx = msgs.length - 1 - i;
        final m = msgs[idx];
        return Balao(
          surda: m.surda,
          texto: m.texto,
          verDeNovo: !m.surda && idx == ultimaResposta
              ? () => _verDeNovo(m, tablet: tablet)
              : null,
        );
      },
    );
  }

  Widget _acoesConversa() {
    final online = _servidor == Servidor.pronto;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_servidor == Servidor.offline) ...[
          const BannerAviso(
            titulo: 'Sem conexão com a internet',
            texto: 'O reconhecimento de sinais precisa de internet.',
          ),
          const SizedBox(height: 10),
        ],
        Botao('Ler próximo sinal',
            tipo: TipoBotao.amarelo,
            icone: Icone.scan,
            vibrar: true,
            onPressed: online && _cameraPronta ? _lerSinal : null),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Botao('Outra resposta',
                  tipo: TipoBotao.secundario,
                  altura: 48,
                  tamanhoFonte: 15,
                  onPressed: _outraResposta),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Botao('Encerrar',
                  tipo: TipoBotao.perigoSuave,
                  altura: 48,
                  tamanhoFonte: 15,
                  onPressed: _encerrar),
            ),
          ],
        ),
      ],
    );
  }

  // ----- Tablet em paisagem (21, 22) -----
  Widget _layoutTablet(BoxConstraints c) {
    final seguro = MediaQuery.paddingOf(context);
    final larguraCamera = c.maxWidth - 384;
    final vogais = _modo == Modo.vogais;
    final lateral = larguraCamera * (vogais ? .2 : .14);
    return Row(
      children: [
        SizedBox(
          width: larguraCamera,
          child: Stack(
            children: [
              Positioned.fill(child: _camera()),
              Positioned(
                left: lateral,
                right: lateral,
                top: seguro.top + 130,
                bottom: c.maxHeight * .27,
                child: _sobreposicoesMoldura(),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(24, seguro.top + 28, 24, 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Cores.noite(.75), Cores.noite(0)],
                    ),
                  ),
                  child: _barraTopo(grande: true),
                ),
              ),
              if (_servidor == Servidor.offline)
                Positioned(
                  left: 24,
                  right: 24,
                  top: seguro.top + 98,
                  child: const BannerAviso(
                    titulo: 'Sem conexão com a internet',
                    texto:
                        'O reconhecimento de sinais precisa de internet. Conecte-se para continuar.',
                  ),
                )
              else if (_estado == Estado.lendo)
                Positioned(
                    left: 24, top: seguro.top + 100, child: _pilulaLendo())
              else
                Positioned(
                  left: 0,
                  right: 0,
                  top: seguro.top + 98,
                  child: Center(child: _pilulaTopo()),
                ),
              if (_estado == Estado.contagem)
                Positioned.fill(child: Center(child: _contagemCentro())),
              if (_estado == Estado.pronto || _estado == Estado.conversa)
                Positioned(right: 24, bottom: 24, child: _botaoAlternar()),
            ],
          ),
        ),
        Container(
          width: 384,
          padding: EdgeInsets.fromLTRB(24, seguro.top + 28, 24, 28 + seguro.bottom),
          decoration: const BoxDecoration(
            color: Cores.bg,
            boxShadow: [
              BoxShadow(
                  color: Color(0x4D020F33),
                  blurRadius: 36,
                  offset: Offset(-14, 0))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text('Conversa',
                    style: Texto.bric(26, 32, espacamento: -.01)),
              ),
              const SizedBox(height: 16),
              Expanded(child: _meioPainelTablet()),
              const SizedBox(height: 16),
              ..._rodapePainelTablet(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _meioPainelTablet() {
    if (_estado == Estado.reconhecido) {
      return _listaRespostas(tablet: true);
    }
    if (_estado == Estado.naoReconhecido ||
        _estado == Estado.letraReconhecida) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _conteudoPainel(escuro: false)
              .where((w) => w is! Botao && w is! _Abas)
              .toList(),
        ),
      );
    }
    if (_modo == Modo.frases && !_sessao.vazia) {
      return _listaBaloes(tablet: true);
    }
    if (_modo == Modo.vogais) {
      return _vazioTablet('Nenhuma letra ainda',
          'Toque em Ler letra. A letra e a palavra aparecem aqui.');
    }
    return _vazioTablet('Nenhuma frase ainda',
        'Toque em Ler sinal. A frase e as respostas aparecem aqui.');
  }

  Widget _vazioTablet(String titulo, String texto) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                children: [
                  Container(
                      decoration: const BoxDecoration(
                          color: Cores.ice, shape: BoxShape.circle)),
                  Positioned(
                    left: 24,
                    top: 24,
                    child: Transform.rotate(
                      angle: -0.14,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: Gradientes.primario,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Center(
                            child: Ico(Icone.mensagem,
                                tamanho: 34, cor: Colors.white)),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 4,
                    top: 6,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                          color: Cores.capture, shape: BoxShape.circle),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(titulo, style: Texto.bric(22, 28)),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Text(texto,
                  textAlign: TextAlign.center,
                  style: Texto.fig(15, 22, cor: Cores.textMuted)),
            ),
          ],
        ),
      );

  List<Widget> _rodapePainelTablet() {
    switch (_estado) {
      case Estado.reconhecido:
        return [_botaoLerDeNovo()];
      case Estado.naoReconhecido:
        return _conteudoPainel(escuro: false).whereType<Botao>().toList();
      case Estado.letraReconhecida:
        return [
          _Abas(modo: _modo, ativo: true, escuro: false, onTroca: _trocarModo),
          const SizedBox(height: 14),
          ..._conteudoPainel(escuro: false).whereType<Botao>(),
        ];
      case Estado.conversa:
        if (_modo == Modo.frases) {
          return [
            _Abas(
                modo: _modo, ativo: true, escuro: false, onTroca: _trocarModo),
            const SizedBox(height: 14),
            _acoesConversa(),
          ];
        }
        return _conteudoPainel(escuro: false);
      default:
        return _conteudoPainel(escuro: false);
    }
  }
}

// Respostas cadastradas: encontra a Resposta de uma mensagem do histórico
Resposta? respostaDaMensagem(Mensagem m) {
  final frase = fraseDoId(m.fraseId ?? '');
  if (frase == null) return null;
  for (final r in frase.respostas) {
    if (r.texto == m.texto) return r;
  }
  return null;
}

// Abas Frases / Vogais (escuro sobre o painel azul; claro no tablet)
class _Abas extends StatelessWidget {
  final Modo modo;
  final bool ativo;
  final bool escuro;
  final ValueChanged<Modo> onTroca;
  const _Abas({
    required this.modo,
    required this.ativo,
    required this.escuro,
    required this.onTroca,
  });

  @override
  Widget build(BuildContext context) {
    Widget aba(Modo m, String rotulo, Icone icone) {
      final sel = m == modo;
      final Color corTexto = sel
          ? (escuro ? Cores.brand : Colors.white)
          : (escuro ? Cores.branco(.88) : Cores.brand);
      return Expanded(
        child: Semantics(
          button: true,
          selected: sel,
          enabled: ativo,
          label: rotulo,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: ativo ? () => onTroca(m) : null,
            child: AnimatedContainer(
              duration: Movimento.pressionar,
              height: 44,
              decoration: BoxDecoration(
                color: sel && escuro ? Colors.white : Colors.transparent,
                gradient: sel && !escuro ? Gradientes.primario : null,
                borderRadius: BorderRadius.circular(15),
                boxShadow: sel
                    ? [
                        BoxShadow(
                          color: escuro
                              ? const Color(0x40020F33)
                              : const Color(0x4D2455E8),
                          blurRadius: escuro ? 12 : 14,
                          offset: Offset(0, escuro ? 4 : 6),
                        )
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Ico(icone, tamanho: 18, cor: corTexto),
                  const SizedBox(width: 8),
                  Text(rotulo,
                      style: Texto.fig(15, 15,
                          peso: FontWeight.w800, cor: corTexto)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Opacity(
      opacity: ativo ? 1 : .55,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: escuro ? Cores.branco(.12) : Cores.ice,
          borderRadius: BorderRadius.circular(19),
        ),
        child: Row(
          children: [
            aba(Modo.frases, 'Frases', Icone.mensagem),
            const SizedBox(width: 4),
            aba(Modo.vogais, 'Vogais', Icone.letra),
          ],
        ),
      ),
    );
  }
}

// Quadrado amarelo da letra: entra com escala 0,7 → 1 e giro de −4°
class _QuadradoLetra extends StatelessWidget {
  final String letra;
  const _QuadradoLetra({super.key, required this.letra});

  @override
  Widget build(BuildContext context) {
    final reduzido = Movimento.reduzido(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduzido ? 1 : 0, end: 1),
      duration: Movimento.letra,
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Transform.rotate(
        angle: -0.07 * t,
        child: Transform.scale(scale: .7 + .3 * t, child: child),
      ),
      child: Semantics(
        label: 'Letra reconhecida: $letra',
        excludeSemantics: true,
        child: Container(
          width: 104,
          height: 104,
          decoration: BoxDecoration(
            color: Cores.capture,
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [
              BoxShadow(color: Cores.captureEdge, offset: Offset(0, 6))
            ],
          ),
          child: Center(
            child: FittedBox(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(letra,
                    style: Texto.bric(72, 72, cor: Cores.brandDark)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Chip de letra da palavra (44×52); a última fica amarela e faz "pop"
class _ChipLetra extends StatelessWidget {
  final String letra;
  final bool ultima;
  final bool escuro;
  const _ChipLetra(
      {required this.letra, required this.ultima, required this.escuro});

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      constraints: const BoxConstraints(minWidth: 46),
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: ultima
            ? Cores.capture
            : (escuro ? Cores.branco(.16) : Cores.ice),
        borderRadius: BorderRadius.circular(15),
        boxShadow: ultima
            ? const [BoxShadow(color: Cores.captureEdge, offset: Offset(0, 4))]
            : null,
      ),
      child: Center(
        child: Text(letra,
            style: Texto.bric(26, 30,
                cor: ultima
                    ? Cores.brandDark
                    : (escuro ? Colors.white : Cores.brand))),
      ),
    );
    if (!ultima || Movimento.reduzido(context)) return chip;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: .85, end: 1),
      duration: Movimento.chip,
      curve: Curves.easeOutBack,
      builder: (_, s, child) => Transform.scale(scale: s, child: child),
      child: chip,
    );
  }
}

class _BotaoTextoBranco extends StatelessWidget {
  final String rotulo;
  final VoidCallback onPressed;
  const _BotaoTextoBranco(this.rotulo, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Raios.botao)),
        ),
        onPressed: onPressed,
        child: Text(rotulo, style: Texto.button.copyWith(color: Colors.white)),
      ),
    );
  }
}

// Sheet sobe da base em 280 ms
class _TweenEntrada extends StatelessWidget {
  final Widget child;
  const _TweenEntrada({required this.child});

  @override
  Widget build(BuildContext context) {
    if (Movimento.reduzido(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Movimento.sheet,
      curve: Movimento.curvaSheet,
      builder: (_, t, c) => Transform.translate(
        offset: Offset(0, 60 * (1 - t)),
        child: Opacity(opacity: t, child: c),
      ),
      child: child,
    );
  }
}
