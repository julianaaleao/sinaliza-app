// 06 · Permissão de câmera (explica o motivo antes do pedido do sistema)
// e 31 · Câmera desativada (mesma rota, outro estado)
import 'package:flutter/material.dart';

import '../camera_stub.dart'
    if (dart.library.html) '../camera_web_impl.dart'
    if (dart.library.io) '../camera_android.dart';
import '../theme/tokens.dart';
import '../ui/botoes.dart';
import '../ui/componentes.dart';
import '../ui/icones.dart';
import 'layout_acesso.dart';
import 'rotas.dart';

class PermissaoCameraPage extends StatefulWidget {
  final bool negada;
  const PermissaoCameraPage({super.key, this.negada = false});

  @override
  State<PermissaoCameraPage> createState() => _PermissaoCameraPageState();
}

class _PermissaoCameraPageState extends State<PermissaoCameraPage>
    with WidgetsBindingObserver {
  late bool _negada = widget.negada;
  bool _pedindo = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _verificarJaNegada();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _verificarJaNegada() async {
    if (await permissaoCamera() == PermissaoCamera.negada && mounted) {
      setState(() => _negada = true);
    }
  }

  // Ao voltar dos ajustes do aparelho com a câmera liberada → 07
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _negada) _seLiberadaIr();
  }

  Future<void> _seLiberadaIr() async {
    if (await permissaoCamera() == PermissaoCamera.concedida && mounted) {
      _irParaHome();
    }
  }

  void _irParaHome() => Navigator.pushNamedAndRemoveUntil(
      context, Rotas.home, (_) => false);

  Future<void> _permitir() async {
    setState(() => _pedindo = true);
    final ok = await pedirPermissaoCamera();
    if (!mounted) return;
    setState(() => _pedindo = false);
    if (ok) {
      _irParaHome();
    } else {
      setState(() => _negada = true);
    }
  }

  Future<void> _abrirAjustes() async {
    final ok = await abrirAjustesAparelho();
    // No navegador "abrir ajustes" pede a permissão de novo
    if (ok && mounted) await _seLiberadaIr();
  }

  void _voltar() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, Rotas.boasVindas);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _negada ? _telaNegada() : _telaPedido();
  }

  LayoutAcesso _base({
    required Gradient gradiente,
    required Icone icone,
    required Color corIcone,
    required List<Widget> corpo,
    required Widget rodape,
  }) {
    return LayoutAcesso(
      alturaTopo: 330 - 44,
      sobreposicao: -32,
      gradiente: gradiente,
      decoracao: false,
      topo: OverflowBox(
        maxHeight: 330,
        child: Center(
          child: Transform.translate(
            offset: const Offset(0, -22),
            child: IlustracaoAneis(icone: icone, corIcone: corIcone),
          ),
        ),
      ),
      cartao: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: corpo,
        ),
      ),
      rodape: rodape,
    );
  }

  Widget _telaPedido() {
    return _base(
      gradiente: Gradientes.marca,
      icone: Icone.camera,
      corIcone: Cores.brand,
      corpo: [
        Semantics(
          header: true,
          child: Text('Precisamos da sua câmera',
              style: Texto.bric(30, 36, espacamento: -.02)),
        ),
        const SizedBox(height: 14),
        Text(
          'É com ela que o Sinaliza lê os sinais de LIBRAS e traduz para você.',
          style: Texto.fig(16, 24, cor: Cores.textMuted),
        ),
        const SizedBox(height: 14),
        const _Aviso(
          papel: Papel.seguro,
          icone: Icone.escudo,
          texto: 'As imagens não são gravadas nem guardadas.',
        ),
        const SizedBox(height: 14),
        const _Aviso(
          papel: Papel.atencao,
          icone: Icone.sol,
          texto: 'Funciona melhor em locais bem iluminados.',
        ),
      ],
      rodape: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Botao('Permitir câmera', carregando: _pedindo, onPressed: _permitir),
          const SizedBox(height: 12),
          Botao('Agora não',
              tipo: TipoBotao.fantasma,
              altura: 48,
              onPressed: () => setState(() => _negada = true)),
        ],
      ),
    );
  }

  Widget _telaNegada() {
    Widget passo(int n, String t) => Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Cores.captureSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text('$n',
                      style: Texto.fig(14, 18,
                          peso: FontWeight.w800,
                          cor: Cores.captureSoftText)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child:
                      Text(t, style: Texto.fig(15, 22, peso: FontWeight.w700))),
            ],
          ),
        );

    return _base(
      gradiente: Gradientes.erro,
      icone: Icone.cameraDesligada,
      corIcone: Cores.dangerSoftText,
      corpo: [
        Semantics(
          header: true,
          liveRegion: true,
          child: Text('A câmera está desativada',
              style: Texto.bric(30, 36, espacamento: -.02)),
        ),
        const SizedBox(height: 14),
        Text('Para ler sinais, ative a câmera nos ajustes do aparelho:',
            style: Texto.fig(16, 24, cor: Cores.textMuted)),
        passo(1, 'Abra os ajustes do aparelho'),
        passo(2, 'Toque em Sinaliza'),
        passo(3, 'Ative a Câmera'),
      ],
      rodape: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Botao('Abrir ajustes do aparelho',
              icone: Icone.abrirExterno, onPressed: _abrirAjustes),
          const SizedBox(height: 12),
          Botao('Voltar',
              tipo: TipoBotao.fantasma, altura: 48, onPressed: _voltar),
        ],
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  final Papel papel;
  final Icone icone;
  final String texto;
  const _Aviso({required this.papel, required this.icone, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: papel.fundo,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Ico(icone, tamanho: 22, cor: papel.texto),
          const SizedBox(width: 12),
          Expanded(
            child: Text(texto,
                style: Texto.fig(14, 20,
                    peso: FontWeight.w700, cor: papel.texto)),
          ),
        ],
      ),
    );
  }
}
