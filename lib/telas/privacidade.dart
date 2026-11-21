// 25 · Privacidade e dados, em linguagem simples.
// (Termos de uso e política completa entram numa etapa futura.)
import 'package:flutter/material.dart';

import '../servicos/conversas.dart';
import '../theme/tokens.dart';
import '../ui/botoes.dart';
import '../ui/componentes.dart';
import '../ui/icones.dart';
import 'historico.dart';
import 'rotas.dart';

class PrivacidadePage extends StatelessWidget {
  const PrivacidadePage({super.key});

  Future<void> _apagar(BuildContext context) async {
    var quantidade = 0;
    try {
      quantidade = (await Conversas.doUsuario().first).length;
    } catch (_) {}
    if (!context.mounted) return;
    final apagou = await apagarHistorico(context, quantidade);
    if (apagou && context.mounted) {
      // Depois de apagar tudo, mostra o histórico vazio (28)
      Navigator.pushNamed(context, Rotas.historico);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget cartao(Icone i, Papel p, String titulo, String texto) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Raios.blocoAjustes),
            border: Border.all(color: Cores.line, width: 1.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              QuadradoIcone.papel(i, p, tamanho: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo,
                        style: Texto.fig(17, 22, peso: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(texto,
                        style: Texto.fig(14, 21, cor: Cores.textMuted)),
                  ],
                ),
              ),
            ],
          ),
        );

    return TelaClara(
      barra: const BarraPagina(titulo: 'Privacidade e dados'),
      corpo: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        children: [
          cartao(Icone.escudo, Papel.seguro, 'A câmera não grava',
              'As imagens são usadas só para ler o sinal na hora e não são guardadas.'),
          const SizedBox(height: 12),
          cartao(Icone.historico, Papel.neutro, 'O histórico é seu',
              'As conversas ficam salvas na sua conta. Você pode apagar uma ou todas quando quiser.'),
          const SizedBox(height: 12),
          cartao(Icone.usuario, Papel.atencao, 'Dados da conta',
              'Guardamos só seu nome e e-mail, para você entrar no aplicativo.'),
        ],
      ),
      rodape: Botao(
        'Apagar meu histórico',
        tipo: TipoBotao.perigoSuave,
        icone: Icone.lixeira,
        altura: 54,
        onPressed: () => _apagar(context),
      ),
    );
  }
}
