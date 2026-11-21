// Ajustes do app guardados no aparelho (Settings do modelo de dados)
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum VelocidadeVideo { normal, lenta }

class Ajustes extends ChangeNotifier {
  Ajustes._();
  static final Ajustes instancia = Ajustes._();

  SharedPreferences? _prefs;

  int contagemSegundos = 3; // 0, 3 ou 5
  VelocidadeVideo velocidade = VelocidadeVideo.normal;
  bool legenda = true;
  bool salvarHistorico = true;
  bool cameraFrontal = true;
  // Boas-vindas e permissão aparecem uma única vez por aparelho
  bool primeiroAcessoFeito = false;

  Future<void> carregar() async {
    try {
      final p = await SharedPreferences.getInstance();
      _prefs = p;
      contagemSegundos = p.getInt('contagem') ?? 3;
      velocidade = p.getString('velocidade') == 'lenta'
          ? VelocidadeVideo.lenta
          : VelocidadeVideo.normal;
      legenda = p.getBool('legenda') ?? true;
      salvarHistorico = p.getBool('salvarHistorico') ?? true;
      cameraFrontal = p.getBool('cameraFrontal') ?? true;
      primeiroAcessoFeito = p.getBool('primeiroAcessoFeito') ?? false;
    } catch (e) {
      debugPrint('Ajustes indisponíveis, usando padrões: $e');
    }
  }

  void definirContagem(int s) {
    contagemSegundos = s;
    _prefs?.setInt('contagem', s);
    notifyListeners();
  }

  void definirVelocidade(VelocidadeVideo v) {
    velocidade = v;
    _prefs?.setString('velocidade', v.name);
    notifyListeners();
  }

  void definirLegenda(bool v) {
    legenda = v;
    _prefs?.setBool('legenda', v);
    notifyListeners();
  }

  void definirSalvarHistorico(bool v) {
    salvarHistorico = v;
    _prefs?.setBool('salvarHistorico', v);
    notifyListeners();
  }

  void definirCameraFrontal(bool v) {
    cameraFrontal = v;
    _prefs?.setBool('cameraFrontal', v);
    notifyListeners();
  }

  void marcarPrimeiroAcesso() {
    primeiroAcessoFeito = true;
    _prefs?.setBool('primeiroAcessoFeito', true);
  }
}
