// 12 · Vídeo da resposta em LIBRAS (tela cheia para a pessoa surda) e
// 32 · Vídeo não carregou. No tablet abre como modal central de 420 px.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../servicos/ajustes.dart';
import '../theme/tokens.dart';
import '../ui/botoes.dart';
import '../ui/componentes.dart';
import '../ui/icones.dart';
import '../ui/player_gif.dart';

enum ResultadoVideo {
  fechado, // X: volta às respostas para escolher outra
  concluido, // Concluir: grava a troca
  legenda, // Continuar com a legenda (vídeo não carregou): grava a troca
}

// Abre o vídeo e devolve o que a pessoa escolheu
Future<ResultadoVideo> mostrarVideoResposta(
  BuildContext context, {
  required String texto,
  required String gif,
  bool modal = false,
}) async {
  final pagina = VideoRespostaPage(texto: texto, gif: gif, modal: modal);
  final ResultadoVideo? r;
  if (modal) {
    r = await showGeneralDialog<ResultadoVideo>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar vídeo',
      barrierColor: Cores.noite(.62),
      transitionDuration: Movimento.fade,
      pageBuilder: (_, __, ___) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 760),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: pagina,
          ),
        ),
      ),
      transitionBuilder: (_, a, __, child) =>
          FadeTransition(opacity: a, child: child),
    );
  } else {
    r = await Navigator.of(context).push<ResultadoVideo>(PageRouteBuilder(
      opaque: true,
      transitionDuration: Movimento.fade,
      reverseTransitionDuration: Movimento.fade,
      pageBuilder: (_, __, ___) => pagina,
      transitionsBuilder: (_, a, __, child) =>
          FadeTransition(opacity: a, child: child),
    ));
  }
  return r ?? ResultadoVideo.fechado;
}

class VideoRespostaPage extends StatefulWidget {
  final String texto;
  final String gif;
  final bool modal;
  const VideoRespostaPage({
    super.key,
    required this.texto,
    required this.gif,
    this.modal = false,
  });

  @override
  State<VideoRespostaPage> createState() => _VideoRespostaPageState();
}

class _VideoRespostaPageState extends State<VideoRespostaPage> {
  final _controle = ControlePlayerGif();
  late bool _legenda = Ajustes.instancia.legenda;
  int _tentativa = 0;

  @override
  void initState() {
    super.initState();
    _controle.lento = Ajustes.instancia.velocidade == VelocidadeVideo.lenta;
    _controle.addListener(_mudou);
    // Mantém a tela acesa enquanto a pessoa assiste
    WakelockPlus.enable().catchError((_) {});
  }

  EstadoGif? _ultimoEstado;
  void _mudou() {
    if (!mounted) return;
    if (_controle.estado == EstadoGif.erro &&
        _ultimoEstado != EstadoGif.erro) {
      SemanticsService.sendAnnouncement(View.of(context),
          'Não foi possível carregar o vídeo', TextDirection.ltr);
    }
    _ultimoEstado = _controle.estado;
    setState(() {});
  }

  @override
  void dispose() {
    _controle.removeListener(_mudou);
    _controle.dispose();
    WakelockPlus.disable().catchError((_) {});
    super.dispose();
  }

  String _tempo(Duration d) {
    final s = (d.inMilliseconds / 1000).round();
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final erro = _controle.estado == EstadoGif.erro;
    final seguro = widget.modal
        ? const EdgeInsets.fromLTRB(0, 16, 0, 16)
        : MediaQuery.paddingOf(context);

    return Scaffold(
      backgroundColor: Cores.night,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: Gradientes.cenaVideo),
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, seguro.top + 6, 24, seguro.bottom + 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Topo: fechar + pílula
              Row(
                children: [
                  BotaoIcone(
                    icone: Icone.fechar,
                    rotulo: 'Fechar vídeo e voltar às respostas',
                    onPressed: () =>
                        Navigator.pop(context, ResultadoVideo.fechado),
                  ),
                  Expanded(
                    child: Center(
                      child: PilulaVidro(
                        fundo: Cores.branco(.16),
                        child: const Text('Mostre a tela para a pessoa'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 14),
              // Quadro do vídeo
              Expanded(child: _quadroVideo(erro)),
              const SizedBox(height: 18),
              if (_legenda || erro) _textoLegenda(),
              const SizedBox(height: 16),
              if (erro) ...[
                Botao('Tentar de novo',
                    tipo: TipoBotao.amarelo,
                    icone: Icone.repetir,
                    altura: 56,
                    tamanhoFonte: 16,
                    onPressed: () => setState(() => _tentativa++)),
                const SizedBox(height: 16),
                Botao('Continuar com a legenda',
                    tipo: TipoBotao.vidro,
                    onPressed: () =>
                        Navigator.pop(context, ResultadoVideo.legenda)),
              ] else ...[
                _controles(),
                const SizedBox(height: 16),
                Botao('Concluir',
                    tipo: TipoBotao.claro,
                    onPressed: () =>
                        Navigator.pop(context, ResultadoVideo.concluido)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _quadroVideo(bool erro) {
    final total = _controle.duracaoTotal;
    final atual = total * _controle.progresso;
    return Container(
      decoration: BoxDecoration(
        gradient: Gradientes.quadroVideo,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: Cores.branco(.2), width: 3),
        boxShadow: const [
          BoxShadow(
              color: Color(0x66000000), blurRadius: 50, offset: Offset(0, 24))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Semantics(
            label: 'Vídeo em LIBRAS: ${widget.texto}',
            image: true,
            child: AnimatedOpacity(
              opacity: _controle.estado == EstadoGif.carregando ? 0 : 1,
              duration: Movimento.fade,
              child: PlayerGif(
                key: ValueKey('${widget.gif}#$_tentativa'),
                asset: 'assets/respostas/${widget.gif}',
                controle: _controle,
              ),
            ),
          ),
          if (_controle.estado == EstadoGif.carregando)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          if (erro)
            ColoredBox(
              color: Cores.noite(.78),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const QuadradoIcone(
                      icone: Icone.alerta,
                      tamanho: 64,
                      tamanhoIcone: 30,
                      fundo: Cores.danger,
                      cor: Colors.white,
                    ),
                    const SizedBox(height: 14),
                    Text('Não foi possível carregar o vídeo',
                        textAlign: TextAlign.center,
                        style: Texto.bric(22, 28, cor: Colors.white)),
                    const SizedBox(height: 14),
                    Text(
                      'Você pode mostrar a resposta pela legenda ou tentar de novo.',
                      textAlign: TextAlign.center,
                      style: Texto.fig(14, 20,
                          peso: FontWeight.w600, cor: Cores.branco(.8)),
                    ),
                  ],
                ),
              ),
            )
          else
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: ExcludeSemantics(
                child: Row(
                  children: [
                    Text(_tempo(atual),
                        style: Texto.fig(12, 16,
                            peso: FontWeight.w700, cor: Colors.white)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: _controle.progresso,
                          minHeight: 6,
                          color: Cores.capture,
                          backgroundColor: Cores.branco(.28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(_tempo(total),
                        style: Texto.fig(12, 16,
                            peso: FontWeight.w700, cor: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Legenda grande; a última palavra ganha um grifo amarelo
  Widget _textoLegenda() {
    final palavras = widget.texto.split(' ');
    final ultima = palavras.removeLast();
    final estilo = Texto.bric(36, 42, cor: Colors.white, espacamento: -.02);
    return Semantics(
      liveRegion: true,
      child: Text.rich(
        TextSpan(children: [
          if (palavras.isNotEmpty) TextSpan(text: '${palavras.join(' ')} '),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 4,
                  height: 12,
                  child: ColoredBox(
                      color: Cores.capture.withValues(alpha: .55)),
                ),
                Text(ultima, style: estilo),
              ],
            ),
          ),
        ]),
        textAlign: TextAlign.center,
        style: estilo,
      ),
    );
  }

  Widget _controles() {
    Widget controle(String rotulo, Icone icone, bool ativo, VoidCallback onTap,
        {bool alternavel = true}) {
      return Expanded(
        child: Semantics(
          button: true,
          toggled: alternavel ? ativo : null,
          label: rotulo,
          excludeSemantics: true,
          child: Material(
            color: ativo ? Cores.capture : Cores.branco(.14),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onTap,
              child: Container(
                height: 60,
                decoration: ativo
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                              color: Cores.captureEdge, offset: Offset(0, 4))
                        ],
                      )
                    : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Ico(icone,
                        tamanho: 22,
                        cor: ativo ? Cores.brandDark : Colors.white),
                    const SizedBox(height: 4),
                    Text(rotulo,
                        style: Texto.fig(12, 14,
                            peso: FontWeight.w800,
                            cor: ativo ? Cores.brandDark : Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        controle('Repetir', Icone.repetir, false, _controle.repetir,
            alternavel: false),
        const SizedBox(width: 10),
        controle('Lento 0,5×', Icone.velocidade, _controle.lento, () {
          _controle.lento = !_controle.lento;
        }),
        const SizedBox(width: 10),
        controle('Legenda', Icone.legenda, _legenda,
            () => setState(() => _legenda = !_legenda)),
      ],
    );
  }
}
