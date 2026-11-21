// Estrutura das telas de acesso: topo azul com a marca, cartão branco
// sobreposto ao topo e rodapé. Rola quando a fonte do sistema cresce.
import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../ui/componentes.dart';

class LayoutAcesso extends StatelessWidget {
  final double alturaTopo;
  final Widget topo;
  final Widget cartao;
  final Widget? rodape;
  final double sobreposicao;
  final bool cantosIguais;
  final Gradient gradiente;

  const LayoutAcesso({
    super.key,
    required this.alturaTopo,
    required this.topo,
    required this.cartao,
    this.rodape,
    this.sobreposicao = 32,
    this.cantosIguais = false,
    this.gradiente = Gradientes.marca,
    this.decoracao = true,
  });

  // Círculos e marca d'água no topo (as telas de permissão não usam)
  final bool decoracao;

  @override
  Widget build(BuildContext context) {
    final seguro = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: Cores.bg,
      body: LayoutBuilder(
        builder: (context, c) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Stack(
                    children: [
                      TopoAzul(
                        altura: alturaTopo,
                        cantosIguais: cantosIguais,
                        gradiente: gradiente,
                        decoracao: decoracao,
                        child: topo,
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(20,
                            topoSeguro(context) + alturaTopo - sobreposicao,
                            20, 0),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: cartao,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (rodape != null)
                    Padding(
                      padding:
                          EdgeInsets.fromLTRB(24, 24, 24, 28 + seguro.bottom),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: rodape,
                        ),
                      ),
                    )
                  else
                    SizedBox(height: 28 + seguro.bottom),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
