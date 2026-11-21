// 17 · Detalhe da conversa e 30 · Excluir conversa
import 'package:flutter/material.dart';

import '../frases.dart';
import '../servicos/conversas.dart';
import '../theme/tokens.dart';
import '../ui/botoes.dart';
import '../ui/componentes.dart';
import '../ui/icones.dart';
import '../ui/sobreposicoes.dart';
import 'historico.dart';
import 'reconhecimento/reconhecimento.dart' show respostaDaMensagem;
import 'video_resposta.dart';

class HistoricoDetalhePage extends StatelessWidget {
  final String id;
  const HistoricoDetalhePage({super.key, required this.id});

  Future<void> _excluir(BuildContext context, Conversa c) async {
    final quando = dia(c.inicio).toLowerCase();
    final ok = await confirmarPerigo(
      context,
      titulo: 'Excluir esta conversa?',
      texto:
          'A conversa ${quando == 'hoje' || quando == 'ontem' ? 'de $quando' : 'de ${dia(c.inicio)}'} às ${hora(c.inicio)} será removida do histórico.',
      acao: 'Excluir',
    );
    if (!ok || !context.mounted) return;
    try {
      await Conversas.excluir(c.id);
      if (context.mounted) Navigator.pop(context);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Não foi possível excluir. Tente de novo.')));
      }
    }
  }

  Future<void> _verDeNovo(BuildContext context, Mensagem m) async {
    final r = respostaDaMensagem(m);
    if (r == null) return;
    final largura = MediaQuery.sizeOf(context).width;
    await mostrarVideoResposta(context,
        texto: r.texto, gif: proximoGif(r), modal: largura >= 768);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Conversa?>(
      stream: Conversas.porId(id),
      builder: (context, snap) {
        final c = snap.data;
        if (c == null) {
          return Scaffold(
            backgroundColor: Cores.bg,
            appBar: const BarraPagina(titulo: 'Conversa'),
            body: Center(
              child: snap.connectionState == ConnectionState.waiting
                  ? const CircularProgressIndicator(color: Cores.action)
                  : Text('Conversa não encontrada.',
                      style: Texto.fig(16, 24, cor: Cores.textMuted)),
            ),
          );
        }
        final msgs = c.mensagens;
        return Scaffold(
          backgroundColor: Cores.bg,
          appBar: BarraPagina(
            titulo: c.primeiraFrase,
            subtitulo: '${dia(c.inicio)} · ${hora(c.inicio)}',
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  itemCount: msgs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, i) {
                    final m = msgs[i];
                    final temVideo =
                        !m.surda && respostaDaMensagem(m) != null;
                    return Balao(
                      surda: m.surda,
                      texto: m.texto,
                      verDeNovo:
                          temVideo ? () => _verDeNovo(context, m) : null,
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                    24, 12, 24, 32 + MediaQuery.paddingOf(context).bottom),
                child: Botao(
                  'Excluir conversa',
                  tipo: TipoBotao.perigoSuave,
                  icone: Icone.lixeira,
                  onPressed: () => _excluir(context, c),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
