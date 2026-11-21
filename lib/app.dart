import 'package:flutter/material.dart';

import 'camera.dart';
import 'telas/abertura.dart';
import 'telas/boas_vindas.dart';
import 'telas/cadastro.dart';
import 'telas/login.dart';
import 'telas/permissao_camera.dart';
import 'telas/recuperar_senha.dart';
import 'telas/rotas.dart';
import 'theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  Route<dynamic> _rota(RouteSettings s) {
    final arg = s.arguments;
    Widget tela;
    switch (s.name) {
      case Rotas.login:
        tela = LoginPage(aviso: arg is String ? arg : null);
      case Rotas.cadastro:
        tela = const CadastroPage();
      case Rotas.recuperarSenha:
        tela = RecuperarSenhaPage(emailInicial: arg is String ? arg : '');
      case Rotas.boasVindas:
        tela = const BoasVindasPage();
      case Rotas.comoFunciona:
        tela = const BoasVindasPage(comoFunciona: true);
      case Rotas.permissaoCamera:
        tela = PermissaoCameraPage(negada: arg == true);
      case Rotas.home:
        tela = const CameraPage();
      default:
        tela = const AberturaPage();
    }
    return MaterialPageRoute(builder: (_) => tela, settings: s);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sinaliza',
      theme: AppTheme.lightTheme(),
      initialRoute: Rotas.abertura,
      onGenerateRoute: _rota,
      // Aceita aumento de fonte do sistema até 130%
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(maxScaleFactor: 1.3),
          ),
          child: child!,
        );
      },
    );
  }
}
