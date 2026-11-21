// Player dos GIFs de resposta em LIBRAS. Decodifica quadro a quadro (sem
// guardar todos na memória), toca uma vez e para no último quadro.
// Permite repetir e tocar em 0,5×.
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

enum EstadoGif { carregando, tocando, fim, erro }

class ControlePlayerGif extends ChangeNotifier {
  EstadoGif estado = EstadoGif.carregando;
  double progresso = 0; // 0 a 1
  Duration duracaoTotal = Duration.zero;
  bool _lento = false;
  VoidCallback? _reiniciar;

  bool get lento => _lento;
  set lento(bool v) {
    _lento = v;
    notifyListeners();
  }

  void repetir() => _reiniciar?.call();

  void _atualizar(EstadoGif e, double p) {
    estado = e;
    progresso = p;
    notifyListeners();
  }
}

class PlayerGif extends StatefulWidget {
  final String asset;
  final ControlePlayerGif controle;
  const PlayerGif({super.key, required this.asset, required this.controle});

  @override
  State<PlayerGif> createState() => _PlayerGifState();
}

class _PlayerGifState extends State<PlayerGif> {
  static const _padraoQuadro = Duration(milliseconds: 100);

  ui.Codec? _codec;
  ui.Image? _quadro;
  Timer? _timer;
  int _indice = 0;
  int _geracao = 0;
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    widget.controle._reiniciar = _iniciar;
    _iniciar();
  }

  @override
  void didUpdateWidget(PlayerGif old) {
    super.didUpdateWidget(old);
    widget.controle._reiniciar = _iniciar;
    if (old.asset != widget.asset) {
      _bytes = null;
      _iniciar();
    }
  }

  Future<void> _iniciar() async {
    final geracao = ++_geracao;
    _timer?.cancel();
    _codec?.dispose();
    _codec = null;
    _indice = 0;
    widget.controle._atualizar(EstadoGif.carregando, 0);
    try {
      _bytes ??= (await rootBundle.load(widget.asset)).buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(_bytes!);
      if (!mounted || geracao != _geracao) {
        codec.dispose();
        return;
      }
      _codec = codec;
      await _proximo(geracao);
    } catch (e) {
      debugPrint('Erro ao carregar ${widget.asset}: $e');
      if (mounted && geracao == _geracao) {
        widget.controle._atualizar(EstadoGif.erro, 0);
      }
    }
  }

  Future<void> _proximo(int geracao) async {
    final codec = _codec;
    if (codec == null || !mounted || geracao != _geracao) return;
    final frame = await codec.getNextFrame();
    if (!mounted || geracao != _geracao) {
      frame.image.dispose();
      return;
    }
    final total = codec.frameCount;
    var dur = frame.duration;
    if (dur <= Duration.zero) dur = _padraoQuadro;
    if (_indice == 0) {
      widget.controle.duracaoTotal = dur * total;
    }
    final antigo = _quadro;
    setState(() => _quadro = frame.image);
    antigo?.dispose();
    _indice++;

    final acabou = _indice >= total;
    widget.controle._atualizar(
      acabou ? EstadoGif.fim : EstadoGif.tocando,
      total == 0 ? 1 : _indice / total,
    );
    if (acabou) return; // para no último quadro

    final espera = widget.controle.lento ? dur * 2 : dur;
    _timer = Timer(espera, () => _proximo(geracao));
  }

  @override
  void dispose() {
    _geracao++;
    _timer?.cancel();
    _codec?.dispose();
    _quadro?.dispose();
    widget.controle._reiniciar = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _quadro;
    if (q == null) return const SizedBox.expand();
    return RawImage(image: q, fit: BoxFit.contain);
  }
}
