// Botões do design (página Componentes, seção 1).
// Amarelo é exclusivo da ação de ler sinal; azul degradê é a ação
// principal das outras telas. Raio 20, altura 48 a 60.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';
import 'icones.dart';

enum TipoBotao {
  amarelo,
  primario,
  secundario,
  contorno,
  fantasma,
  vidro,
  perigoSolido,
  perigoSuave,
  claro,
}

class Botao extends StatefulWidget {
  final String rotulo;
  final VoidCallback? onPressed;
  final TipoBotao tipo;
  final Icone? icone;
  final double? altura;
  final double tamanhoFonte;
  final bool carregando;
  // Desativado sobre o painel escuro usa branco 12% / 60%
  final bool sobreEscuro;
  final bool vibrar;
  final FocusNode? focusNode;
  final bool autofocus;

  const Botao(
    this.rotulo, {
    super.key,
    required this.onPressed,
    this.tipo = TipoBotao.primario,
    this.icone,
    this.altura,
    this.tamanhoFonte = 17,
    this.carregando = false,
    this.sobreEscuro = false,
    this.vibrar = false,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<Botao> createState() => _BotaoState();
}

class _BotaoState extends State<Botao> {
  bool _pressionado = false;
  bool _foco = false;

  bool get _ativo => widget.onPressed != null && !widget.carregando;

  double get _altura =>
      widget.altura ?? (widget.tipo == TipoBotao.amarelo ? 60 : 56);

  ({Color? fundo, Gradient? grad, Color texto, List<BoxShadow> sombras, Border? borda})
      _estilo() {
    final desativado = widget.onPressed == null;
    if (desativado) {
      return widget.sobreEscuro
          ? (
              fundo: Cores.branco(.12),
              grad: null,
              texto: Cores.branco(.6),
              sombras: const [],
              borda: null
            )
          : (
              fundo: Cores.disabledBg,
              grad: null,
              texto: Cores.disabledText,
              sombras: const [],
              borda: null
            );
    }
    switch (widget.tipo) {
      case TipoBotao.amarelo:
        return (
          fundo: Cores.capture,
          grad: null,
          texto: Cores.brandDark,
          sombras: const [
            BoxShadow(color: Cores.captureEdge, offset: Offset(0, 5))
          ],
          borda: null
        );
      case TipoBotao.primario:
        return (
          fundo: null,
          grad: Gradientes.primario,
          texto: Colors.white,
          sombras: Sombras.botaoPrimario,
          borda: null
        );
      case TipoBotao.secundario:
        return (
          fundo: Cores.ice,
          grad: null,
          texto: Cores.brand,
          sombras: const [],
          borda: null
        );
      case TipoBotao.contorno:
        return (
          fundo: Colors.white,
          grad: null,
          texto: Cores.brand,
          sombras: const [],
          borda: Border.all(color: Cores.line, width: 2)
        );
      case TipoBotao.fantasma:
        return (
          fundo: Colors.transparent,
          grad: null,
          texto: Cores.action,
          sombras: const [],
          borda: null
        );
      case TipoBotao.vidro:
        return (
          fundo: Cores.branco(.14),
          grad: null,
          texto: Colors.white,
          sombras: const [],
          borda: Border.all(color: Cores.branco(.28), width: 1.5)
        );
      case TipoBotao.perigoSolido:
        return (
          fundo: Cores.dangerSolid,
          grad: null,
          texto: Colors.white,
          sombras: const [
            BoxShadow(
                color: Color(0x47C62F22), blurRadius: 18, offset: Offset(0, 8))
          ],
          borda: null
        );
      case TipoBotao.perigoSuave:
        return (
          fundo: Cores.dangerSoft,
          grad: null,
          texto: Cores.dangerSoftText,
          sombras: const [],
          borda: null
        );
      case TipoBotao.claro:
        return (
          fundo: Colors.white,
          grad: null,
          texto: Cores.brand,
          sombras: const [
            BoxShadow(
                color: Color(0x40020F33), blurRadius: 20, offset: Offset(0, 8))
          ],
          borda: null
        );
    }
  }

  void _toque() {
    if (!_ativo) return;
    if (widget.vibrar) HapticFeedback.lightImpact();
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final e = _estilo();
    final raio = BorderRadius.circular(Raios.botao);
    final reduzido = Movimento.reduzido(context);

    final conteudo = widget.carregando
        ? SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.6, color: e.texto),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icone != null) ...[
                Ico(widget.icone!, tamanho: 22, cor: e.texto),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(
                  widget.rotulo,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Texto.button.copyWith(
                    color: e.texto,
                    fontSize: widget.tamanhoFonte,
                    height: 1,
                  ),
                ),
              ),
            ],
          );

    return Semantics(
      button: true,
      enabled: _ativo,
      label: widget.carregando ? '${widget.rotulo}, carregando' : null,
      child: AnimatedScale(
        scale: _pressionado && !reduzido ? .97 : 1,
        duration: Movimento.pressionar,
        curve: Curves.easeOut,
        child: Container(
          constraints: BoxConstraints(minHeight: _altura),
          decoration: BoxDecoration(
            color: e.fundo,
            gradient: e.grad,
            borderRadius: raio,
            border: _foco
                ? Border.all(color: Cores.action, width: 2)
                : e.borda,
            boxShadow: [
              ...e.sombras,
              if (_foco)
                BoxShadow(
                    color: Cores.action.withValues(alpha: .18),
                    spreadRadius: 4),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              focusNode: widget.focusNode,
              autofocus: widget.autofocus,
              borderRadius: raio,
              onTap: _ativo ? _toque : null,
              onHighlightChanged: (v) => setState(() => _pressionado = v),
              onFocusChange: (v) => setState(() => _foco = v),
              child: Stack(
                children: [
                  // Brilho interno no topo do botão amarelo
                  if (widget.tipo == TipoBotao.amarelo &&
                      widget.onPressed != null)
                    Positioned(
                      top: 0,
                      left: 14,
                      right: 14,
                      height: 2,
                      child: ColoredBox(color: Cores.branco(.45)),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      height: _altura,
                      child: Center(child: conteudo),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Botão quadrado só de ícone (48 px), com rótulo para leitores de tela
class BotaoIcone extends StatelessWidget {
  final Icone icone;
  final String rotulo;
  final VoidCallback? onPressed;
  final Color fundo;
  final Color cor;
  final double tamanho;
  final double raio;
  final List<BoxShadow> sombras;
  final Border? borda;

  const BotaoIcone({
    super.key,
    required this.icone,
    required this.rotulo,
    required this.onPressed,
    this.fundo = const Color(0x29FFFFFF),
    this.cor = Colors.white,
    this.tamanho = 48,
    this.raio = 17,
    this.sombras = const [],
    this.borda,
  });

  // Variante branca das barras de página (Histórico, Ajustes)
  const BotaoIcone.claro({
    super.key,
    required this.icone,
    required this.rotulo,
    required this.onPressed,
  })  : fundo = Colors.white,
        cor = Cores.brand,
        tamanho = 48,
        raio = 17,
        sombras = Sombras.botaoBranco,
        borda = null;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: rotulo,
      child: Tooltip(
        message: rotulo,
        excludeFromSemantics: true,
        child: Container(
          width: tamanho,
          height: tamanho,
          decoration: BoxDecoration(
            color: fundo,
            borderRadius: BorderRadius.circular(raio),
            boxShadow: sombras,
            border: borda,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(raio),
              onTap: onPressed,
              child: Center(child: Ico(icone, tamanho: 24, cor: cor)),
            ),
          ),
        ),
      ),
    );
  }
}
