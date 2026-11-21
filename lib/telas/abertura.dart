// 00 · Abertura: aparece 1 a 2 s enquanto o app verifica a sessão
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../ui/componentes.dart';
import 'rotas.dart';

class AberturaPage extends StatefulWidget {
  const AberturaPage({super.key});

  @override
  State<AberturaPage> createState() => _AberturaPageState();
}

class _AberturaPageState extends State<AberturaPage> {
  @override
  void initState() {
    super.initState();
    _verificar();
  }

  Future<void> _verificar() async {
    final espera = Future.delayed(const Duration(milliseconds: 1200));
    User? usuario;
    try {
      usuario = await FirebaseAuth.instance
          .authStateChanges()
          .first
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      usuario = FirebaseAuth.instance.currentUser;
    }
    await espera;
    if (!mounted) return;
    if (usuario == null) {
      Navigator.pushReplacementNamed(context, Rotas.login);
    } else {
      await irParaInicio(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.brandDark,
      body: Stack(
        children: [
          const Positioned.fill(child: FundoMarca(marcaDagua: false)),
          const Positioned(
            right: -120,
            top: 240,
            child: MarcaDagua(tamanho: 520, opacidade: .16, graus: -10),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LogoQuadro(tamanho: 132, raio: 42, inclinado: true),
                const SizedBox(height: 20),
                Text('Sinaliza', style: Texto.brand),
                const SizedBox(height: 6),
                Text(
                  'Converse em LIBRAS, sem barreiras.',
                  style: Texto.fig(17, 24,
                      peso: FontWeight.w600, cor: Cores.textOnBrand),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 64 + MediaQuery.paddingOf(context).bottom,
            child: Semantics(
              label: 'Carregando',
              child: const _Pontos(),
            ),
          ),
        ],
      ),
    );
  }
}

// Três pontos de carregamento (amarelo, branco 50%, branco 30%)
class _Pontos extends StatelessWidget {
  const _Pontos();

  @override
  Widget build(BuildContext context) {
    Widget p(Color c) => Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [p(Cores.capture), p(Cores.branco(.5)), p(Cores.branco(.3))],
    );
  }
}
