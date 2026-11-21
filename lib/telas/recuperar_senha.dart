// 04 · Recuperar senha e 23 · Link enviado (mesma rota, dois estados)
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../ui/botoes.dart';
import '../ui/campos.dart';
import '../ui/componentes.dart';
import '../ui/icones.dart';
import 'layout_acesso.dart';

class RecuperarSenhaPage extends StatefulWidget {
  final String emailInicial;
  const RecuperarSenhaPage({super.key, this.emailInicial = ''});

  @override
  State<RecuperarSenhaPage> createState() => _RecuperarSenhaPageState();
}

class _RecuperarSenhaPageState extends State<RecuperarSenhaPage> {
  late final _email = TextEditingController(text: widget.emailInicial);
  final _chave = GlobalKey<CampoState>();
  bool _enviando = false;
  bool _enviado = false;
  String? _erro;
  int _espera = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    FocusScope.of(context).unfocus();
    if (!_enviado && !(_chave.currentState?.validar() ?? true)) return;
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _email.text.trim());
    } on FirebaseAuthException catch (e) {
      // Mesma mensagem exista ou não o e-mail (privacidade)
      if (e.code == 'network-request-failed') {
        setState(() {
          _enviando = false;
          _erro = 'Sem conexão com a internet. Conecte-se e tente de novo.';
        });
        return;
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _enviando = false;
      _enviado = true;
      _espera = 30;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _espera--);
      if (_espera <= 0) t.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _enviado ? _telaEnviado() : _telaPedido();
  }

  Widget _telaPedido() {
    return LayoutAcesso(
      alturaTopo: 268 - 44,
      topo: CabecalhoAcesso(
        titulo: 'Esqueceu a senha?',
        apoio: 'Sem problema. Enviamos um link para você criar outra.',
        voltar: () => Navigator.maybePop(context),
        rotuloVoltar: 'Voltar ao login',
      ),
      cartao: CartaoForm(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_erro != null) ...[
              FaixaErro(_erro!),
              const SizedBox(height: 16),
            ],
            Campo(
              key: _chave,
              rotulo: 'E-mail da conta',
              placeholder: 'voce@email.com',
              icone: Icone.email,
              controller: _email,
              teclado: TextInputType.emailAddress,
              autofill: const [AutofillHints.email],
              acao: TextInputAction.send,
              validador: validarEmail,
              onSubmitted: (_) => _enviar(),
            ),
            const SizedBox(height: 16),
            Botao('Enviar link', carregando: _enviando, onPressed: _enviar),
          ],
        ),
      ),
    );
  }

  Widget _telaEnviado() {
    final email = _email.text.trim();
    final seg = _espera.clamp(0, 30);
    return LayoutAcesso(
      alturaTopo: 300 - 44,
      cantosIguais: true,
      topo: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
            child: BotaoIcone(
              icone: Icone.voltar,
              rotulo: 'Voltar',
              fundo: Cores.branco(.18),
              onPressed: () => setState(() => _enviado = false),
            ),
          ),
          Align(
            alignment: const Alignment(0, .35),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.rotate(
                  angle: -0.105,
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: Cores.capture,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(
                            color: Cores.captureEdge, offset: Offset(0, 6))
                      ],
                    ),
                    child: const Center(
                      child: Ico(Icone.emailEnviado,
                          tamanho: 44, cor: Cores.brandDark),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Semantics(
                  liveRegion: true,
                  header: true,
                  child: Text('Verifique seu e-mail',
                      style: Texto.bric(32, 38,
                          cor: Colors.white, espacamento: -.02)),
                ),
              ],
            ),
          ),
        ],
      ),
      cartao: CartaoForm(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text.rich(
              TextSpan(children: [
                const TextSpan(text: 'Se '),
                TextSpan(
                    text: email,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const TextSpan(
                    text: ' tiver cadastro, o link chega em instantes. '
                        'Confira também a caixa de spam.'),
              ]),
              textAlign: TextAlign.center,
              style: Texto.body,
            ),
            const SizedBox(height: 16),
            Botao('Voltar ao login',
                onPressed: () => Navigator.maybePop(context)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Não chegou? ',
                    style: Texto.fig(14, 20,
                        peso: FontWeight.w700, cor: Cores.textMuted)),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  onPressed: seg > 0 || _enviando ? null : _enviar,
                  child: Text(
                    seg > 0
                        ? 'Reenviar em 0:${seg.toString().padLeft(2, '0')}'
                        : 'Reenviar',
                    style: Texto.fig(14, 20,
                        peso: FontWeight.w700, cor: Cores.action),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
