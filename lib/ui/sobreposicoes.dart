// Diálogo de confirmação (só para ações destrutivas) e sheet de escolha
// (contagem e velocidade). Não entram no histórico de navegação.
import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'botoes.dart';
import 'componentes.dart';
import 'icones.dart';

// Ícone grande em quadrado coral, título, texto, Cancelar à esquerda
// (foco inicial) e ação de perigo à direita. Devolve true se confirmou.
Future<bool> confirmarPerigo(
  BuildContext context, {
  required String titulo,
  required String texto,
  required String acao,
  Icone icone = Icone.lixeira,
}) async {
  final r = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cancelar',
    barrierColor: Cores.noite(.62),
    transitionDuration: Movimento.fade,
    pageBuilder: (context, _, __) => SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 18),
                // A cor fica no mesmo Container da sombra para a sombra
                // ficar só por fora do cartão
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: Sombras.dialogo,
                ),
                child: Semantics(
                  scopesRoute: true,
                  namesRoute: true,
                  explicitChildNodes: true,
                  label: titulo,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      QuadradoIcone.papel(icone, Papel.perigo,
                          tamanho: 60, tamanhoIcone: 28),
                      const SizedBox(height: 14),
                      Text(titulo, style: Texto.bric(24, 30, espacamento: -.01)),
                      const SizedBox(height: 8),
                      Text(texto,
                          style: Texto.fig(15, 22, cor: Cores.textMuted)),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Botao('Cancelar',
                                tipo: TipoBotao.secundario,
                                altura: 52,
                                autofocus: true,
                                onPressed: () =>
                                    Navigator.pop(context, false)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Botao(acao,
                                tipo: TipoBotao.perigoSolido,
                                altura: 52,
                                onPressed: () =>
                                    Navigator.pop(context, true)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (context, a, _, child) =>
        FadeTransition(opacity: a, child: child),
  );
  return r ?? false;
}

class OpcaoEscolha<T> {
  final T valor;
  final String titulo;
  final String apoio;
  const OpcaoEscolha(this.valor, this.titulo, this.apoio);
}

// Sheet claro com cartões de opção; a selecionada tem fundo gelo, borda
// cobalto 2 px e rádio preenchido. Tocar numa opção salva e fecha.
Future<T?> escolherOpcao<T>(
  BuildContext context, {
  required String titulo,
  required String texto,
  required List<OpcaoEscolha<T>> opcoes,
  required T atual,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.white,
    barrierColor: Cores.noite(.55),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Raios.painel)),
    ),
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Alca(clara: true),
            Semantics(
                header: true,
                child: Text(titulo, style: Texto.bric(24, 30))),
            const SizedBox(height: 4),
            Text(texto, style: Texto.fig(14, 20, cor: Cores.textMuted)),
            const SizedBox(height: 14),
            for (final o in opcoes) ...[
              _CartaoOpcao(
                titulo: o.titulo,
                apoio: o.apoio,
                selecionado: o.valor == atual,
                onTap: () => Navigator.pop(context, o.valor),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    ),
  );
}

class _CartaoOpcao extends StatelessWidget {
  final String titulo;
  final String apoio;
  final bool selecionado;
  final VoidCallback onTap;
  const _CartaoOpcao({
    required this.titulo,
    required this.apoio,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selecionado,
      button: true,
      child: Material(
        color: selecionado ? Cores.ice : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: selecionado ? Cores.action : Cores.line,
            width: selecionado ? 2 : 1.5,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 68),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selecionado ? Cores.action : Colors.white,
                      border: Border.all(
                        color: selecionado ? Colors.white : Cores.line,
                        width: selecionado ? 5 : 2,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                      boxShadow: selecionado
                          ? const [
                              BoxShadow(color: Cores.action, spreadRadius: 2)
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titulo,
                            style: Texto.fig(17, 22, peso: FontWeight.w800)),
                        Text(apoio,
                            style: Texto.fig(13, 18, cor: Cores.textMuted)),
                      ],
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

// Alça 40×5 dos painéis e sheets
class Alca extends StatelessWidget {
  final bool clara;
  const Alca({super.key, this.clara = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 5,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: clara ? Cores.line : Cores.branco(.32),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}
