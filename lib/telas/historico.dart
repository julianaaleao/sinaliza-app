// 16 · Histórico, 28 · Histórico vazio e 29 · Apagar todo o histórico
import 'package:flutter/material.dart';

import '../servicos/conversas.dart';
import '../theme/tokens.dart';
import '../ui/botoes.dart';
import '../ui/componentes.dart';
import '../ui/icones.dart';
import '../ui/sobreposicoes.dart';
import 'rotas.dart';

String doisDigitos(int n) => n.toString().padLeft(2, '0');
String hora(DateTime d) => '${doisDigitos(d.hour)}:${doisDigitos(d.minute)}';

const _meses = [
  'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', 'julho',
  'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
];

// "Hoje", "Ontem" ou a data por extenso
String dia(DateTime d) {
  final hoje = DateTime.now();
  final a = DateTime(hoje.year, hoje.month, hoje.day);
  final b = DateTime(d.year, d.month, d.day);
  final diff = a.difference(b).inDays;
  if (diff == 0) return 'Hoje';
  if (diff == 1) return 'Ontem';
  final ano = d.year == hoje.year ? '' : ' de ${d.year}';
  return '${d.day} de ${_meses[d.month - 1]}$ano';
}

// Apagar todo o histórico (diálogo 29). Devolve true se apagou.
Future<bool> apagarHistorico(BuildContext context, int quantidade) async {
  final texto = quantidade == 1
      ? 'A conversa salva será removida e não poderá ser recuperada.'
      : quantidade > 1
          ? 'As $quantidade conversas salvas serão removidas e não poderão ser recuperadas.'
          : 'As conversas salvas serão removidas e não poderão ser recuperadas.';
  final ok = await confirmarPerigo(
    context,
    titulo: 'Apagar todo o histórico?',
    texto: texto,
    acao: 'Apagar',
  );
  if (!ok) return false;
  try {
    await Conversas.apagarTudo();
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Não foi possível apagar. Tente de novo.')));
    }
    return false;
  }
}

class HistoricoPage extends StatelessWidget {
  const HistoricoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Conversa>>(
      stream: Conversas.doUsuario(),
      builder: (context, snap) {
        final lista = snap.data ?? const <Conversa>[];
        final carregando =
            snap.connectionState == ConnectionState.waiting && !snap.hasData;
        final vazio = !carregando && !snap.hasError && lista.isEmpty;

        return Scaffold(
          backgroundColor: Cores.bg,
          appBar: BarraPagina(
            titulo: 'Histórico',
            subtitulo: lista.isEmpty
                ? null
                : lista.length == 1
                    ? '1 conversa'
                    : '${lista.length} conversas',
            acao: lista.isEmpty
                ? null
                : _BotaoLimpar(
                    onPressed: () => apagarHistorico(context, lista.length)),
          ),
          body: snap.hasError
              ? _erro()
              : carregando
                  ? const Center(
                      child: CircularProgressIndicator(color: Cores.action))
                  : vazio
                      ? const HistoricoVazio()
                      : _lista(context, lista),
        );
      },
    );
  }

  Widget _erro() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Não foi possível carregar o histórico. Confira a internet e tente de novo.',
            textAlign: TextAlign.center,
            style: Texto.fig(16, 24, cor: Cores.textMuted),
          ),
        ),
      );

  Widget _lista(BuildContext context, List<Conversa> lista) {
    final itens = <Widget>[];
    String? grupo;
    var i = 0;
    for (final c in lista) {
      final g = dia(c.inicio);
      if (g != grupo) {
        grupo = g;
        itens.add(_TituloGrupo(g));
      }
      itens.add(_ItemConversa(conversa: c, indice: i++));
    }
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 24 + MediaQuery.paddingOf(context).bottom),
      itemCount: itens.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => itens[i],
    );
  }
}

class _BotaoLimpar extends StatelessWidget {
  final VoidCallback onPressed;
  const _BotaoLimpar({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Cores.dangerSoft,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              widthFactor: 1,
              child: Text('Limpar',
                  style: Texto.fig(14, 18,
                      peso: FontWeight.w800, cor: Cores.dangerSoftText)),
            ),
          ),
        ),
      ),
    );
  }
}

class _TituloGrupo extends StatelessWidget {
  final String texto;
  const _TituloGrupo(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Semantics(
        header: true,
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  color: Cores.capture, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(texto, style: Texto.bric(14, 18, cor: Cores.brand)),
          ],
        ),
      ),
    );
  }
}

class _ItemConversa extends StatelessWidget {
  final Conversa conversa;
  final int indice;
  const _ItemConversa({required this.conversa, required this.indice});

  @override
  Widget build(BuildContext context) {
    final resposta = conversa.primeiraResposta;
    return Semantics(
      button: true,
      label: '${conversa.primeiraFrase}. '
          '${resposta.isEmpty ? '' : 'Você: $resposta. '}'
          '${hora(conversa.inicio)}',
      excludeSemantics: true,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Raios.opcao),
          side: const BorderSide(color: Cores.line, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(Raios.opcao),
          onTap: () => Navigator.pushNamed(context, Rotas.historicoDetalhe,
              arguments: conversa.id),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 78),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  QuadradoIcone.papel(
                      Icone.mensagem, papelDecorativo(indice),
                      tamanho: 48),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(conversa.primeiraFrase,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Texto.fig(17, 22, peso: FontWeight.w800)),
                        if (resposta.isNotEmpty)
                          Text('Você: $resposta',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Texto.fig(14, 20, cor: Cores.textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(hora(conversa.inicio),
                          style: Texto.fig(12, 16,
                              peso: FontWeight.w700, cor: Cores.textMuted)),
                      const SizedBox(height: 2),
                      const Ico(Icone.seta, tamanho: 20, cor: Cores.action),
                    ],
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

// 28 · Histórico vazio
class HistoricoVazio extends StatelessWidget {
  const HistoricoVazio({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(36, 80, 36, 24),
            child: Column(
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: Stack(
                    children: [
                      Container(
                          decoration: const BoxDecoration(
                              color: Cores.ice, shape: BoxShape.circle)),
                      Positioned(
                        left: 30,
                        top: 30,
                        child: Transform.rotate(
                          angle: -0.14,
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              gradient: Gradientes.primario,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: const [
                                BoxShadow(
                                    color: Color(0x592455E8),
                                    blurRadius: 28,
                                    offset: Offset(0, 14))
                              ],
                            ),
                            child: const Center(
                                child: Ico(Icone.mensagem,
                                    tamanho: 42, cor: Colors.white)),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 6,
                        top: 10,
                        child: Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                                color: Cores.capture,
                                shape: BoxShape.circle)),
                      ),
                      Positioned(
                        left: 8,
                        bottom: 18,
                        child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                                color: Cores.success,
                                shape: BoxShape.circle)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('Nenhuma conversa ainda',
                    textAlign: TextAlign.center,
                    style: Texto.bric(28, 34, espacamento: -.02)),
                const SizedBox(height: 14),
                Text('As conversas que você encerrar aparecem aqui.',
                    textAlign: TextAlign.center,
                    style: Texto.fig(16, 24, cor: Cores.textMuted)),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
              24, 12, 24, 32 + MediaQuery.paddingOf(context).bottom),
          child: Botao(
            'Começar uma conversa',
            icone: Icone.scan,
            onPressed: () => Navigator.popUntil(
                context, (r) => r.settings.name == Rotas.home || r.isFirst),
          ),
        ),
      ],
    );
  }
}
