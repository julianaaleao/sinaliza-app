// 18 · Perfil e ajustes, 19 · Confirmar saída, 26 · Ajuste de contagem
// e 27 · Ajuste de velocidade. Interruptores salvam na hora.
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../servicos/ajustes.dart';
import '../theme/tokens.dart';
import '../ui/componentes.dart';
import '../ui/icones.dart';
import '../ui/sobreposicoes.dart';
import 'rotas.dart';

class AjustesPage extends StatelessWidget {
  const AjustesPage({super.key});

  String _contagem(int s) => s == 0 ? 'Sem' : '$s s';

  Future<void> _escolherContagem(BuildContext context, Ajustes a) async {
    final v = await escolherOpcao<int>(
      context,
      titulo: 'Contagem regressiva',
      texto: 'Quanto tempo esperar antes de ler o sinal.',
      atual: a.contagemSegundos,
      opcoes: const [
        OpcaoEscolha(0, 'Sem contagem', 'Lê o sinal assim que você tocar'),
        OpcaoEscolha(3, '3 segundos', 'Recomendado'),
        OpcaoEscolha(5, '5 segundos', 'Mais tempo para se preparar'),
      ],
    );
    if (v != null) a.definirContagem(v);
  }

  Future<void> _escolherVelocidade(BuildContext context, Ajustes a) async {
    final v = await escolherOpcao<VelocidadeVideo>(
      context,
      titulo: 'Velocidade do vídeo',
      texto: 'Como os vídeos em LIBRAS começam a tocar.',
      atual: a.velocidade,
      opcoes: const [
        OpcaoEscolha(VelocidadeVideo.normal, 'Normal',
            'Velocidade natural do intérprete'),
        OpcaoEscolha(
            VelocidadeVideo.lenta, 'Lenta', '0,5×: mais fácil de acompanhar'),
      ],
    );
    if (v != null) a.definirVelocidade(v);
  }

  Future<void> _sair(BuildContext context) async {
    final ok = await confirmarPerigo(
      context,
      titulo: 'Sair da conta?',
      texto: 'Você precisará entrar de novo para usar o Sinaliza. '
          'Seu histórico continua salvo na sua conta.',
      acao: 'Sair',
      icone: Icone.sair,
    );
    if (!ok) return;
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, Rotas.login, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;
    final nome = (usuario?.displayName ?? '').trim();
    final email = usuario?.email ?? '';

    return Scaffold(
      backgroundColor: Cores.bg,
      appBar: const BarraPagina(titulo: 'Ajustes'),
      body: ListenableBuilder(
        listenable: Ajustes.instancia,
        builder: (context, _) {
          final a = Ajustes.instancia;
          return ListView(
            padding: EdgeInsets.fromLTRB(
                20, 8, 20, 16 + MediaQuery.paddingOf(context).bottom),
            children: [
              _CartaoPerfil(nome: nome, email: email),
              const SizedBox(height: 14),
              BlocoLista(linhas: [
                LinhaLista(
                  icone: Icone.scan,
                  papel: Papel.neutro,
                  titulo: 'Contagem regressiva',
                  subtitulo: 'Tempo antes de ler o sinal',
                  fim: ValorSeta(_contagem(a.contagemSegundos)),
                  onTap: () => _escolherContagem(context, a),
                ),
                LinhaLista(
                  icone: Icone.velocidade,
                  papel: Papel.atencao,
                  titulo: 'Velocidade do vídeo',
                  fim: ValorSeta(a.velocidade == VelocidadeVideo.lenta
                      ? 'Lenta'
                      : 'Normal'),
                  onTap: () => _escolherVelocidade(context, a),
                ),
                LinhaLista(
                  icone: Icone.legenda,
                  papel: Papel.seguro,
                  titulo: 'Legenda no vídeo',
                  fim: Interruptor(
                    rotulo: 'Legenda no vídeo',
                    valor: a.legenda,
                    onChanged: a.definirLegenda,
                  ),
                ),
                LinhaLista(
                  icone: Icone.historico,
                  papel: Papel.neutro,
                  titulo: 'Salvar histórico',
                  subtitulo: 'Guarda as conversas na sua conta',
                  fim: Interruptor(
                    rotulo: 'Salvar histórico',
                    valor: a.salvarHistorico,
                    onChanged: a.definirSalvarHistorico,
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              BlocoLista(linhas: [
                LinhaLista(
                  icone: Icone.ajuda,
                  papel: Papel.atencao,
                  titulo: 'Como funciona',
                  fim: const ValorSeta(),
                  onTap: () =>
                      Navigator.pushNamed(context, Rotas.comoFunciona),
                ),
                LinhaLista(
                  icone: Icone.escudo,
                  papel: Papel.seguro,
                  titulo: 'Privacidade e dados',
                  subtitulo: 'A câmera não grava imagens',
                  fim: const ValorSeta(),
                  onTap: () =>
                      Navigator.pushNamed(context, Rotas.privacidade),
                ),
              ]),
              const SizedBox(height: 14),
              BlocoLista(linhas: [
                LinhaLista(
                  icone: Icone.sair,
                  papel: Papel.perigo,
                  titulo: 'Sair da conta',
                  corTitulo: Cores.dangerSoftText,
                  onTap: () => _sair(context),
                ),
              ]),
              const SizedBox(height: 14),
              Text('Sinaliza · versão 1.0',
                  textAlign: TextAlign.center,
                  style: Texto.fig(12, 16,
                      peso: FontWeight.w600, cor: Cores.textMuted)),
            ],
          );
        },
      ),
    );
  }
}

class _CartaoPerfil extends StatelessWidget {
  final String nome;
  final String email;
  const _CartaoPerfil({required this.nome, required this.email});

  @override
  Widget build(BuildContext context) {
    final base = nome.isNotEmpty ? nome : email;
    final inicial = base.isEmpty ? '?' : base.characters.first.toUpperCase();
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        children: [
          const Positioned.fill(
              child: FundoMarca(circulos: false, marcaDagua: false)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Transform.rotate(
                  angle: -5 * math.pi / 180,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Cores.capture,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(color: Cores.captureEdge, offset: Offset(0, 4))
                      ],
                    ),
                    child: Center(
                      child: ExcludeSemantics(
                        child: Text(inicial,
                            style: Texto.bric(28, 32, cor: Cores.brandDark)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (nome.isNotEmpty)
                        Text(nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Texto.bric(21, 26, cor: Colors.white)),
                      Text(email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Texto.fig(14, 20,
                              peso: FontWeight.w600,
                              cor: Cores.textOnBrand)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
