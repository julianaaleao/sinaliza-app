// Campo de texto do design (Componentes, seção 2): rótulo sempre
// visível, dica curta opcional à direita do rótulo, altura 56, raio 18,
// ícone num quadrado gelo de 38 px (coral no erro).
import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'icones.dart';

class Campo extends StatefulWidget {
  final String rotulo;
  final String? dica;
  final String placeholder;
  final Icone icone;
  final TextEditingController controller;
  final bool senha;
  final TextInputType teclado;
  final Iterable<String>? autofill;
  final TextInputAction acao;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  // Valida ao sair do campo; devolve a mensagem de erro ou null
  final String? Function(String)? validador;
  // Erro vindo de fora (ex.: login recusado)
  final String? erro;
  final FocusNode? focusNode;

  const Campo({
    super.key,
    required this.rotulo,
    required this.placeholder,
    required this.icone,
    required this.controller,
    this.dica,
    this.senha = false,
    this.teclado = TextInputType.text,
    this.autofill,
    this.acao = TextInputAction.next,
    this.onSubmitted,
    this.onChanged,
    this.validador,
    this.erro,
    this.focusNode,
  });

  @override
  State<Campo> createState() => CampoState();
}

class CampoState extends State<Campo> {
  late final FocusNode _foco = widget.focusNode ?? FocusNode();
  bool _oculto = true;
  bool _focado = false;
  String? _erroValidacao;

  @override
  void initState() {
    super.initState();
    _foco.addListener(() {
      setState(() => _focado = _foco.hasFocus);
      if (!_foco.hasFocus) validar();
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _foco.dispose();
    super.dispose();
  }

  // Chamado ao sair do campo e ao enviar o formulário
  bool validar() {
    final v = widget.validador;
    if (v == null) return true;
    final msg = v(widget.controller.text.trim());
    setState(() => _erroValidacao = msg);
    return msg == null;
  }

  @override
  Widget build(BuildContext context) {
    final erro = widget.erro ?? _erroValidacao;
    final temErro = erro != null;

    final borda = temErro
        ? Border.all(color: Cores.dangerSoftText, width: 2)
        : _focado
            ? Border.all(color: Cores.action, width: 2)
            : Border.all(color: Cores.line, width: 1.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: Text(widget.rotulo, style: Texto.label)),
            if (widget.dica != null)
              Text(
                widget.dica!,
                style: Texto.fig(12, 16,
                    peso: FontWeight.w600, cor: Cores.textMuted),
              ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: Movimento.pressionar,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Raios.campo),
            border: borda,
            boxShadow: _focado && !temErro
                ? [
                    BoxShadow(
                        color: Cores.action.withValues(alpha: .18),
                        spreadRadius: 4)
                  ]
                : null,
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: temErro ? Cores.dangerSoft : Cores.ice,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Ico(
                    temErro ? Icone.alerta : widget.icone,
                    tamanho: 20,
                    cor: temErro ? Cores.dangerSoftText : Cores.brand,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _foco,
                  obscureText: widget.senha && _oculto,
                  keyboardType: widget.teclado,
                  autofillHints: widget.autofill,
                  textInputAction: widget.acao,
                  onSubmitted: widget.onSubmitted,
                  onChanged: (v) {
                    if (_erroValidacao != null) {
                      setState(() => _erroValidacao = null);
                    }
                    widget.onChanged?.call(v);
                  },
                  style: Texto.fig(16, 22, peso: FontWeight.w600),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: widget.placeholder,
                    hintStyle: Texto.fig(16, 22,
                        peso: FontWeight.w500, cor: Cores.textMuted),
                    semanticCounterText: '',
                    // Leitor de tela lê o rótulo junto com o campo
                    labelText: null,
                  ),
                ),
              ),
              if (widget.senha)
                Semantics(
                  button: true,
                  label: _oculto ? 'Mostrar senha' : 'Ocultar senha',
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => setState(() => _oculto = !_oculto),
                      child: Center(
                        child: Ico(
                          _oculto ? Icone.olho : Icone.olhoFechado,
                          tamanho: 22,
                          cor: Cores.textMuted,
                        ),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(width: 12),
            ],
          ),
        ),
        if (temErro) ...[
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Row(
              children: [
                const Ico(Icone.alerta,
                    tamanho: 14, cor: Cores.dangerSoftText),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    erro,
                    style: Texto.fig(13, 18,
                        peso: FontWeight.w700, cor: Cores.dangerSoftText),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

String? validarEmail(String v) {
  if (v.isEmpty) return 'Digite o e-mail';
  final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
  return ok ? null : 'Confira o e-mail';
}
