// 05 · Boas-vindas (primeiro acesso) e 24 · Como funciona (por Ajustes)
import 'package:flutter/material.dart';

import '../camera_stub.dart'
    if (dart.library.html) '../camera_web_impl.dart'
    if (dart.library.io) '../camera_android.dart';
import '../servicos/ajustes.dart';
import '../ui/botoes.dart';
import '../ui/componentes.dart';
import '../ui/icones.dart';
import 'layout_acesso.dart';
import 'rotas.dart';

class BoasVindasPage extends StatefulWidget {
  // true = tela 24 (aberta por Ajustes, com seta e botão "Entendi")
  final bool comoFunciona;
  const BoasVindasPage({super.key, this.comoFunciona = false});

  @override
  State<BoasVindasPage> createState() => _BoasVindasPageState();
}

class _BoasVindasPageState extends State<BoasVindasPage> {
  bool _indo = false;

  Future<void> _vamos() async {
    setState(() => _indo = true);
    Ajustes.instancia.marcarPrimeiroAcesso();
    final permitida = await permissaoCamera() == PermissaoCamera.concedida;
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      permitida ? Rotas.home : Rotas.permissaoCamera,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ajuda = widget.comoFunciona;
    return LayoutAcesso(
      alturaTopo: 276 - 44,
      sobreposicao: -24,
      topo: ajuda
          ? CabecalhoAcesso(
              titulo: 'Como funciona',
              apoio: 'Três passos para conversar em LIBRAS.',
              voltar: () => Navigator.maybePop(context),
              tamanhoTitulo: 32,
            )
          : const CabecalhoAcesso(
              logo: true,
              titulo: 'Bem-vindo ao Sinaliza',
              apoio: 'Conversas em LIBRAS, nos dois sentidos.',
              tamanhoTitulo: 32,
            ),
      cartao: const Column(
        children: [
          CartaoPasso(
            numero: 1,
            icone: Icone.camera,
            papel: Papel.neutro,
            titulo: 'Aponte a câmera',
            texto: 'Para a pessoa surda que vai sinalizar.',
          ),
          SizedBox(height: 12),
          CartaoPasso(
            numero: 2,
            icone: Icone.mensagem,
            papel: Papel.atencao,
            titulo: 'Veja a frase',
            texto: 'O Sinaliza mostra o que foi dito e sugere respostas.',
          ),
          SizedBox(height: 12),
          CartaoPasso(
            numero: 3,
            icone: Icone.video,
            papel: Papel.seguro,
            titulo: 'Mostre a resposta',
            texto: 'Toque numa opção e exiba o vídeo em LIBRAS.',
          ),
        ],
      ),
      rodape: ajuda
          ? Botao('Entendi', onPressed: () => Navigator.maybePop(context))
          : Botao('Vamos sinalizar!', carregando: _indo, onPressed: _vamos),
    );
  }
}
