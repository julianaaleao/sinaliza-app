// Ícones duotom do design: traço de 2,2 px com pontas arredondadas e
// preenchimento suave (cor do traço a 16%) nas formas fechadas.
// Os caminhos SVG foram copiados dos quadros do canvas.
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum _Estilo { linha, duo, solido }

class Icone {
  final String _caminhos;
  final _Estilo _estilo;
  const Icone._(this._caminhos, [this._estilo = _Estilo.linha]);

  static const voltar = Icone._('<path d="M19 12H5M12 19l-7-7 7-7"/>');
  static const seta = Icone._('<path d="M9 6l6 6-6 6"/>');
  static const fechar = Icone._('<path d="M18 6L6 18M6 6l12 12"/>');
  static const check = Icone._('<path d="M5 12.5l4.5 4.5L19 7.5"/>');
  static const mais = Icone._('<path d="M12 5v14M5 12h14"/>');
  static const scan = Icone._(
      '<path d="M4 8V6a2 2 0 0 1 2-2h2M16 4h2a2 2 0 0 1 2 2v2M20 16v2a2 2 0 0 1-2 2h-2M8 20H6a2 2 0 0 1-2-2v-2"/><circle cx="12" cy="12" r="2.5"/>');
  static const velocidade =
      Icone._('<path d="M12 14l4-4"/><path d="M3.3 17a10 10 0 1 1 17.4 0"/>');
  static const legenda = Icone._(
      '<rect x="3" y="5" width="18" height="14" rx="4"/><path d="M7.5 11h3M13.5 11h3M7.5 15h9"/>',
      _Estilo.duo);
  static const historico = Icone._(
      '<path d="M3 12a9 9 0 1 0 3-6.7L3 8"/><path d="M3 3v5h5"/><path d="M12 7v5l3 2"/>');
  static const repetir =
      Icone._('<path d="M3 12a9 9 0 1 0 3-6.7L3 8"/><path d="M3 3v5h5"/>');
  static const ajuda = Icone._(
      '<circle cx="12" cy="12" r="9"/><path d="M9.5 9.5a2.5 2.5 0 1 1 3.5 2.3c-.7.4-1 .9-1 1.7M12 17h.01"/>',
      _Estilo.duo);
  static const info = Icone._(
      '<circle cx="12" cy="12" r="9"/><path d="M12 16v-4M12 8h.01"/>',
      _Estilo.duo);
  static const escudo = Icone._(
      '<path d="M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z"/><path d="M9 12l2.2 2.2L15.5 10"/>',
      _Estilo.duo);
  static const sair = Icone._(
      '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><path d="M16 17l5-5-5-5"/><path d="M21 12H9"/>');
  static const camera = Icone._(
      '<path d="M4 8.5a2.5 2.5 0 0 1 2.5-2.5H8l1.5-2h5L16 6h1.5A2.5 2.5 0 0 1 20 8.5v9a2.5 2.5 0 0 1-2.5 2.5h-11A2.5 2.5 0 0 1 4 17.5z"/><circle cx="12" cy="13" r="3.5"/>',
      _Estilo.duo);
  static const cameraDesligada = Icone._(
      '<path d="M4 8.5a2.5 2.5 0 0 1 2.5-2.5H8l1.5-2h5L16 6h1.5A2.5 2.5 0 0 1 20 8.5v9a2.5 2.5 0 0 1-2.5 2.5h-11A2.5 2.5 0 0 1 4 17.5z"/><path d="M3 3l18 18"/>',
      _Estilo.duo);
  static const mensagem = Icone._(
      '<path d="M5 4h14a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2h-8l-5 4v-4H5a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2z"/>',
      _Estilo.duo);
  static const video = Icone._(
      '<rect x="3" y="6" width="13" height="12" rx="3.5"/><path d="M16 10.5l5-3v9l-5-3z"/>',
      _Estilo.duo);
  static const usuario = Icone._(
      '<circle cx="12" cy="8" r="4"/><path d="M4 21v-1a6 6 0 0 1 6-6h4a6 6 0 0 1 6 6v1"/>',
      _Estilo.duo);
  static const email = Icone._(
      '<rect x="3" y="5" width="18" height="14" rx="4"/><path d="M3.5 8.5L12 14l8.5-5.5"/>',
      _Estilo.duo);
  static const emailEnviado = Icone._(
      '<rect x="3" y="5" width="18" height="14" rx="4"/><path d="M8 12.5l3 3 5-5.5"/>',
      _Estilo.duo);
  static const cadeado = Icone._(
      '<rect x="5" y="11" width="14" height="10" rx="3.5"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>',
      _Estilo.duo);
  static const olho = Icone._(
      '<path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>');
  static const olhoFechado = Icone._(
      '<path d="M9.9 9.9a3 3 0 1 0 4.2 4.2"/><path d="M10.7 5.1A10.4 10.4 0 0 1 12 5c6 0 10 7 10 7a13 13 0 0 1-1.7 2.7"/><path d="M6.6 6.6A13.5 13.5 0 0 0 2 12s4 7 10 7a9.7 9.7 0 0 0 5.4-1.6"/><path d="M2 2l20 20"/>');
  static const abrirExterno = Icone._(
      '<path d="M14 4h6v6M20 4l-9 9"/><path d="M18 14v4a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4"/>');
  static const mao = Icone._(
      '<path d="M18 11V6a2 2 0 0 0-2-2 2 2 0 0 0-2 2"/><path d="M14 10V4a2 2 0 0 0-2-2 2 2 0 0 0-2 2v2"/><path d="M10 10.5V6a2 2 0 0 0-2-2 2 2 0 0 0-2 2v8"/><path d="M18 8a2 2 0 1 1 4 0v6a8 8 0 0 1-8 8h-2c-2.8 0-4.5-.86-5.99-2.34l-3.6-3.6a2 2 0 0 1 2.83-2.82L7 15"/>');
  static const letra = Icone._('<path d="M5 19L12 4l7 15M8 14h8"/>');
  static const play = Icone._('<path d="M8 4.5l12 7.5-12 7.5z"/>', _Estilo.solido);
  static const lixeira = Icone._(
      '<path d="M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3"/>');
  static const apagar = Icone._(
      '<path d="M20 5H9l-7 7 7 7h11a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2z"/><path d="M18 9l-6 6M12 9l6 6"/>',
      _Estilo.duo);
  static const alternarCamera = Icone._(
      '<path d="M3 12a9 9 0 0 1 15-6.7L21 8"/><path d="M21 3v5h-5"/><path d="M21 12a9 9 0 0 1-15 6.7L3 16"/><path d="M3 21v-5h5"/>');
  static const alerta = Icone._(
      '<path d="M12 3.5l9.5 16.5h-19z"/><path d="M12 10v4.5M12 17.5h.01"/>',
      _Estilo.duo);
  static const sol = Icone._(
      '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/>',
      _Estilo.duo);
  static const semInternet = Icone._(
      '<path d="M2 8.8a15 15 0 0 1 4.2-2.6M22 8.8A15 15 0 0 0 10 5.3"/><path d="M5 12.9a10 10 0 0 1 5-2.7M19 12.9a10 10 0 0 0-2.5-1.8"/><path d="M8.5 16.4a5 5 0 0 1 7 0"/><path d="M12 20h.01"/><path d="M2 2l20 20"/>');

  String svg() {
    final preenchimento = switch (_estilo) {
      _Estilo.linha => 'fill="none"',
      _Estilo.duo => 'fill="currentColor" fill-opacity=".16"',
      _Estilo.solido => 'fill="currentColor"',
    };
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
        '$preenchimento stroke="currentColor" stroke-width="2.2" '
        'stroke-linecap="round" stroke-linejoin="round">$_caminhos</svg>';
  }
}

// Desenha um Icone com a cor herdada do contexto (IconTheme) ou a informada
class Ico extends StatelessWidget {
  final Icone icone;
  final double tamanho;
  final Color? cor;
  const Ico(this.icone, {super.key, this.tamanho = 24, this.cor});

  @override
  Widget build(BuildContext context) {
    final c = cor ?? IconTheme.of(context).color ?? Colors.black;
    return ExcludeSemantics(
      child: SvgPicture.string(
        icone.svg(),
        width: tamanho,
        height: tamanho,
        theme: SvgTheme(currentColor: c),
      ),
    );
  }
}
