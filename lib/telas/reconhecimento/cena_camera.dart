// Peças visuais sobre a câmera: moldura por estado, linha de varredura,
// anel da contagem e pontos de leitura (Componentes, seção 5).
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

// Moldura-guia: cantos de 48 px, traço 6, raio 26, brilho na mesma cor e
// contorno fino interno (branco 14%). É um guia, não um recorte.
class MolduraCamera extends StatelessWidget {
  final Color cor;
  final double canto;
  const MolduraCamera({super.key, required this.cor, this.canto = 48});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _MolduraPainter(cor, canto),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _MolduraPainter extends CustomPainter {
  final Color cor;
  final double canto;
  _MolduraPainter(this.cor, this.canto);

  @override
  void paint(Canvas canvas, Size s) {
    const r = 26.0;
    const t = 6.0;
    final rect = Offset.zero & s;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(.75), const Radius.circular(r)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Cores.branco(.14),
    );

    final c = math.min(canto, math.min(s.width, s.height) / 2);
    final path = Path();
    const i = t / 2; // traço por dentro da área
    // superior esquerdo
    path
      ..moveTo(i, c)
      ..lineTo(i, r)
      ..arcToPoint(Offset(r, i), radius: const Radius.circular(r - i))
      ..lineTo(c, i);
    // superior direito
    path
      ..moveTo(s.width - c, i)
      ..lineTo(s.width - r, i)
      ..arcToPoint(Offset(s.width - i, r),
          radius: const Radius.circular(r - i))
      ..lineTo(s.width - i, c);
    // inferior direito
    path
      ..moveTo(s.width - i, s.height - c)
      ..lineTo(s.width - i, s.height - r)
      ..arcToPoint(Offset(s.width - r, s.height - i),
          radius: const Radius.circular(r - i))
      ..lineTo(s.width - c, s.height - i);
    // inferior esquerdo
    path
      ..moveTo(c, s.height - i)
      ..lineTo(r, s.height - i)
      ..arcToPoint(Offset(i, s.height - r),
          radius: const Radius.circular(r - i))
      ..lineTo(i, s.height - c);

    final traco = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = t
      ..strokeCap = StrokeCap.butt
      ..color = cor;
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = t
          ..color = cor.withValues(alpha: .7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawPath(path, traco);
  }

  @override
  bool shouldRepaint(_MolduraPainter o) => o.cor != cor || o.canto != canto;
}

// Linha de varredura: sobe e desce a cada 1,6 s
class LinhaVarredura extends StatefulWidget {
  const LinhaVarredura({super.key});

  @override
  State<LinhaVarredura> createState() => _LinhaVarreduraState();
}

class _LinhaVarreduraState extends State<LinhaVarredura>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Movimento.reduzido(context)) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Align(
          alignment: Alignment(
              0, -0.9 + 1.8 * Curves.easeInOut.transform(_c.value)),
          child: Container(
            height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              gradient: const LinearGradient(colors: [
                Color(0x009DBDFF),
                Cores.sky,
                Colors.white,
                Cores.sky,
                Color(0x009DBDFF),
              ]),
              boxShadow: const [BoxShadow(color: Cores.sky, blurRadius: 22)],
            ),
          ),
        ),
      ),
    );
  }
}

// Anel da contagem: número grande, anel amarelo que esvazia em 1 s e
// número que entra com escala 0,8 → 1
class AnelContagem extends StatefulWidget {
  final int numero;
  const AnelContagem({super.key, required this.numero});

  @override
  State<AnelContagem> createState() => _AnelContagemState();
}

class _AnelContagemState extends State<AnelContagem>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
      vsync: this, duration: const Duration(seconds: 1))
    ..forward();

  @override
  void didUpdateWidget(AnelContagem old) {
    super.didUpdateWidget(old);
    if (old.numero != widget.numero) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduzido = Movimento.reduzido(context);
    return Semantics(
      label: 'Começa em ${widget.numero} segundos',
      liveRegion: true,
      child: SizedBox(
        width: 190,
        height: 190,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final escala = reduzido
                ? 1.0
                : .8 + .2 * Curves.easeOut.transform((_c.value * 4).clamp(0, 1));
            return CustomPaint(
              painter: _AnelPainter(reduzido ? 1 : 1 - _c.value),
              child: Center(
                child: Transform.scale(
                  scale: escala,
                  child: Text('${widget.numero}', style: Texto.counter),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AnelPainter extends CustomPainter {
  final double resto;
  _AnelPainter(this.resto);

  @override
  void paint(Canvas canvas, Size s) {
    final centro = s.center(Offset.zero);
    final raio = s.width / 2 - 8;
    canvas.drawCircle(
        centro,
        raio,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..color = Cores.branco(.2));
    canvas.drawArc(
      Rect.fromCircle(center: centro, radius: raio),
      -math.pi / 2,
      2 * math.pi * resto,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..color = Cores.capture,
    );
  }

  @override
  bool shouldRepaint(_AnelPainter o) => o.resto != resto;
}

// Três pontos amarelos que pulsam em sequência (200 ms de defasagem)
class PontosLeitura extends StatefulWidget {
  const PontosLeitura({super.key});

  @override
  State<PontosLeitura> createState() => _PontosLeituraState();
}

class _PontosLeituraState extends State<PontosLeitura>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduzido = Movimento.reduzido(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          double op = const [1.0, .6, .3][i];
          if (!reduzido) {
            final fase = (_c.value - i * (200 / 1200)) % 1;
            op = .3 + .7 * (1 - (fase * 2 - 1).abs());
          }
          return Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Cores.capture.withValues(alpha: op),
            ),
          );
        }),
      ),
    );
  }
}
