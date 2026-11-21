// Design tokens do Sinaliza (canvas "Sinaliza · Novo design do app",
// página Design tokens). Use só estes valores nas telas.
import 'package:flutter/material.dart';

class Cores {
  // Azuis
  static const brand = Color(0xFF052B7C); // azul-marinho da logo
  static const brandDark = Color(0xFF031A4F); // marinho profundo
  static const night = Color(0xFF020F33); // extremos de degradê e scrims
  static const action = Color(0xFF2455E8); // links, foco, seleção
  static const azure = Color(0xFF4C8DFF); // só decoração
  static const sky = Color(0xFF9DBDFF); // moldura de leitura
  static const ice = Color(0xFFE3ECFF);
  static const bg = Color(0xFFF2F6FF);
  static const card = Color(0xFFFFFFFF);
  static const line = Color(0xFFD3DEF7);
  static const text = Color(0xFF0B1B4A);
  static const textMuted = Color(0xFF4A5A86);
  static const textOnBrand = Color(0xFFDCE8FF);

  // Amarelo: exclusivo da ação de ler sinal
  static const capture = Color(0xFFFFC83D);
  static const captureEdge = Color(0xFFD99A00);
  static const captureSoft = Color(0xFFFFF1C7);
  static const captureSoftText = Color(0xFF7A5200);

  // Menta: deu certo
  static const success = Color(0xFF19C39A);
  static const successSoft = Color(0xFFD8F6EC);
  static const successSoftText = Color(0xFF0B7A5E);

  // Coral: erro ou ação destrutiva
  static const danger = Color(0xFFFF6B5A);
  static const dangerSoft = Color(0xFFFFE6E2);
  static const dangerSoftText = Color(0xFFB3261E);
  static const dangerSolid = Color(0xFFC62F22);

  // Desativado
  static const disabledBg = Color(0xFFDCE4F8);
  static const disabledText = Color(0xFF55658F);

  static Color branco(double opacidade) =>
      Colors.white.withValues(alpha: opacidade);
  static Color noite(double opacidade) => night.withValues(alpha: opacidade);
}

class Gradientes {
  // CSS 160deg ≈ de cima/esquerda para baixo/direita
  static const marca = LinearGradient(
    begin: Alignment(-0.35, -1),
    end: Alignment(0.35, 1),
    colors: [
      Color(0xFF2F66F4),
      Color(0xFF0B3AAE),
      Color(0xFF052B7C),
      Color(0xFF031A4F),
    ],
    stops: [0, .42, .78, 1],
  );

  static const primario = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3068F5), Color(0xFF1A44CC), Color(0xFF0B2F94)],
    stops: [0, .55, 1],
  );

  static const painel = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0B3399), Color(0xFF052470), Color(0xFF031A4F)],
    stops: [0, .55, 1],
  );

  // Fundo atrás da câmera (enquanto carrega) e cena do vídeo
  static const cenaCamera = RadialGradient(
    center: Alignment(0, -0.52),
    radius: 0.9,
    colors: [Color(0xFF3B6CEA), Color(0xFF153F9F), Color(0xFF061E5C)],
    stops: [0, .45, 1],
  );

  static const cenaVideo = RadialGradient(
    center: Alignment(0, -0.84),
    radius: 1.2,
    colors: [Color(0xFF1D4FD0), Color(0xFF0A2A7A), Color(0xFF020F33)],
    stops: [0, .42, 1],
  );

  static const quadroVideo = LinearGradient(
    begin: Alignment(-0.17, -1),
    end: Alignment(0.17, 1),
    colors: [Color(0xFF4B6FD8), Color(0xFF16285F)],
  );

  // Topo da tela "câmera desativada"
  static const erro = LinearGradient(
    begin: Alignment(-0.35, -1),
    end: Alignment(0.35, 1),
    colors: [Color(0xFFC8362A), Color(0xFF7A1A3A), Color(0xFF031A4F)],
    stops: [0, .5, 1],
  );
}

class Fontes {
  static const titulo = 'BricolageGrotesque';
  static const texto = 'Figtree';
}

// Estilos de texto (tokens text.*)
class Texto {
  static const _b = Fontes.titulo;
  static const _f = Fontes.texto;

  static TextStyle bric(double tamanho, double linha,
          {FontWeight peso = FontWeight.w800,
          Color cor = Cores.text,
          double espacamento = 0}) =>
      TextStyle(
        fontFamily: _b,
        fontWeight: peso,
        fontSize: tamanho,
        height: linha / tamanho,
        color: cor,
        letterSpacing: espacamento * tamanho,
      );

  static TextStyle fig(double tamanho, double linha,
          {FontWeight peso = FontWeight.w500, Color cor = Cores.text}) =>
      TextStyle(
        fontFamily: _f,
        fontWeight: peso,
        fontSize: tamanho,
        height: linha / tamanho,
        color: cor,
      );

  static final counter = bric(112, 112, cor: Colors.white);
  static final brand = bric(52, 56, cor: Colors.white, espacamento: -.03);
  static final display = bric(34, 40, cor: Colors.white, espacamento: -.02);
  static final h2 = bric(26, 30, espacamento: -.01);
  static final h3 = bric(19, 24);
  static final bodyL = fig(18, 24, peso: FontWeight.w800);
  static final body = fig(16, 24);
  static final label = fig(14, 18, peso: FontWeight.w700);
  static final caption = fig(13, 18, peso: FontWeight.w600);
  static final button = fig(17, 20, peso: FontWeight.w800);
}

class Raios {
  static const botao = 20.0;
  static const campo = 18.0;
  static const cartaoForm = 30.0;
  static const opcao = 24.0;
  static const blocoAjustes = 26.0;
  static const painel = 34.0;
  static const balao = 22.0;
  static const balaoCanto = 6.0;
}

class Sombras {
  static const botaoPrimario = [
    BoxShadow(
        color: Color(0x522455E8), blurRadius: 22, offset: Offset(0, 10)),
  ];
  static const cartaoForm = [
    BoxShadow(
        color: Color(0x29052B7C), blurRadius: 40, offset: Offset(0, 18)),
  ];
  static const painel = [
    BoxShadow(
        color: Color(0x59020F33), blurRadius: 40, offset: Offset(0, -14)),
  ];
  static const painelClaro = [
    BoxShadow(
        color: Color(0x38020F33), blurRadius: 40, offset: Offset(0, -14)),
  ];
  static const logo = [
    BoxShadow(
        color: Color(0x47020F33), blurRadius: 30, offset: Offset(0, 14)),
  ];
  static const botaoBranco = [
    BoxShadow(
        color: Color(0x1F052B7C), blurRadius: 12, offset: Offset(0, 4)),
  ];
  static const dialogo = [
    BoxShadow(
        color: Color(0x66020F33), blurRadius: 60, offset: Offset(0, 30)),
  ];
}

// Movimento
class Movimento {
  static const pressionar = Duration(milliseconds: 120);
  static const sheet = Duration(milliseconds: 280);
  static const curvaSheet = Cubic(.2, .8, .2, 1);
  static const letra = Duration(milliseconds: 240);
  static const chip = Duration(milliseconds: 160);
  static const fade = Duration(milliseconds: 200);

  // "Reduzir movimento" do sistema
  static bool reduzido(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}
