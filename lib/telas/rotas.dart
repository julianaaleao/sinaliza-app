// Rotas do app (mapa de telas da página Navegação)
import 'package:flutter/material.dart';

import '../camera_stub.dart'
    if (dart.library.html) '../camera_web_impl.dart'
    if (dart.library.io) '../camera_android.dart';
import '../servicos/ajustes.dart';

class Rotas {
  static const abertura = '/';
  static const login = '/login';
  static const cadastro = '/cadastro';
  static const recuperarSenha = '/recuperar-senha';
  static const boasVindas = '/boas-vindas';
  static const comoFunciona = '/como-funciona';
  static const permissaoCamera = '/permissao-camera';
  static const home = '/home';
  static const historico = '/historico';
  static const historicoDetalhe = '/historico/detalhe';
  static const ajustes = '/ajustes';
  static const privacidade = '/privacidade';
}

// Depois do login/cadastro ou ao abrir com sessão: 05 no primeiro acesso,
// 06 se a câmera ainda não foi liberada, senão 07.
Future<void> irParaInicio(BuildContext context) async {
  final navegador = Navigator.of(context);
  String destino;
  if (!Ajustes.instancia.primeiroAcessoFeito) {
    destino = Rotas.boasVindas;
  } else {
    destino = await permissaoCamera() == PermissaoCamera.concedida
        ? Rotas.home
        : Rotas.permissaoCamera;
  }
  navegador.pushNamedAndRemoveUntil(destino, (_) => false);
}
