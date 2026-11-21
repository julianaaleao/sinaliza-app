// Componentes visuais reutilizados pelas telas (página Componentes).
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'botoes.dart';
import 'icones.dart';

const logoPng = 'public/images/sinaliza-logo.png';
const logoBrancaPng = 'public/images/sinaliza-logo-white.png';

// Logo dentro do quadrado branco arredondado (padding ≈ 15%)
class LogoQuadro extends StatelessWidget {
  final double tamanho;
  final double raio;
  final bool inclinado;
  final bool sombra;
  const LogoQuadro({
    super.key,
    this.tamanho = 64,
    double? raio,
    this.inclinado = false,
    this.sombra = true,
  }) : raio = raio ?? tamanho * .33;

  @override
  Widget build(BuildContext context) {
    final quadro = Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(raio),
        boxShadow: sombra ? Sombras.logo : null,
      ),
      padding: EdgeInsets.all(tamanho * .16),
      child: Image.asset(logoPng,
          fit: BoxFit.contain, semanticLabel: 'Sinaliza'),
    );
    return inclinado
        ? Transform.rotate(angle: -6 * math.pi / 180, child: quadro)
        : quadro;
  }
}

// Círculos decorativos dos topos azuis (azul vivo 30%, azul céu 18%,
// um ponto amarelo e um pequeno)
class _CirculosPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final k = s.width / 390;
    final h = s.height;
    void c(double x, double y, double r, Color cor) =>
        canvas.drawCircle(Offset(x * k, y), r, Paint()..color = cor);
    c(359, h * .12, h * .42, Cores.azure.withValues(alpha: .30));
    c(20, h * .95, h * .34, Cores.sky.withValues(alpha: .18));
    c(335, h * .6, 20, Cores.capture.withValues(alpha: .95));
    c(242, h * .1, 8, Cores.capture.withValues(alpha: .8));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Marca d'água de mãos: logo gigante a ~20%, girada
class MarcaDagua extends StatelessWidget {
  final double tamanho;
  final double opacidade;
  final double graus;
  const MarcaDagua(
      {super.key, this.tamanho = 300, this.opacidade = .2, this.graus = -14});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Opacity(
          opacity: opacidade,
          child: Transform.rotate(
            angle: graus * math.pi / 180,
            child: Image.asset(logoBrancaPng,
                width: tamanho, height: tamanho, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

// Fundo da marca: degradê + círculos + marca d'água
class FundoMarca extends StatelessWidget {
  final Gradient gradiente;
  final bool circulos;
  final bool marcaDagua;
  const FundoMarca({
    super.key,
    this.gradiente = Gradientes.marca,
    this.circulos = true,
    this.marcaDagua = true,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradiente),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          if (circulos)
            Positioned.fill(child: CustomPaint(painter: _CirculosPainter())),
          if (marcaDagua)
            const Positioned(right: -80, top: 10, child: MarcaDagua()),
        ],
      ),
    );
  }
}

// Topo azul das telas de acesso: canto inferior esquerdo 56, direito 140
class TopoAzul extends StatelessWidget {
  final double altura;
  final Widget child;
  final Gradient gradiente;
  final bool cantosIguais;
  final bool decoracao;
  const TopoAzul({
    super.key,
    required this.altura,
    required this.child,
    this.gradiente = Gradientes.marca,
    this.cantosIguais = false,
    this.decoracao = true,
  });

  @override
  Widget build(BuildContext context) {
    final topo = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: altura + topo,
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          bottomLeft: const Radius.circular(56),
          bottomRight: Radius.circular(cantosIguais ? 56 : 140),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: FundoMarca(
                gradiente: gradiente,
                circulos: decoracao,
                marcaDagua: decoracao,
              ),
            ),
            Positioned.fill(
              top: topo,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

// Conteúdo padrão do topo: voltar (opcional), logo ou título e apoio
class CabecalhoAcesso extends StatelessWidget {
  final String titulo;
  final String? apoio;
  final VoidCallback? voltar;
  final String rotuloVoltar;
  final bool logo;
  final double tamanhoTitulo;
  const CabecalhoAcesso({
    super.key,
    required this.titulo,
    this.apoio,
    this.voltar,
    this.rotuloVoltar = 'Voltar',
    this.logo = false,
    this.tamanhoTitulo = 34,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, voltar != null ? 6 : 18, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (voltar != null)
            BotaoIcone(
              icone: Icone.voltar,
              rotulo: rotuloVoltar,
              onPressed: voltar,
              fundo: Cores.branco(.18),
            ),
          if (logo) const LogoQuadro(tamanho: 60, raio: 20, inclinado: true),
          const SizedBox(height: 14),
          Semantics(
            header: true,
            child: Text(
              titulo,
              style: Texto.bric(tamanhoTitulo, tamanhoTitulo + 6,
                  cor: Colors.white, espacamento: -.02),
            ),
          ),
          if (apoio != null) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                apoio!,
                style: Texto.fig(16, 24,
                    peso: FontWeight.w600, cor: Cores.textOnBrand),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Cartão branco do formulário (raio 30)
class CartaoForm extends StatelessWidget {
  final Widget child;
  const CartaoForm({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Raios.cartaoForm),
        boxShadow: Sombras.cartaoForm,
      ),
      child: child,
    );
  }
}

// Barra superior branca das páginas empilhadas (Histórico, Ajustes...)
class BarraPagina extends StatelessWidget implements PreferredSizeWidget {
  final String titulo;
  final String? subtitulo;
  final Widget? acao;
  final VoidCallback? voltar;
  const BarraPagina({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.acao,
    this.voltar,
  });

  @override
  Size get preferredSize => const Size.fromHeight(78);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Cores.bg,
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.paddingOf(context).top + 6, 16, 12),
      child: Row(
        children: [
          BotaoIcone.claro(
            icone: Icone.voltar,
            rotulo: 'Voltar',
            onPressed: voltar ?? () => Navigator.maybePop(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  header: true,
                  child: Text(titulo,
                      style: Texto.h2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                if (subtitulo != null)
                  Text(subtitulo!,
                      style: Texto.fig(13, 18,
                          peso: FontWeight.w600, cor: Cores.textMuted)),
              ],
            ),
          ),
          if (acao != null) acao!,
        ],
      ),
    );
  }
}

// Papéis de cor para quadrados de ícone e chips
enum Papel { neutro, atencao, seguro, perigo }

extension PapelCores on Papel {
  Color get fundo => switch (this) {
        Papel.neutro => Cores.ice,
        Papel.atencao => Cores.captureSoft,
        Papel.seguro => Cores.successSoft,
        Papel.perigo => Cores.dangerSoft,
      };
  Color get texto => switch (this) {
        Papel.neutro => Cores.brand,
        Papel.atencao => Cores.captureSoftText,
        Papel.seguro => Cores.successSoftText,
        Papel.perigo => Cores.dangerSoftText,
      };
}

// Sequência decorativa gelo → sol claro → menta clara
Papel papelDecorativo(int i) =>
    const [Papel.neutro, Papel.atencao, Papel.seguro][i % 3];

// Quadrado colorido atrás de ícones (raio 30% do tamanho)
class QuadradoIcone extends StatelessWidget {
  final Icone icone;
  final double tamanho;
  final double tamanhoIcone;
  final Color fundo;
  final Color cor;
  const QuadradoIcone({
    super.key,
    required this.icone,
    this.tamanho = 44,
    this.tamanhoIcone = 24,
    required this.fundo,
    required this.cor,
  });

  QuadradoIcone.papel(this.icone, Papel p,
      {super.key, this.tamanho = 44, this.tamanhoIcone = 24})
      : fundo = p.fundo,
        cor = p.texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(tamanho * .32),
      ),
      child: Center(child: Ico(icone, tamanho: tamanhoIcone, cor: cor)),
    );
  }
}

// Chip de status pequeno (Entendi, Atenção, Letra reconhecida...)
class ChipStatus extends StatelessWidget {
  final String texto;
  final Papel papel;
  final Icone? icone;
  const ChipStatus(this.texto,
      {super.key, this.papel = Papel.seguro, this.icone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: papel.fundo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icone != null) ...[
            Ico(icone!, tamanho: 14, cor: papel.texto),
            const SizedBox(width: 4),
          ],
          Text(texto,
              style: Texto.fig(12, 16,
                  peso: FontWeight.w800, cor: papel.texto)),
        ],
      ),
    );
  }
}

// Pílula de vidro sobre a câmera (branco 18% + contorno branco 25%)
class PilulaVidro extends StatelessWidget {
  final Widget child;
  final Color? fundo;
  final EdgeInsets padding;
  const PilulaVidro({
    super.key,
    required this.child,
    this.fundo,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: fundo ?? Cores.branco(.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Cores.branco(.25)),
      ),
      child: DefaultTextStyle(
        style: Texto.fig(13, 18, peso: FontWeight.w700, cor: Colors.white),
        textAlign: TextAlign.center,
        child: child,
      ),
    );
  }
}

// Interruptor 54×32 (ligado em degradê azul)
class Interruptor extends StatelessWidget {
  final bool valor;
  final ValueChanged<bool> onChanged;
  final String rotulo;
  const Interruptor({
    super.key,
    required this.valor,
    required this.onChanged,
    required this.rotulo,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: valor,
      label: rotulo,
      button: true,
      child: GestureDetector(
        onTap: () => onChanged(!valor),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 54,
          height: 48,
          child: Center(
            child: AnimatedContainer(
              duration: Movimento.pressionar,
              width: 54,
              height: 32,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                gradient: valor ? Gradientes.primario : null,
                color: valor ? null : Cores.line,
                borderRadius: BorderRadius.circular(16),
              ),
              child: AnimatedAlign(
                duration: Movimento.pressionar,
                alignment:
                    valor ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Color(0x4D020F33),
                          blurRadius: 6,
                          offset: Offset(0, 2)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Faixa de erro no topo do formulário (role alert)
class FaixaErro extends StatelessWidget {
  final String texto;
  const FaixaErro(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Cores.dangerSoft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Ico(Icone.alerta, tamanho: 20, cor: Cores.dangerSoftText),
            const SizedBox(width: 10),
            Expanded(
              child: Text(texto,
                  style: Texto.fig(14, 20,
                      peso: FontWeight.w700, cor: Cores.dangerSoftText)),
            ),
          ],
        ),
      ),
    );
  }
}

// Banner branco no topo da câmera (ex.: sem conexão). Não some sozinho
// enquanto o problema existir.
class BannerAviso extends StatelessWidget {
  final String titulo;
  final String texto;
  final Icone icone;
  const BannerAviso({
    super.key,
    required this.titulo,
    required this.texto,
    this.icone = Icone.semInternet,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
                color: Color(0x4D020F33), blurRadius: 30, offset: Offset(0, 14))
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            QuadradoIcone.papel(icone, Papel.perigo),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: Texto.fig(16, 22, peso: FontWeight.w800)),
                  Text(texto,
                      style: Texto.fig(13, 18, cor: Cores.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Avatar de 30 px dos balões: mão sobre amarelo (pessoa surda) ou logo
class AvatarAutor extends StatelessWidget {
  final bool surda;
  const AvatarAutor({super.key, required this.surda});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: surda ? Cores.capture : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: surda
            ? null
            : const [
                BoxShadow(
                    color: Color(0x26052B7C),
                    blurRadius: 6,
                    offset: Offset(0, 2))
              ],
      ),
      padding: surda ? null : const EdgeInsets.all(4),
      child: surda
          ? const Center(
              child: Ico(Icone.mao, tamanho: 18, cor: Cores.brandDark))
          : Image.asset(logoPng, fit: BoxFit.contain),
    );
  }
}

// Balão da conversa. Pessoa surda: branco, canto inferior esquerdo 6.
// Você: degradê azul, canto inferior direito 6, com "Ver em LIBRAS de novo".
class Balao extends StatelessWidget {
  final bool surda;
  final String texto;
  final VoidCallback? verDeNovo;
  const Balao({
    super.key,
    required this.surda,
    required this.texto,
    this.verDeNovo,
  });

  @override
  Widget build(BuildContext context) {
    final autor = surda ? 'Pessoa surda' : 'Você · em LIBRAS';
    final rotuloAutor = Text(autor,
        style: Texto.fig(12, 16, peso: FontWeight.w700, cor: Cores.textMuted));

    final corpo = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: BoxDecoration(
        color: surda ? Colors.white : null,
        gradient: surda ? null : Gradientes.primario,
        border: surda ? Border.all(color: Cores.line, width: 1.5) : null,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(Raios.balao),
          topRight: const Radius.circular(Raios.balao),
          bottomLeft: Radius.circular(surda ? Raios.balaoCanto : Raios.balao),
          bottomRight:
              Radius.circular(surda ? Raios.balao : Raios.balaoCanto),
        ),
        boxShadow: surda
            ? null
            : const [
                BoxShadow(
                    color: Color(0x402455E8),
                    blurRadius: 18,
                    offset: Offset(0, 8))
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(texto,
              style: Texto.fig(17, 24,
                  peso: FontWeight.w700,
                  cor: surda ? Cores.text : Colors.white)),
          if (verDeNovo != null) ...[
            const SizedBox(height: 10),
            Material(
              color: Cores.branco(.2),
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: verDeNovo,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 36),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 7, 12, 7),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Ico(Icone.play, tamanho: 14, cor: Colors.white),
                        const SizedBox(width: 6),
                        Text('Ver em LIBRAS de novo',
                            style: Texto.fig(13, 18,
                                peso: FontWeight.w800, cor: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return Align(
      alignment: surda ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 310),
        child: Semantics(
          container: true,
          label: autor,
          child: Column(
            crossAxisAlignment:
                surda ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: surda
                    ? [
                        const AvatarAutor(surda: true),
                        const SizedBox(width: 6),
                        rotuloAutor
                      ]
                    : [
                        rotuloAutor,
                        const SizedBox(width: 6),
                        const AvatarAutor(surda: false)
                      ],
              ),
              const SizedBox(height: 5),
              corpo,
            ],
          ),
        ),
      ),
    );
  }
}

// Cartão "A pessoa disse" com a frase reconhecida
class CartaoFrase extends StatelessWidget {
  final String frase;
  final bool confirmar; // confiança entre 0,55 e 0,75
  final FocusNode? foco;
  const CartaoFrase(
      {super.key, required this.frase, this.confirmar = false, this.foco});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: const BoxDecoration(
        color: Cores.ice,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(26),
          topRight: Radius.circular(26),
          bottomRight: Radius.circular(26),
          bottomLeft: Radius.circular(8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AvatarAutor(surda: true),
              const SizedBox(width: 8),
              Text('A pessoa disse',
                  style: Texto.fig(13, 18,
                      peso: FontWeight.w800, cor: Cores.brand)),
              const Spacer(),
              confirmar
                  ? const ChipStatus('Confirme se foi isso mesmo',
                      papel: Papel.atencao, icone: Icone.alerta)
                  : const ChipStatus('Entendi',
                      papel: Papel.seguro, icone: Icone.check),
            ],
          ),
          const SizedBox(height: 8),
          Focus(
            focusNode: foco,
            child: Semantics(
              label: 'Frase reconhecida: $frase',
              excludeSemantics: true,
              child: Text(frase,
                  style: Texto.bric(32, 40, espacamento: -.02)),
            ),
          ),
        ],
      ),
    );
  }
}

// Cartão de resposta: o cartão inteiro é o alvo de toque (≥ 76 px)
class CartaoResposta extends StatelessWidget {
  final String texto;
  final int indice;
  final VoidCallback onTap;
  final FocusNode? foco;
  const CartaoResposta({
    super.key,
    required this.texto,
    required this.indice,
    required this.onTap,
    this.foco,
  });

  @override
  Widget build(BuildContext context) {
    final p = papelDecorativo(indice);
    return Semantics(
      button: true,
      label: '$texto. Toque para ver em LIBRAS',
      excludeSemantics: true,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Raios.opcao),
          side: const BorderSide(color: Cores.line, width: 1.5),
        ),
        child: InkWell(
          focusNode: foco,
          borderRadius: BorderRadius.circular(Raios.opcao),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 76),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  QuadradoIcone.papel(Icone.mensagem, p, tamanho: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(texto,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Texto.bodyL),
                        Text('Toque para ver em LIBRAS',
                            style: Texto.fig(12, 16,
                                peso: FontWeight.w600,
                                cor: Cores.textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: Gradientes.primario,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x4D2455E8),
                            blurRadius: 14,
                            offset: Offset(0, 6))
                      ],
                    ),
                    child: const Center(
                        child:
                            Ico(Icone.play, tamanho: 20, cor: Colors.white)),
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

// Bloco branco com linhas (Ajustes): borda, não sombra
class BlocoLista extends StatelessWidget {
  final List<Widget> linhas;
  const BlocoLista({super.key, required this.linhas});

  @override
  Widget build(BuildContext context) {
    final filhos = <Widget>[];
    for (var i = 0; i < linhas.length; i++) {
      if (i > 0) {
        filhos.add(Container(
          height: 1,
          margin: const EdgeInsets.only(left: 70, right: 16),
          color: Cores.ice,
        ));
      }
      filhos.add(linhas[i]);
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Raios.blocoAjustes),
        border: Border.all(color: Cores.line, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Column(children: filhos),
      ),
    );
  }
}

class LinhaLista extends StatelessWidget {
  final Icone icone;
  final Papel papel;
  final String titulo;
  final String? subtitulo;
  final Widget? fim;
  final VoidCallback? onTap;
  final Color? corTitulo;
  const LinhaLista({
    super.key,
    required this.icone,
    required this.papel,
    required this.titulo,
    this.subtitulo,
    this.fim,
    this.onTap,
    this.corTitulo,
  });

  @override
  Widget build(BuildContext context) {
    final conteudo = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 68),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
        child: Row(
          children: [
            QuadradoIcone.papel(icone, papel),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: Texto.fig(16, 22,
                          peso: FontWeight.w800,
                          cor: corTitulo ?? Cores.text)),
                  if (subtitulo != null)
                    Text(subtitulo!,
                        style: Texto.fig(13, 18, cor: Cores.textMuted)),
                ],
              ),
            ),
            if (fim != null) fim!,
          ],
        ),
      ),
    );
    return onTap == null ? conteudo : InkWell(onTap: onTap, child: conteudo);
  }
}

// Valor + seta no fim de uma linha que abre outra tela/sheet
class ValorSeta extends StatelessWidget {
  final String? valor;
  const ValorSeta([this.valor, Key? key]) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (valor != null)
          Text(valor!,
              style: Texto.fig(14, 18,
                  peso: FontWeight.w800, cor: Cores.action)),
        const SizedBox(width: 2),
        const Ico(Icone.seta, tamanho: 22, cor: Cores.action),
      ],
    );
  }
}

// Passo numerado das telas de boas-vindas/como funciona
class CartaoPasso extends StatelessWidget {
  final int numero;
  final Icone icone;
  final Papel papel;
  final String titulo;
  final String texto;
  const CartaoPasso({
    super.key,
    required this.numero,
    required this.icone,
    required this.papel,
    required this.titulo,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Cores.line, width: 1.5),
      ),
      child: Row(
        children: [
          QuadradoIcone.papel(icone, papel, tamanho: 56, tamanhoIcone: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(children: [
                    TextSpan(
                        text: '$numero. ',
                        style: const TextStyle(color: Cores.action)),
                    TextSpan(text: titulo),
                  ]),
                  style: Texto.fig(17, 22, peso: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(texto, style: Texto.fig(14, 20, cor: Cores.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Estrutura comum das telas com rodapé fixo e conteúdo rolável (aceita
// fonte do sistema até 130% sem cortar)
class TelaClara extends StatelessWidget {
  final PreferredSizeWidget? barra;
  final Widget corpo;
  final Widget? rodape;
  const TelaClara({super.key, this.barra, required this.corpo, this.rodape});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.bg,
      appBar: barra,
      body: Column(
        children: [
          Expanded(child: corpo),
          if (rodape != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 12, 24, 28 + MediaQuery.paddingOf(context).bottom),
              child: rodape,
            ),
        ],
      ),
    );
  }
}

// Ilustração do topo das telas de permissão: anéis + ícone em quadro
class IlustracaoAneis extends StatelessWidget {
  final Icone icone;
  final Color corIcone;
  const IlustracaoAneis(
      {super.key, required this.icone, this.corIcone = Cores.brand});

  @override
  Widget build(BuildContext context) {
    Widget anel(double d, double op) => Container(
          width: d,
          height: d,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Cores.branco(op), width: 1.5),
          ),
        );
    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          anel(300, .12),
          anel(230, .2),
          Transform.rotate(
            angle: -6 * math.pi / 180,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x59020F33),
                      blurRadius: 40,
                      offset: Offset(0, 20))
                ],
              ),
              child: Center(child: Ico(icone, tamanho: 64, cor: corIcone)),
            ),
          ),
          Positioned(
            left: 150 + 38,
            top: 150 + 46,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Cores.capture,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Cores.captureEdge, offset: Offset(0, 3))
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
